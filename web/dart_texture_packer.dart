import 'dart:html';
import 'dart:async';
import 'dart:json' as json;
import 'package:dart_texture_packer/texture_packer.dart' as atlas;
import 'package:asset_pack/asset_pack_file.dart';
CanvasElement canvas;
atlas.Settings settings;
atlas.TexturePacker packer;
var file;
var atlasLink, atlasDataLink, atlasPackLink;
void main() {
  atlasLink = query('#atlas-download');
  atlasDataLink = query('#atlas-data-download');
  atlasPackLink = query('#atlas-pack-download');
  //atlasLink.download = "Atlaaaas.png";

  print("link $atlasLink");
  canvas = new CanvasElement()
  ..width = 512
  ..height = 512
  ..onDragOver.listen(_onDragOver)
  ..onClick.listen(_onClick)
  ..onDrop.listen(_onDrop);
  document.body.nodes.add(canvas);
  settings = new atlas.Settings.zero()
  ..fast = false
  ..rotation = true
  ..alphaThreshold = 0
  ..stripWhitespaceX = true
  ..stripWhitespaceY = true
  ..forceSquareOutput = true;
  packer = new atlas.TexturePacker(settings);
  //packer.addImage(atlas.BufferedImage..fromImage(256,256), "test");
  file = new atlas.File()
  ..atlas = canvas
  ..atlasData = {};
  /*var b0 = atlas.BufferedImage.fromUrl("laurels.png")
  ..then((value) {
    packer.addImage(value, "laurels");
    //packer.pack(file, "test");
  });
  var b1 = atlas.BufferedImage.fromUrl("pointer.png")
  ..then((value) {
    packer.addImage(value, "pointer");
    //
  });
  Future.wait([b0,b1]).then((value) {
    packer.pack(file, "test");
  });
  */

}

void _onClick(MouseEvent e) {
  packer.pack(file, "test2");

}

void _onDoubleClick(MouseEvent e) {
  var url = canvas.toDataUrl("image/png", 1.0);
  window.open(url, "atlas");
  e.preventDefault();

}
void _onDragEnd(MouseEvent e) {
}

void _onDrag(MouseEvent e) {
}
void _onDragOver(MouseEvent e) {
  e.preventDefault();
  print(e.dataTransfer.files);
}

void _onDragLeave(MouseEvent e) {

}
void _onDragEnter(MouseEvent e) {

}
void _onDrop(MouseEvent e) {
  print(e.dataTransfer.types);
  List<Future> futures = [];
  for(var file in e.dataTransfer.files) {
    if(file.type == "image/gif" || file.type == "image/png" || file.type == "image/jpeg") {
      var name = file.name;
      var url = Url.createObjectUrl(file.slice());
      var img = atlas.BufferedImage.fromUrl(url)
      ..then((value){
        packer.addImage(value, name);
        var file = new atlas.File()
        ..atlas = canvas
        ..atlasData = {};
        packer.pack(file, "test2");
      });
      futures.add(img);
    }
    print(file.type);
  }
  if(futures.length > 0) {
    Future.wait(futures).then((value){
      var file = new atlas.File()
      ..atlas = canvas
      ..atlasData = {};
      packer.pack(file, "test2");
      atlasDataLink.href = "data:application/json;charset=US-ASCII,${json.stringify(file.atlasData)}"; //Url.createObjectUrl(json.stringify(file.atlasData));
      atlasLink.href = canvas.toDataUrl("image/png", 1.0);
      var ap = new AssetPackFile()
      ..merge([new AssetPackFileAsset("atlas.png","atlas.png","tex2d",{},{}),
               new AssetPackFileAsset("atlas.atlas","atlas.atlas","json",{},{})]
      );
      atlasPackLink.href = "data:application/json;charset=US-ASCII,${json.stringify(ap.toJson())}";

      print(json.stringify(ap.toJson()));
    });
  }


  e.preventDefault();

}

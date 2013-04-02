part of texture_packer;
class BufferedImage {
  Html.ImageData _data;
  List<int> get _pixeldata => _data.data;
  int _width, _height;
  Html.CanvasElement canvas;
  Html.CanvasRenderingContext2D _context;

  int get width => _width;
  int get height => _height;


  BufferedImage(int width, int height) {
    canvas = new Html.CanvasElement()
    ..width
    ..height;
    _context = canvas.context2d;
    _getImageData();
  }
  BufferedImage.fromImage(Html.ImageElement img) {
    canvas = new Html.CanvasElement()
    ..width = img.width
    ..height = img.height;
    _context = canvas.context2d;
    _context.drawImage(img, 0, 0);
    _getImageData();
  }
  BufferedImage.fromBufferedImage(BufferedImage img, int left, int top, int width, int height) {
    canvas = new Html.CanvasElement()
    ..width = img.width
    ..height = img.height;
    _context = canvas.context2d;
    //_context.drawImage(img, 0, 0);
    _context.drawImageScaled(img.canvas, left, top, width, height);
    _getImageData();
  }

  static Future<BufferedImage> fromUrl(String src) {
    Completer<BufferedImage> comp = new Completer<BufferedImage>();
    var img = new Html.ImageElement(src: src);
    img.onLoad.listen((e){
      comp.complete(new BufferedImage.fromImage(img));
    });
    return comp.future;
  }



  void _getImageData() {
    _data = _context.getImageData(0, 0, canvas.width, canvas.height);
    _width = canvas.width;
    _height = canvas.height;
  }



  int getRed(int x, int y) => _pixeldata[(_width * y  + x) * 4 + 0];
  int getGreen(int x, int y) => _pixeldata[(_width * y  + x) * 4 + 1];
  int getBlue(int x, int y) => _pixeldata[(_width * y  + x) * 4 + 2];
  int getAlpha(int x, int y) => _pixeldata[(_width * y  + x) * 4 + 3];
  void getPixel(int x, int y, List<int> rgba) {
    rgba[0] = getRed(x,y);
    rgba[0] = getGreen(x,y);
    rgba[0] = getBlue(x,y);
    rgba[0] = getAlpha(x,y);
  }

  int getWidth() => 0;
  int getHeight() => 0;

}


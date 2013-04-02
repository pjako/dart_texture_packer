part of texture_packer;
/** @author Nathan Sweet */
class Rect {
  String name;
  BufferedImage image;
  int offsetX, offsetY, originalWidth, originalHeight;
  int x, y, width = 0, height = 0;
  int index;
  bool rotated;
  List<String> aliases = new List();
  List<int> splits;
  List<int> pads;
  bool canRotate = true;

  int score1, score2;

  Rect(BufferedImage source, int left, int top, int newWidth, int newHeight) {
    image = new BufferedImage.fromBufferedImage(source,left,top,newWidth,newHeight);
    /*image = new BufferedImage(source.getColorModel(), source.getRaster().createWritableChild(left, top, newWidth, newHeight,
      0, 0, null), source.getColorModel().isAlphaPremultiplied(), null);*/
    offsetX = left;
    offsetY = top;
    originalWidth = source.getWidth();
    originalHeight = source.getHeight();
    width = newWidth;
    height = newHeight;
  }

  Rect.zero() {
  }

  Rect.fromRect(Rect rect) {
    setSize(rect);
  }

  void setSize (Rect rect) {
    x = rect.x;
    y = rect.y;
    width = rect.width;
    height = rect.height;
  }

  void set (Rect rect) {
    name = rect.name;
    image = rect.image;
    offsetX = rect.offsetX;
    offsetY = rect.offsetY;
    originalWidth = rect.originalWidth;
    originalHeight = rect.originalHeight;
    x = rect.x;
    y = rect.y;
    width = rect.width;
    height = rect.height;
    index = rect.index;
    rotated = rect.rotated;
    aliases = rect.aliases;
    splits = rect.splits;
    pads = rect.pads;
    canRotate = rect.canRotate;
    score1 = rect.score1;
    score2 = rect.score2;
  }

  bool equals (Object obj) {
    if (this == obj) return true;
    if (obj == null) return false;
    if (!(obj is Rect)) return false;
    Rect other = obj as Rect;
      if (name == null) {
        if (other.name != null) return false;
      } else if (name != other.name) return false;
      return true;
    }

  String toString () {
    return "['$name', $x, $y, $width, $height]";
  }
}


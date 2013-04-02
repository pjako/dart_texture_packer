part of texture_packer;
/** @author Nathan Sweet */
class Settings {
  bool pot = true;
  int paddingX = 2, paddingY = 2;
  bool edgePadding = true;
  bool duplicatePadding = true;
  bool rotation;
  int minWidth = 16, minHeight = 16;
  int maxWidth = 512, maxHeight = 512;
  bool forceSquareOutput = false;
  bool stripWhitespaceX, stripWhitespaceY;
  int alphaThreshold;
  TextureFilter filterMin, filterMag; // = TextureFilter.Nearest, filterMag = TextureFilter.Nearest;
  TextureWrap wrapX,wrapY;// = TextureWrap.ClampToEdge, wrapY = TextureWrap.ClampToEdge;
  Format format; // = Format.RGBA8888;
  bool alias = true;
  String outputFormat = "png";
  double jpegQuality = 0.9;
  bool ignoreBlankImages = true;
  bool fast = false;
  bool debug = false;
  bool combineSubdirectories;
  bool jsonOutput = true;
  bool flattenPaths = true;

  Settings.zero() {
    stripWhitespaceX = false;
    stripWhitespaceY = false;
    filterMin = TextureFilter.Nearest;
    filterMag = TextureFilter.Nearest;
    wrapX = TextureWrap.ClampToEdge;
    wrapY = TextureWrap.ClampToEdge;
    format = Format.RGBA8888;
  }

  Settings (Settings settings) {
    fast = settings.fast;
    rotation = settings.rotation;
    pot = settings.pot;
    minWidth = settings.minWidth;
    minHeight = settings.minHeight;
    maxWidth = settings.maxWidth;
    maxHeight = settings.maxHeight;
    paddingX = settings.paddingX;
    paddingY = settings.paddingY;
    edgePadding = settings.edgePadding;
    alphaThreshold = settings.alphaThreshold;
    ignoreBlankImages = settings.ignoreBlankImages;
    stripWhitespaceX = settings.stripWhitespaceX;
    stripWhitespaceY = settings.stripWhitespaceY;
    alias = settings.alias;
    format = settings.format;
    jpegQuality = settings.jpegQuality;
    outputFormat = settings.outputFormat;
    filterMin = settings.filterMin;
    filterMag = settings.filterMag;
    wrapX = settings.wrapX;
    wrapY = settings.wrapY;
    duplicatePadding = settings.duplicatePadding;
    debug = settings.debug;
    combineSubdirectories = settings.combineSubdirectories;
    jsonOutput = settings.jsonOutput;
    flattenPaths = settings.flattenPaths;
  }
}


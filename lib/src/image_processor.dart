part of texture_packer;

class ImageProcessor {
  static final BufferedImage emptyImage = new BufferedImage(1, 1);
  //static Pattern indexPattern = Pattern.compile("(.+)_(\\d+)$");

  //String rootPath;
  final Settings settings;
  final Map<String, Rect> crcs = new Map<String, Rect>();
  final List<Rect> rects = new List();

  ImageProcessor (/*File rootDir, */Settings this.settings) {
    //rootPath = rootDir.getAbsolutePath().replace('\\', '/');
    //if (!rootPath.endsWith("/")) rootPath += "/";
  }

  void addImage (BufferedImage image, String name) {
    // Strip root dir off front of image path.
    //String name = file.getAbsolutePath().replace('\\', '/');
    //if (!name.startsWith(rootPath)) throw new RuntimeException("Path '" + name + "' does not start with root: " + rootPath);
    //name = name.substring(rootPath.length());

    // Strip extension.
    //int dotIndex = name.lastIndexOf('.');
    //if (dotIndex != -1) name = name.substring(0, dotIndex);

    Rect rect;

    // Strip ".9" from file name, read ninepatch split pixels, and strip ninepatch split pixels.
    /*List<int> splits = null;
    List<int> pads = null;
    if (name.endsWith(".9")) {
      name = name.substring(0, name.length() - 2);
      splits = getSplits(image, name);
      pads = getPads(image, name, splits);
      // Strip split pixels.
      BufferedImage newImage = new BufferedImage(image.width - 2, image.height - 2, BufferedImage.TYPE_4BYTE_ABGR);
      newImage.getGraphics().drawImage(image, 0, 0, newImage.width, newImage.height, 1, 1, image.width - 1,
        image.height - 1, null);
      image = newImage;
      // Ninepatches won't be rotated or whitespace stripped.
      rect = new Rect(image, 0, 0, image.width, image.height);
      rect.splits = splits;
      rect.pads = pads;
      rect.canRotate = false;
    }

    // Strip digits off end of name and use as index.
    Matcher matcher = indexPattern.matcher(name);
    int index = -1;
    if (matcher.matches()) {
      name = matcher.group(1);
      index = Integer.parseInt(matcher.group(2));
    }
    */

    if (rect == null) {
      rect = createRect(image);
      if (rect == null) {
        print("Ignoring blank input image: " + name);
        return;
      }
    }

    rect.name = name;
    rect.index = -1;
    //rect.index = index;


    if (settings.alias) {
      String crc = hash(rect.image);
      Rect existing = crcs[crc];
      if (existing != null) {
        print("${rect.name} (alias of ${existing.name})");
        existing.aliases.add(rect.name);
        return;
      }
      crcs[crc] = rect;
    }

    rects.add(rect);
  }

  List<Rect> getImages () {
    return rects;
  }

  /** Strips whitespace and returns the rect, or null if the image should be ignored. */
  Rect createRect (BufferedImage source) {
    BufferedImage alphaRaster = source;
    if (alphaRaster == null || (!settings.stripWhitespaceX && !settings.stripWhitespaceY))
      return new Rect(source, 0, 0, source.width, source.height);

    int a = 0;
    int top = 0;
    int bottom = source.height;
    if (settings.stripWhitespaceX) {
      var outer = false;
      for(int y = 0; y < source.height; y++) {
        if(outer == true) break;
        for(int x = 0; x < source.width; x++) {
          //alphaRaster.getDataElements(x, y, a);
          int alpha = alphaRaster.getAlpha(x, y);
          if (alpha < 0) alpha += 256;
          if (alpha > settings.alphaThreshold) {
            outer = true;

            break;
          } //break outer;
        }
        top++;
      }
      outer = false;
      //outer:
      for(int y = source.height; --y >= top;) {
        if(outer == true) break;
        for(int x = 0; x < source.width; x++) {
          //alphaRaster.getDataElements(x, y, a);
          int alpha = alphaRaster.getAlpha(x, y);
          if (alpha < 0) alpha += 256;
          if (alpha > settings.alphaThreshold) {
            outer = true;
            break;
          }
        }
        bottom--;
      }
    }
    int left = 0;
    int right = source.width;
    if (settings.stripWhitespaceY) {
      outer:
      for(int x = 0; x < source.width; x++) {
        for(int y = top; y < bottom; y++) {
          //alphaRaster.getDataElements(x, y, a);
          int alpha = alphaRaster.getAlpha(x, y);
          if (alpha < 0) alpha += 256;
          if (alpha > settings.alphaThreshold) break outer;
        }
        left++;
      }
      outer:
      for(int x = source.width; --x >= left;) {
        for(int y = top; y < bottom; y++) {
          //alphaRaster.getDataElements(x, y, a);
          int alpha = alphaRaster.getAlpha(x, y);
          if (alpha < 0) alpha += 256;
          if (alpha > settings.alphaThreshold) break outer;
        }
        right--;
      }
    }
    int newWidth = right - left;
    int newHeight = bottom - top;
    if (newWidth <= 0 || newHeight <= 0) {
      if (settings.ignoreBlankImages)
        return null;
      else
        return new Rect(emptyImage, 0, 0, 1, 1);
    }
    return new Rect(source, left, top, newWidth, newHeight);
  }

  String splitError (int x, int y, List<int> rgba, String name) => "splitError"; /*{
    throw new RuntimeException("Invalid " + name + " ninepatch split pixel at " + x + ", " + y + ", rgba: " + rgba[0] + ", "
      + rgba[1] + ", " + rgba[2] + ", " + rgba[3]);
  }*/

  /** Returns the splits, or null if the image had no splits or the splits were only a single region. Splits are an int[4] that
   * has left, right, top, bottom. */
  List<int> getSplits (BufferedImage image, String name) {
    BufferedImage raster = image;

    int startX = getSplitPoint(raster, name, 1, 0, true, true);
    int endX = getSplitPoint(raster, name, startX, 0, false, true);
    int startY = getSplitPoint(raster, name, 0, 1, true, false);
    int endY = getSplitPoint(raster, name, 0, startY, false, false);

    // Ensure pixels after the end are not invalid.
    getSplitPoint(raster, name, endX + 1, 0, true, true);
    getSplitPoint(raster, name, 0, endY + 1, true, false);

    // No splits, or all splits.
    if (startX == 0 && endX == 0 && startY == 0 && endY == 0) return null;

    // Subtraction here is because the coordinates were computed before the 1px border was stripped.
    if (startX != 0) {
      startX--;
      endX = raster.width - 2 - (endX - 1);
    } else {
      // If no start point was ever found, we assume full stretch.
      endX = raster.width - 2;
    }
    if (startY != 0) {
      startY--;
      endY = raster.height - 2 - (endY - 1);
    } else {
      // If no start point was ever found, we assume full stretch.
      endY = raster.height - 2;
    }

    return [startX, endX, startY, endY];
  }

  /** Returns the pads, or null if the image had no pads or the pads match the splits. Pads are an int[4] that has left, right,
   * top, bottom. */
  List<int> getPads (BufferedImage image, String name, List<int> splits) {
    BufferedImage raster = image;

    int bottom = raster.height - 1;
    int right = raster.width - 1;

    int startX = getSplitPoint(raster, name, 1, bottom, true, true);
    int startY = getSplitPoint(raster, name, right, 1, true, false);

    // No need to hunt forthe end if a start was never found.
    int endX = 0;
    int endY = 0;
    if (startX != 0) endX = getSplitPoint(raster, name, startX + 1, bottom, false, true);
    if (startY != 0) endY = getSplitPoint(raster, name, right, startY + 1, false, false);

    // Ensure pixels after the end are not invalid.
    getSplitPoint(raster, name, endX + 1, bottom, true, true);
    getSplitPoint(raster, name, right, endY + 1, true, false);

    // No pads.
    if (startX == 0 && endX == 0 && startY == 0 && endY == 0) {
      return null;
    }

    // -2 here is because the coordinates were computed before the 1px border was stripped.
    if (startX == 0 && endX == 0) {
      startX = -1;
      endX = -1;
    } else {
      if (startX > 0) {
        startX--;
        endX = raster.width - 2 - (endX - 1);
      } else {
        // If no start point was ever found, we assume full stretch.
        endX = raster.width - 2;
      }
    }
    if (startY == 0 && endY == 0) {
      startY = -1;
      endY = -1;
    } else {
      if (startY > 0) {
        startY--;
        endY = raster.height - 2 - (endY - 1);
      } else {
        // If no start point was ever found, we assume full stretch.
        endY = raster.height - 2;
      }
    }

    List<int> pads = [startX, endX, startY, endY];

    // orginally tests if it has the same elements
    if (splits != null && pads == splits) {
      return null;
    }

    return pads;
  }

  /** Hunts forthe start or end of a sequence of split pixels. Begins searching at (startX, startY) then follows along the x or y
   * axis (depending on value of xAxis) forthe first non-transparent pixel if startPoint is true, or the first transparent pixel
   * if startPoint is false. Returns 0 if none found, as 0 is considered an invalid split point being in the outer border which
   * will be stripped. */
  int getSplitPoint (BufferedImage raster, String name, int startX, int startY, bool startPoint, bool xAxis) {
    List<int> rgba = new List<int>(4);

    int next = xAxis ? startX : startY;
    int end = xAxis ? raster.width : raster.width;
    int breakA = startPoint ? 255 : 0;

    int x = startX;
    int y = startY;
    while (next != end) {
      if (xAxis)
        x = next;
      else
        y = next;

      raster.getPixel(x, y, rgba);
      if (rgba[3] == breakA) return next;

      if (!startPoint && (rgba[0] != 0 || rgba[1] != 0 || rgba[2] != 0 || rgba[3] != 255)) splitError(x, y, rgba, name);

      next++;
    }

    return 0;
  }


  // This is not right but should work just fine fo now
  static String hash(BufferedImage image) => image.hashCode.toString();
/*{

    try {
      MessageDigest digest = MessageDigest.getInstance("SHA1");
      int width = image.width;
      int height = image.height;
      if (image.getType() != BufferedImage.TYPE_INT_ARGB) {
        BufferedImage newImage = new BufferedImage(width, height, BufferedImage.TYPE_INT_ARGB);
        newImage.getGraphics().drawImage(image, 0, 0, null);
        image = newImage;
      }
      WritableRaster raster = image.getRaster();
      List<int> pixels = new int[width];
      for(int y = 0; y < height; y++) {
        raster.getDataElements(0, y, width, 1, pixels);
        for(int x = 0; x < width; x++) {
          int rgba = pixels[x];
          digest.update((byte)(rgba >> 24));
          digest.update((byte)(rgba >> 16));
          digest.update((byte)(rgba >> 8));
          digest.update((byte)rgba);
        }
      }
      return new BigInteger(1, digest.digest()).toString(16);
    } catch (NoSuchAlgorithmException ex) {
      throw new RuntimeException(ex);
    }
  }*/
}


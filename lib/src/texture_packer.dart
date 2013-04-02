part of texture_packer;
/** @author Nathan Sweet */
class TexturePacker {
  final Settings settings;
  /*final */MaxRectsPacker maxRectsPacker;
  /*final */ImageProcessor imageProcessor;

  TexturePacker (/*File rootDir,*/Settings this.settings){
    //this.settings = settings;

    /*
    if (settings.pot) {
      if (settings.maxWidth != MathUtils.nextPowerOfTwo(settings.maxWidth))
        throw new RuntimeException("If pot is true, maxWidth must be a power of two: " + settings.maxWidth);
      if (settings.maxHeight != MathUtils.nextPowerOfTwo(settings.maxHeight))
        throw new RuntimeException("If pot is true, maxHeight must be a power of two: " + settings.maxHeight);
    }
    */

    maxRectsPacker = new MaxRectsPacker(settings);
    imageProcessor = new ImageProcessor(settings);
  }

  void addImage (BufferedImage file, String name) {
    imageProcessor.addImage(file,name);
  }

  void pack (File outputDir, String packFileName) {
    //outputDir.mkdirs();

    //if (packFileName.indexOf('.') == -1) packFileName += ".atlas";

    List<Page> pages = maxRectsPacker.pack(imageProcessor.getImages());
    writeImages(outputDir, pages, packFileName);

    writePackFile(outputDir, pages, packFileName);
    /*try {
      writePackFile(outputDir, pages, packFileName);
    } catch (IOException ex) {
      throw new RuntimeException("Error writing pack file.", ex);
    }
    */
  }

  void writeImages (File outputDir, List<Page> pages, String packFileName) {
    String imageName = packFileName;
    int dotIndex = imageName.lastIndexOf('.');
    if (dotIndex != -1) imageName = imageName.substring(0, dotIndex);

    int fileIndex = 0;
    for(Page page in pages) {
      int width = page.width, height = page.height;
      int paddingX = settings.paddingX;
      int paddingY = settings.paddingY;
      if (settings.duplicatePadding) {
        paddingX = paddingX ~/ 2;
        paddingY = paddingY ~/ 2;
      }
      width -= settings.paddingX;
      height -= settings.paddingY;
      if (settings.edgePadding) {
        page.x = paddingX;
        page.y = paddingY;
        width += paddingX * 2;
        height += paddingY * 2;
      }
      if (settings.pot) {
        width = MathUtils.nextPowerOfTwo(width);
        height = MathUtils.nextPowerOfTwo(height);
      }
      width = Math.max(settings.minWidth, width);
      height = Math.max(settings.minHeight, height);

      if (settings.forceSquareOutput) {
        if (width > height) {
          height = width;
        } else {
          width = height;
        }
      }

      /*
      File outputFile;
      while (true) {
        outputFile = new File(outputDir, imageName + (fileIndex++ == 0 ? "" : fileIndex) + "." + settings.outputFormat);
        if (!outputFile.exists()) break;
      }
      */
      page.imageName = imageName;//outputFile.getName();

      Html.CanvasElement canvas = outputDir.atlas;//new Html.CanvasElement()
      canvas.width = width;
      canvas.height = height;
      outputDir.atlasData["width"] = width;
      outputDir.atlasData["height"] = height;
      //..width
      //..height;//new BufferedImage(width, height, getBufferedImageType(settings.format));
      Html.CanvasRenderingContext2D g = canvas.context2d;
      g.clearRect(0, 0, canvas.width, canvas.height);

      //print("Writing ${canvas.width} x ${canvas.height} : ${outputFile}");

      for(Rect rect in page.outputRects) {
        int rectX = page.x + rect.x,
            rectY = page.y + page.height - rect.y - rect.height;
        if (rect.rotated) {
          g.translate(rectX, rectY);
          g.rotate(-90 * MathUtils.degreesToRadians);
          g.translate(-rectX, -rectY);
          g.translate(-(rect.height - settings.paddingY), 0);
        }
        BufferedImage image = rect.image;
        if (settings.duplicatePadding) {
          int amountX = settings.paddingX ~/ 2;
          int amountY = settings.paddingY ~/ 2;
          int imageWidth = image.width;
          int imageHeight = image.height;
          // Copy corner pixels to fill corners of the padding.
          g.drawImageScaledFromSource(image.canvas, rectX - amountX, rectY - amountY, rectX, rectY, 0, 0, 1, 1);
          g.drawImageScaledFromSource(image.canvas, rectX + imageWidth, rectY - amountY, rectX + imageWidth + amountX, rectY, imageWidth - 1, 0,
            imageWidth, 1);
          g.drawImageScaledFromSource(image.canvas, rectX - amountX, rectY + imageHeight, rectX, rectY + imageHeight + amountY, 0, imageHeight - 1,
            1, imageHeight);
          g.drawImageScaledFromSource(image.canvas, rectX + imageWidth, rectY + imageHeight, rectX + imageWidth + amountX, rectY + imageHeight
            + amountY, imageWidth - 1, imageHeight - 1, imageWidth, imageHeight);
          // Copy edge pixels into padding.
          g.drawImageScaledFromSource(image.canvas, rectX, rectY - amountY, rectX + imageWidth, rectY, 0, 0, imageWidth, 1);
          g.drawImageScaledFromSource(image.canvas, rectX, rectY + imageHeight, rectX + imageWidth, rectY + imageHeight + amountY, 0,
            imageHeight - 1, imageWidth, imageHeight);
          g.drawImageScaledFromSource(image.canvas, rectX - amountX, rectY, rectX, rectY + imageHeight, 0, 0, 1, imageHeight);
          g.drawImageScaledFromSource(image.canvas, rectX + imageWidth, rectY, rectX + imageWidth + amountX, rectY + imageHeight, imageWidth - 1,
            0, imageWidth, imageHeight);
        }
        g.drawImage(image.canvas, rectX, rectY);
        if (rect.rotated) {
          g.translate(rect.height - settings.paddingY, 0);
          g.translate(rectX, rectY);
          g.rotate(90 * MathUtils.degreesToRadians);
          g.translate(-rectX, -rectY);
        }
        if (settings.debug) {
          //g.fillStyle(Color.magenta);
          //g.drawRect(rectX, rectY, rect.width - settings.paddingX - 1, rect.height - settings.paddingY - 1);
        }
      }
      outputDir.atlas = canvas;

      if (settings.debug) {
        //g.setColor(Color.magenta);
        //g.drawRect(0, 0, width - 1, height - 1);
      }


      /*try {
        if (settings.outputFormat.equalsIgnoreCase("jpg")) {
          Iterator<ImageWriter> writers = ImageIO.getImageWritersByFormatName("jpg");
          ImageWriter writer = writers.next();
          ImageWriteParam param = writer.getDefaultWriteParam();
          param.setCompressionMode(ImageWriteParam.MODE_EXPLICIT);
          param.setCompressionQuality(settings.jpegQuality);
          ImageOutputStream ios = ImageIO.createImageOutputStream(outputFile);
          writer.setOutput(ios);
          writer.write(null, new IIOImage(canvas, null, null), param);
        } else
          ImageIO.write(canvas, "png", outputFile);
      } catch (IOException ex) {
        throw new RuntimeException("Error writing file: " + outputFile, ex);
      }*/
    }
  }

  void writePackFile (File outputDir, List<Page> pages, String packFileName) {
    //File packFile = new File(outputDir, packFileName);
    Map<String,Object> map = outputDir.atlasData;

    /*
    if (packFile.exists()) {
      // Make sure there aren't duplicate names.
      TextureAtlasData textureAtlasData = new TextureAtlasData(new FileHandle(packFile), new FileHandle(packFile), false);
      for(Page page in pages) {
        for(Rect rect in page.outputRects) {
          String rectName = settings.flattenPaths ? new FileHandle(rect.name).name() : rect.name;
          print(rectName);
          for(Region region in textureAtlasData.getRegions()) {
            if (region.name.equals(rectName)) {
              throw new GdxRuntimeException("A region with the name \"" + rectName + "\" has already been packed: "
                + rect.name);
            }
          }
        }
      }
    }
    */

    //FileWriter writer = new FileWriter(packFile, true);
    // if (settings.jsonOutput) {
    // } else {
    for(Page page in pages) {
      map["atlasName"] = page.imageName.toString();
      //map["format"] = settings.format.toString();
      //map["filter-min"] = settings.filterMin;
      //map["filter-mag"] = settings.filterMag;
      //map["repeat"] = getRepeatValue();
      var rects = new Map<String,Object>();
      for(Rect rect in page.outputRects) {
        map[rect.name] = writeRect(page, rect);
        for(String alias in rect.aliases)
          map[alias] = rect.name;
      }
    }
    // }
    //writer.close();
    print(map);
  }


  Map<String,Object> writeRect (Page page, Rect rect) {
    var map = new Map<String,Object>();
    map["name"] = rect.name;
    map["rotated"] = rect.rotated;
    map["position"] = [(page.x + rect.x),(page.y + page.height - rect.height - rect.y)];
    map["width"] = rect.width;
    map["height"] = rect.height;
    if(rect.splits != null) {
      map["split"] = rect.splits;
    }
    if(rect.pads != null) {
      map["pad"] = rect.pads;
    }
    map["orgin"] = [rect.originalWidth, rect.originalHeight];
    map["offset"] = [rect.offsetX, (rect.originalHeight - rect.image.getHeight() - rect.offsetY)];
    if(rect.index != -1) {
      map["index"] = rect.index;
    }
    return map;


/*
    String rectName = settings.flattenPaths ? new FileHandle(name).name() : name;
    writer.write(rectName + "\n");
    writer.write("  rotate: " + rect.rotated + "\n");
    writer.write("  xy: " + (page.x + rect.x) + ", " + (page.y + page.height - rect.height - rect.y) + "\n");
    writer.write("  size: " + rect.image.getWidth() + ", " + rect.image.getHeight() + "\n");
    if (rect.splits != null) {
      writer
        .write("  split: " + rect.splits[0] + ", " + rect.splits[1] + ", " + rect.splits[2] + ", " + rect.splits[3] + "\n");
    }
    if (rect.pads != null) {
      if (rect.splits == null) writer.write("  split: 0, 0, 0, 0\n");
      writer.write("  pad: " + rect.pads[0] + ", " + rect.pads[1] + ", " + rect.pads[2] + ", " + rect.pads[3] + "\n");
    }
    writer.write("  orig: " + rect.originalWidth + ", " + rect.originalHeight + "\n");
    writer.write("  offset: " + rect.offsetX + ", " + (rect.originalHeight - rect.image.getHeight() - rect.offsetY) + "\n");
    writer.write("  index: " + rect.index + "\n");
    */
  }

  String getRepeatValue () {
    if (settings.wrapX == TextureWrap.Repeat && settings.wrapY == TextureWrap.Repeat) return "xy";
    if (settings.wrapX == TextureWrap.Repeat && settings.wrapY == TextureWrap.ClampToEdge) return "x";
    if (settings.wrapX == TextureWrap.ClampToEdge && settings.wrapY == TextureWrap.Repeat) return "y";
    return "none";
  }
  /*
  int getBufferedImageType (Format format) {
    switch (settings.format) {
    case(Format.RGBA8888):
    case(Format.RGBA4444):
      return BufferedImage.TYPE_INT_ARGB;
    case(Format.RGB565):
    case(Format.RGB888):
      return BufferedImage.TYPE_INT_RGB;
    case(Format.Alpha):
      return BufferedImage.TYPE_BYTE_GRAY;
    default:
      //throw new RuntimeException("Unsupported format: " + settings.format);
    }
  }*/




  /** @return true if the output file does not yet exist or its last modification date is before the last modification date of the
   *         input file */
  static bool isModified (String input, String output, String packFileName) {
    return true;
    /*
    String packFullFileName = output;
    if (!packFullFileName.endsWith("/")) packFullFileName += "/";
    packFullFileName += packFileName;
    File outputFile = new File(packFullFileName);
    if (!outputFile.exists()) return true;

    File inputFile = new File(input);
    if (!inputFile.exists()) throw new IllegalArgumentException("Input file does not exist: " + inputFile.getAbsolutePath());
    return inputFile.lastModified() > outputFile.lastModified();
    */
  }
/*
  static void processIfModified (String input, String output, String packFileName) {
    if (isModified(input, output, packFileName)) process(input, output, packFileName);
  }

  static void processIfModified (Settings settings, String input, String output, String packFileName) {
    if (isModified(input, output, packFileName)) process(settings, input, output, packFileName);
  }
*/


}
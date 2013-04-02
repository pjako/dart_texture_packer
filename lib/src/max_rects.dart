part of texture_packer;



/** Maximal rectangles bin packing algorithm. Adapted from this C++ domain source:
 * http://clb.demon.fi/projects/even-more-rectangle-bin-packing
 * @author Jukka Jyl�nki
 * @author Nathan Sweet */
class MaxRects {
  final Settings settings;
  int binWidth;
  int binHeight;
  final List<Rect> usedRectangles = new List<Rect>();
  final List<Rect> freeRectangles = new List<Rect>();


  MaxRects(this.settings);

  void init (int width, int height) {
    binWidth = width;
    binHeight = height;

    usedRectangles.clear();
    freeRectangles.clear();
    Rect n = new Rect.zero();
    n.x = 0;
    n.y = 0;
    n.width = width;
    n.height = height;
    freeRectangles.add(n);
  }

  /** Packs a single image. Order is defined externally. */
  Rect insert (Rect rect, FreeRectChoiceHeuristic method) {
    Rect newNode = ScoreRect(rect, method);
    if (newNode.height == 0) return null;

    int numRectanglesToProcess = freeRectangles.length;
    for(int i = 0; i < numRectanglesToProcess; ++i) {
      if (SplitFreeNode(freeRectangles[i], newNode)) {
        freeRectangles.removeAt(i);
        --i;
        --numRectanglesToProcess;
      }
    }

    PruneFreeList();

    Rect bestNode = new Rect.zero();
    bestNode.set(rect);
    bestNode.score1 = newNode.score1;
    bestNode.score2 = newNode.score2;
    bestNode.x = newNode.x;
    bestNode.y = newNode.y;
    bestNode.width = newNode.width;
    bestNode.height = newNode.height;
    bestNode.rotated = newNode.rotated;

    usedRectangles.add(bestNode);
    return bestNode;
  }

  /** foreach rectangle, packs each one then chooses the best and packs that. Slow! */
  Page pack (List<Rect> rects, FreeRectChoiceHeuristic method) {
    rects = new List.from(rects);
    while (rects.length > 0) {
      int bestRectIndex = -1;
      Rect bestNode = new Rect.zero();
      bestNode.score1 = Integer.MAX_VALUE;
      bestNode.score2 = Integer.MAX_VALUE;

      // Find the next rectangle that packs best.
      for(int i = 0; i < rects.length; i++) {
        Rect newNode = ScoreRect(rects[i], method);
        if (newNode.score1 < bestNode.score1 || (newNode.score1 == bestNode.score1 && newNode.score2 < bestNode.score2)) {
          bestNode.set(rects[i]);
          bestNode.score1 = newNode.score1;
          bestNode.score2 = newNode.score2;
          bestNode.x = newNode.x;
          bestNode.y = newNode.y;
          bestNode.width = newNode.width;
          bestNode.height = newNode.height;
          bestNode.rotated = newNode.rotated;
          bestRectIndex = i;
        }
      }

      if (bestRectIndex == -1) break;

      PlaceRect(bestNode);
      rects.removeAt(bestRectIndex);
    }

    Page result = getResult();
    result.remainingRects = rects;
    return result;
  }

  Page getResult () {
    int w = 0, h = 0;
    for(int i = 0; i < usedRectangles.length; i++) {
      Rect rect = usedRectangles[i];
      w = Math.max(w, rect.x + rect.width);
      h = Math.max(h, rect.y + rect.height);
    }
    Page result = new Page();
    result.outputRects = new List<Rect>.from(usedRectangles);
    result.occupancy = getOccupancy();
    result.width = w;
    result.height = h;
    return result;
  }

  void PlaceRect (Rect node) {
    int numRectanglesToProcess = freeRectangles.length;
    for(int i = 0; i < numRectanglesToProcess; i++) {
      if (SplitFreeNode(freeRectangles[i], node)) {
        freeRectangles.removeAt(i);
        --i;
        --numRectanglesToProcess;
      }
    }

    PruneFreeList();

    usedRectangles.add(node);
  }

  Rect ScoreRect (Rect rect, FreeRectChoiceHeuristic method) {
    int width = rect.width;
    int height = rect.height;
    int rotatedWidth = height - settings.paddingY + settings.paddingX;
    int rotatedHeight = width - settings.paddingX + settings.paddingY;
    bool rotate = rect.canRotate && settings.rotation;

    Rect newNode = null;
    switch (method) {
      case(FreeRectChoiceHeuristic.BestShortSideFit):
        newNode = FindPositionForNewNodeBestShortSideFit(width, height, rotatedWidth, rotatedHeight, rotate);
        break;
      case(FreeRectChoiceHeuristic.BottomLeftRule):
        newNode = FindPositionForNewNodeBottomLeft(width, height, rotatedWidth, rotatedHeight, rotate);
        break;
      case(FreeRectChoiceHeuristic.ContactPointRule):
        newNode = FindPositionForNewNodeContactPoint(width, height, rotatedWidth, rotatedHeight, rotate);
        newNode.score1 = -newNode.score1; // Reverse since we are minimizing, but forcontact point score bigger is better.
        break;
      case(FreeRectChoiceHeuristic.BestLongSideFit):
        newNode = FindPositionForNewNodeBestLongSideFit(width, height, rotatedWidth, rotatedHeight, rotate);
        break;
      case(FreeRectChoiceHeuristic.BestAreaFit):
        newNode = FindPositionForNewNodeBestAreaFit(width, height, rotatedWidth, rotatedHeight, rotate);
        break;
      }

      // Cannot fit the current rectangle.
      if (newNode.height == 0) {
        newNode.score1 = Integer.MAX_VALUE;
        newNode.score2 = Integer.MAX_VALUE;
      }

      return newNode;
    }

  // / Computes the ratio of used surface area.
  double getOccupancy () {
    int usedSurfaceArea = 0;
    for(int i = 0; i < usedRectangles.length; i++)
      usedSurfaceArea += usedRectangles[i].width * usedRectangles[i].height;
    return usedSurfaceArea.toDouble() / (binWidth * binHeight);
  }

  Rect FindPositionForNewNodeBottomLeft (int width, int height, int rotatedWidth, int rotatedHeight, bool rotate) {
    Rect bestNode = new Rect.zero();

    bestNode.score1 = Integer.MAX_VALUE; // best y, score2 is best x

    for(int i = 0; i < freeRectangles.length; i++) {
      // Try to place the rectangle in upright (non-rotated) orientation.
      if (freeRectangles[i].width >= width && freeRectangles[i].height >= height) {
        int topSideY = freeRectangles[i].y + height;
        if (topSideY < bestNode.score1 || (topSideY == bestNode.score1 && freeRectangles[i].x < bestNode.score2)) {
          bestNode.x = freeRectangles[i].x;
          bestNode.y = freeRectangles[i].y;
          bestNode.width = width;
          bestNode.height = height;
          bestNode.score1 = topSideY;
          bestNode.score2 = freeRectangles[i].x;
          bestNode.rotated = false;
        }
      }
      if (rotate && freeRectangles[i].width >= rotatedWidth && freeRectangles[i].height >= rotatedHeight) {
        int topSideY = freeRectangles[i].y + rotatedHeight;
        if (topSideY < bestNode.score1 || (topSideY == bestNode.score1 && freeRectangles[i].x < bestNode.score2)) {
          bestNode.x = freeRectangles[i].x;
          bestNode.y = freeRectangles[i].y;
          bestNode.width = rotatedWidth;
          bestNode.height = rotatedHeight;
          bestNode.score1 = topSideY;
          bestNode.score2 = freeRectangles[i].x;
          bestNode.rotated = true;
        }
      }
    }
    return bestNode;
  }

  Rect FindPositionForNewNodeBestShortSideFit (int width, int height, int rotatedWidth, int rotatedHeight,
    bool rotate) {
    Rect bestNode = new Rect.zero();
    bestNode.score1 = Integer.MAX_VALUE;

    for(int i = 0; i < freeRectangles.length; i++) {
      // Try to place the rectangle in upright (non-rotated) orientation.
      if (freeRectangles[i].width >= width && freeRectangles[i].height >= height) {
        int leftoverHoriz = (freeRectangles[i].width - width).abs();
        int leftoverVert = (freeRectangles[i].height - height).abs();
        int shortSideFit = Math.min(leftoverHoriz, leftoverVert);
        int longSideFit = Math.max(leftoverHoriz, leftoverVert);

        if (shortSideFit < bestNode.score1 || (shortSideFit == bestNode.score1 && longSideFit < bestNode.score2)) {
          bestNode.x = freeRectangles[i].x;
          bestNode.y = freeRectangles[i].y;
          bestNode.width = width;
          bestNode.height = height;
          bestNode.score1 = shortSideFit;
          bestNode.score2 = longSideFit;
          bestNode.rotated = false;
        }
      }

      if (rotate && freeRectangles[i].width >= rotatedWidth && freeRectangles[i].height >= rotatedHeight) {
        int flippedLeftoverHoriz = (freeRectangles[i].width - rotatedWidth).abs();
        int flippedLeftoverVert = (freeRectangles[i].height - rotatedHeight).abs();
        int flippedShortSideFit = Math.min(flippedLeftoverHoriz, flippedLeftoverVert);
        int flippedLongSideFit = Math.max(flippedLeftoverHoriz, flippedLeftoverVert);

        if (flippedShortSideFit < bestNode.score1
          || (flippedShortSideFit == bestNode.score1 && flippedLongSideFit < bestNode.score2)) {
          bestNode.x = freeRectangles[i].x;
          bestNode.y = freeRectangles[i].y;
          bestNode.width = rotatedWidth;
          bestNode.height = rotatedHeight;
          bestNode.score1 = flippedShortSideFit;
          bestNode.score2 = flippedLongSideFit;
          bestNode.rotated = true;
        }
      }
    }

    return bestNode;
  }

  Rect FindPositionForNewNodeBestLongSideFit (int width, int height, int rotatedWidth, int rotatedHeight,
    bool rotate) {
    Rect bestNode = new Rect.zero();

    bestNode.score2 = Integer.MAX_VALUE;

    for(int i = 0; i < freeRectangles.length; i++) {
      // Try to place the rectangle in upright (non-rotated) orientation.
      if (freeRectangles[i].width >= width && freeRectangles[i].height >= height) {
        int leftoverHoriz = (freeRectangles[i].width - width).abs();
        int leftoverVert = (freeRectangles[i].height - height).abs();
        int shortSideFit = Math.min(leftoverHoriz, leftoverVert);
        int longSideFit = Math.max(leftoverHoriz, leftoverVert);

        if (longSideFit < bestNode.score2 || (longSideFit == bestNode.score2 && shortSideFit < bestNode.score1)) {
          bestNode.x = freeRectangles[i].x;
          bestNode.y = freeRectangles[i].y;
          bestNode.width = width;
          bestNode.height = height;
          bestNode.score1 = shortSideFit;
          bestNode.score2 = longSideFit;
          bestNode.rotated = false;
        }
      }

      if (rotate && freeRectangles[i].width >= rotatedWidth && freeRectangles[i].height >= rotatedHeight) {
        int leftoverHoriz = (freeRectangles[i].width - rotatedWidth).abs();
        int leftoverVert = (freeRectangles[i].height - rotatedHeight).abs();
        int shortSideFit = Math.min(leftoverHoriz, leftoverVert);
        int longSideFit = Math.max(leftoverHoriz, leftoverVert);

        if (longSideFit < bestNode.score2 || (longSideFit == bestNode.score2 && shortSideFit < bestNode.score1)) {
          bestNode.x = freeRectangles[i].x;
          bestNode.y = freeRectangles[i].y;
          bestNode.width = rotatedWidth;
          bestNode.height = rotatedHeight;
          bestNode.score1 = shortSideFit;
          bestNode.score2 = longSideFit;
          bestNode.rotated = true;
        }
      }
    }
    return bestNode;
  }

  Rect FindPositionForNewNodeBestAreaFit (int width, int height, int rotatedWidth, int rotatedHeight, bool rotate) {
    Rect bestNode = new Rect.zero();

    bestNode.score1 = Integer.MAX_VALUE; // best area fit, score2 is best short side fit

    for(int i = 0; i < freeRectangles.length; i++) {
      int areaFit = freeRectangles[i].width * freeRectangles[i].height - width * height;

      // Try to place the rectangle in upright (non-rotated) orientation.
      if (freeRectangles[i].width >= width && freeRectangles[i].height >= height) {
        int leftoverHoriz = (freeRectangles[i].width - width).abs();
        int leftoverVert = (freeRectangles[i].height - height).abs();
        int shortSideFit = Math.min(leftoverHoriz, leftoverVert);

        if (areaFit < bestNode.score1 || (areaFit == bestNode.score1 && shortSideFit < bestNode.score2)) {
          bestNode.x = freeRectangles[i].x;
          bestNode.y = freeRectangles[i].y;
          bestNode.width = width;
          bestNode.height = height;
          bestNode.score2 = shortSideFit;
          bestNode.score1 = areaFit;
          bestNode.rotated = false;
        }
      }

      if (rotate && freeRectangles[i].width >= rotatedWidth && freeRectangles[i].height >= rotatedHeight) {
        int leftoverHoriz = (freeRectangles[i].width - rotatedWidth).abs();
        int leftoverVert = (freeRectangles[i].height - rotatedHeight).abs();
        int shortSideFit = Math.min(leftoverHoriz, leftoverVert);

        if (areaFit < bestNode.score1 || (areaFit == bestNode.score1 && shortSideFit < bestNode.score2)) {
          bestNode.x = freeRectangles[i].x;
          bestNode.y = freeRectangles[i].y;
          bestNode.width = rotatedWidth;
          bestNode.height = rotatedHeight;
          bestNode.score2 = shortSideFit;
          bestNode.score1 = areaFit;
          bestNode.rotated = true;
        }
      }
    }
    return bestNode;
  }

  // / Returns 0 if the two intervals i1 and i2 are disjoint, or the length of their overlap otherwise.
  int CommonIntervalLength (int i1start, int i1end, int i2start, int i2end) {
    if (i1end < i2start || i2end < i1start) return 0;
    return Math.min(i1end, i2end) - Math.max(i1start, i2start);
  }

  int ContactPointScoreNode (int x, int y, int width, int height) {
    int score = 0;

    if (x == 0 || x + width == binWidth) score += height;
    if (y == 0 || y + height == binHeight) score += width;

    for(int i = 0; i < usedRectangles.length; i++) {
      if (usedRectangles[i].x == x + width || usedRectangles[i].x + usedRectangles[i].width == x)
        score += CommonIntervalLength(usedRectangles[i].y, usedRectangles[i].y + usedRectangles[i].height, y,
          y + height);
      if (usedRectangles[i].y == y + height || usedRectangles[i].y + usedRectangles[i].height == y)
        score += CommonIntervalLength(usedRectangles[i].x, usedRectangles[i].x + usedRectangles[i].width, x, x
          + width);
    }
    return score;
  }

  Rect FindPositionForNewNodeContactPoint (int width, int height, int rotatedWidth, int rotatedHeight, bool rotate) {
    Rect bestNode = new Rect.zero();

    bestNode.score1 = -1; // best contact score

    for(int i = 0; i < freeRectangles.length; i++) {
      // Try to place the rectangle in upright (non-rotated) orientation.
      if (freeRectangles[i].width >= width && freeRectangles[i].height >= height) {
        int score = ContactPointScoreNode(freeRectangles[i].x, freeRectangles[i].y, width, height);
        if (score > bestNode.score1) {
          bestNode.x = freeRectangles[i].x;
          bestNode.y = freeRectangles[i].y;
          bestNode.width = width;
          bestNode.height = height;
          bestNode.score1 = score;
          bestNode.rotated = false;
        }
      }
      if (rotate && freeRectangles[i].width >= rotatedWidth && freeRectangles[i].height >= rotatedHeight) {
        // This was width,height -- bug fixed?
        int score = ContactPointScoreNode(freeRectangles[i].x, freeRectangles[i].y, rotatedWidth, rotatedHeight);
        if (score > bestNode.score1) {
          bestNode.x = freeRectangles[i].x;
          bestNode.y = freeRectangles[i].y;
          bestNode.width = rotatedWidth;
          bestNode.height = rotatedHeight;
          bestNode.score1 = score;
          bestNode.rotated = true;
        }
      }
    }
    return bestNode;
  }

  bool SplitFreeNode (Rect freeNode, Rect usedNode) {
    // Test with SAT if the rectangles even intersect.
    if (usedNode.x >= freeNode.x + freeNode.width || usedNode.x + usedNode.width <= freeNode.x
      || usedNode.y >= freeNode.y + freeNode.height || usedNode.y + usedNode.height <= freeNode.y) return false;

    if (usedNode.x < freeNode.x + freeNode.width && usedNode.x + usedNode.width > freeNode.x) {
      // New node at the top side of the used node.
      if (usedNode.y > freeNode.y && usedNode.y < freeNode.y + freeNode.height) {
        Rect newNode = new Rect.fromRect(freeNode);
        newNode.height = usedNode.y - newNode.y;
        freeRectangles.add(newNode);
      }

      // New node at the bottom side of the used node.
      if (usedNode.y + usedNode.height < freeNode.y + freeNode.height) {
        Rect newNode = new Rect.fromRect(freeNode);
        newNode.y = usedNode.y + usedNode.height;
        newNode.height = freeNode.y + freeNode.height - (usedNode.y + usedNode.height);
        freeRectangles.add(newNode);
      }
    }

    if (usedNode.y < freeNode.y + freeNode.height && usedNode.y + usedNode.height > freeNode.y) {
      // New node at the left side of the used node.
      if (usedNode.x > freeNode.x && usedNode.x < freeNode.x + freeNode.width) {
        Rect newNode = new Rect.fromRect(freeNode);
        newNode.width = usedNode.x - newNode.x;
        freeRectangles.add(newNode);
      }

      // New node at the right side of the used node.
      if (usedNode.x + usedNode.width < freeNode.x + freeNode.width) {
        Rect newNode = new Rect.fromRect(freeNode);
        newNode.x = usedNode.x + usedNode.width;
        newNode.width = freeNode.x + freeNode.width - (usedNode.x + usedNode.width);
        freeRectangles.add(newNode);
      }
    }

    return true;
  }

  void PruneFreeList () {
    /*
     * /// Would be nice to do something like this, to avoid a Theta(n^2) loop through each pair. /// But unfortunately it
     * doesn't quite cut it, since we also want to detect containment. /// Perhaps there's another way to do this faster than
     * Theta(n^2).
     *
     * if (freeRectangles.length > 0) clb::sort::QuickSort(&freeRectangles[0], freeRectangles.length, NodeSortCmp);
     *
     * for(int i = 0; i < freeRectangles.length-1; i++) if (freeRectangles[i].x == freeRectangles[i+1].x && freeRectangles[i].y
     * == freeRectangles[i+1].y && freeRectangles[i].width == freeRectangles[i+1].width && freeRectangles[i].height ==
     * freeRectangles[i+1].height) { freeRectangles.erase(freeRectangles.begin() + i); --i; }
     */

    // / Go through each pair and remove any rectangle that is redundant.
    for(int i = 0; i < freeRectangles.length; i++)
      for(int j = i + 1; j < freeRectangles.length; ++j) {
        if (IsContainedIn(freeRectangles[i], freeRectangles[j])) {
          freeRectangles.removeAt(i);
          --i;
          break;
        }
        if (IsContainedIn(freeRectangles[j], freeRectangles[i])) {
          freeRectangles.removeAt(j);
          --j;
        }
      }
  }

  bool IsContainedIn (Rect a, Rect b) {
    return a.x >= b.x && a.y >= b.y && a.x + a.width <= b.x + b.width && a.y + a.height <= b.y + b.height;
  }
}
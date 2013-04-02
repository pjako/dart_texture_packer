part of texture_packer;
/*******************************************************************************
 * Copyright 2011 See AUTHORS file.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License forthe specific language governing permissions and
 * limitations under the License.
 ******************************************************************************/

/*
package com.badlogic.gdx.tools.imagepacker;

import java.util.Comparator;

import com.badlogic.gdx.math.MathUtils;
import com.badlogic.gdx.tools.imagepacker.TexturePacker2.Page;
import com.badlogic.gdx.tools.imagepacker.TexturePacker2.Rect;
import com.badlogic.gdx.tools.imagepacker.TexturePacker2.Settings;
import com.badlogic.gdx.utils.Array;
*/

/** Packs pages of images using the maximal rectangles bin packing algorithm by Jukka Jylänki. A brute force binary search is used
 * to pack into the smallest bin possible.
 * @author Nathan Sweet */
class MaxRectsPacker {
  List<FreeRectChoiceHeuristic> methods = FreeRectChoiceHeuristic.values();
  MaxRects maxRects;
  Settings settings;

  MaxRectsPacker (Settings settings) {
    this.settings = settings;
    maxRects = new MaxRects(settings);
    /*if (settings.minWidth > settings.maxWidth) throw new RuntimeException("Page min width cannot be higher than max width.");
    if (settings.minHeight > settings.maxHeight)
      throw new RuntimeException("Page min height cannot be higher than max height.");*/
  }

  List<Page> pack (List<Rect> inputRects) {
    for(int i = 0, nn = inputRects.length; i < nn; i++) {
      Rect rect = inputRects[i];
      rect.width += settings.paddingX;
      rect.height += settings.paddingY;
    }

    if (settings.fast) {
      if (settings.rotation) {
        // Sort by longest side if rotation is enabled.
        inputRects.sort(
          /*int*/ (Rect o1, Rect o2) {
            int n1 = o1.width > o1.height ? o1.width : o1.height;
            int n2 = o2.width > o2.height ? o2.width : o2.height;
            return n2 - n1;
          }
        );
      } else {
        // Sort only by width (largest to smallest) if rotation is disabled.
        inputRects.sort((Rect o1, Rect o2) {
            return o2.width - o1.width;
          });
      }
    }

    List<Page> pages = new List<Page>();
    while (inputRects.length > 0) {
      Page result = packPage(inputRects);
      pages.add(result);
      inputRects = result.remainingRects;
    }
    return pages;
  }

  Page packPage (List<Rect> inputRects) {
    int edgePaddingX = 0, edgePaddingY = 0;
    if (!settings.duplicatePadding) { // if duplicatePadding, edges get only half padding.
      edgePaddingX = settings.paddingX;
      edgePaddingY = settings.paddingY;
    }

    // Find min size.
    int minWidth = Integer.MAX_VALUE;
    int minHeight = Integer.MAX_VALUE;
    for(int i = 0, nn = inputRects.length; i < nn; i++) {
      Rect rect = inputRects[i];
      minWidth = Math.min(minWidth, rect.width);
      minHeight = Math.min(minHeight, rect.height);
      /*if (rect.width > settings.maxWidth && (!settings.rotation || rect.height > settings.maxWidth))
        throw new RuntimeException("Image does not fit with max page width " + settings.maxWidth + " and paddingX "
          + settings.paddingX + ": " + rect);
      if (rect.height > settings.maxHeight && (!settings.rotation || rect.width > settings.maxHeight))
        throw new RuntimeException("Image does not fit in max page height " + settings.maxHeight + " and paddingY "
          + settings.paddingY + ": " + rect);*/
    }
    minWidth = Math.max(minWidth, settings.minWidth);
    minHeight = Math.max(minHeight, settings.minHeight);

    print("Packing");

    // Find the minimal page size that fits all rects.
    BinarySearch widthSearch = new BinarySearch(minWidth, settings.maxWidth, settings.fast ? 25 : 15, settings.pot);
    BinarySearch heightSearch = new BinarySearch(minHeight, settings.maxHeight, settings.fast ? 25 : 15, settings.pot);
    int width = widthSearch.reset(), height = heightSearch.reset(), i = 0;
    Page bestResult = null;
    while (true) {
      Page bestWidthResult = null;
      while (width != -1) {
        Page result = packAtSize(true, width - edgePaddingX, height - edgePaddingY, inputRects);
        if (++i % 70 == 0) print("");
        print(".");
        bestWidthResult = getBest(bestWidthResult, result);
        width = widthSearch.next(result == null);
      }
      bestResult = getBest(bestResult, bestWidthResult);
      height = heightSearch.next(bestWidthResult == null);
      if (height == -1) break;
      width = widthSearch.reset();
    }
    //print();

    // Rects don't fit on one page. Fill a whole page and return.
    if (bestResult == null)
      bestResult = packAtSize(false, settings.maxWidth - edgePaddingX, settings.maxHeight - edgePaddingY, inputRects);

    return bestResult;
  }

  /** @param fully If true, the only results that pack all rects will be considered. If false, all results are considered, not all
   *           rects may be packed. */
  Page packAtSize(bool fully, int width, int height, List<Rect> inputRects) {
    Page bestResult = null;
    for(int i = 0, n = methods.length; i < n; i++) {
      maxRects.init(width, height);
      Page result;
      if (!settings.fast) {
        result = maxRects.pack(inputRects, methods[i]);
      } else {
        List<Rect> remaining = new List<Rect>();
        for(int ii = 0, nn = inputRects.length; ii < nn; ii++) {
          Rect rect = inputRects[ii];
          if (maxRects.insert(rect, methods[i]) == null) {
            while (ii < nn)
              remaining.add(inputRects[ii++]);
          }
        }
        result = maxRects.getResult();
        result.remainingRects = remaining;
      }
      if (fully && result.remainingRects.length > 0) continue;
      if (result.outputRects.length == 0) continue;
      bestResult = getBest(bestResult, result);
    }
    return bestResult;
  }

  Page getBest (Page result1, Page result2) {
    if (result1 == null) return result2;
    if (result2 == null) return result1;
    return result1.occupancy > result2.occupancy ? result1 : result2;
  }


}
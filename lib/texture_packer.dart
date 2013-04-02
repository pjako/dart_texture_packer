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
library texture_packer;
import 'dart:math' as Math;
import 'dart:html' as Html;
import 'dart:async';
part 'src/binary_search.dart';
part 'src/buffered_image.dart';
part 'src/image_processor.dart';
part 'src/max_rects.dart';
part 'src/max_rects_packer.dart';
part 'src/rect.dart';
part 'src/settings.dart';
part 'src/texture_packer.dart';

class Integer {
  static final MAX_VALUE = 4294967296;
}

class MathUtils {
  static int nextPowerOfTwo (int value) {
    if (value == 0) return 1;
    value--;
    value |= value >> 1;
    value |= value >> 2;
    value |= value >> 4;
    value |= value >> 8;
    value |= value >> 16;
    return value + 1;
  }
  static final double degreesToRadians = Math.PI / 180;
}


class File {
  Html.CanvasElement atlas;
  Map<String,Object> atlasData;
}

/** @author Nathan Sweet */
class Page {
  String imageName;
  List<Rect> outputRects, remainingRects;
  double occupancy;
  int x, y, width, height;
}

class FreeRectChoiceHeuristic {
  final int _value;
  /// BSSF: Positions the rectangle against the short side of a free rectangle into which it fits the best.
  static const FreeRectChoiceHeuristic BestShortSideFit = const FreeRectChoiceHeuristic(0);
  /// BLSF: Positions the rectangle against the long side of a free rectangle into which it fits the best.
  static const FreeRectChoiceHeuristic BestLongSideFit = const FreeRectChoiceHeuristic(1);
  // BAF: Positions the rectangle into the smallest free rect into which it fits.
  static const FreeRectChoiceHeuristic BestAreaFit = const FreeRectChoiceHeuristic(2);
  // BL: Does the Tetris placement.
  static const FreeRectChoiceHeuristic BottomLeftRule = const FreeRectChoiceHeuristic(3);
  // CP: Choosest the placement where the rectangle touches other rects as much as possible.
  static const FreeRectChoiceHeuristic ContactPointRule = const FreeRectChoiceHeuristic(4);

  static List<FreeRectChoiceHeuristic> values() => [BestShortSideFit,BestLongSideFit,BestAreaFit,BottomLeftRule,ContactPointRule];


  const FreeRectChoiceHeuristic(this._value);
}

class Format {
  final int _value;
  static const Format RGBA8888 = const Format(0);
  static const Format RGBA4444 = const Format(1);
  static const Format RGB565 = const Format(2);
  static const Format RGB888 = const Format(3);
  static const Format Alpha = const Format(4);

  const Format(this._value);
}
class TextureWrap {
  final int _value;
  static final TextureWrap ClampToEdge = const TextureWrap(0);
  static final TextureWrap Repeat = const TextureWrap(0);
  const TextureWrap(this._value);
}
class TextureFilter {
  final int _value;
  static final TextureFilter Nearest = const TextureFilter(0);
  const TextureFilter(this._value);
}



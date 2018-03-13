// Copyright 2018 the Charts project authors. Please see the AUTHORS file
// for details.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:math' show Rectangle;
import 'color.dart' show Color;
import '../chart/common/chart_canvas.dart' show ChartCanvas;

abstract class SymbolRenderer {
  void paint(ChartCanvas canvas, Rectangle<int> bounds, Color color);

  bool shouldRepaint(covariant SymbolRenderer oldRenderer);
}

class RoundedRectSymbolRenderer extends SymbolRenderer {
  final double radius;

  RoundedRectSymbolRenderer({double radius}) : radius = radius ?? 1.0;

  void paint(ChartCanvas canvas, Rectangle<int> bounds, Color color) {
    canvas.drawRRect(bounds,
        fill: color,
        stroke: color,
        radius: radius,
        roundTopLeft: true,
        roundTopRight: true,
        roundBottomRight: true,
        roundBottomLeft: true);
  }

  bool shouldRepaint(RoundedRectSymbolRenderer oldRenderer) {
    return this != oldRenderer;
  }

  @override
  bool operator ==(Object other) {
    return other is RoundedRectSymbolRenderer && other.radius == radius;
  }

  @override
  int get hashCode => radius.hashCode;
}

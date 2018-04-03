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

import 'dart:math' show Rectangle, Point, min;
import 'color.dart' show Color;
import '../chart/common/chart_canvas.dart' show ChartCanvas;

abstract class SymbolRenderer {
  void paint(ChartCanvas canvas, Rectangle<int> bounds, Color color);

  bool shouldRepaint(covariant SymbolRenderer oldRenderer);
}

/// Rounded rectangular symbol with corners having [radius].
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

/// Line symbol renderer.
class LineSymbolRenderer extends SymbolRenderer {
  static const roundEndCapsPixels = 2;
  static const minLengthToRoundCaps = (roundEndCapsPixels * 2) + 1;

  /// Thickness of the line stroke.
  final double strokeWidth;

  LineSymbolRenderer({double strokeWidth}) : strokeWidth = strokeWidth ?? 4;

  void paint(ChartCanvas canvas, Rectangle<int> bounds, Color color) {
    final centerHeight = (bounds.bottom - bounds.top) / 2;

    // Adjust the length so the total width includes the rounded pixels.
    // Otherwise the cap is drawn past the bounds and appears to be cut off.
    // If bounds is not long enough to accommodate the line, do not adjust.
    var left = bounds.left;
    var right = bounds.right;

    if (bounds.width >= minLengthToRoundCaps) {
      left += roundEndCapsPixels;
      right -= roundEndCapsPixels;
    }

    // TODO: Pass in strokeWidth, roundEndCaps, and dashPattern from
    // line renderer config.
    canvas.drawLine(
      points: [new Point(left, centerHeight), new Point(right, centerHeight)],
      fill: color,
      stroke: color,
      roundEndCaps: true,
      strokeWidthPx: strokeWidth,
    );
  }

  bool shouldRepaint(LineSymbolRenderer oldRenderer) {
    return this != oldRenderer;
  }

  @override
  bool operator ==(Object other) {
    return other is LineSymbolRenderer && other.strokeWidth == strokeWidth;
  }

  @override
  int get hashCode => strokeWidth.hashCode;
}

class PointSymbolRenderer extends SymbolRenderer {
  PointSymbolRenderer();

  void paint(ChartCanvas canvas, Rectangle<int> bounds, Color color) {
    final center = new Point(
      (bounds.right - bounds.left) / 2,
      (bounds.bottom - bounds.top) / 2,
    );
    final radius = min(bounds.width, bounds.height) / 2;
    canvas.drawPoint(point: center, fill: color, radius: radius);
  }

  bool shouldRepaint(PointSymbolRenderer oldRenderer) {
    return this != oldRenderer;
  }
}

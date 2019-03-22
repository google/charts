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

import 'dart:math';

import '../../common/color.dart' show Color;
import '../../common/graphics_factory.dart' show GraphicsFactory;
import '../common/chart_canvas.dart' show ChartCanvas;
import 'bar_renderer.dart' show ImmutableBarRendererElement;
import 'bar_renderer_decorator.dart' show BarRendererDecorator;
import '../cartesian/axis/axis.dart' show ImmutableAxis, measureAxisKey;

/// Decorates bars with error whiskers.
///
/// Used to represent confidence intervals for bar charts.
class BarErrorDecorator<D> extends BarRendererDecorator<D> {
  static const Color _defaultStrokeColor = Color.black;
  static const double _defaultStrokeWidthPx = 1;
  static const double _defaultEndpointLengthPx = 16;

  final Color color;
  final double strokeWidthPx;
  final double endpointLengthPx;

  BarErrorDecorator({this.color, this.strokeWidthPx, this.endpointLengthPx});

  @override
  void decorate(Iterable<ImmutableBarRendererElement<D>> barElements,
      ChartCanvas canvas, GraphicsFactory graphicsFactory,
      {Rectangle<num> drawBounds,
      double animationPercent,
      bool renderingVertically,
      bool rtl = false}) {
    // Only decorate the bars when animation is at 100%.
    if (animationPercent != 1.0) {
      return;
    }

    for (var element in barElements) {
      final bounds = element.bounds;
      final datumIndex = element.index;

      final measureLowerBoundFn = element.series.measureLowerBoundFn;
      final measureUpperBoundFn = element.series.measureUpperBoundFn;

      if (measureLowerBoundFn != null && measureUpperBoundFn != null) {
        final measureOffsetFn = element.series.measureOffsetFn;
        final measureAxis =
            element.series.getAttr(measureAxisKey) as ImmutableAxis<num>;

        final strokeColor = color ?? _defaultStrokeColor;
        final strokeWidth = strokeWidthPx ?? _defaultStrokeWidthPx;

        if (renderingVertically) {
          final startY = measureAxis.getLocation(
              measureLowerBoundFn(datumIndex) + measureOffsetFn(datumIndex));
          final endY = measureAxis.getLocation(
              measureUpperBoundFn(datumIndex) + measureOffsetFn(datumIndex));

          if (startY != endY) {
            final barWidth = bounds.right - bounds.left;
            final x = (bounds.left + bounds.right) / 2;

            // Draw vertical whisker line.
            canvas.drawLine(
                points: [Point(x, startY), Point(x, endY)],
                stroke: strokeColor,
                strokeWidthPx: min(strokeWidth, barWidth as double));

            final endpointLength =
                min(endpointLengthPx ?? _defaultEndpointLengthPx, barWidth);

            // Draw horizontal whisker line for the lower bound.
            canvas.drawLine(points: [
              Point(x - endpointLength / 2, startY),
              Point(x + endpointLength / 2, startY)
            ], stroke: strokeColor, strokeWidthPx: strokeWidth);

            // Draw horizontal whisker line for the upper bound.
            canvas.drawLine(points: [
              Point(x - endpointLength / 2, endY),
              Point(x + endpointLength / 2, endY)
            ], stroke: strokeColor, strokeWidthPx: strokeWidth);
          }
        } else {
          final startX = measureAxis.getLocation(
              measureLowerBoundFn(datumIndex) + measureOffsetFn(datumIndex));
          final endX = measureAxis.getLocation(
              measureUpperBoundFn(datumIndex) + measureOffsetFn(datumIndex));

          if (startX != endX) {
            final barWidth = bounds.bottom - bounds.top;
            final y = (bounds.top + bounds.bottom) / 2;

            // Draw horizontal whisker line.
            canvas.drawLine(
                points: [Point(startX, y), Point(endX, y)],
                stroke: strokeColor,
                strokeWidthPx: min(strokeWidth, barWidth as double));

            final endpointLength =
                min(endpointLengthPx ?? _defaultEndpointLengthPx, barWidth);

            // Draw vertical whisker line for the lower bound.
            canvas.drawLine(
                points: [
                  Point(startX, y - endpointLength / 2),
                  Point(startX, y + endpointLength / 2)
                ],
                stroke: strokeColor,
                strokeWidthPx: min(strokeWidth, barWidth as double));

            // Draw vertical whisker line for the upper bound.
            canvas.drawLine(
                points: [
                  Point(endX, y - endpointLength / 2),
                  Point(endX, y + endpointLength / 2)
                ],
                stroke: strokeColor,
                strokeWidthPx: min(strokeWidth, barWidth as double));
          }
        }
      }
    }
  }
}

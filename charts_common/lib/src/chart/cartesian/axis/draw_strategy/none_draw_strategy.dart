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

import 'package:meta/meta.dart' show immutable, required;

import '../axis.dart' show AxisOrientation;
import '../collision_report.dart' show CollisionReport;
import '../spec/axis_spec.dart' show RenderSpec, LineStyleSpec;
import '../tick.dart' show Tick;
import '../../../common/chart_canvas.dart' show ChartCanvas;
import '../../../common/chart_context.dart' show ChartContext;
import '../../../layout/layout_view.dart' show ViewMeasuredSizes;
import '../../../../common/graphics_factory.dart' show GraphicsFactory;
import '../../../../common/line_style.dart' show LineStyle;
import '../../../../common/style/style_factory.dart' show StyleFactory;

import 'tick_draw_strategy.dart';

/// Renders no ticks no labels, and claims no space in layout.
/// However, it does render the axis line if asked to by the axis.
@immutable
class NoneRenderSpec<D> extends RenderSpec<D> {
  final LineStyleSpec axisLineStyle;

  NoneRenderSpec({this.axisLineStyle});

  @override
  TickDrawStrategy<D> createDrawStrategy(
          ChartContext chartContext, GraphicsFactory graphicsFactory) =>
      new NoneDrawStrategy<D>(chartContext, graphicsFactory,
          axisLineStyleSpec: axisLineStyle);

  @override
  bool operator ==(Object other) => other is NoneRenderSpec;

  @override
  int get hashCode => 0;
}

class NoneDrawStrategy<D> implements TickDrawStrategy<D> {
  LineStyle axisLineStyle;

  NoneDrawStrategy(ChartContext chartContext, GraphicsFactory graphicsFactory,
      {LineStyleSpec axisLineStyleSpec}) {
    axisLineStyle = StyleFactory.style
        .createAxisLineStyle(graphicsFactory, axisLineStyleSpec);
  }

  @override
  CollisionReport collides(List<Tick> ticks, AxisOrientation orientation) =>
      new CollisionReport(ticksCollide: false, ticks: ticks);

  @override
  void decorateTicks(List<Tick> ticks) {}

  @override
  void drawAxisLine(ChartCanvas canvas, AxisOrientation orientation,
      Rectangle<int> axisBounds) {
    Point<num> start;
    Point<num> end;

    switch (orientation) {
      case AxisOrientation.top:
        start = axisBounds.bottomLeft;
        end = axisBounds.bottomRight;

        break;
      case AxisOrientation.bottom:
        start = axisBounds.topLeft;
        end = axisBounds.topRight;
        break;
      case AxisOrientation.right:
        start = axisBounds.topLeft;
        end = axisBounds.bottomLeft;
        break;
      case AxisOrientation.left:
        start = axisBounds.topRight;
        end = axisBounds.bottomRight;
        break;
    }

    canvas.drawLine(
      points: [start, end],
      fill: axisLineStyle.color,
      stroke: axisLineStyle.color,
      strokeWidthPx: axisLineStyle.strokeWidth.toDouble(),
    );
  }

  @override
  void draw(ChartCanvas canvas, Tick<D> tick,
      {@required AxisOrientation orientation,
      @required Rectangle<int> axisBounds,
      @required Rectangle<int> drawAreaBounds,
      @required bool isFirst,
      @required bool isLast}) {}

  @override
  ViewMeasuredSizes measureHorizontallyDrawnTicks(
      List<Tick> ticks, int maxWidth, int maxHeight) {
    return new ViewMeasuredSizes(preferredWidth: 0, preferredHeight: 0);
  }

  @override
  ViewMeasuredSizes measureVerticallyDrawnTicks(
      List<Tick> ticks, int maxWidth, int maxHeight) {
    return new ViewMeasuredSizes(preferredWidth: 0, preferredHeight: 0);
  }
}

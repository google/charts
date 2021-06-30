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

import 'package:meta/meta.dart' show immutable;

import '../../../../common/graphics_factory.dart' show GraphicsFactory;
import '../../../../common/line_style.dart' show LineStyle;
import '../../../../common/style/style_factory.dart' show StyleFactory;
import '../../../common/chart_canvas.dart' show ChartCanvas;
import '../../../common/chart_context.dart' show ChartContext;
import '../axis.dart' show AxisOrientation;
import '../spec/axis_spec.dart'
    show TextStyleSpec, LineStyleSpec, TickLabelAnchor, TickLabelJustification;
import '../tick.dart' show Tick;
import 'base_tick_draw_strategy.dart' show BaseTickDrawStrategy;
import 'small_tick_draw_strategy.dart' show SmallTickRendererSpec;
import 'tick_draw_strategy.dart' show TickDrawStrategy;

@immutable
class GridlineRendererSpec<D> extends SmallTickRendererSpec<D> {
  const GridlineRendererSpec({
    TextStyleSpec? labelStyle,
    LineStyleSpec? lineStyle,
    LineStyleSpec? axisLineStyle,
    TickLabelAnchor? labelAnchor,
    TickLabelJustification? labelJustification,
    int? tickLengthPx,
    int? labelOffsetFromAxisPx,
    int? labelCollisionOffsetFromAxisPx,
    int? labelOffsetFromTickPx,
    int? labelCollisionOffsetFromTickPx,
    int? minimumPaddingBetweenLabelsPx,
    int? labelRotation,
    int? labelCollisionRotation,
  }) : super(
            labelStyle: labelStyle,
            lineStyle: lineStyle,
            labelAnchor: labelAnchor,
            labelJustification: labelJustification,
            labelOffsetFromAxisPx: labelOffsetFromAxisPx,
            labelCollisionOffsetFromAxisPx: labelCollisionOffsetFromAxisPx,
            labelOffsetFromTickPx: labelOffsetFromTickPx,
            labelCollisionOffsetFromTickPx: labelCollisionOffsetFromTickPx,
            minimumPaddingBetweenLabelsPx: minimumPaddingBetweenLabelsPx,
            labelRotation: labelRotation,
            labelCollisionRotation: labelCollisionRotation,
            tickLengthPx: tickLengthPx,
            axisLineStyle: axisLineStyle);

  @override
  TickDrawStrategy<D> createDrawStrategy(
          ChartContext context, GraphicsFactory graphicsFactory) =>
      GridlineTickDrawStrategy<D>(context, graphicsFactory,
          tickLengthPx: tickLengthPx,
          lineStyleSpec: lineStyle,
          labelStyleSpec: labelStyle,
          axisLineStyleSpec: axisLineStyle,
          labelAnchor: labelAnchor,
          labelJustification: labelJustification,
          labelOffsetFromAxisPx: labelOffsetFromAxisPx,
          labelCollisionOffsetFromAxisPx: labelCollisionOffsetFromAxisPx,
          labelOffsetFromTickPx: labelOffsetFromTickPx,
          labelCollisionOffsetFromTickPx: labelCollisionOffsetFromTickPx,
          minimumPaddingBetweenLabelsPx: minimumPaddingBetweenLabelsPx,
          labelRotation: labelRotation,
          labelCollisionRotation: labelCollisionRotation);

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is GridlineRendererSpec && super == other);
  }
}

/// Draws line across chart draw area for each tick.
///
/// Extends [BaseTickDrawStrategy].
class GridlineTickDrawStrategy<D> extends BaseTickDrawStrategy<D> {
  int tickLength;
  LineStyle lineStyle;

  GridlineTickDrawStrategy(
    ChartContext chartContext,
    GraphicsFactory graphicsFactory, {
    int? tickLengthPx,
    LineStyleSpec? lineStyleSpec,
    TextStyleSpec? labelStyleSpec,
    LineStyleSpec? axisLineStyleSpec,
    TickLabelAnchor? labelAnchor,
    TickLabelJustification? labelJustification,
    int? labelOffsetFromAxisPx,
    int? labelCollisionOffsetFromAxisPx,
    int? labelOffsetFromTickPx,
    int? labelCollisionOffsetFromTickPx,
    int? minimumPaddingBetweenLabelsPx,
    int? labelRotation,
    int? labelCollisionRotation,
  })  : tickLength = tickLengthPx ?? 0,
        lineStyle = StyleFactory.style
            .createGridlineStyle(graphicsFactory, lineStyleSpec),
        super(chartContext, graphicsFactory,
            labelStyleSpec: labelStyleSpec,
            axisLineStyleSpec: axisLineStyleSpec ?? lineStyleSpec,
            labelAnchor: labelAnchor,
            labelJustification: labelJustification,
            labelOffsetFromAxisPx: labelOffsetFromAxisPx,
            labelCollisionOffsetFromAxisPx: labelCollisionOffsetFromAxisPx,
            labelOffsetFromTickPx: labelOffsetFromTickPx,
            labelCollisionOffsetFromTickPx: labelCollisionOffsetFromTickPx,
            minimumPaddingBetweenLabelsPx: minimumPaddingBetweenLabelsPx,
            labelRotation: labelRotation,
            labelCollisionRotation: labelCollisionRotation);

  @override
  void draw(
    ChartCanvas canvas,
    Tick<D> tick, {
    required AxisOrientation orientation,
    required Rectangle<int> axisBounds,
    required Rectangle<int> drawAreaBounds,
    required bool isFirst,
    required bool isLast,
    bool collision = false,
  }) {
    Point<num> lineStart;
    Point<num> lineEnd;
    final tickLocationPx = tick.locationPx!;
    switch (orientation) {
      case AxisOrientation.top:
        final x = tickLocationPx;
        lineStart = Point(x, axisBounds.bottom - tickLength);
        lineEnd = Point(x, drawAreaBounds.bottom);
        break;
      case AxisOrientation.bottom:
        final x = tickLocationPx;
        lineStart = Point(x, drawAreaBounds.top + tickLength);
        lineEnd = Point(x, axisBounds.top);
        break;
      case AxisOrientation.right:
        final y = tickLocationPx;
        if (tickLabelAnchor(collision: collision) == TickLabelAnchor.after ||
            tickLabelAnchor(collision: collision) == TickLabelAnchor.before) {
          lineStart = Point(axisBounds.right, y);
        } else {
          lineStart = Point(axisBounds.left + tickLength, y);
        }
        lineEnd = Point(drawAreaBounds.left, y);
        break;
      case AxisOrientation.left:
        final y = tickLocationPx;

        if (tickLabelAnchor(collision: collision) == TickLabelAnchor.after ||
            tickLabelAnchor(collision: collision) == TickLabelAnchor.before) {
          lineStart = Point(axisBounds.left, y);
        } else {
          lineStart = Point(axisBounds.right - tickLength, y);
        }
        lineEnd = Point(drawAreaBounds.right, y);
        break;
    }

    canvas.drawLine(
      points: [lineStart, lineEnd],
      dashPattern: lineStyle.dashPattern,
      fill: lineStyle.color,
      stroke: lineStyle.color,
      strokeWidthPx: lineStyle.strokeWidth.toDouble(),
    );

    drawLabel(canvas, tick,
        orientation: orientation,
        axisBounds: axisBounds,
        drawAreaBounds: drawAreaBounds,
        isFirst: isFirst,
        isLast: isLast,
        collision: collision);
  }
}

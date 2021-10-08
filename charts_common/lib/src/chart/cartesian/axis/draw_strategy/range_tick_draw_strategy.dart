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
import '../../../../common/material_palette.dart' show MaterialPalette;
import '../../../../common/style/style_factory.dart' show StyleFactory;
import '../../../../common/text_style.dart' show TextStyle;
import '../../../common/chart_canvas.dart' show ChartCanvas;
import '../../../common/chart_context.dart' show ChartContext;
import '../../../layout/layout_view.dart' show ViewMeasuredSizes;
import '../axis.dart' show AxisOrientation;
import '../range_axis_tick.dart' show RangeAxisTicks;
import '../spec/axis_spec.dart'
    show TextStyleSpec, LineStyleSpec, TickLabelAnchor, TickLabelJustification;
import '../tick.dart' show Tick;
import 'base_tick_draw_strategy.dart' show BaseTickDrawStrategy;
import 'small_tick_draw_strategy.dart'
    show SmallTickRendererSpec, SmallTickDrawStrategy;
import 'tick_draw_strategy.dart' show TickDrawStrategy;

/// Displays individual ticks and range ticks and with a shade for ranges.
/// Sample ticks looks like:
/// -------------------------------------------------------------------
///  |   |                       |            |                    |
///  |   (Individual tick)       |            (Individual tick)    |
///  |///////Range Label/////////|///////////Range Label///////////|
@immutable
class RangeTickRendererSpec<D> extends SmallTickRendererSpec<D> {
  // Specifies range shade's style.
  final LineStyleSpec? rangeShadeStyle;
  // Specifies range label text style.
  final TextStyleSpec? rangeLabelStyle;
  // Specifies range tick's length.
  final int? rangeTickLengthPx;
  // Specifies range shade's height.
  final int? rangeShadeHeightPx;
  // Specifies the starting offet of range shade from axis in pixels.
  final int? rangeShadeOffsetFromAxisPx;
  // A range tick offset from the original location. The start point offset is
  // toward the origin and end point offset is toward the end of axis.
  final int? rangeTickOffsetPx;

  final TextStyleSpec defaultLabelStyleSpec;

  static const int defaultLabelOffsetFromAxis = 2;
  static const int defaultLabelOffsetFromTick = -4;

  RangeTickRendererSpec(
      {TextStyleSpec? labelStyle,
      LineStyleSpec? lineStyle,
      TickLabelAnchor? labelAnchor,
      TickLabelJustification? labelJustification,
      int? labelOffsetFromAxisPx,
      int? labelCollisionOffsetFromAxisPx,
      int? labelOffsetFromTickPx,
      int? labelCollisionOffsetFromTickPx,
      this.rangeShadeHeightPx,
      this.rangeShadeOffsetFromAxisPx,
      this.rangeShadeStyle,
      this.rangeTickLengthPx,
      this.rangeTickOffsetPx,
      this.rangeLabelStyle,
      int? tickLengthPx,
      int? minimumPaddingBetweenLabelsPx,
      int? labelRotation,
      int? labelCollisionRotation})
      : defaultLabelStyleSpec =
            TextStyleSpec(fontSize: 9, color: StyleFactory.style.tickColor),
        super(
          axisLineStyle: lineStyle,
          labelStyle: labelStyle,
          labelAnchor: labelAnchor,
          labelJustification: labelJustification,
          labelOffsetFromAxisPx:
              labelOffsetFromAxisPx ?? defaultLabelOffsetFromAxis,
          labelCollisionOffsetFromAxisPx: labelCollisionOffsetFromAxisPx,
          labelOffsetFromTickPx:
              labelOffsetFromTickPx ?? defaultLabelOffsetFromTick,
          labelCollisionOffsetFromTickPx: labelCollisionOffsetFromTickPx,
          tickLengthPx: tickLengthPx,
          minimumPaddingBetweenLabelsPx: minimumPaddingBetweenLabelsPx,
          labelRotation: labelRotation,
          labelCollisionRotation: labelCollisionRotation,
        );

  @override
  TickDrawStrategy<D> createDrawStrategy(
          ChartContext context, GraphicsFactory graphicsFactory) =>
      RangeTickDrawStrategy<D>(context, graphicsFactory,
          tickLength: tickLengthPx,
          rangeLabelTextStyleSpec: rangeLabelStyle,
          rangeTickLength: rangeTickLengthPx,
          rangeShadeHeight: rangeShadeHeightPx,
          rangeShadeOffsetFromAxis: rangeShadeOffsetFromAxisPx,
          rangeTickOffset: rangeTickOffsetPx,
          lineStyleSpec: lineStyle,
          labelStyleSpec: labelStyle ?? defaultLabelStyleSpec,
          axisLineStyleSpec: axisLineStyle,
          rangeShadeStyleSpec: rangeShadeStyle,
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
        (other is RangeTickRendererSpec && super == other);
  }
}

/// Draws small tick lines for each tick. Extends [BaseTickDrawStrategy].
class RangeTickDrawStrategy<D> extends SmallTickDrawStrategy<D> {
  int rangeTickLengthPx = 24;
  int rangeShadeHeightPx = 12;
  int rangeShadeOffsetFromAxisPx = 12;
  int rangeTickOffsetPx = 12;
  late LineStyle rangeShadeStyle;
  late TextStyle rangeLabelStyle;

  RangeTickDrawStrategy(
      ChartContext chartContext, GraphicsFactory graphicsFactory,
      {int? tickLength,
      int? rangeTickLength,
      int? rangeShadeHeight,
      int? rangeShadeOffsetFromAxis,
      int? rangeTickOffset,
      TextStyleSpec? rangeLabelTextStyleSpec,
      LineStyleSpec? lineStyleSpec,
      LineStyleSpec? rangeShadeStyleSpec,
      TextStyleSpec? labelStyleSpec,
      LineStyleSpec? axisLineStyleSpec,
      TickLabelAnchor? labelAnchor,
      int? labelOffsetFromAxisPx,
      int? labelCollisionOffsetFromAxisPx,
      int? labelOffsetFromTickPx,
      int? labelCollisionOffsetFromTickPx,
      TickLabelJustification? labelJustification,
      int? minimumPaddingBetweenLabelsPx,
      int? labelRotation,
      int? labelCollisionRotation})
      : super(chartContext, graphicsFactory,
            tickLengthPx: tickLength,
            axisLineStyleSpec: axisLineStyleSpec,
            labelStyleSpec: labelStyleSpec,
            lineStyleSpec: lineStyleSpec,
            labelAnchor: labelAnchor ?? TickLabelAnchor.after,
            labelJustification: labelJustification,
            labelOffsetFromAxisPx: labelOffsetFromAxisPx,
            labelCollisionOffsetFromAxisPx: labelCollisionOffsetFromAxisPx,
            labelOffsetFromTickPx: labelOffsetFromTickPx,
            labelCollisionOffsetFromTickPx: labelCollisionOffsetFromTickPx,
            minimumPaddingBetweenLabelsPx: minimumPaddingBetweenLabelsPx,
            labelRotation: labelRotation,
            labelCollisionRotation: labelCollisionRotation) {
    rangeTickOffsetPx = rangeTickOffset ?? rangeTickOffsetPx;
    rangeTickLengthPx = rangeTickLength ?? rangeTickLengthPx;
    rangeShadeHeightPx = rangeShadeHeight ?? rangeShadeHeightPx;
    rangeShadeOffsetFromAxisPx =
        rangeShadeOffsetFromAxis ?? rangeShadeOffsetFromAxisPx;
    lineStyle =
        StyleFactory.style.createTickLineStyle(graphicsFactory, lineStyleSpec);
    rangeShadeStyleSpec = rangeShadeStyleSpec ??
        LineStyleSpec(
          color: MaterialPalette.gray.shade300,
        );
    rangeShadeStyle = StyleFactory.style
        .createTickLineStyle(graphicsFactory, rangeShadeStyleSpec);
    rangeLabelStyle = rangeLabelTextStyleSpec == null
        ? (graphicsFactory.createTextPaint()
          ..color = labelStyleSpec?.color ?? StyleFactory.style.tickColor
          ..fontFamily = labelStyleSpec?.fontFamily
          ..fontSize = rangeShadeHeightPx - 1)
        : (graphicsFactory.createTextPaint()
          ..color = rangeLabelTextStyleSpec.color
          ..fontFamily = rangeLabelTextStyleSpec.fontFamily
          ..fontSize = rangeLabelTextStyleSpec.fontSize
          ..lineHeight = rangeLabelTextStyleSpec.lineHeight);
  }

  @override
  void draw(ChartCanvas canvas, Tick<D> tick,
      {required AxisOrientation orientation,
      required Rectangle<int> axisBounds,
      required Rectangle<int> drawAreaBounds,
      required bool isFirst,
      required bool isLast,
      bool collision = false}) {
    if (tick is RangeAxisTicks<D>) {
      drawRangeShadeAndRangeLabel(tick, canvas, orientation, axisBounds,
          drawAreaBounds, isFirst, isLast);
    } else {
      super.draw(canvas, tick,
          orientation: orientation,
          axisBounds: axisBounds,
          drawAreaBounds: drawAreaBounds,
          isFirst: isFirst,
          isLast: isLast,
          collision: collision);
    }
  }

  @override
  ViewMeasuredSizes measureVerticallyDrawnTicks(
      List<Tick<D>> ticks, int maxWidth, int maxHeight,
      {bool collision = false}) {
    // TODO: Add spacing to account for the distance between the
    // text and the axis baseline (even if it isn't drawn).

    final maxHorizontalSliceWidth = ticks.fold(0.0, (num prevMax, tick) {
      assert(tick.textElement != null);
      final labelElements = splitLabel(tick.textElement!);
      if (tick is RangeAxisTicks) {
        // Find the maximum within prevMax, label total height and
        // labelOffsetFromAxisPx + rangeShadeHeightPx.
        return max(
            max(
                prevMax,
                calculateWidthForRotatedLabel(
                      labelRotation(collision: collision),
                      getLabelHeight(labelElements),
                      getLabelWidth(labelElements),
                    ) +
                    labelOffsetFromAxisPx(collision: collision)),
            labelOffsetFromAxisPx(collision: collision) + rangeShadeHeightPx);
      } else {
        return max(
            prevMax,
            calculateWidthForRotatedLabel(
                  labelRotation(collision: collision),
                  getLabelHeight(labelElements),
                  getLabelWidth(labelElements),
                ) +
                labelOffsetFromAxisPx(collision: collision));
      }
    }).round();

    return ViewMeasuredSizes(
        preferredWidth: maxHorizontalSliceWidth, preferredHeight: maxHeight);
  }

  @override
  ViewMeasuredSizes measureHorizontallyDrawnTicks(
      List<Tick<D>> ticks, int maxWidth, int maxHeight,
      {bool collision = false}) {
    var maxVerticalSliceWidth = ticks.fold(0.0, (num prevMax, tick) {
      final labelElements = splitLabel(tick.textElement!);

      if (tick is RangeAxisTicks) {
        // Find the maximum within prevMax, label total height and
        // labelOffsetFromAxisPx + rangeShadeHeightPx.
        return max(
            max(
              prevMax,
              calculateHeightForRotatedLabel(
                    labelRotation(collision: collision),
                    getLabelHeight(labelElements),
                    getLabelWidth(labelElements),
                  ) +
                  rangeShadeOffsetFromAxisPx,
            ),
            rangeShadeOffsetFromAxisPx + rangeShadeHeightPx);
      } else {
        return max(
                prevMax,
                calculateHeightForRotatedLabel(
                  labelRotation(collision: collision),
                  getLabelHeight(labelElements),
                  getLabelWidth(labelElements),
                )) +
            labelOffsetFromAxisPx(collision: collision);
      }
    }).round();

    return ViewMeasuredSizes(
        preferredWidth: maxWidth, preferredHeight: maxVerticalSliceWidth);
  }

  void drawRangeShadeAndRangeLabel(
    RangeAxisTicks<D> tick,
    ChartCanvas canvas,
    AxisOrientation orientation,
    Rectangle<int> axisBounds,
    Rectangle<int> drawAreaBounds,
    bool isFirst,
    bool isLast,
  ) {
    // Create virtual range start and end ticks for position calculation.
    var rangeStartTick = Tick<D>(
      value: tick.rangeStartValue,
      locationPx: tick.rangeStartLocationPx - rangeTickOffsetPx,
      textElement: null,
    );
    var rangeEndTick = Tick<D>(
      value: tick.rangeEndValue,
      locationPx: isLast
          ? tick.rangeEndLocationPx + rangeTickOffsetPx
          : tick.rangeEndLocationPx - rangeTickOffsetPx,
      textElement: null,
    );
    // Calculate range start positions.
    var rangeStartPositions = calculateTickPositions(rangeStartTick,
        orientation, axisBounds, drawAreaBounds, rangeTickLengthPx);
    var rangeStartTickStart = rangeStartPositions.first;
    var rangeStartTickEnd = rangeStartPositions.last;

    // Calculate range end positions.
    var rangeEndPositions = calculateTickPositions(rangeEndTick, orientation,
        axisBounds, drawAreaBounds, rangeTickLengthPx);
    var rangeEndTickStart = rangeEndPositions.first;
    var rangeEndTickEnd = rangeEndPositions.last;

    // Draw range shade.
    Rectangle rangeShade;
    switch (orientation) {
      case AxisOrientation.top:
      case AxisOrientation.bottom:
        rangeShade = Rectangle(
            rangeStartTickStart.x,
            rangeStartTickStart.y + rangeShadeOffsetFromAxisPx,
            rangeEndTickStart.x - rangeStartTickStart.x,
            rangeShadeHeightPx);
        break;
      case AxisOrientation.right:
        rangeShade = Rectangle(
            rangeEndTickStart.x + rangeShadeOffsetFromAxisPx,
            rangeEndTickStart.y,
            rangeShadeHeightPx,
            rangeEndTickStart.y - rangeEndTickStart.y);
        break;
      case AxisOrientation.left:
        rangeShade = Rectangle(
            rangeEndTickStart.x -
                rangeShadeOffsetFromAxisPx -
                rangeShadeHeightPx,
            rangeEndTickStart.y,
            rangeShadeHeightPx,
            rangeEndTickStart.y - rangeEndTickStart.y);
        break;
    }
    canvas.drawRect(rangeShade,
        fill: rangeShadeStyle.color,
        stroke: rangeShadeStyle.color,
        strokeWidthPx: rangeShadeStyle.strokeWidth.toDouble());

    // Draw the start and end boundaries of the range.
    canvas.drawLine(
      points: [rangeStartTickStart, rangeStartTickEnd],
      dashPattern: lineStyle.dashPattern,
      fill: lineStyle.color,
      stroke: lineStyle.color,
      strokeWidthPx: lineStyle.strokeWidth.toDouble(),
    );
    canvas.drawLine(
      points: [rangeEndTickStart, rangeEndTickEnd],
      dashPattern: lineStyle.dashPattern,
      fill: lineStyle.color,
      stroke: lineStyle.color,
      strokeWidthPx: lineStyle.strokeWidth.toDouble(),
    );

    // Prepare range label.
    final rangeLabelTextElement = tick.textElement!
      ..textStyle = rangeLabelStyle;

    final labelElements = splitLabel(rangeLabelTextElement);
    final labelWidth = getLabelWidth(labelElements);

    // Draw range label on top of range shade.
    var multiLineLabelOffset = 0;
    for (final line in labelElements) {
      var x = 0;
      var y = 0;

      if (orientation == AxisOrientation.bottom ||
          orientation == AxisOrientation.top) {
        y = rangeStartTickStart.y.toInt() + rangeShadeOffsetFromAxisPx - 1;

        x = (rangeStartTickStart.x +
                (rangeEndTickStart.x - rangeStartTickStart.x - labelWidth) / 2)
            .round();
      }
      // TODO: add support for orientation left and right.
      canvas.drawText(line, x, y + multiLineLabelOffset);
      multiLineLabelOffset += BaseTickDrawStrategy.multiLineLabelPadding +
          line.measurement.verticalSliceWidth.round();
    }
  }
}

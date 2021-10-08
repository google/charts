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

import 'package:meta/meta.dart' show immutable, protected;

import '../../../../common/graphics_factory.dart' show GraphicsFactory;
import '../../../../common/line_style.dart' show LineStyle;
import '../../../../common/style/style_factory.dart' show StyleFactory;
import '../../../../common/text_element.dart'
    show TextDirection, TextElement, MaxWidthStrategy;
import '../../../../common/text_style.dart' show TextStyle;
import '../../../common/chart_canvas.dart' show ChartCanvas;
import '../../../common/chart_context.dart' show ChartContext;
import '../../../layout/layout_view.dart' show ViewMeasuredSizes;
import '../axis.dart' show AxisOrientation;
import '../collision_report.dart' show CollisionReport;
import '../spec/axis_spec.dart'
    show
        TextStyleSpec,
        TickLabelAnchor,
        TickLabelJustification,
        LineStyleSpec,
        RenderSpec;
import '../tick.dart' show Tick;
import 'tick_draw_strategy.dart' show TickDrawStrategy;

@immutable
abstract class BaseRenderSpec<D> implements RenderSpec<D> {
  final TextStyleSpec? labelStyle;
  final TickLabelAnchor? labelAnchor;
  final TickLabelJustification? labelJustification;

  /// Distance from the axis line in px.
  final int? labelOffsetFromAxisPx;

  /// Distance from the axis line in px when a collision between ticks has
  /// occurred.
  final int? labelCollisionOffsetFromAxisPx;

  /// Absolute distance from the tick to the text if using start/end
  final int? labelOffsetFromTickPx;

  /// Absolute distance from the tick to the text when a collision between ticks
  /// has occurred.
  final int? labelCollisionOffsetFromTickPx;

  final int? minimumPaddingBetweenLabelsPx;

  /// Angle of rotation for tick labels, in degrees. When set to a non-zero
  /// value, all labels drawn for this axis will be rotated.
  final int? labelRotation;

  /// Angle of rotation for tick labels, in degrees when a collision between
  /// ticks has occurred.
  final int? labelCollisionRotation;

  final LineStyleSpec? axisLineStyle;

  const BaseRenderSpec({
    this.labelStyle,
    this.labelAnchor,
    this.labelJustification,
    this.labelOffsetFromAxisPx,
    this.labelCollisionOffsetFromAxisPx,
    this.labelOffsetFromTickPx,
    this.labelCollisionOffsetFromTickPx,
    this.minimumPaddingBetweenLabelsPx,
    this.labelRotation,
    this.labelCollisionRotation,
    this.axisLineStyle,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is BaseRenderSpec &&
            labelStyle == other.labelStyle &&
            labelAnchor == other.labelAnchor &&
            labelJustification == other.labelJustification &&
            labelOffsetFromTickPx == other.labelOffsetFromTickPx &&
            labelCollisionOffsetFromTickPx ==
                other.labelCollisionOffsetFromTickPx &&
            labelOffsetFromAxisPx == other.labelOffsetFromAxisPx &&
            labelCollisionOffsetFromAxisPx ==
                other.labelCollisionOffsetFromAxisPx &&
            minimumPaddingBetweenLabelsPx ==
                other.minimumPaddingBetweenLabelsPx &&
            labelRotation == other.labelRotation &&
            labelCollisionRotation == other.labelCollisionRotation &&
            axisLineStyle == other.axisLineStyle);
  }

  @override
  int get hashCode {
    var hashcode = labelStyle.hashCode;
    hashcode = (hashcode * 37) + labelAnchor.hashCode;
    hashcode = (hashcode * 37) + labelJustification.hashCode;
    hashcode = (hashcode * 37) + labelOffsetFromTickPx.hashCode;
    hashcode = (hashcode * 37) + labelCollisionOffsetFromTickPx.hashCode;
    hashcode = (hashcode * 37) + labelOffsetFromAxisPx.hashCode;
    hashcode = (hashcode * 37) + labelCollisionOffsetFromAxisPx.hashCode;
    hashcode = (hashcode * 37) + minimumPaddingBetweenLabelsPx.hashCode;
    hashcode = (hashcode * 37) + labelRotation.hashCode;
    hashcode = (hashcode * 37) + labelCollisionRotation.hashCode;
    hashcode = (hashcode * 37) + axisLineStyle.hashCode;
    return hashcode;
  }
}

/// Base strategy that draws tick labels and checks for label collisions.
abstract class BaseTickDrawStrategy<D> implements TickDrawStrategy<D> {
  static final _labelSplitPattern = '\n';
  static final multiLineLabelPadding = 2;

  static double _degToRad(double deg) => deg * (pi / 180.0);

  final ChartContext chartContext;
  final GraphicsFactory graphicsFactory;

  LineStyle axisLineStyle;
  TextStyle labelStyle;
  TickLabelJustification tickLabelJustification;
  final TickLabelAnchor _defaultTickLabelAnchor;
  final int _labelDefaultOffsetFromAxisPx;
  final int _labelCollisionOffsetFromAxisPx;
  final int _labelDefaultOffsetFromTickPx;
  final int _labelCollisionOffsetFromTickPx;
  final int _labelDefaultRotation;
  final int _labelCollisionRotation;
  final bool _rotateOnCollision;

  int minimumPaddingBetweenLabelsPx;

  int labelRotation({required bool collision}) =>
      collision && _rotateOnCollision
          ? _labelCollisionRotation
          : _labelDefaultRotation;

  int labelOffsetFromAxisPx({required bool collision}) =>
      collision && _rotateOnCollision
          ? _labelCollisionOffsetFromAxisPx
          : _labelDefaultOffsetFromAxisPx;

  int labelOffsetFromTickPx({required bool collision}) =>
      collision && _rotateOnCollision
          ? _labelCollisionOffsetFromTickPx
          : _labelDefaultOffsetFromTickPx;

  TickLabelAnchor tickLabelAnchor({required bool collision}) =>
      collision && _rotateOnCollision
          ? TickLabelAnchor.after
          : _defaultTickLabelAnchor;

  BaseTickDrawStrategy(
    this.chartContext,
    this.graphicsFactory, {
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
  })  : labelStyle = graphicsFactory.createTextPaint(),
        axisLineStyle = graphicsFactory.createLinePaint(),
        _defaultTickLabelAnchor = labelAnchor ?? TickLabelAnchor.centered,
        tickLabelJustification =
            labelJustification ?? TickLabelJustification.inside,
        _rotateOnCollision = labelCollisionRotation != null,
        minimumPaddingBetweenLabelsPx = minimumPaddingBetweenLabelsPx ?? 50,
        _labelDefaultOffsetFromAxisPx = labelOffsetFromAxisPx ?? 5,
        _labelDefaultOffsetFromTickPx = labelOffsetFromTickPx ?? 5,
        _labelDefaultRotation = labelRotation ?? 0,
        _labelCollisionOffsetFromAxisPx = labelCollisionOffsetFromAxisPx ?? 5,
        _labelCollisionOffsetFromTickPx = labelCollisionOffsetFromTickPx ?? 5,
        _labelCollisionRotation = labelCollisionRotation ?? 0 {
    labelStyle
      ..color = labelStyleSpec?.color ?? StyleFactory.style.tickColor
      ..fontFamily = labelStyleSpec?.fontFamily
      ..fontSize = labelStyleSpec?.fontSize ?? 12
      ..lineHeight = labelStyleSpec?.lineHeight
      ..fontWeight = labelStyleSpec?.fontWeight ?? "400";

    axisLineStyle
      ..color = axisLineStyleSpec?.color ?? labelStyle.color
      ..dashPattern = axisLineStyleSpec?.dashPattern
      ..strokeWidth = axisLineStyleSpec?.thickness ?? 1;
  }

  @override
  void decorateTicks(List<Tick<D>> ticks) {
    for (final tick in ticks) {
      var textElement = tick.textElement;
      if (textElement == null) {
        continue;
      }

      // If no style at all, set the default style.
      if (textElement.textStyle == null) {
        textElement.textStyle = labelStyle;
      } else {
        // Fill in whatever is missing
        var textStyle = textElement.textStyle!;
        textStyle.color ??= labelStyle.color;
        textStyle.fontFamily ??= labelStyle.fontFamily;
        textStyle.fontSize ??= labelStyle.fontSize;
        textStyle.fontWeight ??= labelStyle.fontWeight;
        textStyle.lineHeight ??= labelStyle.lineHeight;
      }
    }
  }

  @override
  void updateTickWidth(List<Tick<D>> ticks, int maxWidth, int maxHeight,
      AxisOrientation orientation,
      {bool collision = false}) {
    final isVertical =
        orientation != null && orientation == AxisOrientation.right ||
            orientation == AxisOrientation.left;
    final rotationRelativeToAxis =
        labelRotation(collision: collision).toDouble();
    final rotationRads =
        _degToRad(rotationRelativeToAxis - (isVertical ? 90 : 0)).abs();
    final availableSpace = (isVertical ? maxWidth : maxHeight) -
        labelOffsetFromAxisPx(collision: collision);
    final maxTextWidth = sin(rotationRads) == 0
        ? null
        : (availableSpace / sin(rotationRads)).floor();

    for (final tick in ticks) {
      if (maxTextWidth != null) {
        tick.textElement!.maxWidth = maxTextWidth;
        tick.textElement!.maxWidthStrategy = MaxWidthStrategy.ellipsize;
      } else {
        tick.textElement!.maxWidth = null;
        tick.textElement!.maxWidthStrategy = null;
      }
    }
  }

  @override
  CollisionReport<D> collides(
      List<Tick<D>>? ticks, AxisOrientation? orientation) {
    // TODO: Collision analysis for rotated labels are not
    // supported yet.

    // If there are no ticks, they do not collide.
    if (ticks == null) {
      return CollisionReport(
          ticksCollide: false, ticks: ticks, alternateTicksUsed: false);
    }

    final vertical = orientation == AxisOrientation.left ||
        orientation == AxisOrientation.right;

    ticks = [
      for (var tick in ticks)
        if (tick.locationPx != null) tick,
    ];

    // First sort ticks by smallest locationPx first (NOT sorted by value).
    // This allows us to only check if a tick collides with the previous tick.
    ticks.sort((a, b) => a.locationPx!.compareTo(b.locationPx!));

    var previousEnd = double.negativeInfinity;
    var collides = false;

    for (final tick in ticks) {
      final tickSize = tick.textElement?.measurement;
      final tickLocationPx = tick.locationPx!;

      if (vertical) {
        final adjustedHeight = (tickSize?.verticalSliceWidth ?? 0.0) +
            minimumPaddingBetweenLabelsPx;

        if (_defaultTickLabelAnchor == TickLabelAnchor.inside) {
          if (identical(tick, ticks.first)) {
            // Top most tick draws down from the location
            collides = false;
            previousEnd = tickLocationPx + adjustedHeight;
          } else if (identical(tick, ticks.last)) {
            // Bottom most tick draws up from the location
            collides = previousEnd > tickLocationPx - adjustedHeight;
            previousEnd = tickLocationPx;
          } else {
            // All other ticks is centered.
            final halfHeight = adjustedHeight / 2;
            collides = previousEnd > tickLocationPx - halfHeight;
            previousEnd = tickLocationPx + halfHeight;
          }
        } else {
          collides = previousEnd > tickLocationPx;
          previousEnd = tickLocationPx + adjustedHeight;
        }
      } else {
        // Use the text direction the ticks specified, unless the label anchor
        // is set to [TickLabelAnchor.inside]. When 'inside' is set, the text
        // direction is normalized such that the left most tick is drawn ltr,
        // the last tick is drawn rtl, and all other ticks are in the center.
        // This is not set until it is painted, so collision check needs to get
        // the value also.
        final textDirection = _normalizeHorizontalAnchor(
            _defaultTickLabelAnchor,
            chartContext.isRtl,
            identical(tick, ticks.first),
            identical(tick, ticks.last));
        final adjustedWidth = (tickSize?.horizontalSliceWidth ?? 0.0) +
            minimumPaddingBetweenLabelsPx;
        switch (textDirection) {
          case TextDirection.ltr:
            collides = previousEnd > tickLocationPx;
            previousEnd = tickLocationPx + adjustedWidth;
            break;
          case TextDirection.rtl:
            collides = previousEnd > (tickLocationPx - adjustedWidth);
            previousEnd = tickLocationPx;
            break;
          case TextDirection.center:
            final halfWidth = adjustedWidth / 2;
            collides = previousEnd > tickLocationPx - halfWidth;
            previousEnd = tickLocationPx + halfWidth;

            break;
        }
      }

      if (collides) {
        return CollisionReport(
            ticksCollide: true, ticks: ticks, alternateTicksUsed: false);
      }
    }

    return CollisionReport(
        ticksCollide: false, ticks: ticks, alternateTicksUsed: false);
  }

  @override
  ViewMeasuredSizes measureVerticallyDrawnTicks(
      List<Tick<D>> ticks, int maxWidth, int maxHeight,
      {bool collision = false}) {
    // TODO: Add spacing to account for the distance between the
    // text and the axis baseline (even if it isn't drawn).

    final maxHorizontalSliceWidth = ticks.fold(0.0, (double prevMax, tick) {
      final labelElements = splitLabel(tick.textElement!);

      return max(
          prevMax,
          calculateWidthForRotatedLabel(
                labelRotation(collision: collision),
                getLabelHeight(labelElements),
                getLabelWidth(labelElements),
              ) +
              labelOffsetFromAxisPx(collision: collision));
    }).round();

    return ViewMeasuredSizes(
        preferredWidth: maxHorizontalSliceWidth, preferredHeight: maxHeight);
  }

  @override
  ViewMeasuredSizes measureHorizontallyDrawnTicks(
      List<Tick<D>> ticks, int maxWidth, int maxHeight,
      {bool collision = false}) {
    final maxVerticalSliceWidth = ticks.fold(0.0, (double prevMax, tick) {
      final labelElements = splitLabel(tick.textElement!);

      return max(
          prevMax,
          calculateHeightForRotatedLabel(
            labelRotation(collision: collision),
            getLabelHeight(labelElements),
            getLabelWidth(labelElements),
          ));
    }).round();

    return ViewMeasuredSizes(
        preferredWidth: maxWidth,
        preferredHeight: min(
            maxHeight,
            maxVerticalSliceWidth +
                labelOffsetFromAxisPx(collision: collision)));
  }

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
      dashPattern: axisLineStyle.dashPattern,
    );
  }

  // TODO: Why is drawAreaBounds required when it is unused?
  @protected
  void drawLabel(
    ChartCanvas canvas,
    Tick<D> tick, {
    required AxisOrientation orientation,
    required Rectangle<int> axisBounds,
    required Rectangle<int>? drawAreaBounds,
    required bool isFirst,
    required bool isLast,
    bool collision = false,
  }) {
    final locationPx = tick.locationPx ?? 0;
    final labelOffsetPx = tick.labelOffsetPx ?? 0;
    final isRtl = chartContext.isRtl;
    final labelElements = splitLabel(tick.textElement!);
    final labelHeight = getLabelHeight(labelElements);
    var multiLineLabelOffset = 0;

    for (final line in labelElements) {
      var x = 0;
      var y = 0;

      if (orientation == AxisOrientation.bottom ||
          orientation == AxisOrientation.top) {
        y = orientation == AxisOrientation.bottom
            ? axisBounds.top + labelOffsetFromAxisPx(collision: collision)
            : axisBounds.bottom -
                (labelHeight.toInt() - multiLineLabelOffset) -
                labelOffsetFromAxisPx(collision: collision);

        final direction = _normalizeHorizontalAnchor(
            tickLabelAnchor(collision: collision), isRtl, isFirst, isLast);

        line.textDirection = direction;

        switch (direction) {
          case TextDirection.rtl:
            x = (locationPx +
                    labelOffsetFromTickPx(collision: collision) +
                    labelOffsetPx)
                .toInt();
            break;
          case TextDirection.ltr:
            x = (locationPx -
                    labelOffsetFromTickPx(collision: collision) -
                    labelOffsetPx)
                .toInt();
            break;
          case TextDirection.center:
          default:
            x = (locationPx - labelOffsetPx).toInt();
            break;
        }
      } else {
        if (orientation == AxisOrientation.left) {
          if (tickLabelJustification == TickLabelJustification.inside) {
            x = axisBounds.right - labelOffsetFromAxisPx(collision: collision);
            line.textDirection = TextDirection.rtl;
          } else {
            x = axisBounds.left;
            line.textDirection = TextDirection.ltr;
          }
        } else {
          // orientation == right
          if (tickLabelJustification == TickLabelJustification.inside) {
            x = axisBounds.left + labelOffsetFromAxisPx(collision: collision);
            line.textDirection = TextDirection.ltr;
          } else {
            x = axisBounds.right;
            line.textDirection = TextDirection.rtl;
          }
        }

        switch (normalizeVerticalAnchor(
            tickLabelAnchor(collision: collision), isFirst, isLast)) {
          case _PixelVerticalDirection.over:
            y = (locationPx -
                    (labelHeight - multiLineLabelOffset) -
                    labelOffsetFromTickPx(collision: collision) -
                    labelOffsetPx)
                .toInt();
            break;
          case _PixelVerticalDirection.under:
            y = (locationPx +
                    labelOffsetFromTickPx(collision: collision) +
                    labelOffsetPx)
                .toInt();
            break;
          case _PixelVerticalDirection.center:
          default:
            y = (locationPx - labelHeight / 2 + labelOffsetPx).toInt();
            break;
        }
      }
      canvas.drawText(line, x, y + multiLineLabelOffset,
          rotation: _degToRad(labelRotation(collision: collision).toDouble()));
      multiLineLabelOffset +=
          multiLineLabelPadding + line.measurement.verticalSliceWidth.round();
    }
  }

  TextDirection _normalizeHorizontalAnchor(
      TickLabelAnchor anchor, bool isRtl, bool isFirst, bool isLast) {
    switch (anchor) {
      case TickLabelAnchor.before:
        return isRtl ? TextDirection.ltr : TextDirection.rtl;
      case TickLabelAnchor.after:
        return isRtl ? TextDirection.rtl : TextDirection.ltr;
      case TickLabelAnchor.inside:
        if (isFirst) {
          return TextDirection.ltr;
        }
        if (isLast) {
          return TextDirection.rtl;
        }
        return TextDirection.center;
      case TickLabelAnchor.centered:
      default:
        return TextDirection.center;
    }
  }

  @protected
  _PixelVerticalDirection normalizeVerticalAnchor(
      TickLabelAnchor anchor, bool isFirst, bool isLast) {
    switch (anchor) {
      case TickLabelAnchor.before:
        return _PixelVerticalDirection.under;
      case TickLabelAnchor.after:
        return _PixelVerticalDirection.over;
      case TickLabelAnchor.inside:
        if (isFirst) {
          return _PixelVerticalDirection.over;
        }
        if (isLast) {
          return _PixelVerticalDirection.under;
        }
        return _PixelVerticalDirection.center;
      case TickLabelAnchor.centered:
      default:
        return _PixelVerticalDirection.center;
    }
  }

  /// Returns the width of a rotated labels on a domain axis.
  double calculateWidthForRotatedLabel(
      int rotation, double labelHeight, double labelLength) {
    if (rotation == 0) return labelLength;
    var rotationRadian = _degToRad(rotation.toDouble());

    // Imagine a right triangle with a base that is parallel to the axis
    // baseline. The side of this triangle that is perpendicular to the baseline
    // is the height of the axis we wish to calculate. The hypotenuse of the
    // triangle is the given length of the tick labels, labelLength. The angle
    // between the perpendicular line and the hypotenuse (the tick label) is 90
    // - the label rotation angle, since the tick label transformation is
    // applied relative to the axis baseline. Given this triangle, we can
    // calculate the height of the axis by using the cosine of this angle.

    // The triangle assumes a zero-height line for the labels, but the actual
    // rendered text will be drawn above and below this center line. To account
    // for this, extend the label length by using a triangle with half the
    // height of the label.
    labelLength += labelHeight / 2.0 * tan(rotationRadian);

    // To compute the label width, we need the angle between the label and a
    // line perpendicular to the axis baseline, in radians.
    return labelLength * cos(rotationRadian);
  }

  /// Returns the height of a rotated labels on a domain axis.
  double calculateHeightForRotatedLabel(
      int rotation, double labelHeight, double labelLength) {
    if (rotation == 0) return labelHeight;
    var rotationRadian = _degToRad(rotation.toDouble());

    // Imagine a right triangle with a base that is parallel to the axis
    // baseline. The side of this triangle that is perpendicular to the baseline
    // is the height of the axis we wish to calculate. The hypotenuse of the
    // triangle is the given length of the tick labels, labelLength. The angle
    // between the perpendicular line and the hypotenuse (the tick label) is 90
    // - the label rotation angle, since the tick label transformation is
    // applied relative to the axis baseline. Given this triangle, we can
    // calculate the height of the axis by using the cosine of this angle.

    // The triangle assumes a zero-height line for the labels, but the actual
    // rendered text will be drawn above and below this center line. To account
    // for this, extend the label length by using a triangle with half the
    // height of the label.
    labelLength += labelHeight / 2.0 * tan(rotationRadian);

    // To compute the label height, we need the angle between the label and a
    // line perpendicular to the axis baseline, in radians.
    var angle = pi / 2.0 - rotationRadian.abs();
    return max(labelHeight, labelLength * cos(angle));
  }

  /// The [wholeLabel] is split into constituent chunks if it is multiline.
  List<TextElement> splitLabel(TextElement wholeLabel) => wholeLabel.text
      .split(_labelSplitPattern)
      .map((line) => (graphicsFactory.createTextElement(line.trim())
        ..textStyle = wholeLabel.textStyle))
      .toList();

  /// The width of the label (handles labels spanning multiple lines).
  ///
  /// If the label spans multiple lines then it returns the width of the
  /// longest line.
  double getLabelWidth(Iterable<TextElement> labelElements) => labelElements
      .map((line) => line.measurement.horizontalSliceWidth)
      .reduce(max);

  /// The height of the label (handles labels spanning multiple lines).
  double getLabelHeight(Iterable<TextElement> labelElements) {
    if (labelElements.isEmpty) return 0;
    final textHeight = labelElements.first.measurement.verticalSliceWidth;
    final numLines = labelElements.length;
    return (textHeight * numLines) + (multiLineLabelPadding * (numLines - 1));
  }
}

enum _PixelVerticalDirection {
  over,
  center,
  under,
}

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

import 'dart:math' show max, min, Rectangle;

import 'package:meta/meta.dart' show protected;

import '../../common/color.dart' show Color;
import '../../common/math.dart' show NullablePoint;
import '../cartesian/axis/axis.dart'
    show ImmutableAxis, domainAxisKey, measureAxisKey;
import '../common/canvas_shapes.dart' show CanvasBarStack, CanvasRect;
import '../common/chart_canvas.dart' show ChartCanvas, FillPatternType;
import '../common/datum_details.dart' show DatumDetails;
import '../common/processed_series.dart' show ImmutableSeries, MutableSeries;
import '../common/series_datum.dart' show SeriesDatum;
import 'bar_renderer_config.dart' show BarRendererConfig, CornerStrategy;
import 'bar_renderer_decorator.dart' show BarRendererDecorator;
import 'base_bar_renderer.dart'
    show
        BaseBarRenderer,
        allBarGroupWeightsKey,
        barGroupCountKey,
        barGroupIndexKey,
        barGroupWeightKey,
        previousBarGroupWeightKey;
import 'base_bar_renderer_element.dart'
    show BaseAnimatedBar, BaseBarRendererElement;

/// Renders series data as a series of bars.
class BarRenderer<D>
    extends BaseBarRenderer<D, BarRendererElement<D>, AnimatedBar<D>> {
  /// If we are grouped, use this spacing between the bars in a group.
  final int _barGroupInnerPaddingPx;

  /// The padding between bar stacks.
  ///
  /// The padding comes out of the bottom of the bar.
  final int _stackedBarPaddingPx;

  final BarRendererDecorator<Object?>? barRendererDecorator;

  factory BarRenderer({BarRendererConfig<D>? config, String? rendererId}) {
    rendererId ??= 'bar';
    config ??= BarRendererConfig();
    return BarRenderer.internal(config: config, rendererId: rendererId);
  }

  /// This constructor is protected because it is used by child classes, which
  /// cannot call the factory in their own constructors.
  @protected
  BarRenderer.internal({
    required BarRendererConfig<Object?> config,
    required String rendererId,
  })  : barRendererDecorator = config.barRendererDecorator,
        _stackedBarPaddingPx = config.stackedBarPaddingPx,
        _barGroupInnerPaddingPx = config.barGroupInnerPaddingPx,
        super(
            config: config,
            rendererId: rendererId,
            layoutPaintOrder: config.layoutPaintOrder ?? 0);

  @override
  void configureSeries(List<MutableSeries<D>> seriesList) {
    assignMissingColors(getOrderedSeriesList(seriesList),
        emptyCategoryUsesSinglePalette: true);
  }

  @override
  DatumDetails<D> addPositionToDetailsForSeriesDatum(
      DatumDetails<D> details, SeriesDatum<D> seriesDatum) {
    final series = details.series!;

    final domainAxis = series.getAttr(domainAxisKey) as ImmutableAxis<D>;
    final measureAxis = series.getAttr(measureAxisKey) as ImmutableAxis<num>;

    final barGroupIndex = series.getAttr(barGroupIndexKey)!;
    final previousBarGroupWeight = series.getAttr(previousBarGroupWeightKey);
    final barGroupWeight = series.getAttr(barGroupWeightKey);
    final allBarGroupWeights = series.getAttr(allBarGroupWeightsKey);
    final numBarGroups = series.getAttr(barGroupCountKey)!;

    final bounds = _getBarBounds(
        details.domain,
        domainAxis,
        domainAxis.rangeBand.round(),
        config.maxBarWidthPx,
        details.measure,
        details.measureOffset!,
        measureAxis,
        barGroupIndex,
        previousBarGroupWeight,
        barGroupWeight,
        allBarGroupWeights,
        numBarGroups);

    NullablePoint chartPosition;

    if (renderingVertically) {
      chartPosition = NullablePoint(
          (bounds.left + (bounds.width / 2)).toDouble(), bounds.top.toDouble());
    } else {
      chartPosition = NullablePoint(
          isRtl ? bounds.left.toDouble() : bounds.right.toDouble(),
          (bounds.top + (bounds.height / 2)).toDouble());
    }

    return DatumDetails.from(details,
        chartPosition: chartPosition, bounds: bounds);
  }

  @override
  BarRendererElement<D> getBaseDetails(dynamic datum, int index) {
    return BarRendererElement<D>();
  }

  CornerStrategy get cornerStrategy {
    return (config as BarRendererConfig).cornerStrategy;
  }

  /// Generates an [AnimatedBar] to represent the previous and current state
  /// of one bar on the chart.
  @override
  AnimatedBar<D> makeAnimatedBar(
      {required String key,
      required ImmutableSeries<D> series,
      List<int>? dashPattern,
      dynamic datum,
      Color? color,
      required BarRendererElement<D> details,
      D? domainValue,
      required ImmutableAxis<D> domainAxis,
      required int domainWidth,
      num? measureValue,
      required num measureOffsetValue,
      required ImmutableAxis<num> measureAxis,
      double? measureAxisPosition,
      Color? fillColor,
      FillPatternType? fillPattern,
      double? strokeWidthPx,
      required int barGroupIndex,
      double? previousBarGroupWeight,
      double? barGroupWeight,
      List<double>? allBarGroupWeights,
      required int numBarGroups,
      bool? measureIsNull,
      bool? measureIsNegative}) {
    return AnimatedBar<D>(
        key: key, datum: datum, series: series, domainValue: domainValue)
      ..setNewTarget(makeBarRendererElement(
          color: color,
          dashPattern: dashPattern,
          details: details,
          domainValue: domainValue,
          domainAxis: domainAxis,
          domainWidth: domainWidth,
          measureValue: measureValue,
          measureOffsetValue: measureOffsetValue,
          measureAxisPosition: measureAxisPosition,
          measureAxis: measureAxis,
          fillColor: fillColor,
          fillPattern: fillPattern,
          strokeWidthPx: strokeWidthPx,
          barGroupIndex: barGroupIndex,
          previousBarGroupWeight: previousBarGroupWeight,
          barGroupWeight: barGroupWeight,
          allBarGroupWeights: allBarGroupWeights,
          numBarGroups: numBarGroups,
          measureIsNull: measureIsNull,
          measureIsNegative: measureIsNegative));
  }

  /// Generates a [BarRendererElement] to represent the rendering data for one
  /// bar on the chart.
  @override
  BarRendererElement<D> makeBarRendererElement(
      {Color? color,
      List<int>? dashPattern,
      required BarRendererElement<D> details,
      D? domainValue,
      required ImmutableAxis<D> domainAxis,
      required int domainWidth,
      num? measureValue,
      required num measureOffsetValue,
      required ImmutableAxis<num> measureAxis,
      double? measureAxisPosition,
      Color? fillColor,
      FillPatternType? fillPattern,
      double? strokeWidthPx,
      required int barGroupIndex,
      double? previousBarGroupWeight,
      double? barGroupWeight,
      List<double>? allBarGroupWeights,
      required int numBarGroups,
      bool? measureIsNull,
      bool? measureIsNegative}) {
    return BarRendererElement<D>()
      ..color = color
      ..dashPattern = dashPattern
      ..fillColor = fillColor
      ..fillPattern = fillPattern
      ..measureAxisPosition = measureAxisPosition
      ..roundPx = details.roundPx
      ..strokeWidthPx = strokeWidthPx
      ..measureIsNull = measureIsNull
      ..measureIsNegative = measureIsNegative
      ..bounds = _getBarBounds(
          domainValue,
          domainAxis,
          domainWidth,
          config.maxBarWidthPx,
          measureValue,
          measureOffsetValue,
          measureAxis,
          barGroupIndex,
          previousBarGroupWeight,
          barGroupWeight,
          allBarGroupWeights,
          numBarGroups);
  }

  @override
  void paintBar(ChartCanvas canvas, double animationPercent,
      Iterable<BarRendererElement<D>> barElements) {
    final bars = <CanvasRect>[];

    // When adjusting bars for stacked bar padding, do not modify the first bar
    // if rendering vertically and do not modify the last bar if rendering
    // horizontally.
    final unmodifiedBar =
        renderingVertically ? barElements.first : barElements.last;

    // Find the max bar width from each segment to calculate corner radius.
    var maxBarWidth = 0;

    var measureIsNegative = false;

    for (var bar in barElements) {
      var bounds = bar.bounds;

      measureIsNegative = measureIsNegative || bar.measureIsNegative!;

      if (bar != unmodifiedBar) {
        bounds = renderingVertically
            ? Rectangle<int>(
                bar.bounds!.left,
                max(
                    0,
                    bar.bounds!.top +
                        (measureIsNegative ? _stackedBarPaddingPx : 0)),
                bar.bounds!.width,
                max(0, bar.bounds!.height - _stackedBarPaddingPx),
              )
            : Rectangle<int>(
                max(
                    0,
                    bar.bounds!.left +
                        (measureIsNegative ? _stackedBarPaddingPx : 0)),
                bar.bounds!.top,
                max(0, bar.bounds!.width - _stackedBarPaddingPx),
                bar.bounds!.height,
              );
      }

      bars.add(CanvasRect(bounds!,
          dashPattern: bar.dashPattern,
          fill: bar.fillColor,
          pattern: bar.fillPattern,
          stroke: bar.color,
          strokeWidthPx: bar.strokeWidthPx));

      maxBarWidth =
          max(maxBarWidth, renderingVertically ? bounds.width : bounds.height);
    }

    bool roundTopLeft;
    bool roundTopRight;
    bool roundBottomLeft;
    bool roundBottomRight;

    if (measureIsNegative) {
      // Negative bars should be rounded towards the negative axis direction.
      // In vertical mode, this is the bottom. In horizontal mode, this is the
      // left side of the chart for LTR, or the right side for RTL.
      roundTopLeft = !renderingVertically && !isRtl;
      roundTopRight = !renderingVertically && isRtl;
      roundBottomLeft = renderingVertically || !isRtl;
      roundBottomRight = renderingVertically || isRtl;
    } else {
      // Positive bars should be rounded towards the positive axis direction.
      // In vertical mode, this is the top. In horizontal mode, this is the
      // right side of the chart for LTR, or the left side for RTL.
      roundTopLeft = renderingVertically || isRtl;
      roundTopRight = !isRtl;
      roundBottomLeft = isRtl;
      roundBottomRight = !(renderingVertically || isRtl);
    }

    final barStack = CanvasBarStack(
      bars,
      radius: cornerStrategy.getRadius(maxBarWidth),
      stackedBarPadding: _stackedBarPaddingPx,
      roundTopLeft: roundTopLeft,
      roundTopRight: roundTopRight,
      roundBottomLeft: roundBottomLeft,
      roundBottomRight: roundBottomRight,
    );

    // If bar stack's range width is:
    // * Within the component bounds, then draw the bar stack.
    // * Partially out of component bounds, then clip the stack where it is out
    // of bounds.
    // * Fully out of component bounds, do not draw.

    final componentBounds = this.componentBounds!;
    final barOutsideBounds = renderingVertically
        ? barStack.fullStackRect.left < componentBounds.left ||
            barStack.fullStackRect.right > componentBounds.right
        : barStack.fullStackRect.top < componentBounds.top ||
            barStack.fullStackRect.bottom > componentBounds.bottom;

    // TODO: When we have initial viewport, add image test for
    // clipping.
    if (barOutsideBounds) {
      final clipBounds = _getBarStackBounds(barStack.fullStackRect);

      // Do not draw the bar stack if it is completely outside of the component
      // bounds.
      if (clipBounds.width <= 0 || clipBounds.height <= 0) {
        return;
      }

      canvas.setClipBounds(clipBounds);
    }

    canvas.drawBarStack(barStack, drawAreaBounds: componentBounds);

    if (barOutsideBounds) {
      canvas.resetClipBounds();
    }

    // Decorate the bar segments if there is a decorator.
    barRendererDecorator?.decorate(barElements, canvas, graphicsFactory!,
        drawBounds: drawBounds!,
        animationPercent: animationPercent,
        renderingVertically: renderingVertically,
        rtl: isRtl);
  }

  /// Calculate the clipping region for a rectangle that represents the full bar
  /// stack.
  Rectangle<int> _getBarStackBounds(Rectangle<int> barStackRect) {
    int left;
    int right;
    int top;
    int bottom;

    final componentBounds = this.componentBounds!;

    if (renderingVertically) {
      // Only clip at the start and end so that the bar's width stays within
      // the viewport, but any bar decorations above the bar can still show.
      left = max(componentBounds.left, barStackRect.left);
      right = min(componentBounds.right, barStackRect.right);
      top = barStackRect.top;
      bottom = barStackRect.bottom;
    } else {
      // Only clip at the top and bottom so that the bar's height stays within
      // the viewport, but any bar decorations to the right of the bar can still
      // show.
      left = barStackRect.left;
      right = barStackRect.right;
      top = max(componentBounds.top, barStackRect.top);
      bottom = min(componentBounds.bottom, barStackRect.bottom);
    }

    final width = right - left;
    final height = bottom - top;

    return Rectangle(left, top, width, height);
  }

  /// Generates a set of bounds that describe a bar.
  Rectangle<int> _getBarBounds(
      D? domainValue,
      ImmutableAxis<D> domainAxis,
      int domainWidth,
      int? maxBarWidthPx,
      num? measureValue,
      num measureOffsetValue,
      ImmutableAxis<num> measureAxis,
      int barGroupIndex,
      double? previousBarGroupWeight,
      double? barGroupWeight,
      List<double>? allBarGroupWeights,
      int numBarGroups) {
    // TODO: Investigate why this is negative for a DateTime domain
    // in RTL mode.
    domainWidth = domainWidth.abs();

    // If no weights were passed in, default to equal weight per bar.
    if (barGroupWeight == null) {
      barGroupWeight = 1 / numBarGroups;
      previousBarGroupWeight = barGroupIndex * barGroupWeight;
    }

    // Calculate how wide each bar should be within the group of bars. If we
    // only have one series, or are stacked, then barWidth should equal
    // domainWidth.
    final spacingLoss = _barGroupInnerPaddingPx * (numBarGroups - 1);
    var desiredWidth = ((domainWidth - spacingLoss) / numBarGroups).round();

    if (maxBarWidthPx != null) {
      desiredWidth = min(desiredWidth, maxBarWidthPx);
      domainWidth = desiredWidth * numBarGroups + spacingLoss;
    }

    // If the series was configured with a weight pattern, treat the "max" bar
    // width as the average max width. The overall total width will still equal
    // max times number of bars, but this results in a nicer final picture.
    var barWidth = desiredWidth;
    if (allBarGroupWeights != null) {
      barWidth =
          (desiredWidth * numBarGroups * allBarGroupWeights[barGroupIndex])
              .round();
    }

    // Make sure that bars are at least one pixel wide, so that they will always
    // be visible on the chart. Ideally we should do something clever with the
    // size of the chart, and the density and periodicity of the data, but this
    // at least ensures that dense charts still have visible data.
    barWidth = max(1, barWidth);

    // Flip bar group index for calculating location on the domain axis if RTL.
    final adjustedBarGroupIndex =
        isRtl ? numBarGroups - barGroupIndex - 1 : barGroupIndex;

    // Calculate the start and end of the bar, taking into account accumulated
    // padding for grouped bars.
    final previousAverageWidth = adjustedBarGroupIndex > 0
        ? ((domainWidth - spacingLoss) *
                (previousBarGroupWeight! / adjustedBarGroupIndex))
            .round()
        : 0;

    final domainStart = (domainAxis.getLocation(domainValue)! -
            (domainWidth / 2) +
            (previousAverageWidth + _barGroupInnerPaddingPx) *
                adjustedBarGroupIndex)
        .round();

    final domainEnd = domainStart + barWidth;

    measureValue ??= 0;

    // Calculate measure locations. Stacked bars should have their
    // offset calculated previously.
    int measureStart;
    int measureEnd;
    if (measureValue < 0) {
      measureEnd = measureAxis.getLocation(measureOffsetValue)!.round();
      measureStart =
          measureAxis.getLocation(measureValue + measureOffsetValue)!.round();
    } else {
      measureStart = measureAxis.getLocation(measureOffsetValue)!.round();
      measureEnd =
          measureAxis.getLocation(measureValue + measureOffsetValue)!.round();
    }

    Rectangle<int> bounds;
    if (renderingVertically) {
      // Rectangle clamps to zero width/height
      bounds = Rectangle<int>(domainStart, measureEnd, domainEnd - domainStart,
          measureStart - measureEnd);
    } else {
      // Rectangle clamps to zero width/height
      bounds = Rectangle<int>(min(measureStart, measureEnd), domainStart,
          (measureEnd - measureStart).abs(), domainEnd - domainStart);
    }
    return bounds;
  }

  @override
  Rectangle<int>? getBoundsForBar(BarRendererElement<D> bar) => bar.bounds;
}

abstract class ImmutableBarRendererElement<D> {
  ImmutableSeries<D>? get series;

  dynamic get datum;

  int? get index;

  Rectangle<int>? get bounds;
}

class BarRendererElement<D> extends BaseBarRendererElement
    implements ImmutableBarRendererElement<D> {
  @override
  ImmutableSeries<D>? series;

  @override
  Rectangle<int>? bounds;

  int? roundPx;

  @override
  int? index;

  dynamic _datum;

  @override
  dynamic get datum => _datum;

  set datum(dynamic datum) {
    _datum = datum;
    index = series?.data.indexOf(datum);
  }

  BarRendererElement();

  BarRendererElement.clone(BarRendererElement<D> other) : super.clone(other) {
    series = other.series;
    bounds = other.bounds;
    roundPx = other.roundPx;
    index = other.index;
    _datum = other._datum;
  }

  @override
  void updateAnimationPercent(BaseBarRendererElement previous,
      BaseBarRendererElement target, double animationPercent) {
    final localPrevious = previous as BarRendererElement<D>;
    final localTarget = target as BarRendererElement<D>;

    final previousBounds = localPrevious.bounds!;
    final targetBounds = localTarget.bounds!;

    var top = ((targetBounds.top - previousBounds.top) * animationPercent) +
        previousBounds.top;
    var right =
        ((targetBounds.right - previousBounds.right) * animationPercent) +
            previousBounds.right;
    var bottom =
        ((targetBounds.bottom - previousBounds.bottom) * animationPercent) +
            previousBounds.bottom;
    var left = ((targetBounds.left - previousBounds.left) * animationPercent) +
        previousBounds.left;

    bounds = Rectangle<int>(left.round(), top.round(), (right - left).round(),
        (bottom - top).round());

    roundPx = localTarget.roundPx;

    super.updateAnimationPercent(previous, target, animationPercent);
  }
}

class AnimatedBar<D> extends BaseAnimatedBar<D, BarRendererElement<D>> {
  AnimatedBar(
      {required String key,
      required dynamic datum,
      required ImmutableSeries<D> series,
      required D? domainValue})
      : super(key: key, datum: datum, series: series, domainValue: domainValue);

  @override
  void animateElementToMeasureAxisPosition(BaseBarRendererElement target) {
    final localTarget = target as BarRendererElement<D>;

    // TODO: Animate out bars in the middle of a stack.
    localTarget.bounds = Rectangle<int>(
        localTarget.bounds!.left + (localTarget.bounds!.width / 2).round(),
        localTarget.measureAxisPosition!.round(),
        0,
        0);
  }

  @override
  BarRendererElement<D> getCurrentBar(double animationPercent) {
    final bar = super.getCurrentBar(animationPercent);

    // Update with series and datum information to pass to bar decorator.
    bar.series = series;
    bar.datum = datum;

    return bar;
  }

  @override
  BarRendererElement<D> clone(BarRendererElement<D> bar) =>
      BarRendererElement<D>.clone(bar);
}

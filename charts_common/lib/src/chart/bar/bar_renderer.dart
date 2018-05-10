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
import 'package:meta/meta.dart' show required;

import 'bar_renderer_config.dart' show BarRendererConfig, CornerStrategy;
import 'bar_renderer_decorator.dart' show BarRendererDecorator;
import 'base_bar_renderer.dart' show BaseBarRenderer;
import 'base_bar_renderer_element.dart'
    show BaseAnimatedBar, BaseBarRendererElement;
import '../cartesian/axis/axis.dart' show ImmutableAxis;
import '../common/base_chart.dart' show BaseChart;
import '../common/canvas_shapes.dart' show CanvasBarStack, CanvasRect;
import '../common/chart_canvas.dart' show ChartCanvas, FillPatternType;
import '../common/processed_series.dart' show ImmutableSeries, MutableSeries;
import '../../common/color.dart' show Color;

/// Renders series data as a series of bars.
class BarRenderer<D>
    extends BaseBarRenderer<D, _BarRendererElement<D>, _AnimatedBar<D>> {
  /// If we are grouped, use this spacing between the bars in a group.
  final _barGroupInnerPadding = 2;

  /// The padding between bar stacks.
  ///
  /// The padding comes out of the bottom of the bar.
  final _stackedBarPadding = 1;

  BaseChart<D> _chart;

  final BarRendererDecorator barRendererDecorator;

  factory BarRenderer({BarRendererConfig config, String rendererId}) {
    rendererId ??= 'bar';
    config ??= new BarRendererConfig();
    return new BarRenderer._internal(config: config, rendererId: rendererId);
  }

  BarRenderer._internal({BarRendererConfig config, String rendererId})
      : barRendererDecorator = config.barRendererDecorator,
        super(config: config, rendererId: rendererId, layoutPositionOrder: 10);

  @override
  void configureSeries(List<MutableSeries<D>> seriesList) {
    assignMissingColors(getOrderedSeriesList(seriesList),
        emptyCategoryUsesSinglePalette: true);
  }

  @override
  _BarRendererElement<D> getBaseDetails(dynamic datum, int index) {
    return new _BarRendererElement<D>();
  }

  bool get rtl => _chart.context.rtl;

  CornerStrategy get cornerStrategy {
    return (config as BarRendererConfig).cornerStrategy;
  }

  /// Generates an [_AnimatedBar] to represent the previous and current state
  /// of one bar on the chart.
  @override
  _AnimatedBar<D> makeAnimatedBar(
      {String key,
      ImmutableSeries<D> series,
      List<int> dashPattern,
      dynamic datum,
      Color color,
      _BarRendererElement<D> details,
      D domainValue,
      ImmutableAxis<D> domainAxis,
      int domainWidth,
      num measureValue,
      num measureOffsetValue,
      ImmutableAxis<num> measureAxis,
      double measureAxisPosition,
      Color fillColor,
      FillPatternType fillPattern,
      double strokeWidthPx,
      int barGroupIndex,
      int numBarGroups}) {
    return new _AnimatedBar<D>(
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
          numBarGroups: numBarGroups));
  }

  /// Generates a [_BarRendererElement] to represent the rendering data for one
  /// bar on the chart.
  @override
  _BarRendererElement<D> makeBarRendererElement(
      {Color color,
      List<int> dashPattern,
      _BarRendererElement<D> details,
      D domainValue,
      ImmutableAxis<D> domainAxis,
      int domainWidth,
      num measureValue,
      num measureOffsetValue,
      ImmutableAxis<num> measureAxis,
      double measureAxisPosition,
      Color fillColor,
      FillPatternType fillPattern,
      double strokeWidthPx,
      int barGroupIndex,
      int numBarGroups}) {
    return new _BarRendererElement<D>()
      ..color = color
      ..dashPattern = dashPattern
      ..fillColor = fillColor
      ..fillPattern = fillPattern
      ..measureAxisPosition = measureAxisPosition
      ..roundPx = details.roundPx
      ..strokeWidthPx = strokeWidthPx
      ..bounds = _getBarBounds(
          domainValue,
          domainAxis,
          domainWidth,
          measureValue,
          measureOffsetValue,
          measureAxis,
          barGroupIndex,
          numBarGroups);
  }

  @override
  void onAttach(BaseChart<D> chart) {
    super.onAttach(chart);
    // We only need the chart.context.rtl setting, but context is not yet
    // available when the default renderer is attached to the chart on chart
    // creation time, since chart onInit is called after the chart is created.
    _chart = chart;
  }

  @override
  void paintBar(ChartCanvas canvas, double animationPercent,
      Iterable<_BarRendererElement<D>> barElements) {
    final bars = <CanvasRect>[];

    // When adjusting bars for stacked bar padding, do not modify the first bar
    // if rendering vertically and do not modify the last bar if rendering
    // horizontally.
    final unmodifiedBar =
        renderingVertically ? barElements.first : barElements.last;

    // Find the max bar width from each segement to calculate corner radius.
    int maxBarWidth = 0;

    for (var bar in barElements) {
      var bounds = bar.bounds;

      if (bar != unmodifiedBar) {
        bounds = renderingVertically
            ? new Rectangle<int>(
                bar.bounds.left,
                bar.bounds.top,
                bar.bounds.width,
                max(0, bar.bounds.height - _stackedBarPadding),
              )
            : new Rectangle<int>(
                bar.bounds.left,
                bar.bounds.top,
                max(0, bar.bounds.width - _stackedBarPadding),
                bar.bounds.height,
              );
      }

      bars.add(new CanvasRect(bounds,
          dashPattern: bar.dashPattern,
          fill: bar.fillColor,
          pattern: bar.fillPattern,
          stroke: bar.color,
          strokeWidthPx: bar.strokeWidthPx));

      maxBarWidth = max(
          maxBarWidth, (renderingVertically ? bounds.width : bounds.height));
    }

    final barStack = new CanvasBarStack(
      bars,
      radius: cornerStrategy.getRadius(maxBarWidth),
      stackedBarPadding: _stackedBarPadding,
      roundTopLeft: renderingVertically || rtl ? true : false,
      roundTopRight: rtl ? false : true,
      roundBottomLeft: rtl ? true : false,
      roundBottomRight: renderingVertically || rtl ? false : true,
    );

    // If bar stack's range width is:
    // * Within the component bounds, then draw the bar stack.
    // * Partially out of component bounds, then clip the stack where it is out
    // of bounds.
    // * Fully out of component bounds, do not draw.

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

    canvas.drawBarStack(barStack);

    if (barOutsideBounds) {
      canvas.resetClipBounds();
    }

    // Decorate the bar segments if there is a decorator.
    barRendererDecorator?.decorate(barElements, canvas, graphicsFactory,
        drawBounds: drawBounds,
        animationPercent: animationPercent,
        renderingVertically: renderingVertically,
        rtl: rtl);
  }

  /// Calculate the clipping region for a rectangle that represents the full bar
  /// stack.
  Rectangle<int> _getBarStackBounds(Rectangle<int> barStackRect) {
    int left;
    int right;
    int top;
    int bottom;

    if (renderingVertically) {
      // Only clip at the start and end so that the bar's width stays within
      // the viewport, but any bar decorations above the bar can still show.
      left = max(componentBounds.left, barStackRect.left);
      right = min(componentBounds.right, barStackRect.right);
      top = componentBounds.top;
      bottom = componentBounds.bottom;
    } else {
      // Only clip at the top and bottom so that the bar's height stays within
      // the viewport, but any bar decorations to the right of the bar can still
      // show.
      left = componentBounds.left;
      right = componentBounds.right;
      top = max(componentBounds.top, barStackRect.top);
      bottom = min(componentBounds.bottom, barStackRect.bottom);
    }

    final width = right - left;
    final height = bottom - top;

    return new Rectangle(left, top, width, height);
  }

  /// Generates a set of bounds that describe a bar.
  Rectangle<int> _getBarBounds(
      D domainValue,
      ImmutableAxis<D> domainAxis,
      int domainWidth,
      num measureValue,
      num measureOffsetValue,
      ImmutableAxis<num> measureAxis,
      int barGroupIndex,
      int numBarGroups) {
    // Calculate how wide each bar should be within the group of bars. If we
    // only have one series, or are stacked, then barWidth should equal
    // domainWidth.
    int spacingLoss = (_barGroupInnerPadding * (numBarGroups - 1));
    int barWidth = ((domainWidth - spacingLoss) / numBarGroups).round();

    // Flip bar group index for calculating location on the domain axis if RTL.
    final adjustedBarGroupIndex =
        rtl ? numBarGroups - barGroupIndex - 1 : barGroupIndex;

    // Calculate the start and end of the bar, taking into account accumulated
    // padding for grouped bars.
    int domainStart = (domainAxis.getLocation(domainValue) -
            (domainWidth / 2) +
            (barWidth + _barGroupInnerPadding) * adjustedBarGroupIndex)
        .round();

    int domainEnd = domainStart + barWidth;

    measureValue = measureValue != null ? measureValue : 0;

    // Calculate measure locations. Stacked bars should have their
    // offset calculated previously.
    int measureStart = measureAxis.getLocation(measureOffsetValue).round();
    int measureEnd =
        measureAxis.getLocation(measureValue + measureOffsetValue).round();

    var bounds;
    if (this.renderingVertically) {
      bounds = new Rectangle<int>(domainStart, measureEnd,
          domainEnd - domainStart, measureStart - measureEnd);
    } else {
      bounds = new Rectangle<int>(min(measureStart, measureEnd), domainStart,
          (measureEnd - measureStart).abs(), domainEnd - domainStart);
    }
    return bounds;
  }

  @override
  Rectangle<int> getBoundsForBar(_BarRendererElement bar) => bar.bounds;
}

abstract class ImmutableBarRendererElement<D> {
  ImmutableSeries<D> get series;
  dynamic get datum;
  int get index;
  Rectangle<int> get bounds;
}

class _BarRendererElement<D> extends BaseBarRendererElement
    implements ImmutableBarRendererElement<D> {
  ImmutableSeries<D> series;
  Rectangle<int> bounds;
  int roundPx;
  int index;
  dynamic _datum;

  dynamic get datum => _datum;

  set datum(dynamic datum) {
    _datum = datum;
    index = series.data.indexOf(datum);
  }

  _BarRendererElement();

  _BarRendererElement.clone(_BarRendererElement other) : super.clone(other) {
    series = other.series;
    bounds = other.bounds;
    roundPx = other.roundPx;
    index = other.index;
    _datum = other._datum;
  }

  @override
  void updateAnimationPercent(BaseBarRendererElement previous,
      BaseBarRendererElement target, double animationPercent) {
    final _BarRendererElement localPrevious = previous;
    final _BarRendererElement localTarget = target;

    final previousBounds = localPrevious.bounds;
    final targetBounds = localTarget.bounds;

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

    bounds = new Rectangle<int>(left.round(), top.round(),
        (right - left).round(), (bottom - top).round());

    roundPx = localTarget.roundPx;

    super.updateAnimationPercent(previous, target, animationPercent);
  }
}

class _AnimatedBar<D> extends BaseAnimatedBar<D, _BarRendererElement<D>> {
  _AnimatedBar(
      {@required String key,
      @required dynamic datum,
      @required ImmutableSeries<D> series,
      @required D domainValue})
      : super(key: key, datum: datum, series: series, domainValue: domainValue);

  @override
  animateElementToMeasureAxisPosition(BaseBarRendererElement target) {
    final _BarRendererElement localTarget = target;

    // TODO: Animate out bars in the middle of a stack.
    localTarget.bounds = new Rectangle<int>(
        localTarget.bounds.left + (localTarget.bounds.width / 2).round(),
        localTarget.measureAxisPosition.round(),
        0,
        0);
  }

  _BarRendererElement<D> getCurrentBar(double animationPercent) {
    final _BarRendererElement<D> bar = super.getCurrentBar(animationPercent);

    // Update with series and datum information to pass to bar decorator.
    bar.series = series;
    bar.datum = datum;

    return bar;
  }

  @override
  _BarRendererElement<D> clone(_BarRendererElement other) =>
      new _BarRendererElement<D>.clone(other);
}

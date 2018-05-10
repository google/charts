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

import 'dart:collection' show LinkedHashMap;
import 'dart:math' show Point, Rectangle, max;
import 'package:meta/meta.dart' show protected, required;

import 'base_bar_renderer_config.dart' show BaseBarRendererConfig;
import 'base_bar_renderer_element.dart'
    show BaseAnimatedBar, BaseBarRendererElement;
import '../cartesian/cartesian_renderer.dart' show BaseCartesianRenderer;
import '../cartesian/axis/axis.dart'
    show ImmutableAxis, domainAxisKey, measureAxisKey;
import '../common/chart_canvas.dart' show ChartCanvas, FillPatternType;
import '../common/datum_details.dart' show DatumDetails;
import '../common/processed_series.dart' show ImmutableSeries, MutableSeries;
import '../../common/color.dart' show Color;
import '../../common/symbol_renderer.dart' show RoundedRectSymbolRenderer;
import '../../data/series.dart' show AttributeKey;

const barGroupIndexKey = const AttributeKey<int>('BarRenderer.barGroupIndex');

const barGroupCountKey = const AttributeKey<int>('BarRenderer.barGroupCount');

const stackKeyKey = const AttributeKey<String>('BarRenderer.stackKey');

const barElementsKey =
    const AttributeKey<List<BaseBarRendererElement>>('BarRenderer.elements');

/// Base class for bar renderers that implements common stacking and grouping
/// logic.
///
/// Bar renderers support 4 different modes of rendering multiple series on the
/// chart, configured by the grouped and stacked flags.
/// * grouped - Render bars for each series that shares a domain value
///   side-by-side.
/// * stacked - Render bars for each series that shares a domain value in a
///   stack, ordered in the same order as the series list.
/// * grouped-stacked: Render bars for each series that shares a domain value in
///   a group of bar stacks. Each stack will contain all the series that share a
///   series category.
/// * floating style - When grouped and stacked are both false, all bars that
///   share a domain value will be rendered in the same domain space. Each datum
///   should be configured with a measure offset to position its bar along the
///   measure axis. Bars will freely overlap if their measure values and measure
///   offsets overlap. Note that bars for each series will be rendered in order,
///   such that bars from the last series will be "on top" of bars from previous
///   series.
abstract class BaseBarRenderer<D, R extends BaseBarRendererElement,
    B extends BaseAnimatedBar<D, R>> extends BaseCartesianRenderer<D> {
  final BaseBarRendererConfig config;

  /// Store a map of domain+barGroupIndex+category index to bars in a stack.
  ///
  /// This map is used to render all the bars in a stack together, to account
  /// for rendering effects that need to take the full stack into account (e.g.
  /// corner rounding).
  ///
  /// [LinkedHashMap] is used to render the bars on the canvas in the same order
  /// as the data was given to the chart. For the case where both grouping and
  /// stacking are disabled, this means that bars for data later in the series
  /// will be drawn "on top of" bars earlier in the series.
  final _barStackMap = new LinkedHashMap<String, List<B>>();

  // Store a list of bar stacks that exist in the series data.
  //
  // This list will be used to remove any AnimatingBars that were rendered in
  // previous draw cycles, but no longer have a corresponding datum in the new
  // data.
  final _currentKeys = <String>[];

  /// Stores a list of stack keys for each group key.
  final _currentGroupsStackKeys = new LinkedHashMap<D, Set<String>>();

  /// Optimization for getNearest to avoid scanning all data if possible.
  ImmutableAxis<D> _prevDomainAxis;

  BaseBarRenderer(
      {@required BaseBarRendererConfig config,
      String rendererId,
      int layoutPositionOrder})
      : this.config = config,
        super(
          rendererId: rendererId,
          layoutPositionOrder: layoutPositionOrder,
          symbolRenderer:
              config?.symbolRenderer ?? new RoundedRectSymbolRenderer(),
        );

  @override
  void preprocessSeries(List<MutableSeries<D>> seriesList) {
    var barGroupIndex = 0;

    // Maps used to store the final measure offset of the previous series, for
    // each domain value.
    final posDomainToStackKeyToDetailsMap = {};
    final negDomainToStackKeyToDetailsMap = {};
    final categoryToIndexMap = {};

    // Keep track of the largest bar stack size. This should be 1 for grouped
    // bars, and it should be the size of the tallest stack for stacked or
    // grouped stacked bars.
    var maxBarStackSize = 0;

    final orderedSeriesList = getOrderedSeriesList(seriesList);

    orderedSeriesList.forEach((MutableSeries<D> series) {
      var elements = <BaseBarRendererElement>[];

      var domainFn = series.domainFn;
      var measureFn = series.measureFn;
      var measureOffsetFn = series.measureOffsetFn;
      var fillPatternFn = series.fillPatternFn;
      var strokeWidthPxFn = series.strokeWidthPxFn;

      series.dashPattern ??= config.dashPattern;

      // Identifies which stack the series will go in, by default a single
      // stack.
      var stackKey = '__defaultKey__';

      // Override the stackKey with seriesCategory if we are GROUPED_STACKED
      // so we have a way to choose which series go into which stacks.
      if (config.grouped && config.stacked) {
        if (series.seriesCategory != null) {
          stackKey = series.seriesCategory;
        }

        barGroupIndex = categoryToIndexMap[stackKey];
        if (barGroupIndex == null) {
          barGroupIndex = categoryToIndexMap.length;
          categoryToIndexMap[stackKey] = barGroupIndex;
        }
      }

      var needsMeasureOffset = false;

      for (var barIndex = 0; barIndex < series.data.length; barIndex++) {
        dynamic datum = series.data[barIndex];
        final details = getBaseDetails(datum, barIndex);

        details.barStackIndex = 0;
        details.measureOffset = 0;

        if (fillPatternFn != null) {
          details.fillPattern = fillPatternFn(barIndex);
        } else {
          details.fillPattern = config.fillPattern;
        }

        if (strokeWidthPxFn != null) {
          details.strokeWidthPx = strokeWidthPxFn(barIndex).toDouble();
        } else {
          details.strokeWidthPx = config.strokeWidthPx;
        }

        // When stacking is enabled, adjust the measure offset for each domain
        // value in each series by adding up the measures and offsets of lower
        // series.
        if (config.stacked) {
          needsMeasureOffset = true;
          var domain = domainFn(barIndex);
          var measure = measureFn(barIndex);

          // We will render positive bars in one stack, and negative bars in a
          // separate stack. Keep track of the measure offsets for these stacks
          // independently.
          var domainToCategoryToDetailsMap = measure == null || measure >= 0
              ? posDomainToStackKeyToDetailsMap
              : negDomainToStackKeyToDetailsMap;

          var categoryToDetailsMap =
              domainToCategoryToDetailsMap.putIfAbsent(domain, () => {});

          var prevDetail = categoryToDetailsMap[stackKey];

          if (prevDetail != null) {
            details.barStackIndex = prevDetail.barStackIndex + 1;
          }

          details.cumulativeTotal = measure != null ? measure : 0;

          // Get the previous series' measure offset.
          var measureOffset = measureOffsetFn(barIndex);
          if (prevDetail != null) {
            measureOffset += prevDetail.measureOffsetPlusMeasure;

            details.cumulativeTotal += prevDetail.cumulativeTotal;
          }

          // And overwrite the details measure offset.
          details.measureOffset = measureOffset;
          var measureValue = (measure != null ? measure : 0);
          details.measureOffsetPlusMeasure = measureOffset + measureValue;

          categoryToDetailsMap[stackKey] = details;
        }

        maxBarStackSize = max(maxBarStackSize, details.barStackIndex + 1);

        elements.add(details);
      }

      if (needsMeasureOffset) {
        // Override the measure offset function to return the measure offset we
        // calculated for each datum. This already includes any measure offset
        // that was configured in the series data.
        series.measureOffsetFn = (index) => elements[index].measureOffset;
      }

      series.setAttr(barGroupIndexKey, barGroupIndex);
      series.setAttr(stackKeyKey, stackKey);
      series.setAttr(barElementsKey, elements);

      if (config.grouped) {
        barGroupIndex++;
      }
    });

    // Compute number of bar groups.
    var numBarGroups = 0;
    if (config.grouped && config.stacked) {
      // For grouped stacked bars, categoryToIndexMap effectively one list per
      // group of stacked bars.
      numBarGroups = categoryToIndexMap.length;
    } else if (config.stacked) {
      numBarGroups = 1;
    } else {
      numBarGroups = seriesList.length;
    }

    seriesList.forEach((MutableSeries<D> series) {
      series.setAttr(barGroupCountKey, numBarGroups);
    });
  }

  /// Construct a base details element for a given datum.
  ///
  /// This is intended to be overridden by child classes that need to add
  /// customized rendering properties.
  R getBaseDetails(dynamic datum, int index);

  @override
  void configureDomainAxes(List<MutableSeries<D>> seriesList) {
    super.configureDomainAxes(seriesList);

    // TODO: tell axis that we some rangeBand configuration.
  }

  void update(List<ImmutableSeries<D>> seriesList, bool isAnimatingThisDraw) {
    var numBarGroups = config.stacked ? 1 : seriesList.length;

    _currentKeys.clear();
    _currentGroupsStackKeys.clear();

    final orderedSeriesList = getOrderedSeriesList(seriesList);

    orderedSeriesList.forEach((final ImmutableSeries<D> series) {
      var domainAxis = series.getAttr(domainAxisKey) as ImmutableAxis<D>;
      var domainFn = series.domainFn;
      var measureAxis = series.getAttr(measureAxisKey) as ImmutableAxis<num>;
      var measureFn = series.measureFn;
      var colorFn = series.colorFn;
      var dashPattern = series.dashPattern;
      var fillColorFn = series.fillColorFn;
      var seriesStackKey = series.getAttr(stackKeyKey);
      var barGroupIndex = series.getAttr(barGroupIndexKey);
      var measureAxisPosition = measureAxis.getLocation(0.0);

      var elementsList = series.getAttr(barElementsKey);

      // Save off domainAxis for getNearest.
      _prevDomainAxis = domainAxis;

      for (var barIndex = 0; barIndex < series.data.length; barIndex++) {
        final datum = series.data[barIndex];
        BaseBarRendererElement details = elementsList[barIndex];
        D domainValue = domainFn(barIndex);

        // Each bar should be stored in barStackMap in a structure that mirrors
        // the visual rendering of the bars. Thus, they should be grouped by
        // domain value, series category (by way of the stack keys that were
        // generated for each series in the preprocess step), and bar group
        // index to account for all combinations of grouping and stacking.
        var barStackMapKey = domainValue.toString() +
            '__' +
            seriesStackKey +
            '__' +
            barGroupIndex.toString();

        var barKey = barStackMapKey + details.barStackIndex.toString();

        var barStackList = _barStackMap.putIfAbsent(barStackMapKey, () => []);

        // If we already have a AnimatingBar for that index, use it.
        var animatingBar = barStackList.firstWhere((B bar) => bar.key == barKey,
            orElse: () => null);

        // If we don't have any existing bar element, create a new bar and have
        // it animate in from the domain axis.
        // TODO: Animate bars in the middle of a stack from their
        // nearest neighbors, instead of the measure axis.
        if (animatingBar == null) {
          animatingBar = makeAnimatedBar(
              key: barKey,
              series: series,
              datum: datum,
              barGroupIndex: barGroupIndex,
              color: colorFn(barIndex),
              dashPattern: dashPattern,
              details: details,
              domainValue: domainFn(barIndex),
              domainAxis: domainAxis,
              domainWidth: domainAxis.rangeBand.round(),
              fillColor: fillColorFn(barIndex),
              fillPattern: details.fillPattern,
              measureValue: 0.0,
              measureOffsetValue: 0.0,
              measureAxisPosition: measureAxisPosition,
              measureAxis: measureAxis,
              numBarGroups: numBarGroups,
              strokeWidthPx: details.strokeWidthPx);

          barStackList.add(animatingBar);
        } else {
          animatingBar
            ..datum = datum
            ..series = series
            ..domainValue = domainValue;
        }

        // Update the set of bars that still exist in the series data.
        _currentKeys.add(barKey);

        // Store off stack keys for each bar group to help getNearest identify
        // groups of stacks.
        _currentGroupsStackKeys
            .putIfAbsent(domainValue, () => new Set<String>())
            .add(barStackMapKey);

        // Get the barElement we are going to setup.
        // Optimization to prevent allocation in non-animating case.
        BaseBarRendererElement barElement = makeBarRendererElement(
            barGroupIndex: series.getAttr(barGroupIndexKey),
            color: colorFn(barIndex),
            dashPattern: dashPattern,
            details: details,
            domainValue: domainFn(barIndex),
            domainAxis: domainAxis,
            domainWidth: domainAxis.rangeBand.round(),
            fillColor: fillColorFn(barIndex),
            fillPattern: details.fillPattern,
            measureValue: measureFn(barIndex),
            measureOffsetValue: details.measureOffset,
            measureAxisPosition: measureAxisPosition,
            measureAxis: measureAxis,
            numBarGroups: series.getAttr(barGroupCountKey),
            strokeWidthPx: details.strokeWidthPx);

        animatingBar.setNewTarget(barElement);
      }

      if (config.grouped) {
        barGroupIndex++;
      }
    });

    // Animate out bars that don't exist anymore.
    _barStackMap.forEach((String key, List<B> barStackList) {
      for (var barIndex = 0; barIndex < barStackList.length; barIndex++) {
        var bar = barStackList[barIndex];

        if (_currentKeys.contains(bar.key) != true) {
          bar.animateOut();
        }
      }
    });
  }

  /// Generates a [BaseAnimatedBar] to represent the previous and current state
  /// of one bar on the chart.
  B makeAnimatedBar(
      {String key,
      ImmutableSeries<D> series,
      dynamic datum,
      int barGroupIndex,
      Color color,
      List<int> dashPattern,
      R details,
      D domainValue,
      ImmutableAxis<D> domainAxis,
      int domainWidth,
      num measureValue,
      num measureOffsetValue,
      ImmutableAxis<num> measureAxis,
      double measureAxisPosition,
      int numBarGroups,
      Color fillColor,
      FillPatternType fillPattern,
      double strokeWidthPx});

  /// Generates a [BaseBarRendererElement] to represent the rendering data for
  /// one bar on the chart.
  R makeBarRendererElement(
      {int barGroupIndex,
      Color color,
      List<int> dashPattern,
      R details,
      D domainValue,
      ImmutableAxis<D> domainAxis,
      int domainWidth,
      num measureValue,
      num measureOffsetValue,
      ImmutableAxis<num> measureAxis,
      double measureAxisPosition,
      int numBarGroups,
      Color fillColor,
      FillPatternType fillPattern,
      double strokeWidthPx});

  /// Paints the current bar data on the canvas.
  void paint(ChartCanvas canvas, double animationPercent) {
    // Clean up the bars that no longer exist.
    if (animationPercent == 1.0) {
      final keysToRemove = <String>[];

      _barStackMap.forEach((String key, List<B> barStackList) {
        barStackList.retainWhere((B bar) => !bar.animatingOut);

        if (barStackList.isEmpty) {
          keysToRemove.add(key);
        }
      });

      keysToRemove.forEach((String key) => _barStackMap.remove(key));
    }

    _barStackMap.forEach((String stackKey, List<B> barStack) {
      // Turn this into a list so that the getCurrentBar isn't called more than
      // once for each animationPercent if the barElements are iterated more
      // than once.
      final barElements = barStack
          .map((B animatingBar) => animatingBar.getCurrentBar(animationPercent))
          .toList();

      paintBar(canvas, animationPercent, barElements);
    });
  }

  /// Paints a stack of bar elements on the canvas.
  void paintBar(
      ChartCanvas canvas, double animationPercent, Iterable<R> barElements);

  @override
  List<DatumDetails<D>> getNearestDatumDetailPerSeries(
      Point<double> chartPoint) {
    // Was it even in the drawArea?
    if (!componentBounds.containsPoint(chartPoint)) {
      return <DatumDetails<D>>[];
    }

    final domainValue = _prevDomainAxis
        .getDomain(renderingVertically ? chartPoint.x : chartPoint.y);

    List<DatumDetails<D>> nearest;

    // If we have a domainValue for the event point, then find all segments
    // that match it.
    if (domainValue != null) {
      if (renderingVertically) {
        nearest = _getVerticalDetailsForDomainValue(domainValue, chartPoint);
      } else {
        nearest = _getHorizontalDetailsForDomainValue(domainValue, chartPoint);
      }
    }

    // If we didn't find anything, then keep an empty list.
    nearest ??= <DatumDetails<D>>[];

    // Note: the details are already sorted by domain & measure distance in
    // base chart.

    return nearest;
  }

  Rectangle<int> getBoundsForBar(R bar);

  @protected
  List<BaseAnimatedBar<D, R>> _getSegmentsForDomainValue(D domainValue,
      {bool where(BaseAnimatedBar<D, R> bar)}) {
    final matchingSegments = <BaseAnimatedBar<D, R>>[];

    final stackKeys = _currentGroupsStackKeys[domainValue];
    stackKeys?.forEach((String stackKey) {
      if (where != null) {
        matchingSegments.addAll(_barStackMap[stackKey].where(where));
      } else {
        matchingSegments.addAll(_barStackMap[stackKey]);
      }
    });

    return matchingSegments;
  }

  List<DatumDetails<D>> _getVerticalDetailsForDomainValue(
      D domainValue, Point<double> chartPoint) {
    return new List<DatumDetails<D>>.from(_getSegmentsForDomainValue(
            domainValue,
            where: (BaseAnimatedBar<D, R> bar) => !bar.series.overlaySeries)
        .map<DatumDetails<D>>((BaseAnimatedBar<D, R> bar) {
      final barBounds = getBoundsForBar(bar.currentBar);
      final segmentDomainDistance =
          _getDistance(chartPoint.x.round(), barBounds.left, barBounds.right);
      final segmentMeasureDistance =
          _getDistance(chartPoint.y.round(), barBounds.top, barBounds.bottom);

      return new DatumDetails<D>(
        series: bar.series,
        datum: bar.datum,
        domain: bar.domainValue,
        domainDistance: segmentDomainDistance,
        measureDistance: segmentMeasureDistance,
      );
    }));
  }

  List<DatumDetails<D>> _getHorizontalDetailsForDomainValue(
      D domainValue, Point<double> chartPoint) {
    return new List<DatumDetails<D>>.from(_getSegmentsForDomainValue(
            domainValue,
            where: (BaseAnimatedBar<D, R> bar) => !bar.series.overlaySeries)
        .map((BaseAnimatedBar<D, R> bar) {
      final barBounds = getBoundsForBar(bar.currentBar);
      final segmentDomainDistance =
          _getDistance(chartPoint.y.round(), barBounds.top, barBounds.bottom);
      final segmentMeasureDistance =
          _getDistance(chartPoint.x.round(), barBounds.left, barBounds.right);

      return new DatumDetails<D>(
        series: bar.series,
        datum: bar.datum,
        domain: bar.domainValue,
        domainDistance: segmentDomainDistance,
        measureDistance: segmentMeasureDistance,
      );
    }));
  }

  double _getDistance(int point, int min, int max) {
    if (max >= point && min <= point) {
      return 0.0;
    }
    return (point > max ? (point - max) : (min - point)).toDouble();
  }

  /// Gets the iterator for the series based grouped/stacked and orientation.
  ///
  /// For vertical stacked bars:
  /// * If grouped, return the iterator that keeps the category order but
  /// reverse the order of the series so the first series is on the top of the
  /// stack.
  /// * Otherwise, return iterator of the reversed list
  ///
  /// All other types, use the in order iterator.
  @protected
  Iterable<S> getOrderedSeriesList<S extends ImmutableSeries>(
      List<S> seriesList) {
    return (renderingVertically && config.stacked)
        ? config.grouped
            ? new _ReversedSeriesIterable(seriesList)
            : seriesList.reversed
        : seriesList;
  }
}

/// Iterable wrapping the seriesList that returns the ReversedSeriesItertor.
class _ReversedSeriesIterable<S extends ImmutableSeries> extends Iterable<S> {
  final List<S> seriesList;

  _ReversedSeriesIterable(this.seriesList);

  @override
  Iterator<S> get iterator => new _ReversedSeriesIterator(seriesList);
}

/// Iterator that keeps reverse series order but keeps category order.
///
/// This is needed because for grouped stacked bars, the category stays in the
/// order it was passed in for the grouping, but the series is flipped so that
/// the first series of that category is on the top of the stack.
class _ReversedSeriesIterator<S extends ImmutableSeries> extends Iterator<S> {
  final List<S> _list;
  final _visitIndex = <int>[];
  int _current;

  _ReversedSeriesIterator(List<S> list) : _list = list {
    // In the order of the list, save the category and the indices of the series
    // with the same category.
    final categoryAndSeriesIndexMap = <String, List<int>>{};
    for (var i = 0; i < list.length; i++) {
      categoryAndSeriesIndexMap
          .putIfAbsent(list[i].seriesCategory, () => <int>[])
          .add(i);
    }

    // Creates a visit that is categories in order, but the series is reversed.
    categoryAndSeriesIndexMap
        .forEach((_, indices) => _visitIndex.addAll(indices.reversed));
  }
  @override
  bool moveNext() {
    _current = (_current == null) ? 0 : _current + 1;

    return _current < _list.length;
  }

  @override
  S get current => _list[_visitIndex[_current]];
}

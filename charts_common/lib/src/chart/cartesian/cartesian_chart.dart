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
import 'dart:math' show Point;
import 'package:meta/meta.dart' show protected;

import 'axis/axis.dart'
    show
        Axis,
        AxisOrientation,
        OrdinalAxis,
        NumericAxis,
        domainAxisKey,
        measureAxisIdKey,
        measureAxisKey;
import 'axis/spec/axis_spec.dart' show AxisSpec;
import 'axis/draw_strategy/none_draw_strategy.dart' show NoneDrawStrategy;
import 'axis/draw_strategy/small_tick_draw_strategy.dart'
    show SmallTickRendererSpec;
import 'axis/draw_strategy/gridline_draw_strategy.dart'
    show GridlineRendererSpec;
import '../bar/bar_renderer.dart' show BarRenderer;
import '../common/base_chart.dart' show BaseChart;
import '../common/chart_context.dart' show ChartContext;
import '../common/datum_details.dart' show DatumDetails;
import '../common/processed_series.dart' show MutableSeries;
import '../common/series_renderer.dart' show SeriesRenderer;
import '../common/selection_model/selection_model.dart' show SelectionModelType;
import '../layout/layout_config.dart' show LayoutConfig, MarginSpec;
import '../layout/layout_view.dart' show LayoutViewPaintOrder;
import '../../common/graphics_factory.dart' show GraphicsFactory;
import '../../common/rtl_spec.dart' show AxisPosition;
import '../../data/series.dart' show Series;

class NumericCartesianChart extends CartesianChart<num> {
  final NumericAxis _domainAxis;

  NumericCartesianChart(
      {bool vertical,
      LayoutConfig layoutConfig,
      NumericAxis primaryMeasureAxis,
      NumericAxis secondaryMeasureAxis,
      LinkedHashMap<String, NumericAxis> disjointMeasureAxes})
      : _domainAxis = new NumericAxis()
          ..layoutPaintOrder = LayoutViewPaintOrder.domainAxis,
        super(
            vertical: vertical,
            layoutConfig: layoutConfig,
            primaryMeasureAxis: primaryMeasureAxis,
            secondaryMeasureAxis: secondaryMeasureAxis,
            disjointMeasureAxes: disjointMeasureAxes);

  void init(ChartContext context, GraphicsFactory graphicsFactory) {
    super.init(context, graphicsFactory);
    _domainAxis.context = context;
    initDomainAxis(context, graphicsFactory);
    addView(_domainAxis);
  }

  @protected
  void initDomainAxis(ChartContext context, GraphicsFactory graphicsFactory) {
    _domainAxis.tickDrawStrategy = new SmallTickRendererSpec<num>()
        .createDrawStrategy(context, graphicsFactory);
  }

  @override
  Axis get domainAxis => _domainAxis;
}

class OrdinalCartesianChart extends CartesianChart<String> {
  final OrdinalAxis _domainAxis;

  OrdinalCartesianChart(
      {bool vertical,
      LayoutConfig layoutConfig,
      NumericAxis primaryMeasureAxis,
      NumericAxis secondaryMeasureAxis,
      LinkedHashMap<String, NumericAxis> disjointMeasureAxes})
      : _domainAxis = new OrdinalAxis()
          ..layoutPaintOrder = LayoutViewPaintOrder.domainAxis,
        super(
            vertical: vertical,
            layoutConfig: layoutConfig,
            primaryMeasureAxis: primaryMeasureAxis,
            secondaryMeasureAxis: secondaryMeasureAxis,
            disjointMeasureAxes: disjointMeasureAxes);

  void init(ChartContext context, GraphicsFactory graphicsFactory) {
    super.init(context, graphicsFactory);
    _domainAxis.context = context;
    _domainAxis.tickDrawStrategy = new SmallTickRendererSpec<String>()
        .createDrawStrategy(context, graphicsFactory);
    addView(_domainAxis);
  }

  @override
  Axis get domainAxis => _domainAxis;
}

abstract class CartesianChart<D> extends BaseChart<D> {
  static final _defaultLayoutConfig = new LayoutConfig(
    topSpec: new MarginSpec.fromPixel(minPixel: 20),
    bottomSpec: new MarginSpec.fromPixel(minPixel: 20),
    leftSpec: new MarginSpec.fromPixel(minPixel: 20),
    rightSpec: new MarginSpec.fromPixel(minPixel: 20),
  );

  bool vertical;

  final Axis<num> _primaryMeasureAxis;

  final Axis<num> _secondaryMeasureAxis;

  final LinkedHashMap<String, NumericAxis> _disjointMeasureAxes;

  /// If set to true, the vertical axis will render the opposite of the default
  /// direction.
  bool flipVerticalAxisOutput = false;

  bool _usePrimaryMeasureAxis = false;
  bool _useSecondaryMeasureAxis = false;

  CartesianChart(
      {bool vertical,
      LayoutConfig layoutConfig,
      NumericAxis primaryMeasureAxis,
      NumericAxis secondaryMeasureAxis,
      LinkedHashMap<String, NumericAxis> disjointMeasureAxes})
      : vertical = vertical ?? true,
        _primaryMeasureAxis = primaryMeasureAxis ?? new NumericAxis(),
        _secondaryMeasureAxis = secondaryMeasureAxis ?? new NumericAxis(),
        _disjointMeasureAxes =
            disjointMeasureAxes ?? new LinkedHashMap<String, NumericAxis>(),
        super(layoutConfig: layoutConfig ?? _defaultLayoutConfig) {
    // As a convenience for chart configuration, set the paint order on any axis
    // that is missing one.
    _primaryMeasureAxis.layoutPaintOrder ??= LayoutViewPaintOrder.measureAxis;
    _secondaryMeasureAxis.layoutPaintOrder ??= LayoutViewPaintOrder.measureAxis;

    _disjointMeasureAxes.forEach((String axisId, NumericAxis axis) {
      axis.layoutPaintOrder ??= LayoutViewPaintOrder.measureAxis;
    });
  }

  void init(ChartContext context, GraphicsFactory graphicsFactory) {
    super.init(context, graphicsFactory);

    _primaryMeasureAxis.context = context;
    _primaryMeasureAxis.tickDrawStrategy = new GridlineRendererSpec<num>()
        .createDrawStrategy(context, graphicsFactory);

    _secondaryMeasureAxis.context = context;
    _secondaryMeasureAxis.tickDrawStrategy = new GridlineRendererSpec<num>()
        .createDrawStrategy(context, graphicsFactory);

    _disjointMeasureAxes.forEach((String axisId, NumericAxis axis) {
      axis.context = context;
      axis.tickDrawStrategy =
          new NoneDrawStrategy<num>(context, graphicsFactory);
    });
  }

  Axis get domainAxis;

  set domainAxisSpec(AxisSpec axisSpec) =>
      axisSpec.configure(domainAxis, context, graphicsFactory);

  /// Gets the measure axis matching the provided id.
  ///
  /// If none is provided, this returns the primary measure axis.
  Axis getMeasureAxis({String axisId}) {
    Axis axis;
    if (axisId == Axis.secondaryMeasureAxisId) {
      axis = _secondaryMeasureAxis;
    } else if (axisId == Axis.primaryMeasureAxisId) {
      axis = _primaryMeasureAxis;
    } else if (_disjointMeasureAxes[axisId] != null) {
      axis = _disjointMeasureAxes[axisId];
    }

    // If no valid axisId was provided, fall back to primary axis.
    if (axis == null) {
      axis = _primaryMeasureAxis;
    }

    return axis;
  }

  /// Sets the primary measure axis for the chart, rendered on the start side of
  /// the domain axis.
  set primaryMeasureAxisSpec(AxisSpec axisSpec) {
    axisSpec.configure(_primaryMeasureAxis, context, graphicsFactory);
  }

  /// Sets the secondary measure axis for the chart, rendered on the end side of
  /// the domain axis.
  set secondaryMeasureAxisSpec(AxisSpec axisSpec) {
    axisSpec.configure(_secondaryMeasureAxis, context, graphicsFactory);
  }

  /// Sets a map of disjoint measure axes for the chart.
  ///
  /// Disjoint measure axes can be used to scale a sub-set of series on the
  /// chart independently from the primary and secondary axes. The general use
  /// case for this type of chart is to show differences in the trends of the
  /// data, without comparing their absolute values.
  ///
  /// Disjoint axes will not render any tick or gridline elements. With
  /// independent scales, there would be a lot of collision in labels were they
  /// to do so.
  ///
  /// If any series is rendered with a disjoint axis, it is highly recommended
  /// to render all series with disjoint axes. Otherwise, the chart may be
  /// visually misleading.
  ///
  /// A [LinkedHashMap] is used to ensure consistent ordering when painting the
  /// axes.
  set disjointMeasureAxisSpecs(LinkedHashMap<String, AxisSpec> axisSpecs) {
    axisSpecs.forEach((String axisId, AxisSpec axisSpec) {
      axisSpec.configure(
          _disjointMeasureAxes[axisId], context, graphicsFactory);
    });
  }

  @override
  MutableSeries<D> makeSeries(Series<dynamic, D> series) {
    MutableSeries<D> s = super.makeSeries(series);

    s.measureOffsetFn ??= (_) => 0;

    // Setup the Axes
    s.setAttr(domainAxisKey, domainAxis);
    s.setAttr(measureAxisKey,
        getMeasureAxis(axisId: series.getAttribute(measureAxisIdKey)));

    return s;
  }

  @override
  SeriesRenderer<D> makeDefaultRenderer() {
    return new BarRenderer()..rendererId = SeriesRenderer.defaultRendererId;
  }

  @override
  Map<String, List<MutableSeries<D>>> preprocessSeries(
      List<MutableSeries<D>> seriesList) {
    var rendererToSeriesList = super.preprocessSeries(seriesList);

    // Check if primary or secondary measure axis is being used.
    for (final series in seriesList) {
      final measureAxisId = series.getAttr(measureAxisIdKey);
      _usePrimaryMeasureAxis = _usePrimaryMeasureAxis ||
          (measureAxisId == null || measureAxisId == Axis.primaryMeasureAxisId);
      _useSecondaryMeasureAxis = _useSecondaryMeasureAxis ||
          (measureAxisId == Axis.secondaryMeasureAxisId);
    }

    // Add or remove the primary axis view.
    if (_usePrimaryMeasureAxis) {
      addView(_primaryMeasureAxis);
    } else {
      removeView(_primaryMeasureAxis);
    }

    // Add or remove the secondary axis view.
    if (_useSecondaryMeasureAxis) {
      addView(_secondaryMeasureAxis);
    } else {
      removeView(_secondaryMeasureAxis);
    }

    // Add all disjoint axis views so that their range will be configured.
    _disjointMeasureAxes.forEach((String axisId, NumericAxis axis) {
      addView(axis);
    });

    // Reset stale values from previous draw cycles.
    domainAxis.resetDomains();
    _primaryMeasureAxis.resetDomains();
    _secondaryMeasureAxis.resetDomains();

    _disjointMeasureAxes.forEach((String axisId, NumericAxis axis) {
      axis.resetDomains();
    });

    final reverseAxisPosition = context != null &&
        context.rtl &&
        context.rtlSpec.axisPosition == AxisPosition.reversed;

    if (vertical) {
      domainAxis
        ..axisOrientation = AxisOrientation.bottom
        ..reverseOutputRange = reverseAxisPosition;

      _primaryMeasureAxis
        ..axisOrientation =
            (reverseAxisPosition ? AxisOrientation.right : AxisOrientation.left)
        ..reverseOutputRange = flipVerticalAxisOutput;

      _secondaryMeasureAxis
        ..axisOrientation =
            (reverseAxisPosition ? AxisOrientation.left : AxisOrientation.right)
        ..reverseOutputRange = flipVerticalAxisOutput;

      _disjointMeasureAxes.forEach((String axisId, NumericAxis axis) {
        axis
          ..axisOrientation = (reverseAxisPosition
              ? AxisOrientation.left
              : AxisOrientation.right)
          ..reverseOutputRange = flipVerticalAxisOutput;
      });
    } else {
      domainAxis
        ..axisOrientation =
            (reverseAxisPosition ? AxisOrientation.right : AxisOrientation.left)
        ..reverseOutputRange = flipVerticalAxisOutput;

      _primaryMeasureAxis
        ..axisOrientation = AxisOrientation.bottom
        ..reverseOutputRange = reverseAxisPosition;

      _secondaryMeasureAxis
        ..axisOrientation = AxisOrientation.top
        ..reverseOutputRange = reverseAxisPosition;

      _disjointMeasureAxes.forEach((String axisId, NumericAxis axis) {
        axis
          ..axisOrientation = AxisOrientation.top
          ..reverseOutputRange = reverseAxisPosition;
      });
    }

    // Have each renderer configure the axes with their domain and measure
    // values.
    rendererToSeriesList
        .forEach((String rendererId, List<MutableSeries<D>> seriesList) {
      getSeriesRenderer(rendererId).configureDomainAxes(seriesList);
      getSeriesRenderer(rendererId).configureMeasureAxes(seriesList);
    });

    return rendererToSeriesList;
  }

  @override
  void onSkipLayout() {
    // Update ticks only when skipping layout.
    domainAxis.updateTicks();

    if (_usePrimaryMeasureAxis) {
      _primaryMeasureAxis.updateTicks();
    }

    if (_useSecondaryMeasureAxis) {
      _secondaryMeasureAxis.updateTicks();
    }

    _disjointMeasureAxes.forEach((String axisId, NumericAxis axis) {
      axis.updateTicks();
    });

    super.onSkipLayout();
  }

  @override
  void onPostLayout(Map<String, List<MutableSeries<D>>> rendererToSeriesList) {
    fireOnAxisConfigured();

    super.onPostLayout(rendererToSeriesList);
  }

  /// Returns a list of datum details from selection model of [type].
  @override
  List<DatumDetails<D>> getDatumDetails(SelectionModelType type) {
    final entries = <DatumDetails<D>>[];

    getSelectionModel(type).selectedDatum.forEach((seriesDatum) {
      final series = seriesDatum.series;
      final datum = seriesDatum.datum;
      final datumIndex = seriesDatum.index;

      final domain = series.domainFn(datumIndex);
      final measure = series.measureFn(datumIndex);
      final rawMeasure = series.rawMeasureFn(datumIndex);
      final color = series.colorFn(datumIndex);

      final chartPosition = new Point<double>(
          series.getAttr(domainAxisKey).getLocation(domain),
          series.getAttr(measureAxisKey).getLocation(measure));

      entries.add(new DatumDetails(
          datum: datum,
          domain: domain,
          measure: measure,
          rawMeasure: rawMeasure,
          series: series,
          color: color,
          chartPosition: chartPosition));
    });

    return entries;
  }
}

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
import '../../common/graphics_factory.dart' show GraphicsFactory;
import '../../common/rtl_spec.dart' show AxisPosition;
import '../../data/series.dart' show Series;

class NumericCartesianChart<T> extends CartesianChart<T, num> {
  final NumericAxis _domainAxis;

  NumericCartesianChart({bool vertical, LayoutConfig layoutConfig})
      : _domainAxis = new NumericAxis(),
        super(vertical: vertical, layoutConfig: layoutConfig);

  void init(ChartContext context, GraphicsFactory graphicsFactory) {
    super.init(context, graphicsFactory);
    _domainAxis.context = context;
    _domainAxis.tickDrawStrategy = new SmallTickRendererSpec<num>()
        .createDrawStrategy(context, graphicsFactory);
    addView(_domainAxis);
  }

  @override
  Axis get domainAxis => _domainAxis;
}

class OrdinalCartesianChart<T> extends CartesianChart<T, String> {
  final OrdinalAxis _domainAxis;

  OrdinalCartesianChart({bool vertical, LayoutConfig layoutConfig})
      : _domainAxis = new OrdinalAxis(),
        super(vertical: vertical, layoutConfig: layoutConfig);

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

abstract class CartesianChart<T, D> extends BaseChart<T, D> {
  static final _defaultLayoutConfig = new LayoutConfig(
    topSpec: new MarginSpec.fromPixel(minPixel: 20),
    bottomSpec: new MarginSpec.fromPixel(minPixel: 20),
    leftSpec: new MarginSpec.fromPixel(minPixel: 20),
    rightSpec: new MarginSpec.fromPixel(minPixel: 20),
  );

  bool vertical;
  final _primaryMeasureAxis = new NumericAxis();
  final _secondaryMeasureAxis = new NumericAxis();

  bool _usePrimaryMeasureAxis = false;
  bool _useSecondaryMeasureAxis = false;

  CartesianChart({bool vertical, LayoutConfig layoutConfig})
      : vertical = vertical ?? true,
        super(layoutConfig: layoutConfig ?? _defaultLayoutConfig);

  void init(ChartContext context, GraphicsFactory graphicsFactory) {
    super.init(context, graphicsFactory);

    _primaryMeasureAxis.context = context;
    _primaryMeasureAxis.tickDrawStrategy = new GridlineRendererSpec<num>()
        .createDrawStrategy(context, graphicsFactory);
    _secondaryMeasureAxis.context = context;
    _secondaryMeasureAxis.tickDrawStrategy = new GridlineRendererSpec<num>()
        .createDrawStrategy(context, graphicsFactory);
  }

  Axis get domainAxis;

  set domainAxisSpec(AxisSpec axisSpec) =>
      axisSpec.configure(domainAxis, context, graphicsFactory);

  Axis getMeasureAxis(String axisId) => axisId == Axis.secondaryMeasureAxisId
      ? _secondaryMeasureAxis
      : _primaryMeasureAxis;

  set primaryMeasureAxisSpec(AxisSpec axisSpec) =>
      axisSpec.configure(_primaryMeasureAxis, context, graphicsFactory);

  set secondaryMeasureAxisSpec(AxisSpec axisSpec) =>
      axisSpec.configure(_secondaryMeasureAxis, context, graphicsFactory);

  @override
  MutableSeries<T, D> makeSeries(Series<T, D> series) {
    MutableSeries<T, D> s = super.makeSeries(series);

    s.measureOffsetFn ??= (_, __) => 0;

    // Setup the Axes
    s.setAttr(domainAxisKey, domainAxis);
    s.setAttr(
        measureAxisKey, getMeasureAxis(series.getAttribute(measureAxisIdKey)));

    return s;
  }

  @override
  SeriesRenderer<T, D> makeDefaultRenderer() {
    return new BarRenderer()..rendererId = SeriesRenderer.defaultRendererId;
  }

  @override
  Map<String, List<MutableSeries<T, D>>> preprocessSeries(
      List<MutableSeries<T, D>> seriesList) {
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

    // Reset stale values from previous draw cycles.
    domainAxis.resetDomains();
    _primaryMeasureAxis.resetDomains();
    _secondaryMeasureAxis.resetDomains();

    final reverseAxisPosition = context != null &&
        context.rtl &&
        context.rtlSpec.axisPosition == AxisPosition.reversed;

    if (vertical) {
      domainAxis
        ..axisOrientation = AxisOrientation.bottom
        ..reverseOutputRange = reverseAxisPosition;
      _primaryMeasureAxis.axisOrientation =
          reverseAxisPosition ? AxisOrientation.right : AxisOrientation.left;
      _secondaryMeasureAxis.axisOrientation =
          reverseAxisPosition ? AxisOrientation.left : AxisOrientation.right;
    } else {
      domainAxis.axisOrientation =
          reverseAxisPosition ? AxisOrientation.right : AxisOrientation.left;
      _primaryMeasureAxis
        ..axisOrientation = AxisOrientation.bottom
        ..reverseOutputRange = reverseAxisPosition;
      _secondaryMeasureAxis
        ..axisOrientation = AxisOrientation.top
        ..reverseOutputRange = reverseAxisPosition;
    }

    // Have each renderer configure the axes with their domain and measure
    // values.
    rendererToSeriesList
        .forEach((String rendererId, List<MutableSeries<T, D>> seriesList) {
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

    super.onSkipLayout();
  }

  @override
  void onPostLayout(
      Map<String, List<MutableSeries<T, D>>> rendererToSeriesList) {
    fireOnAxisConfigured();

    super.onPostLayout(rendererToSeriesList);
  }

  /// Returns a list of datum details from selection model of [type].
  @override
  List<DatumDetails<T, D>> getDatumDetails(SelectionModelType type) {
    final entries = <DatumDetails<T, D>>[];

    getSelectionModel(type).selectedDatum.forEach((seriesDatum) {
      final series = seriesDatum.series;
      final datum = seriesDatum.datum;

      final domain = series.domainFn(datum, null);
      final measure = series.measureFn(datum, null);
      final color = series.colorFn(datum, null);

      final x =
          series.getAttr(domainAxisKey).getLocation(series.domainFn(datum, -1));
      final y = series
          .getAttr(measureAxisKey)
          .getLocation(series.measureFn(datum, -1));

      entries.add(new DatumDetails(
          datum: datum,
          domain: domain,
          measure: measure,
          series: series,
          color: color,
          chartX: x,
          chartY: y));
    });

    return entries;
  }
}

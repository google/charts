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

import '../../common/color.dart' show Color;
import 'datum_details.dart' show DomainFormatter, MeasureFormatter;
import '../../data/series.dart'
    show AccessorFn, Series, SeriesAttributes, AttributeKey;
import '../cartesian/axis/axis.dart' show Axis;
import '../cartesian/axis/spec/axis_spec.dart' show TextStyleSpec;
import '../common/chart_canvas.dart' show FillPatternType;

class MutableSeries<D> extends ImmutableSeries<D> {
  @override
  final String id;

  @override
  String? displayName;

  @override
  bool overlaySeries;

  @override
  String? seriesCategory;

  @override
  Color? seriesColor;

  @override
  late int seriesIndex;

  /// Sum of the measure values for the series.
  @override
  late num seriesMeasureTotal;

  @override
  List<dynamic> data;

  @override
  AccessorFn<String>? keyFn;

  @override
  AccessorFn<D> domainFn;

  @override
  AccessorFn<DomainFormatter<D>>? domainFormatterFn;

  @override
  AccessorFn<D?>? domainLowerBoundFn;

  @override
  AccessorFn<D?>? domainUpperBoundFn;

  @override
  AccessorFn<num?> measureFn;

  @override
  AccessorFn<MeasureFormatter>? measureFormatterFn;

  @override
  AccessorFn<num?>? measureLowerBoundFn;

  @override
  AccessorFn<num?>? measureUpperBoundFn;

  @override
  AccessorFn<num?>? measureOffsetFn;

  @override
  AccessorFn<num?> rawMeasureFn;

  @override
  AccessorFn<num?>? rawMeasureLowerBoundFn;

  @override
  AccessorFn<num?>? rawMeasureUpperBoundFn;

  @override
  AccessorFn<Color?>? areaColorFn;

  @override
  AccessorFn<Color>? colorFn;

  @override
  AccessorFn<List<int>?>? dashPatternFn;

  @override
  AccessorFn<Color?>? fillColorFn;

  @override
  AccessorFn<FillPatternType?>? fillPatternFn;

  @override
  AccessorFn<Color?>? patternColorFn;

  @override
  AccessorFn<num?>? radiusPxFn;
  @override
  AccessorFn<num?>? strokeWidthPxFn;
  @override
  AccessorFn<String>? labelAccessorFn;

  @override
  AccessorFn<TextStyleSpec>? insideLabelStyleAccessorFn;

  @override
  AccessorFn<TextStyleSpec>? outsideLabelStyleAccessorFn;

  final _attrs = SeriesAttributes();

  Axis<num>? measureAxis;
  Axis<D>? domainAxis;

  MutableSeries(Series<dynamic, D> series)
      : id = series.id,
        displayName = series.displayName ?? series.id,
        overlaySeries = series.overlaySeries,
        seriesCategory = series.seriesCategory,
        seriesColor = series.seriesColor,
        data = series.data,
        keyFn = series.keyFn,
        domainFn = series.domainFn,
        domainFormatterFn = series.domainFormatterFn,
        domainLowerBoundFn = series.domainLowerBoundFn,
        domainUpperBoundFn = series.domainUpperBoundFn,
        measureFn = series.measureFn,
        measureFormatterFn = series.measureFormatterFn,
        measureLowerBoundFn = series.measureLowerBoundFn,
        measureUpperBoundFn = series.measureUpperBoundFn,
        measureOffsetFn = series.measureOffsetFn,

        // Save the original measure functions in case they get replaced later.
        rawMeasureFn = series.measureFn,
        rawMeasureLowerBoundFn = series.measureLowerBoundFn,
        rawMeasureUpperBoundFn = series.measureUpperBoundFn,
        areaColorFn = series.areaColorFn,
        colorFn = series.colorFn,
        dashPatternFn = series.dashPatternFn,
        fillColorFn = series.fillColorFn,
        fillPatternFn = series.fillPatternFn,
        patternColorFn = series.patternColorFn,
        insideLabelStyleAccessorFn = series.insideLabelStyleAccessorFn,
        outsideLabelStyleAccessorFn = series.outsideLabelStyleAccessorFn,
        radiusPxFn = series.radiusPxFn,
        strokeWidthPxFn = series.strokeWidthPxFn {
    // Pre-compute the sum of the measure values to make it available on demand.
    seriesMeasureTotal = 0;
    for (var i = 0; i < data.length; i++) {
      final measure = measureFn(i);
      if (measure != null) {
        seriesMeasureTotal += measure;
      }
    }

    labelAccessorFn = series.labelAccessorFn ?? (i) => domainFn(i).toString();

    _attrs.mergeFrom(series.attributes);
  }

  MutableSeries.clone(MutableSeries<D> other)
      : id = other.id,
        displayName = other.displayName,
        overlaySeries = other.overlaySeries,
        seriesCategory = other.seriesCategory,
        seriesColor = other.seriesColor,
        seriesIndex = other.seriesIndex,
        data = other.data,
        keyFn = other.keyFn,
        domainFn = other.domainFn,
        domainFormatterFn = other.domainFormatterFn,
        domainLowerBoundFn = other.domainLowerBoundFn,
        domainUpperBoundFn = other.domainUpperBoundFn,
        measureFn = other.measureFn,
        measureFormatterFn = other.measureFormatterFn,
        measureLowerBoundFn = other.measureLowerBoundFn,
        measureUpperBoundFn = other.measureUpperBoundFn,
        measureOffsetFn = other.measureOffsetFn,
        rawMeasureFn = other.rawMeasureFn,
        rawMeasureLowerBoundFn = other.rawMeasureLowerBoundFn,
        rawMeasureUpperBoundFn = other.rawMeasureUpperBoundFn,
        seriesMeasureTotal = other.seriesMeasureTotal,
        areaColorFn = other.areaColorFn,
        colorFn = other.colorFn,
        dashPatternFn = other.dashPatternFn,
        fillColorFn = other.fillColorFn,
        fillPatternFn = other.fillPatternFn,
        patternColorFn = other.patternColorFn,
        labelAccessorFn = other.labelAccessorFn,
        insideLabelStyleAccessorFn = other.insideLabelStyleAccessorFn,
        outsideLabelStyleAccessorFn = other.outsideLabelStyleAccessorFn,
        radiusPxFn = other.radiusPxFn,
        strokeWidthPxFn = other.strokeWidthPxFn,
        measureAxis = other.measureAxis,
        domainAxis = other.domainAxis {
    _attrs.mergeFrom(other._attrs);
  }

  @override
  void setAttr<R>(AttributeKey<R> key, R value) => _attrs.setAttr(key, value);

  @override
  R? getAttr<R>(AttributeKey<R> key) => _attrs.getAttr(key);

  @override
  bool operator ==(Object other) =>
      other is MutableSeries && data == other.data && id == other.id;

  @override
  int get hashCode => data.hashCode * 31 + id.hashCode;
}

abstract class ImmutableSeries<D> {
  String get id;

  String? get displayName;

  /// Overlay series provided supplemental information on a chart, but are not
  /// considered to be primary data. They should not be selectable by user
  /// interaction.
  bool get overlaySeries;

  String? get seriesCategory;

  /// Color which represents the entire series in legends.
  ///
  /// If this is not provided in the original series object, it will be inferred
  /// from the color of the first datum in the series.
  ///
  /// If this is provided, but no [colorFn] is provided, then it will be treated
  /// as the color for each datum in the series.
  ///
  /// If neither are provided, then the chart will insert colors for each series
  /// on the chart using a mapping function.
  Color? get seriesColor;

  int get seriesIndex;

  /// Sum of the measure values for the series.
  num get seriesMeasureTotal;

  // Uses `dynamic` for convenience to callers.
  List<dynamic> get data;

  /// [keyFn] defines a globally unique identifier for each datum.
  ///
  /// The key for each datum is used during chart animation to smoothly
  /// transition data still in the series to its new state.
  ///
  /// Note: This is currently an optional function that is not fully used by all
  /// series renderers yet.
  AccessorFn<String>? keyFn;

  AccessorFn<D> get domainFn;

  AccessorFn<DomainFormatter<D>>? get domainFormatterFn;

  AccessorFn<D?>? get domainLowerBoundFn;

  AccessorFn<D?>? get domainUpperBoundFn;

  AccessorFn<num?> get measureFn;

  AccessorFn<MeasureFormatter>? get measureFormatterFn;

  AccessorFn<num?>? get measureLowerBoundFn;

  AccessorFn<num?>? get measureUpperBoundFn;

  AccessorFn<num?>? get measureOffsetFn;

  AccessorFn<num?> get rawMeasureFn;

  AccessorFn<num?>? get rawMeasureLowerBoundFn;

  AccessorFn<num?>? get rawMeasureUpperBoundFn;

  AccessorFn<Color?>? get areaColorFn;

  AccessorFn<Color?>? get colorFn;

  AccessorFn<List<int>?>? get dashPatternFn;

  AccessorFn<Color?>? get fillColorFn;

  AccessorFn<Color?>? get patternColorFn;

  AccessorFn<FillPatternType?>? get fillPatternFn;

  AccessorFn<String>? get labelAccessorFn;

  AccessorFn<TextStyleSpec>? insideLabelStyleAccessorFn;
  AccessorFn<TextStyleSpec>? outsideLabelStyleAccessorFn;

  AccessorFn<num?>? get radiusPxFn;

  AccessorFn<num?>? get strokeWidthPxFn;

  void setAttr<R>(AttributeKey<R> key, R value);

  R? getAttr<R>(AttributeKey<R> key);
}

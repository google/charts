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

import '../chart/cartesian/axis/spec/axis_spec.dart' show TextStyleSpec;
import '../chart/common/chart_canvas.dart' show FillPatternType;
import '../chart/common/datum_details.dart'
    show DomainFormatter, MeasureFormatter;
import '../common/color.dart' show Color;
import '../common/typed_registry.dart' show TypedRegistry, TypedKey;

class Series<T, D> {
  final String id;
  final String? displayName;

  /// Overlay series provided supplemental information on a chart, but are not
  /// considered to be primary data. They should not be selectable by user
  /// interaction.
  final bool overlaySeries;

  final String? seriesCategory;

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
  final Color? seriesColor;

  final List<T> data;

  /// [keyFn] defines a globally unique identifier for each datum.
  ///
  /// The key for each datum is used during chart animation to smoothly
  /// transition data still in the series to its new state.
  ///
  /// Note: This is currently an optional function that is not fully used by all
  /// series renderers yet.
  final AccessorFn<String>? keyFn;

  final AccessorFn<D> domainFn;
  final AccessorFn<DomainFormatter<D>>? domainFormatterFn;
  final AccessorFn<D?>? domainLowerBoundFn;
  final AccessorFn<D?>? domainUpperBoundFn;
  final AccessorFn<num?> measureFn;
  final AccessorFn<MeasureFormatter>? measureFormatterFn;
  final AccessorFn<num?>? measureLowerBoundFn;
  final AccessorFn<num?>? measureUpperBoundFn;
  final AccessorFn<num>? measureOffsetFn;

  /// [areaColorFn] returns the area color for a given data value. If not
  /// provided, then some variation of the main [colorFn] will be used (e.g.
  /// 10% opacity).
  ///
  /// This color is used for supplemental information on the series, such as
  /// confidence intervals or area skirts.
  final AccessorFn<Color>? areaColorFn;

  /// [colorFn] returns the rendered stroke color for a given data value.
  ///
  /// If this is not provided, then [seriesColor] will be used for every datum.
  ///
  /// If neither are provided, then the chart will insert colors for each series
  /// on the chart using a mapping function.
  final AccessorFn<Color>? colorFn;

  /// [dashPatternFn] returns the dash pattern for a given data value.
  final AccessorFn<List<int>?>? dashPatternFn;

  /// [fillColorFn] returns the rendered fill color for a given data value. If
  /// not provided, then [colorFn] will be used as a fallback.
  final AccessorFn<Color?>? fillColorFn;

  /// [patternColorFn] returns the background color of tile when a
  /// [FillPatternType] beside `solid` is used. If not provided, then
  /// background color is used.
  final AccessorFn<Color>? patternColorFn;

  final AccessorFn<FillPatternType>? fillPatternFn;
  final AccessorFn<num>? radiusPxFn;
  final AccessorFn<num?>? strokeWidthPxFn;
  final AccessorFn<String>? labelAccessorFn;
  final AccessorFn<TextStyleSpec>? insideLabelStyleAccessorFn;
  final AccessorFn<TextStyleSpec>? outsideLabelStyleAccessorFn;

  // TODO: should this be immutable as well? If not, should any of
  // the non-required ones be final?
  final SeriesAttributes attributes = SeriesAttributes();

  factory Series(
      {required String id,
      required List<T> data,
      required TypedAccessorFn<T, D> domainFn,
      required TypedAccessorFn<T, num?> measureFn,
      String? displayName,
      Color? seriesColor,
      TypedAccessorFn<T, Color>? areaColorFn,
      TypedAccessorFn<T, Color>? colorFn,
      TypedAccessorFn<T, List<int>?>? dashPatternFn,
      TypedAccessorFn<T, DomainFormatter<D>>? domainFormatterFn,
      TypedAccessorFn<T, D?>? domainLowerBoundFn,
      TypedAccessorFn<T, D?>? domainUpperBoundFn,
      TypedAccessorFn<T, Color?>? fillColorFn,
      TypedAccessorFn<T, Color>? patternColorFn,
      TypedAccessorFn<T, FillPatternType>? fillPatternFn,
      TypedAccessorFn<T, String>? keyFn,
      TypedAccessorFn<T, String>? labelAccessorFn,
      TypedAccessorFn<T, TextStyleSpec>? insideLabelStyleAccessorFn,
      TypedAccessorFn<T, TextStyleSpec>? outsideLabelStyleAccessorFn,
      TypedAccessorFn<T, MeasureFormatter>? measureFormatterFn,
      TypedAccessorFn<T, num?>? measureLowerBoundFn,
      TypedAccessorFn<T, num?>? measureUpperBoundFn,
      TypedAccessorFn<T, num>? measureOffsetFn,
      bool overlaySeries = false,
      TypedAccessorFn<T, num>? radiusPxFn,
      String? seriesCategory,
      TypedAccessorFn<T, num?>? strokeWidthPxFn}) {
    // Wrap typed accessors.
    final _domainFn = (int? index) => domainFn(data[index!], index);
    final _measureFn = (int? index) => measureFn(data[index!], index);
    final _areaColorFn = areaColorFn == null
        ? null
        : (int? index) => areaColorFn(data[index!], index);
    final _colorFn =
        colorFn == null ? null : (int? index) => colorFn(data[index!], index);
    final _dashPatternFn = dashPatternFn == null
        ? null
        : (int? index) => dashPatternFn(data[index!], index);
    final _domainFormatterFn = domainFormatterFn == null
        ? null
        : (int? index) => domainFormatterFn(data[index!], index);
    final _domainLowerBoundFn = domainLowerBoundFn == null
        ? null
        : (int? index) => domainLowerBoundFn(data[index!], index);
    final _domainUpperBoundFn = domainUpperBoundFn == null
        ? null
        : (int? index) => domainUpperBoundFn(data[index!], index);
    final _fillColorFn = fillColorFn == null
        ? null
        : (int? index) => fillColorFn(data[index!], index);
    final _patternColorFn = patternColorFn == null
        ? null
        : (int? index) => patternColorFn(data[index!], index);
    final _fillPatternFn = fillPatternFn == null
        ? null
        : (int? index) => fillPatternFn(data[index!], index);
    final _labelAccessorFn = labelAccessorFn == null
        ? null
        : (int? index) => labelAccessorFn(data[index!], index);
    final _insideLabelStyleAccessorFn = insideLabelStyleAccessorFn == null
        ? null
        : (int? index) => insideLabelStyleAccessorFn(data[index!], index);
    final _outsideLabelStyleAccessorFn = outsideLabelStyleAccessorFn == null
        ? null
        : (int? index) => outsideLabelStyleAccessorFn(data[index!], index);
    final _measureFormatterFn = measureFormatterFn == null
        ? null
        : (int? index) => measureFormatterFn(data[index!], index);
    final _measureLowerBoundFn = measureLowerBoundFn == null
        ? null
        : (int? index) => measureLowerBoundFn(data[index!], index);
    final _measureUpperBoundFn = measureUpperBoundFn == null
        ? null
        : (int? index) => measureUpperBoundFn(data[index!], index);
    final _measureOffsetFn = measureOffsetFn == null
        ? null
        : (int? index) => measureOffsetFn(data[index!], index);
    final _radiusPxFn = radiusPxFn == null
        ? null
        : (int? index) => radiusPxFn(data[index!], index);
    final _strokeWidthPxFn = strokeWidthPxFn == null
        ? null
        : (int? index) => strokeWidthPxFn(data[index!], index);
    final _keyFn =
        keyFn == null ? null : (int? index) => keyFn(data[index!], index);

    return Series._internal(
      id: id,
      data: data,
      domainFn: _domainFn,
      measureFn: _measureFn,
      displayName: displayName,
      areaColorFn: _areaColorFn,
      colorFn: _colorFn,
      dashPatternFn: _dashPatternFn,
      domainFormatterFn: _domainFormatterFn,
      domainLowerBoundFn: _domainLowerBoundFn,
      domainUpperBoundFn: _domainUpperBoundFn,
      fillColorFn: _fillColorFn,
      fillPatternFn: _fillPatternFn,
      keyFn: _keyFn,
      patternColorFn: _patternColorFn,
      labelAccessorFn: _labelAccessorFn,
      insideLabelStyleAccessorFn: _insideLabelStyleAccessorFn,
      outsideLabelStyleAccessorFn: _outsideLabelStyleAccessorFn,
      measureFormatterFn: _measureFormatterFn,
      measureLowerBoundFn: _measureLowerBoundFn,
      measureUpperBoundFn: _measureUpperBoundFn,
      measureOffsetFn: _measureOffsetFn,
      overlaySeries: overlaySeries,
      radiusPxFn: _radiusPxFn,
      seriesCategory: seriesCategory,
      seriesColor: seriesColor,
      strokeWidthPxFn: _strokeWidthPxFn,
    );
  }

  Series._internal({
    required this.id,
    required this.data,
    required this.domainFn,
    required this.measureFn,
    required this.displayName,
    required this.areaColorFn,
    required this.colorFn,
    required this.dashPatternFn,
    required this.domainFormatterFn,
    required this.domainLowerBoundFn,
    required this.domainUpperBoundFn,
    required this.fillColorFn,
    required this.fillPatternFn,
    required this.patternColorFn,
    required this.keyFn,
    required this.labelAccessorFn,
    required this.insideLabelStyleAccessorFn,
    required this.outsideLabelStyleAccessorFn,
    required this.measureFormatterFn,
    required this.measureLowerBoundFn,
    required this.measureUpperBoundFn,
    required this.measureOffsetFn,
    required this.overlaySeries,
    required this.radiusPxFn,
    required this.seriesCategory,
    required this.seriesColor,
    required this.strokeWidthPxFn,
  });

  void setAttribute<R>(AttributeKey<R> key, R value) {
    attributes.setAttr(key, value);
  }

  R? getAttribute<R>(AttributeKey<R> key) {
    return attributes.getAttr<R>(key);
  }
}

/// Computed property on series.
///
/// If the [index] argument is `null`, the accessor is asked to provide a
/// property of [series] as a whole. Accessors are not required to support
/// such usage.
///
/// Otherwise, [index] must be a valid subscript into a list of `series.length`.
typedef AccessorFn<R> = R Function(int? index);

typedef TypedAccessorFn<T, R> = R Function(T datum, int? index);

class AttributeKey<R> extends TypedKey<R> {
  const AttributeKey(String uniqueKey) : super(uniqueKey);
}

class SeriesAttributes extends TypedRegistry {}

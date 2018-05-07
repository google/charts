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

import 'package:meta/meta.dart';
import '../chart/cartesian/axis/spec/axis_spec.dart' show TextStyleSpec;
import '../common/color.dart' show Color;
import '../common/typed_registry.dart' show TypedRegistry, TypedKey;
import '../chart/common/chart_canvas.dart' show FillPatternType;

class Series<T, D> {
  final String id;
  final String displayName;
  final String seriesCategory;
  final bool overlaySeries;

  final List<T> data;

  final AccessorFn<D> domainFn;
  final AccessorFn<D> domainLowerBoundFn;
  final AccessorFn<D> domainUpperBoundFn;
  final AccessorFn<num> measureFn;
  final AccessorFn<num> measureLowerBoundFn;
  final AccessorFn<num> measureUpperBoundFn;
  final AccessorFn<num> measureOffsetFn;

  /// [colorFn] returns the rendered stroke color for a given data value.
  final AccessorFn<Color> colorFn;

  /// [fillColorFn] returns the rendered fill color for a given data value. If
  /// not provided, then [colorFn] will be used as a fallback.
  final AccessorFn<Color> fillColorFn;
  final AccessorFn<FillPatternType> fillPatternFn;
  final AccessorFn<num> radiusPxFn;
  final AccessorFn<num> strokeWidthPxFn;
  final AccessorFn<String> labelAccessorFn;
  final AccessorFn<TextStyleSpec> insideLabelStyleAccessorFn;
  final AccessorFn<TextStyleSpec> outsideLabelStyleAccessorFn;

  final List<int> dashPattern;

  // TODO: should this be immutable as well? If not, should any of
  // the non-required ones be final?
  final SeriesAttributes attributes = new SeriesAttributes();

  factory Series(
      {@required String id,
      @required List<T> data,
      @required TypedAccessorFn<T, D> domainFn,
      @required TypedAccessorFn<T, num> measureFn,
      String displayName,
      TypedAccessorFn<T, Color> colorFn,
      List<int> dashPattern,
      TypedAccessorFn<T, D> domainLowerBoundFn,
      TypedAccessorFn<T, D> domainUpperBoundFn,
      TypedAccessorFn<T, Color> fillColorFn,
      TypedAccessorFn<T, FillPatternType> fillPatternFn,
      TypedAccessorFn<T, String> labelAccessorFn,
      TypedAccessorFn<T, TextStyleSpec> insideLabelStyleAccessorFn,
      TypedAccessorFn<T, TextStyleSpec> outsideLabelStyleAccessorFn,
      TypedAccessorFn<T, num> measureLowerBoundFn,
      TypedAccessorFn<T, num> measureUpperBoundFn,
      TypedAccessorFn<T, num> measureOffsetFn,
      bool overlaySeries = false,
      TypedAccessorFn<T, num> radiusPxFn,
      String seriesCategory,
      TypedAccessorFn<T, num> strokeWidthPxFn}) {
    // Wrap typed accessors.
    final _domainFn = (int index) => domainFn(data[index], index);
    final _measureFn = (int index) => measureFn(data[index], index);
    final _colorFn =
        colorFn == null ? null : (int index) => colorFn(data[index], index);
    final _domainLowerBoundFn = domainLowerBoundFn == null
        ? null
        : (int index) => domainLowerBoundFn(data[index], index);
    final _domainUpperBoundFn = domainUpperBoundFn == null
        ? null
        : (int index) => domainUpperBoundFn(data[index], index);
    final _fillColorFn = fillColorFn == null
        ? null
        : (int index) => fillColorFn(data[index], index);
    final _fillPatternFn = fillPatternFn == null
        ? null
        : (int index) => fillPatternFn(data[index], index);
    final _labelAccessorFn = labelAccessorFn == null
        ? null
        : (int index) => labelAccessorFn(data[index], index);
    final _insideLabelStyleAccessorFn = insideLabelStyleAccessorFn == null
        ? null
        : (int index) => insideLabelStyleAccessorFn(data[index], index);
    final _outsideLabelStyleAccessorFn = outsideLabelStyleAccessorFn == null
        ? null
        : (int index) => outsideLabelStyleAccessorFn(data[index], index);
    final _measureLowerBoundFn = measureLowerBoundFn == null
        ? null
        : (int index) => measureLowerBoundFn(data[index], index);
    final _measureUpperBoundFn = measureUpperBoundFn == null
        ? null
        : (int index) => measureUpperBoundFn(data[index], index);
    final _measureOffsetFn = measureOffsetFn == null
        ? null
        : (int index) => measureOffsetFn(data[index], index);
    final _radiusPxFn = radiusPxFn == null
        ? null
        : (int index) => radiusPxFn(data[index], index);
    final _strokeWidthPxFn = strokeWidthPxFn == null
        ? null
        : (int index) => strokeWidthPxFn(data[index], index);

    return new Series._internal(
      id: id,
      data: data,
      domainFn: _domainFn,
      measureFn: _measureFn,
      displayName: displayName,
      colorFn: _colorFn,
      dashPattern: dashPattern,
      domainLowerBoundFn: _domainLowerBoundFn,
      domainUpperBoundFn: _domainUpperBoundFn,
      fillColorFn: _fillColorFn,
      fillPatternFn: _fillPatternFn,
      labelAccessorFn: _labelAccessorFn,
      insideLabelStyleAccessorFn: _insideLabelStyleAccessorFn,
      outsideLabelStyleAccessorFn: _outsideLabelStyleAccessorFn,
      measureLowerBoundFn: _measureLowerBoundFn,
      measureUpperBoundFn: _measureUpperBoundFn,
      measureOffsetFn: _measureOffsetFn,
      overlaySeries: overlaySeries,
      radiusPxFn: _radiusPxFn,
      seriesCategory: seriesCategory,
      strokeWidthPxFn: _strokeWidthPxFn,
    );
  }

  Series._internal({
    @required this.id,
    @required this.data,
    @required this.domainFn,
    @required this.measureFn,
    this.displayName,
    this.colorFn,
    this.dashPattern,
    this.domainLowerBoundFn,
    this.domainUpperBoundFn,
    this.fillColorFn,
    this.fillPatternFn,
    this.labelAccessorFn,
    this.insideLabelStyleAccessorFn,
    this.outsideLabelStyleAccessorFn,
    this.measureLowerBoundFn,
    this.measureUpperBoundFn,
    this.measureOffsetFn,
    this.overlaySeries = false,
    this.radiusPxFn,
    this.seriesCategory,
    this.strokeWidthPxFn,
  });

  void setAttribute<R>(AttributeKey<R> key, R value) {
    this.attributes.setAttr(key, value);
  }

  R getAttribute<R>(AttributeKey<R> key) {
    return this.attributes.getAttr<R>(key);
  }
}

/// Computed property on series.
///
/// If the [index] argument is `null`, the accessor is asked to provide a
/// property of [series] as a whole. Accessors are not required to support
/// such usage.
///
/// Otherwise, [index] must be a valid subscript into a list of `series.length`.
typedef R AccessorFn<R>(int index);

typedef R TypedAccessorFn<T, R>(T datum, int index);

class AttributeKey<R> extends TypedKey<R> {
  const AttributeKey(String uniqueKey) : super(uniqueKey);
}

class SeriesAttributes extends TypedRegistry {}

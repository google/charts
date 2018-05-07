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

import '../cartesian/axis/axis.dart' show Axis;
import '../cartesian/axis/spec/axis_spec.dart' show TextStyleSpec;
import '../common/chart_canvas.dart' show FillPatternType;
import '../../data/series.dart'
    show AccessorFn, Series, SeriesAttributes, AttributeKey;
import '../../common/color.dart' show Color;

class MutableSeries<D> extends ImmutableSeries<D> {
  final String id;
  String displayName;
  String seriesCategory;
  bool overlaySeries;
  int seriesIndex;

  List data;

  AccessorFn<D> domainFn;
  AccessorFn<D> domainLowerBoundFn;
  AccessorFn<D> domainUpperBoundFn;
  AccessorFn<num> measureFn;
  AccessorFn<num> measureLowerBoundFn;
  AccessorFn<num> measureUpperBoundFn;
  AccessorFn<num> measureOffsetFn;
  AccessorFn<Color> colorFn;
  AccessorFn<Color> fillColorFn;
  AccessorFn<FillPatternType> fillPatternFn;
  AccessorFn<num> radiusPxFn;
  AccessorFn<num> strokeWidthPxFn;
  AccessorFn<String> labelAccessorFn;
  AccessorFn<TextStyleSpec> insideLabelStyleAccessorFn;
  AccessorFn<TextStyleSpec> outsideLabelStyleAccessorFn;

  List<int> dashPattern;

  final _attrs = new SeriesAttributes();

  Axis measureAxis;
  Axis domainAxis;

  MutableSeries(Series<dynamic, D> series) : this.id = series.id {
    displayName = series.displayName ?? series.id;
    seriesCategory = series.seriesCategory;
    overlaySeries = series.overlaySeries;

    data = series.data;
    domainFn = series.domainFn;
    domainLowerBoundFn = series.domainLowerBoundFn;
    domainUpperBoundFn = series.domainUpperBoundFn;

    measureFn = series.measureFn;
    measureLowerBoundFn = series.measureLowerBoundFn;
    measureUpperBoundFn = series.measureUpperBoundFn;
    measureOffsetFn = series.measureOffsetFn;

    colorFn = series.colorFn;
    fillColorFn = series.fillColorFn;
    fillPatternFn = series.fillPatternFn;
    labelAccessorFn = series.labelAccessorFn ?? (i) => domainFn(i).toString();
    insideLabelStyleAccessorFn = series.insideLabelStyleAccessorFn;
    outsideLabelStyleAccessorFn = series.outsideLabelStyleAccessorFn;

    radiusPxFn = series.radiusPxFn;
    strokeWidthPxFn = series.strokeWidthPxFn;

    dashPattern = series.dashPattern;

    _attrs.mergeFrom(series.attributes);
  }

  MutableSeries.clone(MutableSeries<D> other) : this.id = other.id {
    displayName = other.displayName;
    seriesCategory = other.seriesCategory;
    overlaySeries = other.overlaySeries;
    seriesIndex = other.seriesIndex;

    data = other.data;
    domainFn = other.domainFn;
    domainLowerBoundFn = other.domainLowerBoundFn;
    domainUpperBoundFn = other.domainUpperBoundFn;

    measureFn = other.measureFn;
    measureLowerBoundFn = other.measureLowerBoundFn;
    measureUpperBoundFn = other.measureUpperBoundFn;
    measureOffsetFn = other.measureOffsetFn;

    colorFn = other.colorFn;
    fillColorFn = other.fillColorFn;
    fillPatternFn = other.fillPatternFn;
    labelAccessorFn = other.labelAccessorFn;
    insideLabelStyleAccessorFn = other.insideLabelStyleAccessorFn;
    outsideLabelStyleAccessorFn = other.outsideLabelStyleAccessorFn;
    radiusPxFn = other.radiusPxFn;
    strokeWidthPxFn = other.strokeWidthPxFn;

    dashPattern = other.dashPattern;

    _attrs.mergeFrom(other._attrs);
    measureAxis = other.measureAxis;
    domainAxis = other.domainAxis;
  }

  void setAttr<R>(AttributeKey<R> key, R value) {
    this._attrs.setAttr(key, value);
  }

  R getAttr<R>(AttributeKey<R> key) {
    return this._attrs.getAttr(key);
  }

  bool operator ==(Object other) =>
      other is MutableSeries && data == other.data && id == other.id;

  @override
  int get hashCode => data.hashCode * 31 + id.hashCode;
}

abstract class ImmutableSeries<D> {
  String get id;
  String get displayName;
  String get seriesCategory;
  bool get overlaySeries;
  int get seriesIndex;

  List get data;

  AccessorFn<D> get domainFn;
  AccessorFn<D> get domainLowerBoundFn;
  AccessorFn<D> get domainUpperBoundFn;
  AccessorFn<num> get measureFn;
  AccessorFn<num> get measureLowerBoundFn;
  AccessorFn<num> get measureUpperBoundFn;
  AccessorFn<num> get measureOffsetFn;
  AccessorFn<Color> get colorFn;
  AccessorFn<Color> get fillColorFn;
  AccessorFn<FillPatternType> get fillPatternFn;
  AccessorFn<String> get labelAccessorFn;
  AccessorFn<TextStyleSpec> insideLabelStyleAccessorFn;
  AccessorFn<TextStyleSpec> outsideLabelStyleAccessorFn;
  AccessorFn<num> get radiusPxFn;
  AccessorFn<num> get strokeWidthPxFn;

  List<int> get dashPattern;

  void setAttr<R>(AttributeKey<R> key, R value);
  R getAttr<R>(AttributeKey<R> key);
}

class SeriesDatum<D> {
  final ImmutableSeries<D> series;
  final dynamic datum;
  int _index;

  SeriesDatum(this.series, this.datum) {
    _index = datum == null ? null : series.data.indexOf(datum);
  }

  int get index => _index;

  @override
  bool operator ==(Object other) =>
      other is SeriesDatum && other.series == series && other.datum == datum;

  @override
  int get hashCode => series.hashCode * 31 + datum.hashCode;
}

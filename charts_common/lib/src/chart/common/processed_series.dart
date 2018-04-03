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

class MutableSeries<T, D> extends ImmutableSeries<T, D> {
  final String id;
  String displayName;
  String seriesCategory;
  bool overlaySeries;
  int seriesIndex;

  List<T> data;

  AccessorFn<T, D> domainFn;
  AccessorFn<T, num> measureFn;
  AccessorFn<T, num> measureUpperBoundFn;
  AccessorFn<T, num> measureLowerBoundFn;
  AccessorFn<T, num> measureOffsetFn;
  AccessorFn<T, Color> colorFn;
  AccessorFn<T, FillPatternType> fillPatternFn;
  AccessorFn<T, num> radiusPxFn;
  AccessorFn<T, num> strokeWidthPxFn;
  AccessorFn<T, String> labelAccessorFn;
  AccessorFn<T, TextStyleSpec> insideLabelStyleAccessorFn;
  AccessorFn<T, TextStyleSpec> outsideLabelStyleAccessorFn;

  List<int> dashPattern;

  final _attrs = new SeriesAttributes();

  Axis measureAxis;
  Axis domainAxis;

  MutableSeries(Series<T, D> series) : this.id = series.id {
    displayName = series.displayName ?? series.id;
    seriesCategory = series.seriesCategory;
    overlaySeries = series.overlaySeries;

    data = series.data;
    domainFn = series.domainFn;

    measureFn = series.measureFn;
    measureUpperBoundFn = series.measureUpperBoundFn;
    measureLowerBoundFn = series.measureLowerBoundFn;
    measureOffsetFn = series.measureOffsetFn;

    colorFn = series.colorFn;
    fillPatternFn = series.fillPatternFn;
    labelAccessorFn =
        series.labelAccessorFn ?? (d, i) => domainFn(d, i).toString();
    insideLabelStyleAccessorFn = series.insideLabelStyleAccessorFn;
    outsideLabelStyleAccessorFn = series.outsideLabelStyleAccessorFn;

    radiusPxFn = series.radiusPxFn;
    strokeWidthPxFn = series.strokeWidthPxFn;

    dashPattern = series.dashPattern;

    _attrs.mergeFrom(series.attributes);
  }

  MutableSeries.clone(MutableSeries<T, D> other) : this.id = other.id {
    displayName = other.displayName;
    seriesCategory = other.seriesCategory;
    overlaySeries = other.overlaySeries;
    seriesIndex = other.seriesIndex;

    data = other.data;
    domainFn = other.domainFn;

    measureFn = other.measureFn;
    measureUpperBoundFn = other.measureUpperBoundFn;
    measureLowerBoundFn = other.measureLowerBoundFn;
    measureOffsetFn = other.measureOffsetFn;

    colorFn = other.colorFn;
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

abstract class ImmutableSeries<T, D> {
  String get id;
  String get displayName;
  String get seriesCategory;
  bool get overlaySeries;
  int get seriesIndex;

  List<T> get data;

  AccessorFn<T, D> get domainFn;
  AccessorFn<T, num> get measureFn;
  AccessorFn<T, num> get measureUpperBoundFn;
  AccessorFn<T, num> get measureLowerBoundFn;
  AccessorFn<T, num> get measureOffsetFn;
  AccessorFn<T, Color> get colorFn;
  AccessorFn<T, FillPatternType> get fillPatternFn;
  AccessorFn<T, String> get labelAccessorFn;
  AccessorFn<T, TextStyleSpec> insideLabelStyleAccessorFn;
  AccessorFn<T, TextStyleSpec> outsideLabelStyleAccessorFn;
  AccessorFn<T, num> get radiusPxFn;
  AccessorFn<T, num> get strokeWidthPxFn;

  List<int> get dashPattern;

  void setAttr<R>(AttributeKey<R> key, R value);
  R getAttr<R>(AttributeKey<R> key);
}

class SeriesDatum<T, D> {
  final ImmutableSeries<T, D> series;
  final T datum;

  SeriesDatum(this.series, this.datum);

  @override
  bool operator ==(Object other) =>
      other is SeriesDatum && other.series == series && other.datum == datum;

  @override
  int get hashCode => series.hashCode * 31 + datum.hashCode;
}

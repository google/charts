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
import '../common/color.dart' show Color;
import '../common/typed_registry.dart' show TypedRegistry, TypedKey;
import '../chart/common/chart_canvas.dart' show FillPatternType;

class Series<T, D> {
  final String id;
  final String displayName;
  final String seriesCategory;
  final bool overlaySeries;

  final List<T> data;

  final AccessorFn<T, D> domainFn;
  final AccessorFn<T, num> measureFn;
  final AccessorFn<T, num> measureUpperBoundFn;
  final AccessorFn<T, num> measureLowerBoundFn;
  final AccessorFn<T, num> measureOffsetFn;
  final AccessorFn<T, Color> colorFn;
  final AccessorFn<T, FillPatternType> fillPatternFn;
  final AccessorFn<T, String> labelAccessorFn;
  final AccessorFn<T, num> radiusPxFn;
  final AccessorFn<T, num> strokeWidthPxFn;

  final List<int> dashPattern;

  // TODO: should this be immutable as well? If not, should any of
  // the non-required ones be final?
  final SeriesAttributes attributes = new SeriesAttributes();

  Series({
    @required this.id,
    @required this.data,
    @required this.domainFn,
    @required this.measureFn,
    this.displayName,
    this.colorFn,
    this.dashPattern,
    this.fillPatternFn,
    this.labelAccessorFn,
    this.measureLowerBoundFn,
    this.measureOffsetFn,
    this.measureUpperBoundFn,
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
typedef R AccessorFn<T, R>(T datum, int index);

class AttributeKey<R> extends TypedKey<R> {
  const AttributeKey(String uniqueKey) : super(uniqueKey);
}

class SeriesAttributes extends TypedRegistry {}

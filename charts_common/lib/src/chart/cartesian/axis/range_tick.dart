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

import '../../../common/text_element.dart';

import 'tick.dart' show Tick;

/// A labeled range on an axis.
///
/// [D] is the type of the value this tick is associated with.
class RangeTick<D> extends Tick<D> {
  /// The value that this range tick starting point represents
  final D rangeStartValue;

  /// Position of the range tick starting point.
  double rangeStartLocationPx;

  /// The value that this range tick ending point represents.
  final D rangeEndValue;

  /// Position of the range tick ending point.
  double rangeEndLocationPx;

  RangeTick(
      {required D value,
      required TextElement textElement,
      double? locationPx,
      double? labelOffsetPx,
      required this.rangeStartValue,
      required this.rangeStartLocationPx,
      required this.rangeEndValue,
      required this.rangeEndLocationPx})
      : super(
            value: value,
            locationPx: locationPx,
            textElement: textElement,
            labelOffsetPx: labelOffsetPx);

  @override
  String toString() => 'RangeTick(value: $value, locationPx: $locationPx, '
      'labelOffsetPx: $labelOffsetPx, rangeStartValue: $rangeStartValue, '
      'rangeStartLocationPx: $rangeStartLocationPx, '
      'rangeEndValue: $rangeEndValue,  rangeEndLocationPx: $rangeEndLocationPx)';
}

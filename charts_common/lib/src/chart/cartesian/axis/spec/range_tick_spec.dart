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

import 'axis_spec.dart' show TextStyleSpec;
import 'tick_spec.dart' show TickSpec;

/// Definition for a range tick.
///
/// Used to define a tick that is used by range tick provider.
class RangeTickSpec<D> extends TickSpec<D> {
  final D rangeStartValue;
  final D rangeEndValue;

  /// Creates a range tick for [value].
  /// A [label] optionally labels this tick. If not set, the tick formatter
  /// formatter of the axis is used.
  /// A [style] optionally sets the style for this tick. If not set, the style
  /// of the axis is used.
  /// A [rangeStartValue] represents value of this range tick's starting point.
  /// A [rangeEndValue] represents the value of this range tick's ending point.
  const RangeTickSpec(
    D value, {
    String? label,
    TextStyleSpec? style,
    required this.rangeStartValue,
    required this.rangeEndValue,
  }) : super(value, label: label, style: style);
}

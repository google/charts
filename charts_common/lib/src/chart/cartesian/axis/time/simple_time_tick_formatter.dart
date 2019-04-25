// Copyright 2019 the Charts project authors. Please see the AUTHORS file
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

import 'package:intl/intl.dart' show DateFormat;
import 'package:meta/meta.dart' show required;
import 'time_tick_formatter.dart' show TimeTickFormatter;

/// Formatter that formats all ticks using a single [DateFormat].
class SimpleTimeTickFormatter implements TimeTickFormatter {
  DateFormat dateFormat;

  SimpleTimeTickFormatter({@required DateFormat dateFormat})
      : this.dateFormat = dateFormat;

  @override
  String formatFirstTick(DateTime date) => dateFormat.format(date);

  @override
  String formatSimpleTick(DateTime date) => dateFormat.format(date);

  @override
  String formatTransitionTick(DateTime date) => dateFormat.format(date);

  // Transition fields don't matter here.
  @override
  bool isTransition(DateTime tickValue, DateTime prevTickValue) => false;
}

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

import 'time_tick_formatter.dart' show TimeTickFormatter;

typedef DateTimeFormatterFunction = String Function(DateTime datetime);

/// Formatter that formats all ticks using a single [DateTimeFormatterFunction].
class SimpleTimeTickFormatter implements TimeTickFormatter {
  DateTimeFormatterFunction formatter;

  SimpleTimeTickFormatter({required this.formatter});

  @override
  String formatFirstTick(DateTime date) => formatter(date);

  @override
  String formatSimpleTick(DateTime date) => formatter(date);

  @override
  String formatTransitionTick(DateTime date) => formatter(date);

  // Transition fields don't matter here.
  @override
  bool isTransition(DateTime tickValue, DateTime prevTickValue) => false;
}

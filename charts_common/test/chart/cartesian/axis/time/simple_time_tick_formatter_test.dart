// @dart=2.9

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

import 'package:charts_common/src/chart/cartesian/axis/time/simple_time_tick_formatter.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:test/test.dart';

void main() {
  const String tickLabel = '-tick-';
  final DateTime testDate1 = DateTime.utc(1984, 11, 11);
  final DateTime testDate2 = DateTime.utc(1984, 11, 12);

  SimpleTimeTickFormatter simpleTimeFormatter;
  SimpleTimeTickFormatter simpleTimeFormatterWithDateFormat;
  DateFormat dateFormat;

  String testFormatter(DateTime dateTime) {
    return tickLabel;
  }

  setUp(() {
    dateFormat = DateFormat.yMMMd();
    simpleTimeFormatter = SimpleTimeTickFormatter(formatter: testFormatter);
    simpleTimeFormatterWithDateFormat =
        SimpleTimeTickFormatter(formatter: dateFormat.format);
  });

  group(SimpleTimeTickFormatter, () {
    test('formatter with custom formatting function input', () {
      final actualLabelFirstTick =
          simpleTimeFormatter.formatFirstTick(testDate1);
      final actualLabelSimpleTick =
          simpleTimeFormatter.formatSimpleTick(testDate1);
      final actualLabelTransitionTick =
          simpleTimeFormatter.formatTransitionTick(testDate1);
      final actualBoolIsTransition =
          simpleTimeFormatter.isTransition(testDate2, testDate1);

      expect(actualLabelFirstTick, equals(tickLabel));
      expect(actualLabelSimpleTick, equals(tickLabel));
      expect(actualLabelTransitionTick, equals(tickLabel));
      expect(actualBoolIsTransition, isFalse);
    });

    test('formatter with DateFormat formatting function', () {
      final expectedLabel = 'Nov 11, 1984';

      final actualLabelFirstTick =
          simpleTimeFormatterWithDateFormat.formatFirstTick(testDate1);
      final actualLabelSimpleTick =
          simpleTimeFormatterWithDateFormat.formatSimpleTick(testDate1);
      final actualLabelTransitionTick =
          simpleTimeFormatterWithDateFormat.formatTransitionTick(testDate1);
      final actualBoolIsTransition =
          simpleTimeFormatterWithDateFormat.isTransition(testDate2, testDate1);

      expect(actualLabelFirstTick, equals(expectedLabel));
      expect(actualLabelSimpleTick, equals(expectedLabel));
      expect(actualLabelTransitionTick, equals(expectedLabel));
      expect(actualBoolIsTransition, isFalse);
    });
  });
}

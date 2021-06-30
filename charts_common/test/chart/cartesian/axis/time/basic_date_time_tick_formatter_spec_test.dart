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

import 'package:charts_common/src/chart/cartesian/axis/spec/date_time_axis_spec.dart';
import 'package:charts_common/src/chart/cartesian/axis/time/date_time_tick_formatter.dart';
import 'package:charts_common/src/chart/common/chart_context.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockContext extends Mock implements ChartContext {}

void main() {
  const String tickLabel = '-tick-';
  final DateTime testDate1 = DateTime.utc(1984, 11, 11);
  final DateTime testDate2 = DateTime.utc(1984, 11, 12);
  final DateTime testDate3 = DateTime.utc(1984, 11, 13);

  BasicDateTimeTickFormatterSpec dateTimeTickSpec;
  BasicDateTimeTickFormatterSpec dateTimeTickSpecWithDateFormat;
  DateFormat dateFormat;
  MockContext mockContext;

  String testFormatter(DateTime dateTime) {
    return tickLabel;
  }

  setUp(() {
    dateFormat = DateFormat.yMMMd();
    dateTimeTickSpec = BasicDateTimeTickFormatterSpec(testFormatter);
    dateTimeTickSpecWithDateFormat =
        BasicDateTimeTickFormatterSpec.fromDateFormat(dateFormat);

    mockContext = MockContext();
  });

  group(BasicDateTimeTickFormatterSpec, () {
    test('formats ticks with custom formatter', () {
      final DateTimeTickFormatter dateTimeTickFormatter =
          dateTimeTickSpec.createTickFormatter(mockContext);

      final ticks = [testDate1, testDate2, testDate3];
      final expectedLabels = [tickLabel, tickLabel, tickLabel];
      final actualLabels =
          dateTimeTickFormatter.format(ticks, null, stepSize: 10);

      expect(actualLabels, equals(expectedLabels));
    });

    test('formats ticks with provided DateFormat', () {
      final DateTimeTickFormatter dateTimeTickFormatter =
          dateTimeTickSpecWithDateFormat.createTickFormatter(mockContext);

      final ticks = [testDate1, testDate2, testDate3];
      final expectedLabels = [
        'Nov 11, 1984',
        'Nov 12, 1984',
        'Nov 13, 1984',
      ];
      final actualLabels =
          dateTimeTickFormatter.format(ticks, null, stepSize: 10);

      expect(actualLabels, equals(expectedLabels));
    });

    test('== override works correctly', () {
      final otherDateTimeTickSpec =
          BasicDateTimeTickFormatterSpec(testFormatter);
      final otherDateTimeTickSpecWithDateFormat =
          BasicDateTimeTickFormatterSpec.fromDateFormat(dateFormat);

      expect(dateTimeTickSpec == otherDateTimeTickSpec, isTrue);
      expect(
          dateTimeTickSpecWithDateFormat == otherDateTimeTickSpecWithDateFormat,
          isTrue);
    });

    test('hash code works correctly', () {
      final expectedHash = dateTimeTickSpec.formatter.hashCode *
          37 *
          dateTimeTickSpec.dateFormat.hashCode;
      final actualHash = dateTimeTickSpec.hashCode;

      expect(actualHash, equals(expectedHash));
    });
  });
}

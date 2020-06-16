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

import 'package:intl/intl.dart' show DateFormat;
import 'package:timezone/timezone.dart' as tz;

/// Interface for factory that creates [DateTime] and [DateFormat].
///
/// This allows for creating of locale specific date time and date format.
abstract class DateTimeFactory {
  DateTime createDateTimeFromMilliSecondsSinceEpoch(int millisecondsSinceEpoch);

  DateTime createDateTime(int year,
      [int month = 1,
      int day = 1,
      int hour = 0,
      int minute = 0,
      int second = 0,
      int millisecond = 0,
      int microsecond = 0]);

  /// Returns a [DateFormat].
  DateFormat createDateFormat(String pattern);
}

/// A local time [DateTimeFactory].
class LocalDateTimeFactory implements DateTimeFactory {
  const LocalDateTimeFactory();

  DateTime createDateTimeFromMilliSecondsSinceEpoch(
      int millisecondsSinceEpoch) {
    return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
  }

  DateTime createDateTime(int year,
      [int month = 1,
      int day = 1,
      int hour = 0,
      int minute = 0,
      int second = 0,
      int millisecond = 0,
      int microsecond = 0]) {
    return DateTime(
        year, month, day, hour, minute, second, millisecond, microsecond);
  }

  /// Returns a [DateFormat].
  DateFormat createDateFormat(String pattern) {
    return DateFormat(pattern);
  }
}

/// An UTC time [DateTimeFactory].
class UTCDateTimeFactory implements DateTimeFactory {
  const UTCDateTimeFactory();

  DateTime createDateTimeFromMilliSecondsSinceEpoch(
      int millisecondsSinceEpoch) {
    return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch,
        isUtc: true);
  }

  DateTime createDateTime(int year,
      [int month = 1,
      int day = 1,
      int hour = 0,
      int minute = 0,
      int second = 0,
      int millisecond = 0,
      int microsecond = 0]) {
    return DateTime.utc(
        year, month, day, hour, minute, second, millisecond, microsecond);
  }

  /// Returns a [DateFormat].
  DateFormat createDateFormat(String pattern) {
    return DateFormat(pattern);
  }
}

/// A TimeZone aware time [DateTimeFactory].
class TimeZoneAwareDateTimeFactory implements DateTimeFactory {
  final tz.Location location;

  const TimeZoneAwareDateTimeFactory(this.location) : assert(location != null);

  DateTime createDateTimeFromMilliSecondsSinceEpoch(int millisecondsSinceEpoch) {
    return tz.TZDateTime.fromMillisecondsSinceEpoch(location, millisecondsSinceEpoch);
  }

  DateTime createDateTime(int year,
      [int month = 1, int day = 1, int hour = 0, int minute = 0, int second = 0, int millisecond = 0, int microsecond = 0]) {
    return tz.TZDateTime(location, year, month, day, hour, minute, second, millisecond, microsecond);
  }

  /// Returns a [DateFormat].
  DateFormat createDateFormat(String pattern) {
    return new DateFormat(pattern);
  }
}


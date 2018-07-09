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

import '../../common/color.dart' show Color;
import 'processed_series.dart' show ImmutableSeries;

typedef DomainFormatter<D>(D domain);
typedef MeasureFormatter(num measure);

class DatumDetails<D> {
  final dynamic datum;

  /// Domain value of [datum].
  final D domain;

  /// Measure value of [datum].
  final num measure;

  /// The series the [datum] is from.
  final ImmutableSeries<D> series;

  /// The color of this [datum].
  final Color color;

  /// The chart X coordinate for the [datum] from a renderer.
  final double chartX;

  /// The chart Y coordinate for the [datum] from a renderer.
  final double chartY;

  /// Distance of [domain] from a given x, y coordinates.
  final double domainDistance;

  /// Distance of [measure] from a given x, y coordinates.
  final double measureDistance;

  /// Optional formatter for [domain].
  DomainFormatter<D> domainFormatter;

  /// Optional formatter for [measure].
  MeasureFormatter measureFormatter;

  DatumDetails(
      {this.datum,
      this.domain,
      this.measure,
      this.series,
      this.color,
      this.chartX,
      this.chartY,
      this.domainDistance,
      this.measureDistance});

  String get formattedDomain =>
      (domainFormatter != null) ? domainFormatter(domain) : domain.toString();

  String get formattedMeasure => (measureFormatter != null)
      ? measureFormatter(measure)
      : measure.toString();
}

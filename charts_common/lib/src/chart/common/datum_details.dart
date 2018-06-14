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

import 'dart:math' show Point;

import '../../common/color.dart' show Color;
import 'processed_series.dart' show ImmutableSeries;

typedef String DomainFormatter<D>(D domain);
typedef String MeasureFormatter(num measure);

/// Represents processed rendering details for a data point from a series.
class DatumDetails<D> {
  final dynamic datum;

  /// The index of the datum in the series.
  final int index;

  /// Domain value of [datum].
  final D domain;

  /// Domain lower bound value of [datum]. This may represent an error bound, or
  /// a previous domain value.
  final D domainLowerBound;

  /// Domain upper bound value of [datum]. This may represent an error bound, or
  /// a target domain value.
  final D domainUpperBound;

  /// Measure value of [datum].
  final num measure;

  /// Measure lower bound value of [datum]. This may represent an error bound,
  /// or a previous value.
  final num measureLowerBound;

  /// Measure upper bound value of [datum]. This may represent an error bound,
  /// or a target measure value.
  final num measureUpperBound;

  /// Measure offset value of [datum].
  final num measureOffset;

  /// Original measure value of [datum]. This may differ from [measure] if a
  /// behavior attached to a chart automatically adjusts measure values.
  final num rawMeasure;

  /// Original measure lower bound value of [datum]. This may differ from
  /// [measureLowerBound] if a behavior attached to a chart automatically
  /// adjusts measure values.
  final num rawMeasureLowerBound;

  /// Original measure upper bound value of [datum]. This may differ from
  /// [measureUpperBound] if a behavior attached to a chart automatically
  /// adjusts measure values.
  final num rawMeasureUpperBound;

  /// The series the [datum] is from.
  final ImmutableSeries<D> series;

  /// The color of this [datum].
  final Color color;

  /// The chart position of the (domain, measure) for the [datum] from a
  /// renderer.
  final Point<double> chartPosition;

  /// The chart position of the (domainLowerBound, measureLowerBound) for the
  /// [datum] from a renderer.
  final Point<double> chartPositionLower;

  /// The chart position of the (domainUpperBound, measureUpperBound) for the
  /// [datum] from a renderer.
  final Point<double> chartPositionUpper;

  /// Distance of [domain] from a given (x, y) coordinate.
  final double domainDistance;

  /// Distance of [measure] from a given (x, y) coordinate.
  final double measureDistance;

  /// Relative Cartesian distance of ([domain], [measure]) from a given (x, y)
  /// coordinate.
  final double relativeDistance;

  /// The radius of this [datum].
  final double radiusPx;

  /// Optional formatter for [domain].
  DomainFormatter<D> domainFormatter;

  /// Optional formatter for [measure].
  MeasureFormatter measureFormatter;

  DatumDetails(
      {this.datum,
      this.index,
      this.domain,
      this.domainLowerBound,
      this.domainUpperBound,
      this.measure,
      this.measureLowerBound,
      this.measureUpperBound,
      this.measureOffset,
      this.rawMeasure,
      this.rawMeasureLowerBound,
      this.rawMeasureUpperBound,
      this.series,
      this.color,
      this.chartPosition,
      this.chartPositionLower,
      this.chartPositionUpper,
      this.domainDistance,
      this.measureDistance,
      this.relativeDistance,
      this.radiusPx});

  factory DatumDetails.from(DatumDetails<D> other,
      {D datum,
      int index,
      D domain,
      D domainLowerBound,
      D domainUpperBound,
      num measure,
      num measureLowerBound,
      num measureUpperBound,
      num measureOffset,
      num rawMeasure,
      num rawMeasureLowerBound,
      num rawMeasureUpperBound,
      ImmutableSeries<D> series,
      Color color,
      Point<double> chartPosition,
      Point<double> chartPositionLower,
      Point<double> chartPositionUpper,
      double domainDistance,
      double measureDistance,
      double radiusPx}) {
    return new DatumDetails<D>(
        datum: datum ?? other.datum,
        index: index ?? other.index,
        domain: domain ?? other.domain,
        domainLowerBound: domainLowerBound ?? other.domainLowerBound,
        domainUpperBound: domainUpperBound ?? other.domainUpperBound,
        measure: measure ?? other.measure,
        measureLowerBound: measureLowerBound ?? other.measureLowerBound,
        measureUpperBound: measureUpperBound ?? other.measureUpperBound,
        measureOffset: measureOffset ?? other.measureOffset,
        rawMeasure: rawMeasure ?? other.rawMeasure,
        rawMeasureLowerBound:
            rawMeasureLowerBound ?? other.rawMeasureLowerBound,
        rawMeasureUpperBound:
            rawMeasureUpperBound ?? other.rawMeasureUpperBound,
        series: series ?? other.series,
        color: color ?? other.color,
        chartPosition: chartPosition ?? other.chartPosition,
        chartPositionLower: chartPositionLower ?? other.chartPositionLower,
        chartPositionUpper: chartPositionUpper ?? other.chartPositionUpper,
        domainDistance: domainDistance ?? other.domainDistance,
        measureDistance: measureDistance ?? other.measureDistance,
        radiusPx: radiusPx ?? other.radiusPx);
  }

  String get formattedDomain =>
      (domainFormatter != null) ? domainFormatter(domain) : domain.toString();

  String get formattedMeasure => (measureFormatter != null)
      ? measureFormatter(measure)
      : measure.toString();
}

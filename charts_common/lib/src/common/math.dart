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

import 'dart:math' show max, min, sqrt, Point;
import 'package:vector_math/vector_math.dart' show Vector2;

const _defaultEpsilon = 2e-10;

/// Takes a value along with an upper and lower bound and returns whether or not
/// the value falls inclusively within the bounds.
///
/// [value] The input number.
/// [lowerBound] The lower bound.
/// [upperBound] The upper bound.
/// [epsilon] Maximum valid difference between [value] and the bounds. Defaults
/// to 2e-10.
bool withinBounds(num value, num lowerBound, num upperBound,
    {double epsilon = _defaultEpsilon}) {
  return value + epsilon >= lowerBound && value - epsilon <= upperBound;
}

/// Takes a number and clamps it to within the provided bounds.
///
/// Returns the input number if it is within bounds, or the nearest number
/// within the bounds.
///
/// [value] The input number.
/// [minValue] The minimum value to return.
/// [maxValue] The maximum value to return.
num clamp(num value, num minValue, num maxValue) {
  return min(max(value, minValue), maxValue);
}

/// Returns the minimum distance between point p and the line segment vw.
///
/// [p] The point.
/// [v] Start point for the line segment.
/// [w] End point for the line segment.
double distanceBetweenPointAndLineSegment(Vector2 p, Vector2 v, Vector2 w) {
  return sqrt(distanceBetweenPointAndLineSegmentSquared(p, v, w));
}

/// Returns the squared minimum distance between point p and the line segment
/// vw.
///
/// [p] The point.
/// [v] Start point for the line segment.
/// [w] End point for the line segment.
double distanceBetweenPointAndLineSegmentSquared(
    Vector2 p, Vector2 v, Vector2 w) {
  final lineLength = v.distanceToSquared(w);

  if (lineLength == 0) {
    return p.distanceToSquared(v);
  }

  var t0 = (p - v).dot(w - v) / lineLength;
  t0 = max(0.0, min(1.0, t0));

  final projection = v + ((w - v) * t0);

  return p.distanceToSquared(projection);
}

/// A two-dimensional cartesian coordinate pair with potentially null coordinate
/// values.
class NullablePoint {
  final double? x;
  final double? y;

  /// Creates a point with the provided [x] and [y] coordinates.
  const NullablePoint(this.x, this.y);

  /// Creates a [NullablePoint] from a [Point].
  NullablePoint.from(Point<double>? point) : this(point?.x, point?.y);

  @override
  String toString() => 'NullablePoint($x, $y)';

  /// Whether [other] is a point with the same coordinates as this point.
  ///
  /// Returns `true` if [other] is a [NullablePoint] with [x] and [y]
  /// coordinates equal to the corresponding coordinates of this point,
  /// and `false` otherwise.
  @override
  bool operator ==(Object other) =>
      other is NullablePoint && x == other.x && y == other.y;

  @override
  int get hashCode => x.hashCode * 37 + y.hashCode;

  /// Converts this to a [Point].
  ///
  /// Throws if [x] or [y] is null.
  Point<double> toPoint() {
    assert(x != null);
    assert(y != null);
    return Point<double>(x!, y!);
  }
}

extension NullablePointsToPoints on Iterable<NullablePoint> {
  /// Converts an [Iterable] of [NullablePoint]s to a [List] of [Point]s.
  ///
  /// Any [NullablePoint]s that have null values will be filtered out.
  List<Point<double>> toPoints() {
    return [
      for (final nullablePoint in this)
        if (nullablePoint.x != null && nullablePoint.y != null)
          nullablePoint.toPoint(),
    ];
  }
}

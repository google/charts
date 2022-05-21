import 'dart:math';
import 'dart:ui';

/**
 * original code from
 * https://github.com/123lxw123/charts/blob/dev/charts_flutter/lib/src/util/monotonex.dart
 */
class MonotoneX {
  // Calculate a one-sided slope.
  static double _slope2(double x0, double y0, double x1, double y1, double t) {
    var h = x1 - x0;
    return h != 0 ? (3 * (y1 - y0) / h - t) / 2 : t;
  }

  static double _slope3(
      double x0, double y0, double x1, double y1, double x2, double y2) {
    double h0 = x1 - x0;
    double h1 = x2 - x1;
    double s0 = (y1 - y0) /
        (h0 != 0 ? h0 : (h1 < 0 ? -double.infinity : double.infinity));
    double s1 = (y2 - y1) /
        (h1 != 0 ? h1 : (h0 < 0 ? -double.infinity : double.infinity));
    double p = (s0 * h1 + s1 * h0) / (h0 + h1);
    return (s0.sign + s1.sign) *
        [s0.abs(), s1.abs(), 0.5 * p.abs()].reduce(min);
  }

  // According to https://en.wikipedia.org/wiki/Cubic_Hermite_spline#Representations
  // "you can express cubic Hermite interpolation in terms of cubic Bézier curves
  // with respect to the four values p0, p0 + m0 / 3, p1 - m1 / 3, p1".
  static Path _point(Path path, double x0, double y0, double x1, double y1,
      double t0, double t1) {
    var dx = (x1 - x0) / 3;
    path.cubicTo(x0 + dx, y0 + dx * t0, x1 - dx, y1 - dx * t1, x1, y1);
    return path;
  }

  static Path addCurve(Path path, List<Point> points, [bool reversed = false]) {
    if (points.length < 1) return path;

    var targetPoints = List.from(points);
    targetPoints.add(Point(
        points[points.length - 1].x * 2, points[points.length - 1].y * 2));
    double x0, y0, x1, y1, t0, t1, x, y;

    /**
     * arr= [[x0, y0, x1, y1, t0=slope2, t1=slope3], [],.... []]
     */
    List<List<double>> arr = [];

    x0 = targetPoints[0].x as double;
    y0 = targetPoints[0].y as double;

    x1 = targetPoints[1].x as double;
    y1 = targetPoints[1].y as double;

    x = targetPoints[2].x as double;
    y = targetPoints[2].y as double;

    t1 = _slope3(x0, y0, x1, y1, x, y);
    arr.add([x0, y0, x1, y1, _slope2(x0, y0, x1, y1, t1), t1]);

    /**
     *        curve information for point[1]
     * arr= [ [x0, y0, x1, y1, t0=slope2, t1=slope3] ]
     */
    for (int i = 3; i < targetPoints.length; i++) {
      x0 = x1;
      y0 = y1;
      x1 = x;
      y1 = y;
      t0 = t1;

      x = targetPoints[i].x as double;
      y = targetPoints[i].y as double;
      if (x == x1 && y == y1) continue;
      t1 = _slope3(x0, y0, x1, y1, x, y);
      arr.add([x0, y0, x1, y1, t0, t1]);
    }
    if (reversed) {
      arr.reversed.forEach((f) {
        /**
       * f: [ x1, y1, x0, y0, t1=slope3, t0=slope2]
       */
        _point(path, f[2], f[3], f[0], f[1], f[5], f[4]);
      });
    } else {
      /**
       * f: [x0, y0, x1, y1, t0=slope2, t1=slope3]
       */
      arr.forEach((f) {
        _point(path, f[0], f[1], f[2], f[3], f[4], f[5]);
      });
    }
    return path;
  }
}

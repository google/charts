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

import 'dart:collection' show LinkedHashMap;
import 'dart:math' show Point;

import 'package:meta/meta.dart' show required;

import '../cartesian/axis/axis.dart'
    show ImmutableAxis, domainAxisKey, measureAxisKey;
import '../cartesian/cartesian_renderer.dart' show BaseCartesianRenderer;
import '../common/chart_canvas.dart' show ChartCanvas, getAnimatedColor;
import '../common/datum_details.dart' show DatumDetails;
import '../common/processed_series.dart' show ImmutableSeries, MutableSeries;
import '../../common/color.dart' show Color;
import '../../data/series.dart' show AttributeKey;
import 'line_renderer_config.dart' show LineRendererConfig;

const lineElementsKey =
    const AttributeKey<List<_LineRendererElement>>('LineRenderer.elements');

class LineRenderer<T, D> extends BaseCartesianRenderer<T, D> {
  final LineRendererConfig config;

  /// Store a map of series drawn on the chart, mapped by series name.
  ///
  /// [LinkedHashMap] is used to render the series on the canvas in the same
  /// order as the data was given to the chart.
  final _seriesLineMap = new LinkedHashMap<String, List<_AnimatedLine<T, D>>>();

  // Store a list of lines that exist in the series data.
  //
  // This list will be used to remove any [_AnimatedLine] that were rendered in
  // previous draw cycles, but no longer have a corresponding datum in the new
  // data.
  final _currentKeys = <String>[];

  LineRenderer({String rendererId, LineRendererConfig config})
      : this.config = config ?? new LineRendererConfig(),
        super(
            rendererId: rendererId ?? 'line',
            layoutPositionOrder: 10,
            symbolRenderer: config?.symbolRenderer);

  void preprocessSeries(List<MutableSeries<T, D>> seriesList) {
    assignMissingColors(seriesList, emptyCategoryUsesSinglePalette: false);

    seriesList.forEach((MutableSeries<T, D> series) {
      var elements = <_LineRendererElement<T, D>>[];

      var strokeWidthPxFn = series.strokeWidthPxFn;

      if (series.dashPattern == null) {
        series.dashPattern = config.dashPattern;
      }

      var details = new _LineRendererElement<T, D>();

      // Since we do not currently support segments for lines, just grab the
      // stroke width from the first datum for each series.
      //
      // TODO: Support stroke width per datum with line segments.
      if (series.data.length > 0 && strokeWidthPxFn != null) {
        T datum = series.data[0];
        details.strokeWidthPx = strokeWidthPxFn(datum, 0).toDouble();
      } else {
        details.strokeWidthPx = this.config.strokeWidthPx;
      }

      elements.add(details);

      series.setAttr(lineElementsKey, elements);
    });
  }

  void update(
      List<ImmutableSeries<T, D>> seriesList, bool isAnimatingThisDraw) {
    _currentKeys.clear();

    seriesList.forEach((ImmutableSeries<T, D> series) {
      var domainAxis = series.getAttr(domainAxisKey) as ImmutableAxis<D>;
      var domainFn = series.domainFn;
      var measureAxis = series.getAttr(measureAxisKey) as ImmutableAxis<num>;
      var measureFn = series.measureFn;
      var measureOffsetFn = series.measureOffsetFn;
      var colorFn = series.colorFn;
      var lineKey = series.id;
      var dashPattern = series.dashPattern;

      // TODO: Handle changes in data color, pattern, or other
      // attributes by configuring a list of line segments for the series,
      // instead of just one big line that contains all the points.
      var lineList = _seriesLineMap.putIfAbsent(lineKey, () => []);

      var elementsList = series.getAttr(lineElementsKey);
      _LineRendererElement details = elementsList[0];

      // If we already have a AnimatingLine for that index, use it.
      _AnimatedLine<T, D> animatingLine;
      if (lineList.length > 0) {
        animatingLine = lineList[0];
      } else {
        // Create a new line and have it animate in from axis.
        var pointList = <_DatumPoint<T, D>>[];
        Color color;
        for (var index = 0; index < series.data.length; index++) {
          T datum = series.data[index];

          pointList.add(_getPoint(datum, domainFn(datum, index), series,
              domainAxis, 0.0, 0.0, measureAxis));

          color = colorFn(series.data[index], index);
        }

        animatingLine = new _AnimatedLine<T, D>(
            key: lineKey, overlaySeries: series.overlaySeries)
          ..setNewTarget(new _LineRendererElement<T, D>()
            ..color = color
            ..points = pointList
            ..dashPattern = dashPattern
            ..measureAxisPosition = measureAxis.getLocation(0.0)
            ..strokeWidthPx = details.strokeWidthPx);

        lineList.add(animatingLine);
      }

      // Create a new line using the final point locations.
      var pointList = <_DatumPoint<T, D>>[];
      Color color;
      for (var index = 0; index < series.data.length; index++) {
        T datum = series.data[index];

        pointList.add(_getPoint(
            datum,
            domainFn(datum, index),
            series,
            domainAxis,
            measureFn(datum, index),
            measureOffsetFn(datum, index),
            measureAxis));

        color = colorFn(series.data[index], index);
      }

      // Update the set of lines that still exist in the series data.
      _currentKeys.add(lineKey);

      // Get the lineElement we are going to setup.
      final lineElement = new _LineRendererElement<T, D>()
        ..points = pointList
        ..color = color
        ..dashPattern = dashPattern
        ..measureAxisPosition = measureAxis.getLocation(0.0)
        ..strokeWidthPx = details.strokeWidthPx;

      animatingLine.setNewTarget(lineElement);
    });

    // Animate out lines that don't exist anymore.
    _seriesLineMap.forEach((String key, List<_AnimatedLine<T, D>> lines) {
      for (var line in lines) {
        if (_currentKeys.contains(line.key) != true) {
          line.animateOut();
        }
      }
    });
  }

  void paint(ChartCanvas canvas, double animationPercent) {
    // Clean up the lines that no longer exist.
    if (animationPercent == 1.0) {
      final keysToRemove = <String>[];

      _seriesLineMap.forEach((String key, List<_AnimatedLine<T, D>> lines) {
        lines.removeWhere((_AnimatedLine<T, D> line) => line.animatingOut);

        if (lines.isEmpty) {
          keysToRemove.add(key);
        }
      });

      keysToRemove.forEach((String key) => _seriesLineMap.remove(key));
    }

    _seriesLineMap.forEach((String key, List<_AnimatedLine<T, D>> lines) {
      lines
          .map<_LineRendererElement<T, D>>(
              (_AnimatedLine<T, D> animatingLine) =>
                  animatingLine.getCurrentLine(animationPercent))
          .forEach((_LineRendererElement line) {
        canvas.drawLine(
            dashPattern: line.dashPattern,
            points: line.points,
            stroke: line.color,
            strokeWidthPx: line.strokeWidthPx);
      });
    });
  }

  _DatumPoint<T, D> _getPoint(
      T datum,
      D domainValue,
      ImmutableSeries<T, D> series,
      ImmutableAxis<D> domainAxis,
      num measureValue,
      num measureOffsetValue,
      ImmutableAxis<num> measureAxis) {
    final domainPosition = domainAxis.getLocation(domainValue);

    final measurePosition =
        measureAxis.getLocation(measureValue + measureOffsetValue);

    return new _DatumPoint<T, D>(
        datum: datum,
        domain: domainValue,
        series: series,
        x: domainPosition,
        y: measurePosition);
  }

  @override
  List<DatumDetails<T, D>> getNearestDatumDetailPerSeries(
      Point<double> chartPoint) {
    final nearest = <DatumDetails<T, D>>[];

    // Was it even in the drawArea?
    if (!componentBounds.containsPoint(chartPoint)) {
      return nearest;
    }

    _seriesLineMap.values.forEach((List<_AnimatedLine<T, D>> seriesSegments) {
      _DatumPoint<T, D> nearestPoint;
      double nearestDomainDistance = 10000.0;
      double nearestMeasureDistance = 10000.0;

      seriesSegments.forEach((_AnimatedLine<T, D> segment) {
        if (segment.overlaySeries) {
          return;
        }

        segment._currentLine.points.forEach((Point p) {
          // Don't look at points not in the drawArea.
          if (p.x < componentBounds.left || p.x > componentBounds.right) {
            return;
          }

          final domainDistance = (p.x - chartPoint.x).abs();
          final measureDistance = (p.y - chartPoint.y).abs();
          if ((domainDistance < nearestDomainDistance) ||
              ((domainDistance == nearestDomainDistance &&
                  measureDistance < nearestMeasureDistance))) {
            nearestPoint = p;
            nearestDomainDistance = domainDistance;
            nearestMeasureDistance = measureDistance;
          }
        });
      });

      // Found a point, add it to the list.
      if (nearestPoint != null) {
        nearest.add(new DatumDetails<T, D>(
            datum: nearestPoint.datum,
            domain: nearestPoint.domain,
            series: nearestPoint.series,
            domainDistance: nearestDomainDistance,
            measureDistance: nearestMeasureDistance));
      }
    });

    // Note: the details are already sorted by domain & measure distance in
    // base chart.

    return nearest;
  }
}

class _DatumPoint<T, D> extends Point<double> {
  final T datum;
  final D domain;
  final ImmutableSeries<T, D> series;

  _DatumPoint({this.datum, this.domain, this.series, double x, double y})
      : super(x, y);

  factory _DatumPoint.from(_DatumPoint<T, D> other, [double x, double y]) {
    return new _DatumPoint<T, D>(
        datum: other.datum,
        domain: other.domain,
        series: other.series,
        x: x ?? other.x,
        y: y ?? other.y);
  }
}

class _LineRendererElement<T, D> {
  List<_DatumPoint<T, D>> points;
  Color color;
  List<int> dashPattern;
  double measureAxisPosition;
  double strokeWidthPx;

  _LineRendererElement<T, D> clone() {
    return new _LineRendererElement<T, D>()
      ..points = this.points
      ..color = this.color
      ..dashPattern = this.dashPattern
      ..measureAxisPosition = this.measureAxisPosition
      ..strokeWidthPx = this.strokeWidthPx;
  }

  void updateAnimationPercent(_LineRendererElement previous,
      _LineRendererElement target, double animationPercent) {
    Point lastPoint;

    int pointIndex;
    for (pointIndex = 0; pointIndex < target.points.length; pointIndex++) {
      var targetPoint = target.points[pointIndex];

      // If we have more points than the previous line, animate in the new point
      // by starting its measure position at the last known official point.
      // TODO: Can this be done in setNewTarget instead?
      _DatumPoint<T, D> previousPoint;
      if (previous.points.length - 1 >= pointIndex) {
        previousPoint = previous.points[pointIndex];
        lastPoint = previousPoint;
      } else {
        previousPoint =
            new _DatumPoint<T, D>.from(targetPoint, targetPoint.x, lastPoint.y);
      }

      var x = ((targetPoint.x - previousPoint.x) * animationPercent) +
          previousPoint.x;

      var y = ((targetPoint.y - previousPoint.y) * animationPercent) +
          previousPoint.y;

      if (points.length - 1 >= pointIndex) {
        points[pointIndex] = new _DatumPoint<T, D>.from(targetPoint, x, y);
      } else {
        points.add(new _DatumPoint<T, D>.from(targetPoint, x, y));
      }
    }

    // Removing extra points that don't exist anymore.
    if (pointIndex < points.length) {
      points.removeRange(pointIndex, points.length);
    }

    color = getAnimatedColor(previous.color, target.color, animationPercent);

    strokeWidthPx =
        (((target.strokeWidthPx - previous.strokeWidthPx) * animationPercent) +
            previous.strokeWidthPx);
  }
}

class _AnimatedLine<T, D> {
  final String key;
  final bool overlaySeries;

  _LineRendererElement<T, D> _previousLine;
  _LineRendererElement<T, D> _targetLine;
  _LineRendererElement<T, D> _currentLine;

  // Flag indicating whether this line is being animated out of the chart.
  bool animatingOut = false;

  _AnimatedLine({@required this.key, @required this.overlaySeries});

  /// Animates a line that was removed from the series out of the view.
  ///
  /// This should be called in place of "setNewTarget" for lines that represent
  /// data that has been removed from the series.
  ///
  /// Animates the height of the line down to the measure axis position
  /// (position of 0).
  void animateOut() {
    var newTarget = _currentLine.clone();

    // Set the target measure value to the axis position for all points.
    var newPoints = <_DatumPoint<T, D>>[];
    for (var index = 0; index < newTarget.points.length; index++) {
      var targetPoint = newTarget.points[index];

      newPoints.add(new _DatumPoint<T, D>.from(targetPoint, targetPoint.x,
          newTarget.measureAxisPosition.roundToDouble()));
    }

    newTarget.points = newPoints;

    // Animate the stroke width to 0 so that we don't get a lingering line after
    // animation is done.
    newTarget.strokeWidthPx = 0.0;

    setNewTarget(newTarget);
    animatingOut = true;
  }

  void setNewTarget(_LineRendererElement<T, D> newTarget) {
    animatingOut = false;
    _currentLine ??= newTarget.clone();
    _previousLine = _currentLine;
    _targetLine = newTarget;
  }

  _LineRendererElement<T, D> getCurrentLine(double animationPercent) {
    if (animationPercent == 1.0 || _previousLine == null) {
      _currentLine = _targetLine;
      _previousLine = _targetLine;
      return _currentLine;
    }

    _currentLine.updateAnimationPercent(
        _previousLine, _targetLine, animationPercent);

    return _currentLine;
  }
}

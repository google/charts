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
import 'dart:math' show Rectangle, Point;

import 'package:meta/meta.dart' show required;

import '../cartesian/axis/axis.dart'
    show ImmutableAxis, domainAxisKey, measureAxisKey;
import '../cartesian/cartesian_renderer.dart' show BaseCartesianRenderer;
import '../common/chart_canvas.dart' show ChartCanvas, getAnimatedColor;
import '../common/datum_details.dart' show DatumDetails;
import '../common/processed_series.dart' show ImmutableSeries, MutableSeries;
import '../scatter_plot/point_renderer.dart' show PointRenderer;
import '../scatter_plot/point_renderer_config.dart' show PointRendererConfig;
import '../../common/color.dart' show Color;
import '../../data/series.dart' show AttributeKey;
import 'line_renderer_config.dart' show LineRendererConfig;

const lineElementsKey =
    const AttributeKey<List<_LineRendererElement>>('LineRenderer.elements');

class LineRenderer<D> extends BaseCartesianRenderer<D> {
  final LineRendererConfig config;

  PointRenderer _pointRenderer;

  /// Store a map of series drawn on the chart, mapped by series name.
  ///
  /// [LinkedHashMap] is used to render the series on the canvas in the same
  /// order as the data was given to the chart.
  final _seriesLineMap = new LinkedHashMap<String, List<_AnimatedLine<D>>>();

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
            symbolRenderer: config?.symbolRenderer) {
    _pointRenderer = new PointRenderer<D>(
        config: new PointRendererConfig<D>(radiusPx: this.config.radiusPx));
  }

  @override
  void layout(Rectangle<int> componentBounds, Rectangle<int> drawAreaBounds) {
    super.layout(componentBounds, drawAreaBounds);

    if (config.includePoints) {
      _pointRenderer.layout(componentBounds, drawAreaBounds);
    }
  }

  @override
  void configureSeries(List<MutableSeries<D>> seriesList) {
    assignMissingColors(seriesList, emptyCategoryUsesSinglePalette: false);

    if (config.includePoints) {
      _pointRenderer.configureSeries(seriesList);
    }
  }

  @override
  void preprocessSeries(List<MutableSeries<D>> seriesList) {
    seriesList.forEach((MutableSeries<D> series) {
      var elements = <_LineRendererElement<D>>[];

      var strokeWidthPxFn = series.strokeWidthPxFn;

      if (series.dashPattern == null) {
        series.dashPattern = config.dashPattern;
      }

      var details = new _LineRendererElement<D>();

      // Since we do not currently support segments for lines, just grab the
      // stroke width from the first datum for each series.
      //
      // TODO: Support stroke width per datum with line segments.
      if (series.data.length > 0 && strokeWidthPxFn != null) {
        details.strokeWidthPx = strokeWidthPxFn(0).toDouble();
      } else {
        details.strokeWidthPx = this.config.strokeWidthPx;
      }

      elements.add(details);

      series.setAttr(lineElementsKey, elements);
    });

    if (config.includePoints) {
      _pointRenderer.preprocessSeries(seriesList);
    }
  }

  void update(List<ImmutableSeries<D>> seriesList, bool isAnimatingThisDraw) {
    _currentKeys.clear();

    seriesList.forEach((ImmutableSeries<D> series) {
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
      _AnimatedLine<D> animatingLine;
      if (lineList.length > 0) {
        animatingLine = lineList[0];
      } else {
        // Create a new line and have it animate in from axis.
        var pointList = <_DatumPoint<D>>[];
        Color color;
        for (var index = 0; index < series.data.length; index++) {
          final datum = series.data[index];

          pointList.add(_getPoint(datum, domainFn(index), series, domainAxis,
              0.0, 0.0, measureAxis));

          color = colorFn(index);
        }

        animatingLine = new _AnimatedLine<D>(
            key: lineKey, overlaySeries: series.overlaySeries)
          ..setNewTarget(new _LineRendererElement<D>()
            ..color = color
            ..points = pointList
            ..dashPattern = dashPattern
            ..measureAxisPosition = measureAxis.getLocation(0.0)
            ..strokeWidthPx = details.strokeWidthPx);

        lineList.add(animatingLine);
      }

      // Create a new line using the final point locations.
      var pointList = <_DatumPoint<D>>[];
      Color color;
      for (var index = 0; index < series.data.length; index++) {
        final datum = series.data[index];

        final datumPoint = _getPoint(datum, domainFn(index), series, domainAxis,
            measureFn(index), measureOffsetFn(index), measureAxis);

        // Only add the point if it is within the draw area bounds.
        if (datumPoint.x != null &&
            datumPoint.x >= drawBounds.left &&
            datumPoint.x <= drawBounds.right) {
          pointList.add(datumPoint);
        }

        color = colorFn(index);
      }

      // Update the set of lines that still exist in the series data.
      _currentKeys.add(lineKey);

      // Get the lineElement we are going to setup.
      final lineElement = new _LineRendererElement<D>()
        ..points = pointList
        ..color = color
        ..dashPattern = dashPattern
        ..measureAxisPosition = measureAxis.getLocation(0.0)
        ..strokeWidthPx = details.strokeWidthPx;

      animatingLine.setNewTarget(lineElement);
    });

    // Animate out lines that don't exist anymore.
    _seriesLineMap.forEach((String key, List<_AnimatedLine<D>> lines) {
      for (var line in lines) {
        if (_currentKeys.contains(line.key) != true) {
          line.animateOut();
        }
      }
    });

    if (config.includePoints) {
      _pointRenderer.update(seriesList, isAnimatingThisDraw);
    }
  }

  void paint(ChartCanvas canvas, double animationPercent) {
    // Clean up the lines that no longer exist.
    if (animationPercent == 1.0) {
      final keysToRemove = <String>[];

      _seriesLineMap.forEach((String key, List<_AnimatedLine<D>> lines) {
        lines.removeWhere((_AnimatedLine<D> line) => line.animatingOut);

        if (lines.isEmpty) {
          keysToRemove.add(key);
        }
      });

      keysToRemove.forEach((String key) => _seriesLineMap.remove(key));
    }

    _seriesLineMap.forEach((String key, List<_AnimatedLine<D>> lines) {
      lines
          .map<_LineRendererElement<D>>((_AnimatedLine<D> animatingLine) =>
              animatingLine.getCurrentLine(animationPercent))
          .forEach((_LineRendererElement line) {
        canvas.drawLine(
            dashPattern: line.dashPattern,
            points: line.points,
            stroke: line.color,
            strokeWidthPx: line.strokeWidthPx);
      });
    });

    if (config.includePoints) {
      _pointRenderer.paint(canvas, animationPercent);
    }
  }

  _DatumPoint<D> _getPoint(
      dynamic datum,
      D domainValue,
      ImmutableSeries<D> series,
      ImmutableAxis<D> domainAxis,
      num measureValue,
      num measureOffsetValue,
      ImmutableAxis<num> measureAxis) {
    final domainPosition = domainAxis.getLocation(domainValue);

    final measurePosition =
        measureAxis.getLocation(measureValue + measureOffsetValue);

    return new _DatumPoint<D>(
        datum: datum,
        domain: domainValue,
        series: series,
        x: domainPosition,
        y: measurePosition);
  }

  @override
  List<DatumDetails<D>> getNearestDatumDetailPerSeries(
      Point<double> chartPoint) {
    final nearest = <DatumDetails<D>>[];

    // Was it even in the drawArea?
    if (!componentBounds.containsPoint(chartPoint)) {
      return nearest;
    }

    _seriesLineMap.values.forEach((List<_AnimatedLine<D>> seriesSegments) {
      _DatumPoint<D> nearestPoint;
      double nearestDomainDistance = 10000.0;
      double nearestMeasureDistance = 10000.0;

      seriesSegments.forEach((_AnimatedLine<D> segment) {
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
        nearest.add(new DatumDetails<D>(
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

class _DatumPoint<D> extends Point<double> {
  final dynamic datum;
  final D domain;
  final ImmutableSeries<D> series;

  _DatumPoint({this.datum, this.domain, this.series, double x, double y})
      : super(x, y);

  factory _DatumPoint.from(_DatumPoint<D> other, [double x, double y]) {
    return new _DatumPoint<D>(
        datum: other.datum,
        domain: other.domain,
        series: other.series,
        x: x ?? other.x,
        y: y ?? other.y);
  }
}

class _LineRendererElement<D> {
  List<_DatumPoint<D>> points;
  Color color;
  List<int> dashPattern;
  double measureAxisPosition;
  double strokeWidthPx;

  _LineRendererElement<D> clone() {
    return new _LineRendererElement<D>()
      ..points = new List<_DatumPoint<D>>.from(points)
      ..color = color != null ? new Color.fromOther(color: color) : null
      ..dashPattern =
          dashPattern != null ? new List<int>.from(dashPattern) : null
      ..measureAxisPosition = measureAxisPosition
      ..strokeWidthPx = strokeWidthPx;
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
      _DatumPoint<D> previousPoint;
      if (previous.points.length - 1 >= pointIndex) {
        previousPoint = previous.points[pointIndex];
        lastPoint = previousPoint;
      } else {
        previousPoint =
            new _DatumPoint<D>.from(targetPoint, targetPoint.x, lastPoint.y);
      }

      var x = ((targetPoint.x - previousPoint.x) * animationPercent) +
          previousPoint.x;

      var y = ((targetPoint.y - previousPoint.y) * animationPercent) +
          previousPoint.y;

      if (points.length - 1 >= pointIndex) {
        points[pointIndex] = new _DatumPoint<D>.from(targetPoint, x, y);
      } else {
        points.add(new _DatumPoint<D>.from(targetPoint, x, y));
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

class _AnimatedLine<D> {
  final String key;
  final bool overlaySeries;

  _LineRendererElement<D> _previousLine;
  _LineRendererElement<D> _targetLine;
  _LineRendererElement<D> _currentLine;

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
    var newPoints = <_DatumPoint<D>>[];
    for (var index = 0; index < newTarget.points.length; index++) {
      var targetPoint = newTarget.points[index];

      newPoints.add(new _DatumPoint<D>.from(targetPoint, targetPoint.x,
          newTarget.measureAxisPosition.roundToDouble()));
    }

    newTarget.points = newPoints;

    // Animate the stroke width to 0 so that we don't get a lingering line after
    // animation is done.
    newTarget.strokeWidthPx = 0.0;

    setNewTarget(newTarget);
    animatingOut = true;
  }

  void setNewTarget(_LineRendererElement<D> newTarget) {
    animatingOut = false;
    _currentLine ??= newTarget.clone();
    _previousLine = _currentLine.clone();
    _targetLine = newTarget;
  }

  _LineRendererElement<D> getCurrentLine(double animationPercent) {
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

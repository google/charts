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
import '../common/processed_series.dart'
    show ImmutableSeries, MutableSeries, SeriesDatum;
import '../scatter_plot/point_renderer.dart' show PointRenderer;
import '../scatter_plot/point_renderer_config.dart' show PointRendererConfig;
import '../../common/color.dart' show Color;
import '../../data/series.dart' show AttributeKey;
import 'line_renderer_config.dart' show LineRendererConfig;

const lineElementsKey =
    const AttributeKey<List<_LineRendererElement>>('LineRenderer.lineElements');

class LineRenderer<D> extends BaseCartesianRenderer<D> {
  final LineRendererConfig config;

  PointRenderer _pointRenderer;

  /// Store a map of series drawn on the chart, mapped by series name.
  ///
  /// [LinkedHashMap] is used to render the series on the canvas in the same
  /// order as the data was given to the chart.
  final _seriesLineMap =
      new LinkedHashMap<String, List<_AnimatedElements<D>>>();

  // Store a list of lines that exist in the series data.
  //
  // This list will be used to remove any [_AnimatedLine] that were rendered in
  // previous draw cycles, but no longer have a corresponding datum in the new
  // data.
  final _currentKeys = <String>[];

  factory LineRenderer({String rendererId, LineRendererConfig config}) {
    return new LineRenderer._internal(
        rendererId: rendererId ?? 'line',
        config: config ?? new LineRendererConfig());
  }

  LineRenderer._internal({String rendererId, this.config})
      : super(
            rendererId: rendererId,
            layoutPaintOrder: config.layoutPaintOrder,
            symbolRenderer: config.symbolRenderer) {
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

    // If we are stacking, generate new stacking measure offset functions for
    // each series. Each datum should have a measure offset consisting of the
    // sum of the measure and measure offsets of each datum with the same domain
    // value in series below it in the stack. The first series will be treated
    // as the bottom of the stack.
    if (config.stacked) {
      var curOffsets =
          (seriesList.isEmpty) ? null : _createInitialOffsetMap(seriesList[0]);
      var nextOffsets = <D, num>{};

      for (var i = 0; i < seriesList.length; i++) {
        final series = seriesList[i];
        final measureOffsetFn = _createStackedMeasureOffsetFunction(
            series, curOffsets, nextOffsets);

        if (i > 0) {
          series.measureOffsetFn = measureOffsetFn;
        }

        curOffsets = nextOffsets;
        nextOffsets = <D, num>{};
      }
    }
  }

  /// Creates the initial offsets for the series given the measureOffset values.
  Map<D, num> _createInitialOffsetMap(MutableSeries<D> series) {
    final domainFn = series.domainFn;
    final measureOffsetFn = series.measureOffsetFn;
    final initialOffsets = <D, num>{};

    for (var index = 0; index < series.data.length; index++) {
      final domainValue = domainFn(index);
      initialOffsets[domainValue] = measureOffsetFn(index);
    }

    return initialOffsets;
  }

  /// Function needed to create a closure preserving the previous series
  /// information.  y0 for this series is just y + y0 for previous series as
  /// long as both y and y0 are not null.  If they are null propagate up the
  /// missing/null data.
  Function _createStackedMeasureOffsetFunction(MutableSeries<D> series,
      Map<D, num> curOffsets, Map<D, num> nextOffsets) {
    final domainFn = series.domainFn;
    final measureFn = series.measureFn;

    for (var index = 0; index < series.data.length; index++) {
      final domainValue = domainFn(index);
      final measure = measureFn(index);
      final prevOffset = curOffsets != null ? curOffsets[domainValue] : 0;

      if (measure != null && prevOffset != null) {
        nextOffsets[domainValue] = measure + prevOffset;
      }
    }

    return (int i) {
      final domainValue = domainFn(i);
      return curOffsets != null ? curOffsets[domainValue] : 0;
    };
  }

  void update(List<ImmutableSeries<D>> seriesList, bool isAnimatingThisDraw) {
    _currentKeys.clear();

    // List of final points for the previous line in a stack.
    List<_DatumPoint<D>> previousPointList;

    // List of initial points for the previous line in a stack, animated in from
    // the measure axis.
    List<_DatumPoint<D>> previousInitialPointList;

    seriesList.forEach((ImmutableSeries<D> series) {
      var lineKey = series.id;

      // TODO: Handle changes in data color, pattern, or other
      // attributes by configuring a list of line segments for the series,
      // instead of just one big line that contains all the points.
      var elementsList = _seriesLineMap.putIfAbsent(lineKey, () => []);

      var detailsList = series.getAttr(lineElementsKey);
      _LineRendererElement details = detailsList[0];

      // If we already have an AnimatingLine for that index, use it.
      _AnimatedElements<D> animatingElements;
      if (elementsList.length > 0) {
        animatingElements = elementsList[0];

        previousInitialPointList = animatingElements.line.currentPoints;
      } else {
        // Create a new line and have it animate in from axis.
        final lineAndArea = _getLineAndAreaElements(
            series, details, previousInitialPointList, true);

        // Create the line element.
        final animatingLine = new _AnimatedLine<D>(
            key: lineKey, overlaySeries: series.overlaySeries)
          ..setNewTarget(lineAndArea[0]);

        // Create the area element.
        var animatingArea;
        if (config.includeArea) {
          animatingArea = new _AnimatedArea<D>(
              key: lineKey, overlaySeries: series.overlaySeries)
            ..setNewTarget(lineAndArea[1]);
        }

        animatingElements = new _AnimatedElements<D>()
          ..line = animatingLine
          ..area = animatingArea;

        elementsList.add(animatingElements);

        previousInitialPointList = lineAndArea[0].points;
      }

      // Create a new line using the final point locations.
      final lineAndArea =
          _getLineAndAreaElements(series, details, previousPointList, false);

      animatingElements.line.setNewTarget(lineAndArea[0]);

      if (config.includeArea) {
        animatingElements.area.setNewTarget(lineAndArea[1]);
      }

      // Save the line points for the current series so that we can use them in
      // the area skirt for the next stacked series.
      previousPointList = lineAndArea[0].points;
    });

    // Animate out lines that don't exist anymore.
    _seriesLineMap.forEach((String key, List<_AnimatedElements<D>> elements) {
      for (var element in elements) {
        if (element.line != null &&
            _currentKeys.contains(element.line.key) != true) {
          element.line.animateOut();
        }
        if (element.area != null &&
            _currentKeys.contains(element.area.key) != true) {
          element.area.animateOut();
        }
      }
    });

    if (config.includePoints) {
      _pointRenderer.update(seriesList, isAnimatingThisDraw);
    }
  }

  /// Creates a [_LineRendererElement] and a [_AreaRendererElement] for a given
  /// segment of a series.
  ///
  /// [details] represents the element details for a line segment. Until
  /// b/70576908 is implemented, there is only one segment for every series.
  ///
  /// [previousPointList] contains the points for the line below this series in
  /// the stack, if stacking is enabled. It forms the bottom edges for the area
  /// skirt.
  ///
  /// [initializeFromZero] controls whether we generate elements with measure
  /// values of 0, or using series data. This should be true when calculating
  /// point positions to animate in from the measure axis.
  List _getLineAndAreaElements(
      ImmutableSeries<D> series,
      _LineRendererElement details,
      List previousPointList,
      bool initializeFromZero) {
    var domainAxis = series.getAttr(domainAxisKey) as ImmutableAxis<D>;
    var domainFn = series.domainFn;
    var measureAxis = series.getAttr(measureAxisKey) as ImmutableAxis<num>;
    var measureFn = series.measureFn;
    var measureOffsetFn = series.measureOffsetFn;
    var colorFn = series.colorFn;
    var lineKey = series.id;
    var dashPattern = series.dashPattern;

    // Create a new line using the final point locations.
    var pointList = <_DatumPoint<D>>[];
    var areaPointList = <_DatumPoint<D>>[];

    if (config.includeArea && series.data.length > 0) {
      if (!config.stacked || previousPointList == null) {
        // Start area segments at the bottom of a stack by adding a bottom line
        // segment along the measure axis.
        areaPointList.add(_getPoint(null, domainFn(series.data.length - 1),
            series, domainAxis, 0.0, 0.0, measureAxis));

        areaPointList.add(_getPoint(
            null, domainFn(0), series, domainAxis, 0.0, 0.0, measureAxis));
      } else {
        // Start subsequent area segments in a stack by adding the previous
        // points in reverse order, so that we can get a properly closed
        // polygon.
        areaPointList.addAll(previousPointList.reversed);
      }
    }

    // TODO: Use the first datum until we break out line segments.
    Color color = colorFn(0);

    for (var index = 0; index < series.data.length; index++) {
      final datum = series.data[index];

      // TODO: Animate from the nearest lines in the stack.
      final measure = !initializeFromZero ? measureFn(index) : 0.0;
      final measureOffset = !initializeFromZero ? measureOffsetFn(index) : 0.0;

      final datumPoint = _getPoint(datum, domainFn(index), series, domainAxis,
          measure, measureOffset, measureAxis);

      // Only add the point if it is within the draw area bounds.
      if (datumPoint.x != null &&
          datumPoint.x >= drawBounds.left &&
          datumPoint.x <= drawBounds.right) {
        pointList.add(datumPoint);

        // Create points for the area element.
        if (config.includeArea) {
          areaPointList.add(_getPoint(
              datum,
              domainFn(index),
              series,
              domainAxis,
              measureFn(index),
              measureOffsetFn(index),
              measureAxis));
        }
      }
    }

    // Update the set of lines that still exist in the series data.
    _currentKeys.add(lineKey);

    // Get the line element we are going to to set up.
    final lineElement = new _LineRendererElement<D>()
      ..points = pointList
      ..color = color
      ..dashPattern = dashPattern
      ..measureAxisPosition = measureAxis.getLocation(0.0)
      ..strokeWidthPx = details.strokeWidthPx;

    _AreaRendererElement areaElement;

    // Get the area element we are going to set up.
    if (config.includeArea) {
      // Apply opacity to the series color for the area skirt.
      Color areaColor = new Color(
          r: color.r,
          g: color.g,
          b: color.b,
          a: (color.a * config.areaOpacity).round());

      areaElement = new _AreaRendererElement<D>()
        ..points = areaPointList
        ..color = areaColor
        ..measureAxisPosition = measureAxis.getLocation(0.0);
    }

    return [lineElement, areaElement];
  }

  void paint(ChartCanvas canvas, double animationPercent) {
    // Clean up the lines that no longer exist.
    if (animationPercent == 1.0) {
      final keysToRemove = <String>[];

      _seriesLineMap.forEach((String key, List<_AnimatedElements<D>> elements) {
        elements.removeWhere(
            (_AnimatedElements<D> element) => element.animatingOut);

        if (elements.isEmpty) {
          keysToRemove.add(key);
        }
      });

      keysToRemove.forEach((String key) => _seriesLineMap.remove(key));
    }

    _seriesLineMap.forEach((String key, List<_AnimatedElements<D>> elements) {
      elements
          .map<_AreaRendererElement<D>>(
              (_AnimatedElements<D> animatingElement) =>
                  animatingElement.area?.getCurrentArea(animationPercent))
          .forEach((_AreaRendererElement area) {
        if (area != null) {
          canvas.drawPolygon(points: area.points, fill: area.color);
        }
      });

      elements
          .map<_LineRendererElement<D>>(
              (_AnimatedElements<D> animatingElement) =>
                  animatingElement.line?.getCurrentLine(animationPercent))
          .forEach((_LineRendererElement line) {
        if (line != null) {
          canvas.drawLine(
              dashPattern: line.dashPattern,
              points: line.points,
              stroke: line.color,
              strokeWidthPx: line.strokeWidthPx);
        }
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

    // TODO: Support null measure values.
    measureValue ??= 0;

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
      Point<double> chartPoint, bool byDomain, Rectangle<int> boundsOverride) {
    final nearest = <DatumDetails<D>>[];

    // Was it even in the component bounds?
    if (!isPointWithinBounds(chartPoint, boundsOverride)) {
      return nearest;
    }

    _seriesLineMap.values.forEach((List<_AnimatedElements<D>> seriesSegments) {
      _DatumPoint<D> nearestPoint;
      double nearestDomainDistance = 10000.0;
      double nearestMeasureDistance = 10000.0;
      double nearestRelativeDistance = 10000.0;

      seriesSegments.forEach((_AnimatedElements<D> segment) {
        if (segment.overlaySeries) {
          return;
        }

        segment.line._currentLine.points.forEach((Point p) {
          // Don't look at points not in the drawArea.
          if (p.x < componentBounds.left || p.x > componentBounds.right) {
            return;
          }

          final domainDistance = (p.x - chartPoint.x).abs();
          final measureDistance = (p.y - chartPoint.y).abs();
          final relativeDistance = chartPoint.distanceTo(p);

          if (byDomain) {
            if ((domainDistance < nearestDomainDistance) ||
                ((domainDistance == nearestDomainDistance &&
                    measureDistance < nearestMeasureDistance))) {
              nearestPoint = p;
              nearestDomainDistance = domainDistance;
              nearestMeasureDistance = measureDistance;
              nearestRelativeDistance = relativeDistance;
            }
          } else {
            if (relativeDistance < nearestRelativeDistance) {
              nearestPoint = p;
              nearestDomainDistance = domainDistance;
              nearestMeasureDistance = measureDistance;
              nearestRelativeDistance = relativeDistance;
            }
          }
        });
      });

      // Found a point, add it to the list.
      if (nearestPoint != null) {
        nearest.add(new DatumDetails<D>(
            chartPosition: new Point<double>(nearestPoint.x, nearestPoint.y),
            datum: nearestPoint.datum,
            domain: nearestPoint.domain,
            series: nearestPoint.series,
            domainDistance: nearestDomainDistance,
            measureDistance: nearestMeasureDistance,
            relativeDistance: nearestRelativeDistance));
      }
    });

    // Note: the details are already sorted by domain & measure distance in
    // base chart.

    return nearest;
  }

  DatumDetails<D> addPositionToDetailsForSeriesDatum(
      DatumDetails<D> details, SeriesDatum<D> seriesDatum) {
    final series = details.series;

    final domainAxis = series.getAttr(domainAxisKey) as ImmutableAxis<D>;
    final measureAxis = series.getAttr(measureAxisKey) as ImmutableAxis<num>;

    final point = _getPoint(seriesDatum.datum, details.domain, series,
        domainAxis, details.measure, details.measureOffset, measureAxis);
    final chartPosition = new Point<double>(point.x, point.y);

    return new DatumDetails.from(details, chartPosition: chartPosition);
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

/// Rendering information for the line portion of a series.
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

/// Animates the line element of a series between different states.
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
    // TODO: Animate to the nearest lines in the stack.
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

  /// Returns the [points] of the current target element, without updating
  /// animation state.
  List<_DatumPoint<D>> get currentPoints => _currentLine?.points;
}

/// Rendering information for the area skirt portion of a series.
class _AreaRendererElement<D> {
  List<_DatumPoint<D>> points;
  Color color;
  double measureAxisPosition;

  _AreaRendererElement<D> clone() {
    return new _AreaRendererElement<D>()
      ..points = new List<_DatumPoint<D>>.from(points)
      ..color = color != null ? new Color.fromOther(color: color) : null
      ..measureAxisPosition = measureAxisPosition;
  }

  void updateAnimationPercent(_AreaRendererElement previous,
      _AreaRendererElement target, double animationPercent) {
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
  }
}

/// Animates the area element of a series between different states.
class _AnimatedArea<D> {
  final String key;
  final bool overlaySeries;

  _AreaRendererElement<D> _previousArea;
  _AreaRendererElement<D> _targetArea;
  _AreaRendererElement<D> _currentArea;

  // Flag indicating whether this line is being animated out of the chart.
  bool animatingOut = false;

  _AnimatedArea({@required this.key, @required this.overlaySeries});

  /// Animates a line that was removed from the series out of the view.
  ///
  /// This should be called in place of "setNewTarget" for lines that represent
  /// data that has been removed from the series.
  ///
  /// Animates the height of the line down to the measure axis position
  /// (position of 0).
  void animateOut() {
    var newTarget = _currentArea.clone();

    // Set the target measure value to the axis position for all points.
    // TODO: Animate to the nearest areas in the stack.
    var newPoints = <_DatumPoint<D>>[];
    for (var index = 0; index < newTarget.points.length; index++) {
      var targetPoint = newTarget.points[index];

      newPoints.add(new _DatumPoint<D>.from(targetPoint, targetPoint.x,
          newTarget.measureAxisPosition.roundToDouble()));
    }

    newTarget.points = newPoints;

    setNewTarget(newTarget);
    animatingOut = true;
  }

  void setNewTarget(_AreaRendererElement<D> newTarget) {
    animatingOut = false;
    _currentArea ??= newTarget.clone();
    _previousArea = _currentArea.clone();
    _targetArea = newTarget;
  }

  _AreaRendererElement<D> getCurrentArea(double animationPercent) {
    if (animationPercent == 1.0 || _previousArea == null) {
      _currentArea = _targetArea;
      _previousArea = _targetArea;
      return _currentArea;
    }

    _currentArea.updateAnimationPercent(
        _previousArea, _targetArea, animationPercent);

    return _currentArea;
  }
}

class _AnimatedElements<D> {
  _AnimatedArea<D> area;
  _AnimatedLine<D> line;

  bool get animatingOut {
    return (area == null || area.animatingOut) &&
        (line == null || line.animatingOut);
  }

  bool get overlaySeries {
    return (area == null || area.overlaySeries) &&
        (line == null || line.overlaySeries);
  }
}

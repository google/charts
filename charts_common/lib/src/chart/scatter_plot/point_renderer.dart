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
import 'dart:math' show Point, Rectangle;

import 'package:meta/meta.dart' show required;

import '../cartesian/axis/axis.dart'
    show ImmutableAxis, domainAxisKey, measureAxisKey;
import '../cartesian/cartesian_renderer.dart' show BaseCartesianRenderer;
import '../common/chart_canvas.dart' show ChartCanvas, getAnimatedColor;
import '../common/datum_details.dart' show DatumDetails;
import '../common/processed_series.dart' show ImmutableSeries, MutableSeries;
import '../../common/color.dart' show Color;
import '../../common/symbol_renderer.dart' show PointSymbolRenderer;
import '../../data/series.dart' show AccessorFn, AttributeKey;
import 'point_renderer_config.dart' show PointRendererConfig;

const pointElementsKey =
    const AttributeKey<List<_PointRendererElement>>('PointRenderer.elements');

const pointSymbolRendererFnKey =
    const AttributeKey<AccessorFn<dynamic, String>>(
        'PointRenderer.symbolRendererFn');

const pointSymbolRendererIdKey =
    const AttributeKey<String>('PointRenderer.symbolRendererId');

const defaultSymbolRendererId = '__default__';

class PointRenderer<T, D> extends BaseCartesianRenderer<T, D> {
  final PointRendererConfig config;

  /// Store a map of series drawn on the chart, mapped by series name.
  ///
  /// [LinkedHashMap] is used to render the series on the canvas in the same
  /// order as the data was given to the chart.
  final _seriesPointMap =
      new LinkedHashMap<String, List<_AnimatedPoint<T, D>>>();

  // Store a list of lines that exist in the series data.
  //
  // This list will be used to remove any [_AnimatedPoint] that were rendered in
  // previous draw cycles, but no longer have a corresponding datum in the new
  // data.
  final _currentKeys = <String>[];

  PointRenderer({String rendererId, PointRendererConfig config})
      : this.config = config ?? new PointRendererConfig(),
        super(
            rendererId: rendererId ?? 'point',
            layoutPositionOrder: 10,
            symbolRenderer:
                config?.symbolRenderer ?? new PointSymbolRenderer());

  @override
  void configureSeries(List<MutableSeries<T, D>> seriesList) {
    assignMissingColors(seriesList, emptyCategoryUsesSinglePalette: false);
  }

  @override
  void preprocessSeries(List<MutableSeries<T, D>> seriesList) {
    seriesList.forEach((MutableSeries<T, D> series) {
      var elements = <_PointRendererElement<T, D>>[];

      // Default to the configured radius if none was defined by the series.
      var radiusPxFn = series.radiusPxFn;
      radiusPxFn ??= (_, __) => config.radiusPx;

      final symbolRendererFn = series.getAttr(pointSymbolRendererFnKey);

      for (var index = 0; index < series.data.length; index++) {
        T datum = series.data[index];

        // Default to the configured radius if none was returned by the
        // accessor function.
        var radiusPx = radiusPxFn(datum, index);
        radiusPx ??= config.radiusPx;

        // Get the ID of the [SymbolRenderer] for this point. An ID may be
        // specified on the datum, or on the series. If neither is specified,
        // fall back to the default.
        String symbolRendererId;
        if (symbolRendererFn != null) {
          symbolRendererId = symbolRendererFn(datum, index);
        }
        symbolRendererId ??= series.getAttr(pointSymbolRendererIdKey);
        symbolRendererId ??= defaultSymbolRendererId;

        var details = new _PointRendererElement<T, D>()
          ..radiusPx = radiusPx.toDouble()
          ..symbolRendererId = symbolRendererId;

        elements.add(details);
      }

      series.setAttr(pointElementsKey, elements);
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
      var seriesKey = series.id;

      var pointList = _seriesPointMap.putIfAbsent(seriesKey, () => []);

      var elementsList = series.getAttr(pointElementsKey);

      for (var index = 0; index < series.data.length; index++) {
        T datum = series.data[index];
        final details = elementsList[index];
        D domainValue = domainFn(datum, index);
        num measureValue = measureFn(datum, index);

        // Create a new point using the final location.
        var point = _getPoint(
            datum,
            domainFn(datum, index),
            series,
            domainAxis,
            measureFn(datum, index),
            measureOffsetFn(datum, index),
            measureAxis);

        // Skip points whose center lies outside the draw bounds. Those that lie
        // near the edge will be allowed to render partially outside. This
        // prevents harshly clipping off half of the shape.
        if (!componentBounds.containsPoint(point)) {
          continue;
        }

        var pointKey = '${domainValue}__${measureValue}';

        // If we already have an AnimatingPoint for that index, use it.
        var animatingPoint = pointList.firstWhere(
            (_AnimatedPoint point) => point.key == pointKey,
            orElse: () => null);

        // If we don't have any existing arc element, create a new arc and
        // have it animate in from the position of the previous arc's end
        // angle. If there were no previous arcs, then animate everything in
        // from 0.
        if (animatingPoint == null) {
          // Create a new point and have it animate in from axis.
          var point = _getPoint(datum, domainFn(datum, index), series,
              domainAxis, 0.0, 0.0, measureAxis);

          animatingPoint = new _AnimatedPoint<T, D>(
              key: pointKey, overlaySeries: series.overlaySeries)
            ..setNewTarget(new _PointRendererElement<T, D>()
              ..color = colorFn(datum, index)
              ..measureAxisPosition = measureAxis.getLocation(0.0)
              ..point = point
              ..radiusPx = details.radiusPx
              ..symbolRendererId = details.symbolRendererId);

          pointList.add(animatingPoint);
        }

        // Update the set of arcs that still exist in the series data.
        _currentKeys.add(pointKey);

        // Get the pointElement we are going to setup.
        final pointElement = new _PointRendererElement<T, D>()
          ..color = colorFn(datum, index)
          ..measureAxisPosition = measureAxis.getLocation(0.0)
          ..point = point
          ..radiusPx = details.radiusPx
          ..symbolRendererId = details.symbolRendererId;

        animatingPoint.setNewTarget(pointElement);
      }
    });

    // Animate out points that don't exist anymore.
    _seriesPointMap.forEach((String key, List<_AnimatedPoint<T, D>> points) {
      for (var point in points) {
        if (_currentKeys.contains(point.key) != true) {
          point.animateOut();
        }
      }
    });
  }

  void paint(ChartCanvas canvas, double animationPercent) {
    // Clean up the points that no longer exist.
    if (animationPercent == 1.0) {
      final keysToRemove = <String>[];

      _seriesPointMap.forEach((String key, List<_AnimatedPoint<T, D>> points) {
        points.removeWhere((_AnimatedPoint<T, D> point) => point.animatingOut);

        if (points.isEmpty) {
          keysToRemove.add(key);
        }
      });

      keysToRemove.forEach((String key) => _seriesPointMap.remove(key));
    }

    _seriesPointMap.forEach((String key, List<_AnimatedPoint<T, D>> points) {
      points
          .map<_PointRendererElement<T, D>>(
              (_AnimatedPoint<T, D> animatingPoint) =>
                  animatingPoint.getCurrentPoint(animationPercent))
          .forEach((_PointRendererElement point) {
        final bounds = new Rectangle<double>(
            point.point.x - point.radiusPx,
            point.point.y - point.radiusPx,
            point.radiusPx * 2,
            point.radiusPx * 2);

        if (point.symbolRendererId == defaultSymbolRendererId) {
          symbolRenderer.paint(canvas, bounds, point.color);
        } else {
          final id = point.symbolRendererId;
          if (!config.customSymbolRenderers.containsKey(id)) {
            throw new ArgumentError(
                'Invalid custom symbol renderer id "${id}"');
          }

          final customRenderer = config.customSymbolRenderers[id];
          customRenderer.paint(canvas, bounds, point.color);
        }
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

    _seriesPointMap.values.forEach((List<_AnimatedPoint<T, D>> points) {
      _DatumPoint<T, D> nearestPoint;
      double nearestDomainDistance = 10000.0;
      double nearestMeasureDistance = 10000.0;

      points.forEach((_AnimatedPoint<T, D> point) {
        if (point.overlaySeries) {
          return;
        }

        Point p = point._currentPoint.point;

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

class _PointRendererElement<T, D> {
  _DatumPoint<T, D> point;
  Color color;
  double measureAxisPosition;
  double radiusPx;
  String symbolRendererId;

  _PointRendererElement<T, D> clone() {
    return new _PointRendererElement<T, D>()
      ..point = new _DatumPoint<T, D>.from(point)
      ..color = color != null ? new Color.fromOther(color: color) : null
      ..measureAxisPosition = measureAxisPosition
      ..radiusPx = radiusPx
      ..symbolRendererId = symbolRendererId;
  }

  void updateAnimationPercent(_PointRendererElement previous,
      _PointRendererElement target, double animationPercent) {
    var targetPoint = target.point;
    var previousPoint = previous.point;

    var x = ((targetPoint.x - previousPoint.x) * animationPercent) +
        previousPoint.x;

    var y = ((targetPoint.y - previousPoint.y) * animationPercent) +
        previousPoint.y;

    point = new _DatumPoint<T, D>.from(targetPoint, x, y);

    color = getAnimatedColor(previous.color, target.color, animationPercent);

    radiusPx = (((target.radiusPx - previous.radiusPx) * animationPercent) +
        previous.radiusPx);
  }
}

class _AnimatedPoint<T, D> {
  final String key;
  final bool overlaySeries;

  _PointRendererElement<T, D> _previousPoint;
  _PointRendererElement<T, D> _targetPoint;
  _PointRendererElement<T, D> _currentPoint;

  // Flag indicating whether this point is being animated out of the chart.
  bool animatingOut = false;

  _AnimatedPoint({@required this.key, @required this.overlaySeries});

  /// Animates a point that was removed from the series out of the view.
  ///
  /// This should be called in place of "setNewTarget" for points that represent
  /// data that has been removed from the series.
  ///
  /// Animates the height of the point down to the measure axis position
  /// (position of 0).
  void animateOut() {
    var newTarget = _currentPoint.clone();

    // Set the target measure value to the axis position.
    var targetPoint = newTarget.point;
    newTarget.point = new _DatumPoint<T, D>.from(targetPoint, targetPoint.x,
        newTarget.measureAxisPosition.roundToDouble());

    // Animate the stroke width to 0 so that we don't get a lingering point after
    // animation is done.
    newTarget.radiusPx = 0.0;

    setNewTarget(newTarget);
    animatingOut = true;
  }

  void setNewTarget(_PointRendererElement<T, D> newTarget) {
    animatingOut = false;
    _currentPoint ??= newTarget.clone();
    _previousPoint = _currentPoint.clone();
    _targetPoint = newTarget;
  }

  _PointRendererElement<T, D> getCurrentPoint(double animationPercent) {
    if (animationPercent == 1.0 || _previousPoint == null) {
      _currentPoint = _targetPoint;
      _previousPoint = _targetPoint;
      return _currentPoint;
    }

    _currentPoint.updateAnimationPercent(
        _previousPoint, _targetPoint, animationPercent);

    return _currentPoint;
  }
}

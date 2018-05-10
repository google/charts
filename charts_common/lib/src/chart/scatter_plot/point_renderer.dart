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
import '../common/base_chart.dart' show BaseChart;
import '../common/chart_canvas.dart' show ChartCanvas, getAnimatedColor;
import '../common/datum_details.dart' show DatumDetails;
import '../common/processed_series.dart' show ImmutableSeries, MutableSeries;
import '../../common/color.dart' show Color;
import '../../common/symbol_renderer.dart' show CircleSymbolRenderer;
import '../../data/series.dart' show AccessorFn, AttributeKey;
import 'point_renderer_config.dart' show PointRendererConfig;
import 'point_renderer_decorator.dart' show PointRendererDecorator;

const pointElementsKey =
    const AttributeKey<List<PointRendererElement>>('PointRenderer.elements');

const pointSymbolRendererFnKey =
    const AttributeKey<AccessorFn<String>>('PointRenderer.symbolRendererFn');

const pointSymbolRendererIdKey =
    const AttributeKey<String>('PointRenderer.symbolRendererId');

const defaultSymbolRendererId = '__default__';

class PointRenderer<D> extends BaseCartesianRenderer<D> {
  final PointRendererConfig config;

  final List<PointRendererDecorator> pointRendererDecorators;

  BaseChart<D> _chart;

  /// Store a map of series drawn on the chart, mapped by series name.
  ///
  /// [LinkedHashMap] is used to render the series on the canvas in the same
  /// order as the data was given to the chart.
  final _seriesPointMap = new LinkedHashMap<String, List<_AnimatedPoint<D>>>();

  // Store a list of lines that exist in the series data.
  //
  // This list will be used to remove any [_AnimatedPoint] that were rendered in
  // previous draw cycles, but no longer have a corresponding datum in the new
  // data.
  final _currentKeys = <String>[];

  PointRenderer({String rendererId, PointRendererConfig config})
      : this.config = config ?? new PointRendererConfig(),
        pointRendererDecorators = config?.pointRendererDecorators ?? [],
        super(
            rendererId: rendererId ?? 'point',
            layoutPositionOrder: 10,
            symbolRenderer:
                config?.symbolRenderer ?? new CircleSymbolRenderer());

  @override
  void configureSeries(List<MutableSeries<D>> seriesList) {
    assignMissingColors(seriesList, emptyCategoryUsesSinglePalette: false);
  }

  @override
  void preprocessSeries(List<MutableSeries<D>> seriesList) {
    seriesList.forEach((MutableSeries<D> series) {
      var elements = <PointRendererElement<D>>[];

      // Default to the configured radius if none was defined by the series.
      var radiusPxFn = series.radiusPxFn;
      radiusPxFn ??= (_) => config.radiusPx;

      final symbolRendererFn = series.getAttr(pointSymbolRendererFnKey);

      for (var index = 0; index < series.data.length; index++) {
        // Default to the configured radius if none was returned by the
        // accessor function.
        var radiusPx = radiusPxFn(index);
        radiusPx ??= config.radiusPx;

        // Get the ID of the [SymbolRenderer] for this point. An ID may be
        // specified on the datum, or on the series. If neither is specified,
        // fall back to the default.
        String symbolRendererId;
        if (symbolRendererFn != null) {
          symbolRendererId = symbolRendererFn(index);
        }
        symbolRendererId ??= series.getAttr(pointSymbolRendererIdKey);
        symbolRendererId ??= defaultSymbolRendererId;

        var details = new PointRendererElement<D>()
          ..radiusPx = radiusPx.toDouble()
          ..symbolRendererId = symbolRendererId;

        elements.add(details);
      }

      series.setAttr(pointElementsKey, elements);
    });
  }

  void update(List<ImmutableSeries<D>> seriesList, bool isAnimatingThisDraw) {
    _currentKeys.clear();

    seriesList.forEach((ImmutableSeries<D> series) {
      var domainAxis = series.getAttr(domainAxisKey) as ImmutableAxis<D>;
      var domainFn = series.domainFn;
      var domainLowerBoundFn = series.domainLowerBoundFn;
      var domainUpperBoundFn = series.domainUpperBoundFn;
      var measureAxis = series.getAttr(measureAxisKey) as ImmutableAxis<num>;
      var measureFn = series.measureFn;
      var measureLowerBoundFn = series.measureLowerBoundFn;
      var measureUpperBoundFn = series.measureUpperBoundFn;
      var measureOffsetFn = series.measureOffsetFn;
      var colorFn = series.colorFn;
      var seriesKey = series.id;

      var pointList = _seriesPointMap.putIfAbsent(seriesKey, () => []);

      var elementsList = series.getAttr(pointElementsKey);

      for (var index = 0; index < series.data.length; index++) {
        final datum = series.data[index];
        final details = elementsList[index];

        D domainValue = domainFn(index);
        D domainLowerBoundValue =
            domainLowerBoundFn != null ? domainLowerBoundFn(index) : null;
        D domainUpperBoundValue =
            domainUpperBoundFn != null ? domainUpperBoundFn(index) : null;

        num measureValue = measureFn(index);
        num measureLowerBoundValue =
            measureLowerBoundFn != null ? measureLowerBoundFn(index) : null;
        num measureUpperBoundValue =
            measureUpperBoundFn != null ? measureUpperBoundFn(index) : null;
        num measureOffsetValue = measureOffsetFn(index);

        // Create a new point using the final location.
        var point = _getPoint(
            datum,
            domainValue,
            domainLowerBoundValue,
            domainUpperBoundValue,
            series,
            domainAxis,
            measureValue,
            measureLowerBoundValue,
            measureUpperBoundValue,
            measureOffsetValue,
            measureAxis);

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
          var point = _getPoint(
              datum,
              domainValue,
              domainLowerBoundValue,
              domainUpperBoundValue,
              series,
              domainAxis,
              0.0,
              0.0,
              0.0,
              0.0,
              measureAxis);

          animatingPoint = new _AnimatedPoint<D>(
              key: pointKey, overlaySeries: series.overlaySeries)
            ..setNewTarget(new PointRendererElement<D>()
              ..color = colorFn(index)
              ..measureAxisPosition = measureAxis.getLocation(0.0)
              ..point = point
              ..radiusPx = details.radiusPx
              ..symbolRendererId = details.symbolRendererId);

          pointList.add(animatingPoint);
        }

        // Update the set of arcs that still exist in the series data.
        _currentKeys.add(pointKey);

        // Get the pointElement we are going to setup.
        final pointElement = new PointRendererElement<D>()
          ..color = colorFn(index)
          ..measureAxisPosition = measureAxis.getLocation(0.0)
          ..point = point
          ..radiusPx = details.radiusPx
          ..symbolRendererId = details.symbolRendererId;

        animatingPoint.setNewTarget(pointElement);
      }
    });

    // Animate out points that don't exist anymore.
    _seriesPointMap.forEach((String key, List<_AnimatedPoint<D>> points) {
      for (var point in points) {
        if (_currentKeys.contains(point.key) != true) {
          point.animateOut();
        }
      }
    });
  }

  @override
  void onAttach(BaseChart<D> chart) {
    super.onAttach(chart);
    // We only need the chart.context.rtl setting, but context is not yet
    // available when the default renderer is attached to the chart on chart
    // creation time, since chart onInit is called after the chart is created.
    _chart = chart;
  }

  void paint(ChartCanvas canvas, double animationPercent) {
    // Clean up the points that no longer exist.
    if (animationPercent == 1.0) {
      final keysToRemove = <String>[];

      _seriesPointMap.forEach((String key, List<_AnimatedPoint<D>> points) {
        points.removeWhere((_AnimatedPoint<D> point) => point.animatingOut);

        if (points.isEmpty) {
          keysToRemove.add(key);
        }
      });

      keysToRemove.forEach((String key) => _seriesPointMap.remove(key));
    }

    _seriesPointMap.forEach((String key, List<_AnimatedPoint<D>> points) {
      points
          .map<PointRendererElement<D>>((_AnimatedPoint<D> animatingPoint) =>
              animatingPoint.getCurrentPoint(animationPercent))
          .forEach((PointRendererElement point) {
        final bounds = new Rectangle<double>(
            point.point.x - point.radiusPx,
            point.point.y - point.radiusPx,
            point.radiusPx * 2,
            point.radiusPx * 2);

        // Decorate the points with decorators that should appear below the main
        // series data.
        pointRendererDecorators
            .where((PointRendererDecorator decorator) => !decorator.renderAbove)
            .forEach((PointRendererDecorator decorator) {
          decorator.decorate(point, canvas, graphicsFactory,
              drawBounds: drawBounds,
              animationPercent: animationPercent,
              rtl: rtl);
        });

        // Skip points whose center lies outside the draw bounds. Those that lie
        // near the edge will be allowed to render partially outside. This
        // prevents harshly clipping off half of the shape.
        if (componentBounds.containsPoint(point.point)) {
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
        }

        // Decorate the points with decorators that should appear above the main
        // series data. This is the typical place for labels.
        pointRendererDecorators
            .where((PointRendererDecorator decorator) => decorator.renderAbove)
            .forEach((PointRendererDecorator decorator) {
          decorator.decorate(point, canvas, graphicsFactory,
              drawBounds: drawBounds,
              animationPercent: animationPercent,
              rtl: rtl);
        });
      });
    });
  }

  bool get rtl => _chart?.context?.rtl ?? false;

  DatumPoint<D> _getPoint(
      final datum,
      D domainValue,
      D domainLowerBoundValue,
      D domainUpperBoundValue,
      ImmutableSeries<D> series,
      ImmutableAxis<D> domainAxis,
      num measureValue,
      num measureLowerBoundValue,
      num measureUpperBoundValue,
      num measureOffsetValue,
      ImmutableAxis<num> measureAxis) {
    final domainPosition = domainAxis.getLocation(domainValue);

    final domainLowerBoundPosition = domainLowerBoundValue != null
        ? domainAxis.getLocation(domainLowerBoundValue)
        : null;

    final domainUpperBoundPosition = domainUpperBoundValue != null
        ? domainAxis.getLocation(domainUpperBoundValue)
        : null;

    final measurePosition =
        measureAxis.getLocation(measureValue + measureOffsetValue);

    final measureLowerBoundPosition = measureLowerBoundValue != null
        ? measureAxis.getLocation(measureLowerBoundValue + measureOffsetValue)
        : null;

    final measureUpperBoundPosition = measureUpperBoundValue != null
        ? measureAxis.getLocation(measureUpperBoundValue + measureOffsetValue)
        : null;

    return new DatumPoint<D>(
        datum: datum,
        domain: domainValue,
        series: series,
        x: domainPosition,
        xLower: domainLowerBoundPosition,
        xUpper: domainUpperBoundPosition,
        y: measurePosition,
        yLower: measureLowerBoundPosition,
        yUpper: measureUpperBoundPosition);
  }

  @override
  List<DatumDetails<D>> getNearestDatumDetailPerSeries(
      Point<double> chartPoint) {
    final nearest = <DatumDetails<D>>[];

    // Was it even in the drawArea?
    if (!componentBounds.containsPoint(chartPoint)) {
      return nearest;
    }

    _seriesPointMap.values.forEach((List<_AnimatedPoint<D>> points) {
      DatumPoint<D> nearestPoint;
      double nearestDomainDistance = 10000.0;
      double nearestMeasureDistance = 10000.0;

      points.forEach((_AnimatedPoint<D> point) {
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

class DatumPoint<D> extends Point<double> {
  final datum;
  final D domain;
  final ImmutableSeries<D> series;

  // Coordinates for domain bounds.
  final double xLower;
  final double xUpper;

  // Coordinates for measure bounds.
  final double yLower;
  final double yUpper;

  DatumPoint(
      {this.datum,
      this.domain,
      this.series,
      double x,
      this.xLower,
      this.xUpper,
      double y,
      this.yLower,
      this.yUpper})
      : super(x, y);

  factory DatumPoint.from(DatumPoint<D> other,
      {double x,
      double xLower,
      double xUpper,
      double y,
      double yLower,
      double yUpper}) {
    return new DatumPoint<D>(
        datum: other.datum,
        domain: other.domain,
        series: other.series,
        x: x ?? other.x,
        xLower: xLower ?? other.xLower,
        xUpper: xUpper ?? other.xUpper,
        y: y ?? other.y,
        yLower: yLower ?? other.yLower,
        yUpper: yUpper ?? other.yUpper);
  }
}

class PointRendererElement<D> {
  DatumPoint<D> point;
  //Rectangle<int> get bounds;
  Color color;
  double measureAxisPosition;
  double radiusPx;
  String symbolRendererId;

  PointRendererElement<D> clone() {
    return new PointRendererElement<D>()
      ..point = new DatumPoint<D>.from(point)
      ..color = color != null ? new Color.fromOther(color: color) : null
      ..measureAxisPosition = measureAxisPosition
      ..radiusPx = radiusPx
      ..symbolRendererId = symbolRendererId;
  }

  void updateAnimationPercent(PointRendererElement previous,
      PointRendererElement target, double animationPercent) {
    final targetPoint = target.point;
    final previousPoint = previous.point;

    final x = ((targetPoint.x - previousPoint.x) * animationPercent) +
        previousPoint.x;

    final xLower = targetPoint.xLower != null && previousPoint.xLower != null
        ? ((targetPoint.xLower - previousPoint.xLower) * animationPercent) +
            previousPoint.xLower
        : null;

    final xUpper = targetPoint.xUpper != null && previousPoint.xUpper != null
        ? ((targetPoint.xUpper - previousPoint.xUpper) * animationPercent) +
            previousPoint.xUpper
        : null;

    final y = ((targetPoint.y - previousPoint.y) * animationPercent) +
        previousPoint.y;

    final yLower = targetPoint.yLower != null && previousPoint.yLower != null
        ? ((targetPoint.yLower - previousPoint.yLower) * animationPercent) +
            previousPoint.yLower
        : null;

    final yUpper = targetPoint.yUpper != null && previousPoint.yUpper != null
        ? ((targetPoint.yUpper - previousPoint.yUpper) * animationPercent) +
            previousPoint.yUpper
        : null;

    point = new DatumPoint<D>.from(targetPoint,
        x: x,
        xLower: xLower,
        xUpper: xUpper,
        y: y,
        yLower: yLower,
        yUpper: yUpper);

    color = getAnimatedColor(previous.color, target.color, animationPercent);

    radiusPx = (((target.radiusPx - previous.radiusPx) * animationPercent) +
        previous.radiusPx);
  }
}

class _AnimatedPoint<D> {
  final String key;
  final bool overlaySeries;

  PointRendererElement<D> _previousPoint;
  PointRendererElement<D> _targetPoint;
  PointRendererElement<D> _currentPoint;

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
    newTarget.point = new DatumPoint<D>.from(targetPoint,
        x: targetPoint.x,
        y: newTarget.measureAxisPosition.roundToDouble(),
        yLower: newTarget.measureAxisPosition.roundToDouble(),
        yUpper: newTarget.measureAxisPosition.roundToDouble());

    // Animate the stroke width to 0 so that we don't get a lingering point after
    // animation is done.
    newTarget.radiusPx = 0.0;

    setNewTarget(newTarget);
    animatingOut = true;
  }

  void setNewTarget(PointRendererElement<D> newTarget) {
    animatingOut = false;
    _currentPoint ??= newTarget.clone();
    _previousPoint = _currentPoint.clone();
    _targetPoint = newTarget;
  }

  PointRendererElement<D> getCurrentPoint(double animationPercent) {
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

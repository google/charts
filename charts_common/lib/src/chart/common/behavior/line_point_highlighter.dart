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
import 'package:meta/meta.dart';

import '../../cartesian/axis/axis.dart'
    show ImmutableAxis, domainAxisKey, measureAxisKey;
import '../base_chart.dart' show BaseChart, LifecycleListener;
import '../chart_canvas.dart' show ChartCanvas, getAnimatedColor;
import '../processed_series.dart' show ImmutableSeries, MutableSeries;
import '../selection_model/selection_model.dart'
    show SelectionModel, SelectionModelType;
import 'chart_behavior.dart' show ChartBehavior;
import '../../cartesian/cartesian_chart.dart' show CartesianChart;
import '../../layout/layout_view.dart'
    show LayoutPosition, LayoutView, LayoutViewConfig, ViewMeasuredSizes;
import '../../../common/color.dart' show Color;
import '../../../common/graphics_factory.dart' show GraphicsFactory;
import '../../../common/style/style_factory.dart' show StyleFactory;

/// Chart behavior that monitors the specified [SelectionModel] and renders a
/// dot for selected data.
///
/// This is typically used for line charts to highlight segments.
///
/// It is used in combination with SelectNearest to update the selection model
/// and expand selection out to the domain value.
class LinePointHighlighter<D> implements ChartBehavior<D> {
  final SelectionModelType selectionModelType;

  /// Default radius of the dots if the series has no radius mapping function.
  ///
  /// When no radius mapping function is provided, this value will be used as
  /// is. [radiusPaddingPx] will not be added to [defaultRadiusPx].
  final double defaultRadiusPx;

  /// Additional radius value added to the radius of the selected data.
  ///
  /// This value is only used when the series has a radius mapping function
  /// defined.
  final double radiusPaddingPx;

  final bool showHorizontalFollowLine;

  final bool showVerticalFollowLine;

  BaseChart<D> _chart;

  _LinePointLayoutView _view;

  LifecycleListener<D> _lifecycleListener;

  List<MutableSeries<D>> _seriesList;

  /// Store a map of data drawn on the chart, mapped by series name.
  ///
  /// [LinkedHashMap] is used to render the series on the canvas in the same
  /// order as the data was given to the chart.
  final _seriesPointMap = new LinkedHashMap<String, _AnimatedPoint<D>>();

  // Store a list of points that exist in the series data.
  //
  // This list will be used to remove any [_AnimatedPoint] that were rendered in
  // previous draw cycles, but no longer have a corresponding datum in the new
  // data.
  final _currentKeys = <String>[];

  LinePointHighlighter(
      {this.selectionModelType = SelectionModelType.info,
      this.defaultRadiusPx = 4.0,
      this.radiusPaddingPx = 0.5,
      this.showHorizontalFollowLine = false,
      this.showVerticalFollowLine = true}) {
    _lifecycleListener = new LifecycleListener<D>(
        onPostprocess: _updateSeriesList, onAxisConfigured: _updateViewData);
  }

  @override
  void attachTo(BaseChart<D> chart) {
    _chart = chart;

    _view = new _LinePointLayoutView<D>(
        layoutPositionOrder: 20,
        showHorizontalFollowLine: showHorizontalFollowLine,
        showVerticalFollowLine: showVerticalFollowLine);

    if (chart is CartesianChart) {
      // Only vertical rendering is supported by this behavior.
      assert((chart as CartesianChart).vertical);
    }

    chart.addView(_view);

    chart.addLifecycleListener(_lifecycleListener);
    chart
        .getSelectionModel(selectionModelType)
        .addSelectionListener(_selectionChanged);
  }

  @override
  void removeFrom(BaseChart chart) {
    chart.removeView(_view);
    chart
        .getSelectionModel(selectionModelType)
        .removeSelectionListener(_selectionChanged);
    chart.removeLifecycleListener(_lifecycleListener);
  }

  void _selectionChanged(SelectionModel selectionModel) {
    _chart.redraw(skipLayout: true, skipAnimation: true);
  }

  void _updateSeriesList(List<MutableSeries<D>> seriesList) {
    _seriesList = seriesList;
  }

  void _updateViewData() {
    _currentKeys.clear();

    SelectionModel selectionModel =
        _chart.getSelectionModel(selectionModelType);

    _seriesList?.forEach((MutableSeries<D> series) {
      var domainAxis = series.getAttr(domainAxisKey) as ImmutableAxis<D>;
      var domainFn = series.domainFn;
      var measureAxis = series.getAttr(measureAxisKey) as ImmutableAxis<num>;
      var measureFn = series.measureFn;
      var measureOffsetFn = series.measureOffsetFn;
      var colorFn = series.colorFn;
      var lineKey = series.id;
      var radiusPxFn = series.radiusPxFn;

      for (var index = 0; index < series.data.length; index++) {
        final datum = series.data[index];

        if (selectionModel.isDatumSelected(series, index)) {
          final domainValue = domainFn(index);

          Color color = colorFn(index);

          double radiusPx;
          if (radiusPxFn != null) {
            radiusPx = radiusPxFn(index).toDouble() + radiusPaddingPx;
          } else {
            radiusPx = defaultRadiusPx;
          }

          var pointKey = '${lineKey}::${domainValue}';

          // If we already have a AnimatingPoint for that index, use it.
          _AnimatedPoint<D> animatingPoint;
          if (_seriesPointMap.containsKey(pointKey)) {
            animatingPoint = _seriesPointMap[pointKey];
          } else {
            // Create a new line and have it animate in from axis.
            var point = _getPoint(
                datum, domainValue, series, domainAxis, 0.0, 0.0, measureAxis);

            animatingPoint = new _AnimatedPoint<D>(
                key: pointKey, overlaySeries: series.overlaySeries)
              ..setNewTarget(new _PointRendererElement<D>()
                ..color = color
                ..point = point
                ..radiusPx = radiusPx
                ..measureAxisPosition = measureAxis.getLocation(0.0));

            _seriesPointMap[pointKey] = animatingPoint;
          }

          // Create a new line using the final point locations.
          var point = _getPoint(datum, domainValue, series, domainAxis,
              measureFn(index), measureOffsetFn(index), measureAxis);

          // Update the set of lines that still exist in the series data.
          _currentKeys.add(pointKey);

          // Get the point element we are going to setup.
          final pointElement = new _PointRendererElement<D>()
            ..point = point
            ..color = color
            ..radiusPx = radiusPx
            ..measureAxisPosition = measureAxis.getLocation(0.0);

          animatingPoint.setNewTarget(pointElement);
        }
      }
    });

    // Animate out points that don't exist anymore.
    _seriesPointMap.forEach((String key, _AnimatedPoint<D> point) {
      if (_currentKeys.contains(point.key) != true) {
        point.animateOut();
      }
    });

    _view.seriesPointMap = _seriesPointMap;
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
  String get role => 'LinePointHighlighter-${selectionModelType.toString()}';
}

class _LinePointLayoutView<D> extends LayoutView {
  final LayoutViewConfig layoutConfig;

  final bool showHorizontalFollowLine;

  final bool showVerticalFollowLine;

  Rectangle<int> _drawAreaBounds;
  Rectangle<int> get drawBounds => _drawAreaBounds;

  GraphicsFactory _graphicsFactory;

  /// Store a map of series drawn on the chart, mapped by series name.
  ///
  /// [LinkedHashMap] is used to render the series on the canvas in the same
  /// order as the data was given to the chart.
  LinkedHashMap<String, _AnimatedPoint<D>> _seriesPointMap;

  _LinePointLayoutView({
    @required int layoutPositionOrder,
    @required this.showHorizontalFollowLine,
    @required this.showVerticalFollowLine,
  }) : this.layoutConfig = new LayoutViewConfig(
            position: LayoutPosition.DrawArea,
            positionOrder: layoutPositionOrder);

  set seriesPointMap(LinkedHashMap<String, _AnimatedPoint<D>> value) {
    _seriesPointMap = value;
  }

  @override
  GraphicsFactory get graphicsFactory => _graphicsFactory;

  @override
  set graphicsFactory(GraphicsFactory value) {
    _graphicsFactory = value;
  }

  @override
  ViewMeasuredSizes measure(int maxWidth, int maxHeight) {
    return null;
  }

  @override
  void layout(Rectangle<int> componentBounds, Rectangle<int> drawAreaBounds) {
    this._drawAreaBounds = drawAreaBounds;
  }

  @override
  void paint(ChartCanvas canvas, double animationPercent) {
    if (_seriesPointMap == null) {
      return;
    }

    // Clean up the lines that no longer exist.
    if (animationPercent == 1.0) {
      final keysToRemove = <String>[];

      _seriesPointMap.forEach((String key, _AnimatedPoint<D> point) {
        if (point.animatingOut) {
          keysToRemove.add(key);
        }
      });

      keysToRemove.forEach((String key) => _seriesPointMap.remove(key));
    }

    _seriesPointMap.forEach((String key, _AnimatedPoint<D> point) {
      final pointElement = point.getCurrentPoint(animationPercent);

      // Draw the horizontal follow line.
      if (showHorizontalFollowLine) {
        canvas.drawLine(
            points: [
              new Point<num>(_drawAreaBounds.left, pointElement.point.y),
              new Point<num>(_drawAreaBounds.left + _drawAreaBounds.width,
                  pointElement.point.y),
            ],
            stroke: StyleFactory.style.linePointHighlighterColor,
            strokeWidthPx: 1.0,
            dashPattern: [1, 3]);
      }

      // Draw the vertical follow line.
      if (showVerticalFollowLine) {
        canvas.drawLine(
            points: [
              new Point<num>(pointElement.point.x, _drawAreaBounds.top),
              new Point<num>(pointElement.point.x,
                  _drawAreaBounds.top + _drawAreaBounds.height),
            ],
            stroke: StyleFactory.style.linePointHighlighterColor,
            strokeWidthPx: 1.0,
            dashPattern: [1, 3]);
      }

      // Draw the highlight dot.
      canvas.drawPoint(
          point: pointElement.point,
          fill: pointElement.color,
          radius: pointElement.radiusPx);
    });
  }

  @override
  Rectangle<int> get componentBounds => this._drawAreaBounds;
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

class _PointRendererElement<D> {
  _DatumPoint<D> point;
  Color color;
  double radiusPx;
  double measureAxisPosition;

  _PointRendererElement<D> clone() {
    return new _PointRendererElement<D>()
      ..point = this.point
      ..color = this.color
      ..measureAxisPosition = this.measureAxisPosition
      ..radiusPx = this.radiusPx;
  }

  void updateAnimationPercent(_PointRendererElement previous,
      _PointRendererElement target, double animationPercent) {
    final targetPoint = target.point;
    final previousPoint = previous.point;

    final x = ((targetPoint.x - previousPoint.x) * animationPercent) +
        previousPoint.x;

    final y = ((targetPoint.y - previousPoint.y) * animationPercent) +
        previousPoint.y;

    point = new _DatumPoint<D>.from(targetPoint, x, y);

    color = getAnimatedColor(previous.color, target.color, animationPercent);

    radiusPx = (((target.radiusPx - previous.radiusPx) * animationPercent) +
        previous.radiusPx);
  }
}

class _AnimatedPoint<D> {
  final String key;
  final bool overlaySeries;

  _PointRendererElement<D> _previousPoint;
  _PointRendererElement<D> _targetPoint;
  _PointRendererElement<D> _currentPoint;

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
    final newTarget = _currentPoint.clone();

    // Set the target measure value to the axis position for all points.
    final targetPoint = newTarget.point;

    final newPoint = new _DatumPoint<D>.from(targetPoint, targetPoint.x,
        newTarget.measureAxisPosition.roundToDouble());

    newTarget.point = newPoint;

    // Animate the radius to 0 so that we don't get a lingering point after
    // animation is done.
    newTarget.radiusPx = 0.0;

    setNewTarget(newTarget);
    animatingOut = true;
  }

  void setNewTarget(_PointRendererElement<D> newTarget) {
    animatingOut = false;
    _currentPoint ??= newTarget.clone();
    _previousPoint = _currentPoint.clone();
    _targetPoint = newTarget;
  }

  _PointRendererElement<D> getCurrentPoint(double animationPercent) {
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

/// Helper class that exposes fewer private internal properties for unit tests.
@visibleForTesting
class LinePointHighlighterTester<D> {
  final LinePointHighlighter<D> behavior;

  LinePointHighlighterTester(this.behavior);

  int getSelectionLength() {
    return behavior._seriesPointMap.length;
  }

  bool isDatumSelected(D datum) {
    var contains = false;

    behavior._seriesPointMap.forEach((String key, _AnimatedPoint<D> point) {
      if (point._currentPoint.point.datum == datum) {
        contains = true;
        return;
      }
    });

    return contains;
  }
}

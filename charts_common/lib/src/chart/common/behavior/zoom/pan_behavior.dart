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

import 'package:meta/meta.dart' show protected;

import '../../base_chart.dart';
import '../../../cartesian/cartesian_chart.dart';
import '../../../cartesian/axis/axis.dart' show Axis;
import '../chart_behavior.dart';
import '../../../../common/gesture_listener.dart';

/// Adds domain axis panning support to a chart.
///
/// Panning is supported by clicking and dragging the mouse for web, or tapping
/// and dragging on the chart for mobile devices.
class PanBehavior<T, D> implements ChartBehavior<T, D> {
  @override
  String get role => 'Pan';

  /// Listens for drag gestures.
  GestureListener _listener;

  /// The chart to which the behavior is attached.
  BaseChart _chart;

  @protected
  BaseChart get chart => _chart;

  /// Flag which is enabled to indicate that the user is "panning" the chart.
  bool _isPanning = false;

  @protected
  bool get isPanning => _isPanning;

  /// Last position of the mouse/tap that was used to adjust the scale translate
  /// factor.
  Point<double> _lastPosition;

  @protected
  Point<double> get lastPosition => _lastPosition;

  PanBehavior() {
    _listener = new GestureListener(
        onTapTest: onTapTest,
        onDragStart: onDragStart,
        onDragUpdate: onDragUpdate,
        onDragEnd: onDragEnd);
  }

  /// Injects the behavior into a chart.
  attachTo(BaseChart<T, D> chart) {
    if (!(chart is CartesianChart)) {
      throw new ArgumentError(
          'PanBehavior can only be attached to a CartesianChart');
    }

    _chart = chart;
    chart.addGestureListener(_listener);

    // Disable the autoViewport feature to enable panning.
    (_chart as CartesianChart).domainAxis?.autoViewport = false;

    /// TODO: Lock the measure axis during panning & flinging.
  }

  /// Removes the behavior from a chart.
  removeFrom(BaseChart<T, D> chart) {
    if (!(chart is CartesianChart)) {
      throw new ArgumentError(
          'PanBehavior can only be attached to a CartesianChart');
    }

    chart.removeGestureListener(_listener);

    // Restore the default autoViewport state.
    (_chart as CartesianChart).domainAxis?.autoViewport = true;

    _chart = null;
  }

  @protected
  bool onTapTest(Point<double> localPosition) {
    if (_chart == null) {
      return false;
    }

    return _chart.withinDrawArea(localPosition);
  }

  @protected
  bool onDragStart(Point<double> localPosition) {
    if (_chart == null) {
      return false;
    }

    onPanStart();

    _lastPosition = localPosition;
    _isPanning = true;
    return true;
  }

  @protected
  bool onDragUpdate(Point<double> localPosition, double scale) {
    if (!_isPanning || _lastPosition == null || _chart == null) {
      return false;
    }

    // Pinch gestures should be handled by the [PanAndZoomBehavior].
    if (scale != 1.0) {
      _isPanning = false;
      return false;
    }

    // Update the domain axis's viewport translate to pan the chart.
    final domainAxis = (_chart as CartesianChart).domainAxis;

    if (domainAxis == null) {
      return false;
    }

    double domainScalingFactor = domainAxis.viewportScalingFactor;

    double domainChange =
        domainAxis.viewportTranslatePx + localPosition.x - _lastPosition.x;

    domainAxis.setViewportSettings(domainScalingFactor, domainChange,
        drawAreaWidth: chart.drawAreaBounds.width);

    _lastPosition = localPosition;

    _chart.redraw(skipAnimation: true, skipLayout: true);
    return true;
  }

  @protected
  bool onDragEnd(
      Point<double> localPosition, double scale, double pixelsPerSec) {
    onPanEnd();
    return true;
  }

  @protected
  void onPanStart() {
    final CartesianChart cartesianChart = _chart;
    // When panning starts, domain axis should update tick location only.
    // TODO: Panning should generate a set of ticks before and after
    // current viewport that is used for panning.
    cartesianChart.domainAxis.updateTickLocationOnly = true;
    // When panning starts, measure axes should not update ticks or viewport.
    cartesianChart.getMeasureAxis(null).lockAxis = true;
    cartesianChart.getMeasureAxis(Axis.secondaryMeasureAxisId)?.lockAxis = true;
  }

  @protected
  void onPanEnd() {
    cancelPanning();

    final CartesianChart cartesianChart = _chart;
    // When panning stops, allow axes to update ticks, and request redraw.
    cartesianChart.domainAxis.updateTickLocationOnly = false;
    cartesianChart.getMeasureAxis(null).lockAxis = false;
    cartesianChart.getMeasureAxis(Axis.secondaryMeasureAxisId)?.lockAxis =
        false;

    _chart.redraw();
  }

  /// Cancels the handling of any current panning event.
  void cancelPanning() {
    _isPanning = false;
  }
}

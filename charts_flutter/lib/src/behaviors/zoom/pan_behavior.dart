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

import 'dart:math' show max, pow, Point;
import 'dart:ui';

import 'package:flutter/widgets.dart' show AnimationController;

import 'package:charts_common/common.dart' as common
    show BaseChart, CartesianChart, ChartBehavior, PanBehavior;
import 'package:meta/meta.dart' show immutable;

import '../../base_chart_state.dart' show BaseChartState;
import '../chart_behavior.dart'
    show ChartBehavior, ChartStateBehavior, GestureType;

@immutable
class PanBehavior extends ChartBehavior<common.PanBehavior> {
  final _desiredGestures = new Set<GestureType>.from([
    GestureType.onDrag,
  ]);

  Set<GestureType> get desiredGestures => _desiredGestures;

  @override
  common.PanBehavior<T, D> createCommonBehavior<T, D>() {
    return new FlutterPanBehavior<T, D>();
  }

  @override
  void updateCommonBehavior(common.ChartBehavior commonBehavior) {}

  @override
  String get role => 'Pan';

  bool operator ==(Object other) => other is PanBehavior;

  int get hashCode {
    return this.runtimeType.hashCode;
  }
}

/// Adds fling gesture support to [common.PanBehavior].
class FlutterPanBehavior<T, D> extends common.PanBehavior<T, D>
    implements ChartStateBehavior {
  BaseChartState _chartState;

  BaseChartState get chartState => _chartState;

  set chartState(BaseChartState chartState) {
    _chartState = chartState;

    if (_chartState != null) {
      _flingAnimator = new AnimationController(vsync: _chartState)
        ..addListener(_onFlingTick);
    } else {
      _flingAnimator = null;
    }
  }

  AnimationController _flingAnimator;

  double _flingAnimationInitialTranslatePx;
  double _flingAnimationTargetTranslatePx;

  bool _isFlinging = false;

  static const flingDistanceMultiplier = 0.15;
  static const flingDeceleratorFactor = 1.0;
  static const flingDurationMultiplier = 0.15;
  static const minimumFlingVelocity = 300.0;

  @override
  removeFrom(common.BaseChart chart) {
    stopFlingAnimation();
    _flingAnimator = null;
    super.removeFrom(chart);
  }

  @override
  bool onTapTest(Point<double> chartPoint) {
    super.onTapTest(chartPoint);

    stopFlingAnimation();

    return true;
  }

  @override
  bool onDragEnd(
      Point<double> localPosition, double scale, double pixelsPerSec) {
    if (isPanning) {
      // Ignore slow drag gestures to avoid jitter.
      if (pixelsPerSec.abs() < minimumFlingVelocity) {
        onPanEnd();
        return true;
      }

      _startFling(pixelsPerSec);
    }
    return true;
  }

  /// Starts a 'fling' in the direction and speed given by [pixelsPerSec].
  void _startFling(double pixelsPerSec) {
    final domainAxis = (chart as common.CartesianChart).domainAxis;

    _flingAnimationInitialTranslatePx = domainAxis.viewportTranslatePx;
    _flingAnimationTargetTranslatePx = _flingAnimationInitialTranslatePx +
        pixelsPerSec * flingDistanceMultiplier;

    final flingDuration = new Duration(
        milliseconds:
            max(200, (pixelsPerSec * flingDurationMultiplier).abs().round()));

    _flingAnimator
      ..duration = flingDuration
      ..forward(from: 0.0);
    _isFlinging = true;
  }

  /// Decelerates a fling event.
  double _decelerate(double value) => flingDeceleratorFactor == 1.0
      ? 1.0 - (1.0 - value) * (1.0 - value)
      : 1.0 - pow(1.0 - value, 2 * flingDeceleratorFactor);

  /// Updates the chart axis state on each tick of the [AnimationController].
  void _onFlingTick() {
    if (!_isFlinging) {
      return;
    }

    final percent = _flingAnimator.value;
    final deceleratedPercent = _decelerate(percent);
    final translation = lerpDouble(_flingAnimationInitialTranslatePx,
        _flingAnimationTargetTranslatePx, deceleratedPercent);

    final domainAxis = (chart as common.CartesianChart).domainAxis;

    domainAxis.setViewportSettings(
        domainAxis.viewportScalingFactor, translation,
        drawAreaWidth: chart.drawAreaBounds.width);

    if (percent >= 1.0) {
      stopFlingAnimation();
      onPanEnd();
      chart.redraw();
    }
  }

  /// Stops any current fling animations that may be executing.
  void stopFlingAnimation() {
    if (_isFlinging) {
      _isFlinging = false;
      _flingAnimator.stop();
    }
  }
}

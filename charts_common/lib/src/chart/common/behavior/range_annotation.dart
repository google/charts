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

import '../../cartesian/axis/axis.dart' show ImmutableAxis;
import '../base_chart.dart' show BaseChart, LifecycleListener;
import '../chart_canvas.dart' show ChartCanvas, getAnimatedColor;
import '../processed_series.dart' show MutableSeries;
import 'chart_behavior.dart' show ChartBehavior;
import '../../cartesian/cartesian_chart.dart' show CartesianChart;
import '../../layout/layout_view.dart'
    show
        LayoutPosition,
        LayoutView,
        LayoutViewConfig,
        LayoutViewPaintOrder,
        LayoutViewPositionOrder,
        ViewMeasuredSizes;
import '../../../common/color.dart' show Color;
import '../../../common/graphics_factory.dart' show GraphicsFactory;
import '../../../common/style/style_factory.dart' show StyleFactory;

/// Chart behavior that annotates domain ranges with a solid fill color.
///
/// The annotations will be drawn underneath series data and chart axes.
///
/// This is typically used for line charts to call out sections of the data
/// range.
///
/// TODO: Support labels.
class RangeAnnotation<D> implements ChartBehavior<D> {
  /// List of annotations to render on the chart.
  final List<RangeAnnotationSegment> annotations;

  /// Default color for annotations.
  final Color defaultColor;

  /// Whether or not the range of the axis should be extended to include the
  /// annotation start and end values.
  final bool extendAxis;

  CartesianChart<D> _chart;

  _RangeAnnotationLayoutView _view;

  LifecycleListener<D> _lifecycleListener;

  /// Store a map of data drawn on the chart, mapped by series name.
  ///
  /// [LinkedHashMap] is used to render the series on the canvas in the same
  /// order as the data was given to the chart.
  final _annotationMap = new LinkedHashMap<String, _AnimatedAnnotation<D>>();

  // Store a list of annotations that exist in the current annotation list.
  //
  // This list will be used to remove any [_AnimatedAnnotation] that were
  // rendered in previous draw cycles, but no longer have a corresponding datum
  // in the new data.
  final _currentKeys = <String>[];

  RangeAnnotation(this.annotations,
      {Color defaultColor, this.extendAxis = true})
      : defaultColor = StyleFactory.style.rangeAnnotationColor {
    _lifecycleListener = new LifecycleListener<D>(
        onPostprocess: _updateAxisRange, onAxisConfigured: _updateViewData);
  }

  @override
  void attachTo(BaseChart<D> chart) {
    if (!(chart is CartesianChart)) {
      throw new ArgumentError(
          'RangeAnnotation can only be attached to a CartesianChart');
    }

    _chart = chart;

    _view = new _RangeAnnotationLayoutView<D>(defaultColor: defaultColor);

    chart.addView(_view);

    chart.addLifecycleListener(_lifecycleListener);
  }

  @override
  void removeFrom(BaseChart chart) {
    chart.removeView(_view);
    chart.removeLifecycleListener(_lifecycleListener);
  }

  void _updateAxisRange(List<MutableSeries<D>> seriesList) {
    // Extend the axis range if enabled.
    if (extendAxis) {
      final domainAxis = _chart.domainAxis;

      annotations.forEach((RangeAnnotationSegment annotation) {
        var axis;

        switch (annotation.axisType) {
          case RangeAnnotationAxisType.domain:
            axis = domainAxis;
            break;

          case RangeAnnotationAxisType.measure:
            // We expect an empty axisId to get us the primary measure axis.
            axis = _chart.getMeasureAxis(annotation.axisId);
            break;
        }

        axis.addDomainValue(annotation.startValue);
        axis.addDomainValue(annotation.endValue);
      });
    }
  }

  void _updateViewData() {
    _currentKeys.clear();

    annotations.forEach((RangeAnnotationSegment annotation) {
      var axis;

      switch (annotation.axisType) {
        case RangeAnnotationAxisType.domain:
          axis = _chart.domainAxis;
          break;

        case RangeAnnotationAxisType.measure:
          // We expect an empty axisId to get us the primary measure axis.
          axis = _chart.getMeasureAxis(annotation.axisId);
          break;
      }

      final key = '${annotation.axisType}::${annotation.axisId}::' +
          '${annotation.startValue}::${annotation.endValue}';

      final color = annotation.color ?? defaultColor;

      final annotationDatum = _getAnnotationDatum(annotation.startValue,
          annotation.endValue, axis, annotation.axisType);

      // If we already have a animatingAnnotation for that index, use it.
      _AnimatedAnnotation<D> animatingAnnotation;
      if (_annotationMap.containsKey(key)) {
        animatingAnnotation = _annotationMap[key];
      } else {
        // Create a new annotation, positioned at the start and end values.
        animatingAnnotation = new _AnimatedAnnotation<D>(key: key)
          ..setNewTarget(new _AnnotationElement<D>()
            ..annotation = annotationDatum
            ..color = color);

        _annotationMap[key] = animatingAnnotation;
      }

      // Update the set of annotations that still exist in the series data.
      _currentKeys.add(key);

      // Get the annotation element we are going to setup.
      final annotationElement = new _AnnotationElement<D>()
        ..annotation = annotationDatum
        ..color = color;

      animatingAnnotation.setNewTarget(annotationElement);
    });

    // Animate out annotations that don't exist anymore.
    _annotationMap.forEach((String key, _AnimatedAnnotation<D> annotation) {
      if (_currentKeys.contains(annotation.key) != true) {
        annotation.animateOut();
      }
    });

    _view.annotationMap = _annotationMap;
  }

  /// Generates a datum that describes an annotation.
  _DatumAnnotation<D> _getAnnotationDatum(D startValue, D endValue,
      ImmutableAxis<D> axis, RangeAnnotationAxisType axisType) {
    final startPosition = axis.getLocation(startValue);
    final endPosition = axis.getLocation(endValue);

    return new _DatumAnnotation<D>(
        startPosition: startPosition,
        endPosition: endPosition,
        axisType: axisType);
  }

  @override
  String get role => 'RangeAnnotation';
}

class _RangeAnnotationLayoutView<D> extends LayoutView {
  final LayoutViewConfig layoutConfig;

  final Color defaultColor;

  Rectangle<int> _drawAreaBounds;
  Rectangle<int> get drawBounds => _drawAreaBounds;

  GraphicsFactory _graphicsFactory;

  /// Store a map of series drawn on the chart, mapped by series name.
  ///
  /// [LinkedHashMap] is used to render the series on the canvas in the same
  /// order as the data was given to the chart.
  LinkedHashMap<String, _AnimatedAnnotation<D>> _annotationMap;

  _RangeAnnotationLayoutView({
    @required this.defaultColor,
  }) : this.layoutConfig = new LayoutViewConfig(
            paintOrder: LayoutViewPaintOrder.rangeAnnotation,
            position: LayoutPosition.DrawArea,
            positionOrder: LayoutViewPositionOrder.drawArea);

  set annotationMap(LinkedHashMap<String, _AnimatedAnnotation<D>> value) {
    _annotationMap = value;
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
    if (_annotationMap == null) {
      return;
    }

    // Clean up the annotations that no longer exist.
    if (animationPercent == 1.0) {
      final keysToRemove = <String>[];

      _annotationMap.forEach((String key, _AnimatedAnnotation<D> annotation) {
        if (annotation.animatingOut) {
          keysToRemove.add(key);
        }
      });

      keysToRemove.forEach((String key) => _annotationMap.remove(key));
    }

    _annotationMap.forEach((String key, _AnimatedAnnotation<D> annotation) {
      final annotationElement =
          annotation.getCurrentAnnotation(animationPercent);

      switch (annotationElement.annotation.axisType) {
        case RangeAnnotationAxisType.domain:
          canvas.drawRect(
              new Rectangle<num>(
                  annotationElement.annotation.startPosition,
                  _drawAreaBounds.top,
                  annotationElement.annotation.endPosition -
                      annotationElement.annotation.startPosition,
                  _drawAreaBounds.height),
              fill: annotationElement.color);
          break;

        case RangeAnnotationAxisType.measure:
          canvas.drawRect(
              new Rectangle<num>(
                  _drawAreaBounds.left,
                  annotationElement.annotation.endPosition,
                  _drawAreaBounds.left + _drawAreaBounds.width,
                  annotationElement.annotation.startPosition -
                      annotationElement.annotation.endPosition),
              fill: annotationElement.color);
          break;
      }
    });
  }

  @override
  Rectangle<int> get componentBounds => this._drawAreaBounds;

  @override
  bool get isSeriesRenderer => false;
}

class _DatumAnnotation<D> {
  final double startPosition;
  final double endPosition;
  final RangeAnnotationAxisType axisType;

  _DatumAnnotation({this.startPosition, this.endPosition, this.axisType});

  factory _DatumAnnotation.from(_DatumAnnotation<D> other,
      [double startPosition, double endPosition]) {
    return new _DatumAnnotation<D>(
        startPosition: startPosition ?? other.startPosition,
        endPosition: endPosition ?? other.endPosition,
        axisType: other.axisType);
  }
}

class _AnnotationElement<D> {
  _DatumAnnotation<D> annotation;
  Color color;
  String label;
  Point<double> labelPosition;

  _AnnotationElement<D> clone() {
    return new _AnnotationElement<D>()
      ..annotation = new _DatumAnnotation.from(annotation)
      ..color = color != null ? new Color.fromOther(color: color) : null
      ..label = this.label
      ..labelPosition = labelPosition;
  }

  void updateAnimationPercent(_AnnotationElement previous,
      _AnnotationElement target, double animationPercent) {
    final targetAnnotation = target.annotation;
    final previousAnnotation = previous.annotation;

    final startPosition =
        ((targetAnnotation.startPosition - previousAnnotation.startPosition) *
                animationPercent) +
            previousAnnotation.startPosition;

    final endPosition =
        ((targetAnnotation.endPosition - previousAnnotation.endPosition) *
                animationPercent) +
            previousAnnotation.endPosition;

    annotation = new _DatumAnnotation<D>.from(
        targetAnnotation, startPosition, endPosition);

    color = getAnimatedColor(previous.color, target.color, animationPercent);
  }
}

class _AnimatedAnnotation<D> {
  final String key;

  _AnnotationElement<D> _previousAnnotation;
  _AnnotationElement<D> _targetAnnotation;
  _AnnotationElement<D> _currentAnnotation;

  // Flag indicating whether this annotation is being animated out of the chart.
  bool animatingOut = false;

  _AnimatedAnnotation({@required this.key});

  /// Animates an annotation that was removed from the list out of the view.
  ///
  /// This should be called in place of "setNewTarget" for annotations have been
  /// removed from the list.
  /// TODO: Needed?
  void animateOut() {
    final newTarget = _currentAnnotation.clone();

    setNewTarget(newTarget);
    animatingOut = true;
  }

  void setNewTarget(_AnnotationElement<D> newTarget) {
    animatingOut = false;
    _currentAnnotation ??= newTarget.clone();
    _previousAnnotation = _currentAnnotation.clone();
    _targetAnnotation = newTarget;
  }

  _AnnotationElement<D> getCurrentAnnotation(double animationPercent) {
    if (animationPercent == 1.0 || _previousAnnotation == null) {
      _currentAnnotation = _targetAnnotation;
      _previousAnnotation = _targetAnnotation;
      return _currentAnnotation;
    }

    _currentAnnotation.updateAnimationPercent(
        _previousAnnotation, _targetAnnotation, animationPercent);

    return _currentAnnotation;
  }
}

/// Helper class that exposes fewer private internal properties for unit tests.
@visibleForTesting
class RangeAnnotationTester<D> {
  final RangeAnnotation<D> behavior;

  RangeAnnotationTester(this.behavior);

  /// Checks if an annotation exists with the given position and color.
  bool doesAnnotationExist(num startPosition, num endPosition, Color color) {
    var exists = false;

    behavior._annotationMap.forEach((String key, _AnimatedAnnotation<D> a) {
      final currentAnnotation = a._currentAnnotation;
      final annotation = currentAnnotation.annotation;

      if (annotation.startPosition == startPosition &&
          annotation.endPosition == endPosition &&
          currentAnnotation.color == color) {
        exists = true;
        return;
      }
    });

    return exists;
  }
}

/// Data for a chart annotation.
class RangeAnnotationSegment<D> {
  final D startValue;
  final D endValue;
  final RangeAnnotationAxisType axisType;
  final String axisId;
  final Color color;
  final String label;
  final AnnotationLabelDirection labelDirection;

  RangeAnnotationSegment(this.startValue, this.endValue, this.axisType,
      {this.axisId, this.color, this.label, this.labelDirection});
}

enum RangeAnnotationAxisType {
  domain,
  measure,
}

enum AnnotationLabelDirection {
  horizontal,
  vertical,
}

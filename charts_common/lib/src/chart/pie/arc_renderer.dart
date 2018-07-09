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
import 'dart:math' show max, PI, Point;

import 'package:meta/meta.dart' show required;

import '../common/base_chart.dart' show BaseChart;
import '../common/canvas_shapes.dart' show CanvasPieSlice, CanvasPie;
import '../common/chart_canvas.dart' show ChartCanvas, getAnimatedColor;
import '../common/datum_details.dart' show DatumDetails;
import '../common/processed_series.dart' show ImmutableSeries, MutableSeries;
import '../common/series_renderer.dart' show BaseSeriesRenderer;
import '../../common/color.dart' show Color;
import '../../common/style/style_factory.dart' show StyleFactory;
import '../../data/series.dart' show AttributeKey;
import 'arc_renderer_config.dart' show ArcRendererConfig;

const arcElementsKey =
    const AttributeKey<List<_ArcRendererElement>>('ArcRenderer.elements');

const arcSeriesTotalKey =
    const AttributeKey<List<_ArcRendererElement>>('ArcRenderer.seriesTotal');

class ArcRenderer<D> extends BaseSeriesRenderer<D> {
  final ArcRendererConfig<D> config;

  BaseChart<D> _chart;

  /// Store a map of series drawn on the chart, mapped by series name.
  ///
  /// [LinkedHashMap] is used to render the series on the canvas in the same
  /// order as the data was given to the chart.
  final _seriesArcMap = new LinkedHashMap<String, _AnimatedArcList<D>>();

  // Store a list of arcs that exist in the series data.
  //
  // This list will be used to remove any [_AnimatedArc] that were rendered in
  // previous draw cycles, but no longer have a corresponding datum in the new
  // data.
  final _currentKeys = <String>[];

  ArcRenderer({String rendererId, ArcRendererConfig<D> config})
      : config = config ?? new ArcRendererConfig(),
        super(
            rendererId: rendererId ?? 'arc',
            layoutPositionOrder: 10,
            symbolRenderer: config?.symbolRenderer);

  @override
  void onAttach(BaseChart<D> chart) {
    super.onAttach(chart);
    _chart = chart;
  }

  @override
  void configureSeries(List<MutableSeries<D>> seriesList) {
    assignMissingColors(seriesList, emptyCategoryUsesSinglePalette: false);
  }

  @override
  void preprocessSeries(List<MutableSeries<D>> seriesList) {
    seriesList.forEach((MutableSeries<D> series) {
      var elements = <_ArcRendererElement<D>>[];

      var measureFn = series.measureFn;

      var seriesTotal = 0.0;

      for (var arcIndex = 0; arcIndex < series.data.length; arcIndex++) {
        var measure = measureFn(arcIndex);
        if (measure != null) {
          seriesTotal = seriesTotal += measure;
        }
      }

      // On the canvas, arc measurements are defined as angles from the positive
      // x axis. Start our first slice at the positive y axis instead.
      var startAngle = config.startAngle;

      var totalAngle = 0.0;

      var measures = [];

      if (series.data.length == 0) {
        // If the series has no data, generate an empty arc element that
        // occupies the entire chart.
        //
        // Use a tiny epsilon difference to ensure that the canvas renders a
        // "full" circle, in the correct direction.
        var angle = 2 * PI * .999999;
        var endAngle = startAngle + angle;

        var details = new _ArcRendererElement<D>();
        details.startAngle = startAngle;
        details.endAngle = endAngle;
        details.key = 0;
        details.measure = 0.0;

        elements.add(details);
      } else {
        // Otherwise, generate an arc element per datum.
        for (var arcIndex = 0; arcIndex < series.data.length; arcIndex++) {
          var measure = measureFn(arcIndex);
          measures.add(measure);
          if (measure == null) {
            continue;
          }

          var angle = (measure / seriesTotal) * 2 * PI;
          var endAngle = startAngle + angle;

          var details = new _ArcRendererElement<D>();
          details.startAngle = startAngle;
          details.endAngle = endAngle;
          details.key = arcIndex;
          details.measure = measure;

          elements.add(details);

          // Update the starting angle for the next datum in the series.
          startAngle = endAngle;

          totalAngle = totalAngle + angle;
        }
      }

      series.setAttr(arcElementsKey, elements);
    });
  }

  void update(List<ImmutableSeries<D>> seriesList, bool isAnimatingThisDraw) {
    _currentKeys.clear();

    final bounds = _chart.drawAreaBounds;

    final center = new Point((bounds.left + bounds.width / 2).toDouble(),
        (bounds.top + bounds.height / 2).toDouble());

    final radius = bounds.height < bounds.width
        ? (bounds.height / 2).toDouble()
        : (bounds.width / 2).toDouble();

    if (config.arcRatio != null) {
      if (0 < config.arcRatio || config.arcRatio > 1) {
        throw new ArgumentError('arcRatio must be between 0 and 1');
      }
    }

    final innerRadius = _calculateInnerRadius(radius);

    seriesList.forEach((ImmutableSeries<D> series) {
      var domainFn = series.domainFn;
      var colorFn = series.colorFn;
      var arcListKey = series.id;

      var arcList =
          _seriesArcMap.putIfAbsent(arcListKey, () => new _AnimatedArcList());

      var elementsList = series.getAttr(arcElementsKey);

      if (series.data.length == 0) {
        // If the series is empty, set up the "no data" arc element. This should
        // occupy the entire chart, and use the chart style's no data color.
        final details = elementsList[0];

        var arcKey = '__no_data__';

        // If we already have an AnimatingArc for that index, use it.
        var animatingArc = arcList.arcs.firstWhere(
            (_AnimatedArc arc) => arc.key == arcKey,
            orElse: () => null);

        arcList.center = center;
        arcList.radius = radius;
        arcList.innerRadius = innerRadius;
        arcList.stroke = config.noDataColor;
        arcList.strokeWidthPx = config.strokeWidthPx;
        arcList.strokeWidthPx = 0.0;

        // If we don't have any existing arc element, create a new arc. Unlike
        // real arcs, we should not animate the no data state in from 0.
        if (animatingArc == null) {
          animatingArc = new _AnimatedArc<D>(arcKey, null);
          arcList.arcs.add(animatingArc);
        } else {
          animatingArc.datum = null;
        }

        // Update the set of arcs that still exist in the series data.
        _currentKeys.add(arcKey);

        // Get the arcElement we are going to setup.
        // Optimization to prevent allocation in non-animating case.
        final arcElement = new _ArcRendererElement<D>()
          ..color = config.noDataColor
          ..startAngle = details.startAngle
          ..endAngle = details.endAngle;

        animatingArc.setNewTarget(arcElement);
      } else {
        var previousEndAngle = config.startAngle;

        for (var arcIndex = 0; arcIndex < series.data.length; arcIndex++) {
          final datum = series.data[arcIndex];
          final details = elementsList[arcIndex];
          D domainValue = domainFn(arcIndex);

          var arcKey = domainValue.toString();

          // If we already have an AnimatingArc for that index, use it.
          var animatingArc = arcList.arcs.firstWhere(
              (_AnimatedArc arc) => arc.key == arcKey,
              orElse: () => null);

          arcList.center = center;
          arcList.radius = radius;
          arcList.innerRadius = innerRadius;
          arcList.stroke = config.stroke;
          arcList.strokeWidthPx = config.strokeWidthPx;

          // If we don't have any existing arc element, create a new arc and
          // have it animate in from the position of the previous arc's end
          // angle. If there were no previous arcs, then animate everything in
          // from 0.
          if (animatingArc == null) {
            animatingArc = new _AnimatedArc<D>(arcKey, datum)
              ..setNewTarget(new _ArcRendererElement<D>()
                ..color = colorFn(arcIndex)
                ..startAngle = previousEndAngle
                ..endAngle = previousEndAngle);

            arcList.arcs.add(animatingArc);
          } else {
            animatingArc.datum = datum;

            previousEndAngle = animatingArc.previousArcEndAngle ?? 0.0;
          }

          // Update the set of arcs that still exist in the series data.
          _currentKeys.add(arcKey);

          // Get the arcElement we are going to setup.
          // Optimization to prevent allocation in non-animating case.
          final arcElement = new _ArcRendererElement<D>()
            ..color = colorFn(arcIndex)
            ..startAngle = details.startAngle
            ..endAngle = details.endAngle;

          animatingArc.setNewTarget(arcElement);
        }
      }
    });

    // Animate out arcs that don't exist anymore.
    _seriesArcMap.forEach((String key, _AnimatedArcList<D> arcList) {
      for (var arcIndex = 0; arcIndex < arcList.arcs.length; arcIndex++) {
        final arc = arcList.arcs[arcIndex];
        final arcStartAngle = arc.previousArcStartAngle;

        if (_currentKeys.contains(arc.key) != true) {
          // Default to animating out to the top of the chart, clockwise, if
          // there are no arcs that start past this arc.
          var targetArcAngle = (2 * PI) + config.startAngle;

          // Find the nearest start angle of the next arc that still exists in
          // the data.
          for (_AnimatedArc nextArc
              in arcList.arcs.where((arc) => _currentKeys.contains(arc.key))) {
            final nextArcStartAngle = nextArc.newTargetArcStartAngle;

            if (arcStartAngle < nextArcStartAngle &&
                nextArcStartAngle < targetArcAngle) {
              targetArcAngle = nextArcStartAngle;
            }
          }

          arc.animateOut(targetArcAngle);
        }
      }
    });
  }

  void paint(ChartCanvas canvas, double animationPercent) {
    // Clean up the arcs that no longer exist.
    if (animationPercent == 1.0) {
      final keysToRemove = <String>[];

      _seriesArcMap.forEach((String key, _AnimatedArcList<D> arcList) {
        arcList.arcs.removeWhere((_AnimatedArc<D> arc) => arc.animatingOut);

        if (arcList.arcs.isEmpty) {
          keysToRemove.add(key);
        }
      });

      keysToRemove.forEach((String key) => _seriesArcMap.remove(key));
    }

    _seriesArcMap.forEach((String key, _AnimatedArcList<D> arcList) {
      final circleSectors = <CanvasPieSlice>[];

      arcList.arcs
          .map<_ArcRendererElement<D>>((_AnimatedArc<D> animatingArc) =>
              animatingArc.getCurrentArc(animationPercent))
          .forEach((_ArcRendererElement arc) {
        circleSectors.add(
            new CanvasPieSlice(arc.startAngle, arc.endAngle, fill: arc.color));
      });

      canvas.drawPie(new CanvasPie(
          circleSectors, arcList.center, arcList.radius, arcList.innerRadius,
          stroke: arcList.stroke, strokeWidthPx: arcList.strokeWidthPx));
    });
  }

  @override
  List<DatumDetails<D>> getNearestDatumDetailPerSeries(
      Point<double> chartPoint) {
    final nearest = <DatumDetails<D>>[];

    // Was it even in the drawArea?
    if (!componentBounds.containsPoint(chartPoint)) {
      return nearest;
    }

    // TODO: Implement to support interactive behaviors.

    return nearest;
  }

  /// Assigns colors to series that are missing their colorFn.
  @override
  assignMissingColors(Iterable<MutableSeries> seriesList,
      {@required bool emptyCategoryUsesSinglePalette}) {
    int maxMissing = 0;

    seriesList.forEach((MutableSeries series) {
      if (series.colorFn == null) {
        maxMissing = max(maxMissing, series.data.length);
      }
    });

    if (maxMissing > 0) {
      final colorPalettes = StyleFactory.style.getOrderedPalettes(1);
      final colorPalette = colorPalettes[0].makeShades(maxMissing);

      seriesList.forEach((MutableSeries series) {
        if (series.colorFn == null) {
          series.colorFn = (index) => colorPalette[index];
        }
      });
    }
  }

  /// Calculates the size of the inner pie radius given the outer radius.
  double _calculateInnerRadius(double radius) {
    // arcRatio trumps arcWidth. If neither is defined, then inner radius is 0.
    if (config.arcRatio != null) {
      return max(radius - radius * config.arcRatio, 0.0).toDouble();
    } else if (config.arcWidth != null) {
      return max(radius - config.arcWidth, 0.0).toDouble();
    } else {
      return 0.0;
    }
  }
}

class _ArcRendererElement<D> {
  double startAngle;
  double endAngle;
  Color color;
  num key;
  num measure;

  _ArcRendererElement<D> clone() {
    return new _ArcRendererElement<D>()
      ..startAngle = startAngle
      ..endAngle = endAngle
      ..color = new Color.fromOther(color: color);
  }

  void updateAnimationPercent(_ArcRendererElement previous,
      _ArcRendererElement target, double animationPercent) {
    startAngle =
        ((target.startAngle - previous.startAngle) * animationPercent) +
            previous.startAngle;

    endAngle = ((target.endAngle - previous.endAngle) * animationPercent) +
        previous.endAngle;

    color = getAnimatedColor(previous.color, target.color, animationPercent);
  }
}

class _AnimatedArcList<D> {
  final arcs = <_AnimatedArc<D>>[];
  Point center;
  double radius;
  double innerRadius;
  Color stroke;
  double strokeWidthPx;
}

class _AnimatedArc<D> {
  final String key;
  dynamic datum;

  _ArcRendererElement<D> _previousArc;
  _ArcRendererElement<D> _targetArc;
  _ArcRendererElement<D> _currentArc;

  // Flag indicating whether this arc is being animated out of the chart.
  bool animatingOut = false;

  _AnimatedArc(this.key, this.datum);

  /// Animates a arc that was removed from the series out of the view.
  ///
  /// This should be called in place of "setNewTarget" for arcs that represent
  /// data that has been removed from the series.
  ///
  /// Animates the angle of the arc to [endAngle], in radians.
  void animateOut(endAngle) {
    var newTarget = _currentArc.clone();

    // Animate the arc out by setting the angles to 0.
    newTarget.startAngle = endAngle;
    newTarget.endAngle = endAngle;

    setNewTarget(newTarget);
    animatingOut = true;
  }

  void setNewTarget(_ArcRendererElement<D> newTarget) {
    animatingOut = false;
    _currentArc ??= newTarget.clone();
    _previousArc = _currentArc.clone();
    _targetArc = newTarget;
  }

  _ArcRendererElement<D> getCurrentArc(double animationPercent) {
    if (animationPercent == 1.0 || _previousArc == null) {
      _currentArc = _targetArc;
      _previousArc = _targetArc;
      return _currentArc;
    }

    _currentArc.updateAnimationPercent(
        _previousArc, _targetArc, animationPercent);

    return _currentArc;
  }

  /// Returns the [startAngle] of the new target element, without updating
  /// animation state.
  double get newTargetArcStartAngle {
    return _targetArc != null ? _targetArc.startAngle : null;
  }

  /// Returns the [endAngle] of the new target element, without updating
  /// animation state.
  double get previousArcEndAngle {
    return _previousArc != null ? _previousArc.endAngle : null;
  }

  /// Returns the [startAngle] of the previously rendered element, without
  /// updating animation state.
  double get previousArcStartAngle {
    return _previousArc != null ? _previousArc.startAngle : null;
  }
}

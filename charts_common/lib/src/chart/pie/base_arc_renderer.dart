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

import 'dart:math' show atan2, cos, sin, pi, Point, Rectangle;

import 'package:meta/meta.dart' show protected;

import '../../common/math.dart' show NullablePoint;
import '../../data/series.dart' show AttributeKey;
import '../common/base_chart.dart' show BaseChart;
import '../common/canvas_shapes.dart' show CanvasPieSlice, CanvasPie;
import '../common/chart_canvas.dart' show ChartCanvas;
import '../common/datum_details.dart' show DatumDetails;
import '../common/processed_series.dart' show MutableSeries;
import '../common/series_datum.dart' show SeriesDatum;
import '../common/series_renderer.dart' show BaseSeriesRenderer;
import 'arc_renderer_config.dart' show ArcRendererConfig;
import 'arc_renderer_decorator.dart' show ArcRendererDecorator;
import 'arc_renderer_element.dart'
    show
        ArcRendererElement,
        ArcRendererElementList,
        AnimatedArcList,
        AnimatedArc;
import 'base_arc_renderer_config.dart' show BaseArcRendererConfig;

const arcElementsKey =
    AttributeKey<List<ArcRendererElement<Object>>>('ArcRenderer.elements');

abstract class BaseArcRenderer<D> extends BaseSeriesRenderer<D> {
  // Constant used in the calculation of [centerContentBounds], calculated
  // once to save runtime cost.
  static final _cosPIOver4 = cos(pi / 4);

  final BaseArcRendererConfig<D> config;

  final List<ArcRendererDecorator<D>> arcRendererDecorators;

  @protected
  BaseChart<D>? chart;

  BaseArcRenderer({required this.config, required String rendererId})
      : arcRendererDecorators = config.arcRendererDecorators,
        super(
            rendererId: rendererId,
            layoutPaintOrder: config.layoutPaintOrder,
            symbolRenderer: config.symbolRenderer);

  @override
  void onAttach(BaseChart<D> chart) {
    super.onAttach(chart);
    this.chart = chart;
  }

  @override
  void configureSeries(List<MutableSeries<D>> seriesList) {
    assignMissingColors(seriesList, emptyCategoryUsesSinglePalette: false);
  }

  bool get isRtl => chart?.context.isRtl ?? false;

  /// Gets a bounding box for the largest center content card that can fit
  /// inside the hole of the chart.
  ///
  /// If the inner radius of the arcs is smaller than
  /// [ArcRendererConfig.minHoleWidthForCenterContent], this will return a
  /// rectangle of 0 width and height to indicate that no card can fit inside
  /// the chart.
  Rectangle<int> get centerContentBounds {
    // Grab the first arcList from the animated set.
    var arcLists = getArcLists();
    var arcList = arcLists.isNotEmpty ? arcLists.first : null;

    // No card should be visible if the hole in the chart is too small.
    if (arcList == null ||
        arcList.innerRadius! < config.minHoleWidthForCenterContent) {
      // Return default bounds of 0 size.
      final bounds = chart!.drawAreaBounds;
      return Rectangle<int>((bounds.left + bounds.width / 2).round(),
          (bounds.top + bounds.height / 2).round(), 0, 0);
    }

    // Fix the height and width of the center content div to the maximum box
    // size that will fit within the pie's inner radius.
    final width = (_cosPIOver4 * arcList.innerRadius!).floor();

    return Rectangle<int>((arcList.center!.x - width).round(),
        (arcList.center!.y - width).round(), width * 2, width * 2);
  }

  /// Returns an expanded [DatumDetails] object that contains location data.
  DatumDetails<D> getExpandedDatumDetails(SeriesDatum<D> seriesDatum) {
    final series = seriesDatum.series;
    final Object? datum = seriesDatum.datum;
    final datumIndex = seriesDatum.index;

    final domain = series.domainFn(datumIndex);
    final measure = series.measureFn(datumIndex);
    final color = series.colorFn!(datumIndex);

    final chartPosition = _getChartPosition(series.id, '${series.id}__$domain');

    return DatumDetails(
        datum: datum,
        domain: domain,
        measure: measure,
        series: series,
        color: color,
        chartPosition: NullablePoint.from(chartPosition));
  }

  /// Returns the List of AnimatedArcList associated with the renderer. The Pie
  /// Chart has one AnimatedArcList and the Sunburst chart usually has multiple
  /// elements.
  @protected
  List<AnimatedArcList<D>> getArcLists({String? seriesId});

  /// Returns the chart position for a given datum by series ID and domain
  /// value.
  ///
  /// [seriesId] the series ID.
  ///
  /// [key] the key in the current animated arc list.
  Point<double>? _getChartPosition(String seriesId, String key) {
    Point<double>? chartPosition;

    final arcLists = getArcLists(seriesId: seriesId);

    if (arcLists.isEmpty) {
      return chartPosition;
    }

    for (var arcList in arcLists) {
      for (final arc in arcList.arcs) {
        if (arc.key == key) {
          // Now that we have found the matching arc, calculate the center
          // point halfway between the inner and outer radius, and the start
          // and end angles.
          final centerAngle = arc.currentArcStartAngle! +
              (arc.currentArcEndAngle! - arc.currentArcStartAngle!) / 2;

          final centerPointRadius = arcList.innerRadius! +
              (arcList.radius! - arcList.innerRadius!) / 2;

          chartPosition = Point<double>(
              centerPointRadius * cos(centerAngle) + arcList.center!.x,
              centerPointRadius * sin(centerAngle) + arcList.center!.y);

          break;
        }
      }
    }

    return chartPosition;
  }

  @override
  void paint(ChartCanvas canvas, double animationPercent) {
    final arcLists = getArcLists();
    var arcListToElementsList = {};
    for (var arcList in arcLists) {
      final elementsList = ArcRendererElementList<D>(
        arcs: <ArcRendererElement<D>>[],
        center: arcList.center!,
        innerRadius: arcList.innerRadius!,
        radius: arcList.radius!,
        startAngle: config.startAngle,
        stroke: arcList.stroke,
        strokeWidthPx: arcList.strokeWidthPx,
      );

      arcListToElementsList[arcList] = elementsList;
    }

    // Decorate the arcs with decorators that should appear below the main
    // series data.
    arcRendererDecorators
        .where((decorator) => !decorator.renderAbove)
        .forEach((decorator) {
      decorator.decorate(
          arcLists
              .map<ArcRendererElementList<D>>((e) => arcListToElementsList[e])
              .toList(),
          canvas,
          graphicsFactory!,
          drawBounds: drawBounds!,
          animationPercent: animationPercent,
          rtl: isRtl);
    });

    for (var arcList in arcLists) {
      final circleSectors = <CanvasPieSlice>[];

      arcList.arcs
          .map<ArcRendererElement<D>>((AnimatedArc<D> animatingArc) =>
              animatingArc.getCurrentArc(animationPercent))
          .forEach((arc) {
        circleSectors
            .add(CanvasPieSlice(arc.startAngle, arc.endAngle, fill: arc.color));

        arcListToElementsList[arcList].arcs.add(arc);
      });

      // Draw the arcs.
      canvas.drawPie(CanvasPie(
          circleSectors, arcList.center!, arcList.radius!, arcList.innerRadius!,
          stroke: arcList.stroke, strokeWidthPx: arcList.strokeWidthPx ?? 0));
    }

    // Decorate the arcs with decorators that should appear above the main
    // series data. This is the typical place for labels.
    arcRendererDecorators
        .where((decorator) => decorator.renderAbove)
        .forEach((decorator) {
      decorator.decorate(
          arcLists
              .map<ArcRendererElementList<D>>((e) => arcListToElementsList[e])
              .toList(),
          canvas,
          graphicsFactory!,
          drawBounds: drawBounds!,
          animationPercent: animationPercent,
          rtl: isRtl);
    });
  }

  @override
  List<DatumDetails<D>> getNearestDatumDetailPerSeries(
    Point<double> chartPoint,
    bool byDomain,
    Rectangle<int>? boundsOverride, {
    bool selectOverlappingPoints = false,
    bool selectExactEventLocation = false,
  }) {
    final nearest = <DatumDetails<D>>[];

    // Was it even in the component bounds?
    if (!isPointWithinBounds(chartPoint, boundsOverride)) {
      return nearest;
    }

    final arcLists = getArcLists();

    for (var arcList in arcLists) {
      if (arcList.series!.overlaySeries) {
        return nearest;
      }

      final center = arcList.center!;
      final innerRadius = arcList.innerRadius!;
      final radius = arcList.radius!;

      final distance = center.distanceTo(chartPoint);

      // Calculate the angle of [chartPoint] from the center of the arcs.
      var chartPointAngle =
          atan2(chartPoint.y - center.y, chartPoint.x - center.x);

      // atan2 returns NaN if we are at the exact center of the circle.
      if (chartPointAngle.isNaN) {
        chartPointAngle = config.startAngle;
      }

      // atan2 returns an angle in the range -PI..PI, from the positive x-axis.
      // Our arcs start at the positive y-axis, in the range -PI/2..3PI/2. Thus,
      // if angle is in the -x, +y section of the circle, we need to adjust the
      // angle into our range.
      if (chartPointAngle < config.startAngle && chartPointAngle < 0) {
        chartPointAngle = 2 * pi + chartPointAngle;
      }

      arcList.arcs.forEach((AnimatedArc<D> arc) {
        if (innerRadius <= distance &&
            distance <= radius &&
            arc.currentArcStartAngle! <= chartPointAngle &&
            chartPointAngle <= arc.currentArcEndAngle!) {
          nearest.add(DatumDetails<D>(
            series: arcList.series,
            datum: arc.datum,
            domain: arc.domain,
            domainDistance: 0.0,
            measureDistance: 0.0,
          ));
        }
      });
    }

    return nearest;
  }

  @override
  DatumDetails<D> addPositionToDetailsForSeriesDatum(
      DatumDetails<D> details, SeriesDatum<D> seriesDatum) {
    final chartPosition =
        _getChartPosition(details.series!.id, details.domain.toString());

    return DatumDetails.from(details,
        chartPosition: NullablePoint.from(chartPosition));
  }
}

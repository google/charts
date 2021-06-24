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

import 'package:meta/meta.dart';

import '../../common/symbol_renderer.dart' show SymbolRenderer;
import '../../data/series.dart' show AccessorFn;
import '../common/base_chart.dart' show BaseChart;
import '../common/processed_series.dart' show MutableSeries;
import '../common/series_renderer.dart' show BaseSeriesRenderer, SeriesRenderer;
import 'axis/axis.dart' show Axis, domainAxisKey, measureAxisKey;
import 'cartesian_chart.dart' show CartesianChart;

abstract class CartesianRenderer<D> extends SeriesRenderer<D> {
  @override
  void configureDomainAxes(List<MutableSeries<D>> seriesList);

  @override
  void configureMeasureAxes(List<MutableSeries<D>> seriesList);
}

abstract class BaseCartesianRenderer<D> extends BaseSeriesRenderer<D>
    implements CartesianRenderer<D> {
  BaseCartesianRenderer({
    required String rendererId,
    required int layoutPaintOrder,
    SymbolRenderer? symbolRenderer,
  }) : super(
            rendererId: rendererId,
            layoutPaintOrder: layoutPaintOrder,
            symbolRenderer: symbolRenderer);

  @protected
  late CartesianChart<D> chart;

  @override
  void onAttach(BaseChart<D> chart) {
    super.onAttach(chart);

    // Save a reference to the parent chart so that we can access properties
    // that are not set until a later state (e.g. isRtl), or that might change
    // dynamically (e.g. vertical).
    this.chart = chart as CartesianChart<D>;
  }

  // True when the chart should be rendered in vertical mode, false when in
  // horizontal mode.
  bool get renderingVertically => chart.vertical;

  @override
  void configureDomainAxes(List<MutableSeries<D>> seriesList) {
    seriesList.forEach((MutableSeries<D> series) {
      if (series.data.isEmpty) {
        return;
      }

      final domainAxis = series.getAttr(domainAxisKey);
      final domainFn = series.domainFn;
      final domainLowerBoundFn = series.domainLowerBoundFn;
      final domainUpperBoundFn = series.domainUpperBoundFn;

      if (domainAxis == null) {
        return;
      }

      if (renderingVertically) {
        for (var i = 0; i < series.data.length; i++) {
          domainAxis.addDomainValue(domainFn(i)!);

          if (domainLowerBoundFn != null && domainUpperBoundFn != null) {
            final domainLowerBound = domainLowerBoundFn(i);
            final domainUpperBound = domainUpperBoundFn(i);
            if (domainLowerBound != null && domainUpperBound != null) {
              domainAxis.addDomainValue(domainLowerBound);
              domainAxis.addDomainValue(domainUpperBound);
            }
          }
        }
      } else {
        // When rendering horizontally, domains are displayed from top to bottom
        // in order to match visual display in legend.
        for (var i = series.data.length - 1; i >= 0; i--) {
          domainAxis.addDomainValue(domainFn(i)!);

          if (domainLowerBoundFn != null && domainUpperBoundFn != null) {
            final domainLowerBound = domainLowerBoundFn(i);
            final domainUpperBound = domainUpperBoundFn(i);
            if (domainLowerBound != null && domainUpperBound != null) {
              domainAxis.addDomainValue(domainLowerBound);
              domainAxis.addDomainValue(domainUpperBound);
            }
          }
        }
      }
    });
  }

  @override
  void configureMeasureAxes(List<MutableSeries<D>> seriesList) {
    seriesList.forEach((MutableSeries<D> series) {
      if (series.data.isEmpty) {
        return;
      }

      final domainAxis = series.getAttr(domainAxisKey) as Axis<D>?;
      final domainFn = series.domainFn;

      if (domainAxis == null) {
        return;
      }

      final measureAxis = series.getAttr(measureAxisKey) as Axis<num>?;
      if (measureAxis == null) {
        return;
      }

      // Only add the measure values for datum who's domain is within the
      // domainAxis viewport.
      final startIndex =
          findNearestViewportStart(domainAxis, domainFn, series.data);
      final endIndex =
          findNearestViewportEnd(domainAxis, domainFn, series.data);

      addMeasureValuesFor(series, measureAxis, startIndex, endIndex);
    });
  }

  void addMeasureValuesFor(
    MutableSeries<D> series,
    Axis<num> measureAxis,
    int startIndex,
    int endIndex,
  ) {
    final measureFn = series.measureFn;
    final measureOffsetFn = series.measureOffsetFn!;
    final measureLowerBoundFn = series.measureLowerBoundFn;
    final measureUpperBoundFn = series.measureUpperBoundFn;

    for (var i = startIndex; i <= endIndex; i++) {
      final measure = measureFn(i);
      final measureOffset = measureOffsetFn(i);

      if (measure != null && measureOffset != null) {
        measureAxis.addDomainValue(measure + measureOffset);

        if (measureLowerBoundFn != null && measureUpperBoundFn != null) {
          measureAxis
              .addDomainValue((measureLowerBoundFn(i) ?? 0) + measureOffset);
          measureAxis
              .addDomainValue((measureUpperBoundFn(i) ?? 0) + measureOffset);
        }
      }
    }
  }

  @visibleForTesting
  int findNearestViewportStart(
      Axis<D> domainAxis, AccessorFn<D> domainFn, List<Object?> data) {
    assert(data.isNotEmpty);

    // Quick optimization for full viewport (likely).
    if (domainAxis.compareDomainValueToViewport(domainFn(0)) == 0) {
      return 0;
    }

    var start = 1; // Index zero was already checked for above.
    var end = data.length - 1;

    // Binary search for the start of the viewport.
    while (end >= start) {
      final searchIndex = ((end - start) / 2).floor() + start;
      final prevIndex = searchIndex - 1;

      var comparisonValue =
          domainAxis.compareDomainValueToViewport(domainFn(searchIndex));
      var prevComparisonValue =
          domainAxis.compareDomainValueToViewport(domainFn(prevIndex));

      // Found start?
      if (prevComparisonValue == -1 && comparisonValue == 0) {
        return searchIndex;
      }

      // Straddling viewport?
      // Return previous index as the nearest start of the viewport.
      if (comparisonValue == 1 && prevComparisonValue == -1) {
        return searchIndex - 1;
      }

      // Before start? Update startIndex
      if (comparisonValue == -1) {
        start = searchIndex + 1;
      } else {
        // Middle or after viewport? Update endIndex
        end = searchIndex - 1;
      }
    }

    // Binary search would reach this point for the edge cases where the domain
    // specified is prior or after the domain viewport.
    // If domain is prior to the domain viewport, return the first index as the
    // nearest viewport start.
    // If domain is after the domain viewport, return the last index as the
    // nearest viewport start.
    final lastComparison =
        domainAxis.compareDomainValueToViewport(domainFn(data.length - 1));
    return lastComparison == 1 ? (data.length - 1) : 0;
  }

  @visibleForTesting
  int findNearestViewportEnd(
      Axis<D> domainAxis, AccessorFn<D> domainFn, List<Object?> data) {
    assert(data.isNotEmpty);

    var start = 1;
    var end = data.length - 1;

    // Quick optimization for full viewport (likely).
    if (domainAxis.compareDomainValueToViewport(domainFn(end)) == 0) {
      return end;
    }
    end = end - 1; // Last index was already checked for above.

    // Binary search for the start of the viewport.
    while (end >= start) {
      final searchIndex = ((end - start) / 2).floor() + start;
      final prevIndex = searchIndex - 1;

      final comparisonValue =
          domainAxis.compareDomainValueToViewport(domainFn(searchIndex));
      final prevComparisonValue =
          domainAxis.compareDomainValueToViewport(domainFn(prevIndex));

      // Found end?
      if (prevComparisonValue == 0 && comparisonValue == 1) {
        return prevIndex;
      }

      // Straddling viewport?
      // Return the current index as the start of the viewport.
      if (comparisonValue == 1 && prevComparisonValue == -1) {
        return searchIndex;
      }

      // After end? Update endIndex
      if (comparisonValue == 1) {
        end = searchIndex - 1;
      } else {
        // Middle or before viewport? Update startIndex
        start = searchIndex + 1;
      }
    }

    // Binary search would reach this point for the edge cases where the domain
    // specified is prior or after the domain viewport.
    // If domain is prior to the domain viewport, return the first index as the
    // nearest viewport end.
    // If domain is after the domain viewport, return the last index as the
    // nearest viewport end.
    final lastComparison =
        domainAxis.compareDomainValueToViewport(domainFn(data.length - 1));
    return lastComparison == 1 ? (data.length - 1) : 0;
  }
}

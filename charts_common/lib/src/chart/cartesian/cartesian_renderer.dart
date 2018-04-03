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

import 'axis/axis.dart' show Axis, domainAxisKey, measureAxisKey;
import 'cartesian_chart.dart' show CartesianChart;
import '../common/base_chart.dart' show BaseChart;
import '../common/series_renderer.dart' show BaseSeriesRenderer, SeriesRenderer;
import '../common/processed_series.dart' show MutableSeries;
import '../../data/series.dart' show AccessorFn;
import '../../common/symbol_renderer.dart' show SymbolRenderer;

abstract class CartesianRenderer<T, D> extends SeriesRenderer<T, D> {
  void configureDomainAxes(List<MutableSeries<T, D>> seriesList);
  void configureMeasureAxes(List<MutableSeries<T, D>> seriesList);
}

abstract class BaseCartesianRenderer<T, D> extends BaseSeriesRenderer<T, D>
    implements CartesianRenderer<T, D> {
  bool _renderingVertically = true;

  BaseCartesianRenderer(
      {@required String rendererId,
      @required int layoutPositionOrder,
      SymbolRenderer symbolRenderer})
      : super(
            rendererId: rendererId,
            layoutPositionOrder: layoutPositionOrder,
            symbolRenderer: symbolRenderer);

  @override
  void onAttach(BaseChart<T, D> chart) {
    super.onAttach(chart);
    _renderingVertically = (chart as CartesianChart).vertical;
  }

  bool get renderingVertically => _renderingVertically;

  @override
  void configureDomainAxes(List<MutableSeries<T, D>> seriesList) {
    seriesList.forEach((MutableSeries<T, D> series) {
      var domainAxis = series.getAttr(domainAxisKey);
      var domainFn = series.domainFn;

      if (domainAxis == null) {
        return;
      }

      if (renderingVertically) {
        for (int i = 0; i < series.data.length; i++) {
          domainAxis.addDomainValue(domainFn(series.data[i], i));
        }
      } else {
        // When rendering horizontally, domains are displayed from top to bottom
        // in order to match visual display in legend.
        for (int i = series.data.length - 1; i >= 0; i--) {
          domainAxis.addDomainValue(domainFn(series.data[i], i));
        }
      }
    });
  }

  @override
  void configureMeasureAxes(List<MutableSeries<T, D>> seriesList) {
    seriesList.forEach((MutableSeries<T, D> series) {
      var domainAxis = series.getAttr(domainAxisKey);
      var domainFn = series.domainFn;

      if (domainAxis == null) {
        return;
      }

      var measureAxis = series.getAttr(measureAxisKey);
      if (measureAxis == null) {
        return;
      }

      // Only add the measure values for datum who's domain is within the
      // domainAxis viewport.
      int startIndex =
          findNearestViewportStart(domainAxis, domainFn, series.data);
      int endIndex = findNearestViewportEnd(domainAxis, domainFn, series.data);

      addMeasureValuesFor(series, measureAxis, startIndex, endIndex);
    });
  }

  void addMeasureValuesFor(MutableSeries<T, D> series, Axis measureAxis,
      int startIndex, int endIndex) {
    for (int i = startIndex; i <= endIndex; i++) {
      final measure = series.measureFn(series.data[i], i);

      if (measure != null) {
        measureAxis.addDomainValue(series.measureFn(series.data[i], i) +
            series.measureOffsetFn(series.data[i], i));
      }
    }
  }

  @visibleForTesting
  int findNearestViewportStart(
      Axis domainAxis, AccessorFn<T, D> domainFn, List<T> data) {
    // Quick optimization for full viewport (likely).
    if (domainAxis.compareDomainValueToViewport(domainFn(data[0], 0)) == 0) {
      return 0;
    }

    var start = 1; // Index zero was already checked for above.
    var end = data.length - 1;

    // Binary search for the start of the viewport.
    while (end >= start) {
      int searchIndex = ((end - start) / 2).floor() + start;
      int prevIndex = searchIndex - 1;

      var comparisonValue = domainAxis.compareDomainValueToViewport(
          domainFn(data[searchIndex], searchIndex));
      var prevComparisonValue = domainAxis
          .compareDomainValueToViewport(domainFn(data[prevIndex], prevIndex));

      // Found start?
      if (prevComparisonValue == -1 && comparisonValue == 0) {
        return searchIndex;
      }

      // Straddling viewport?
      // Return previous index as the nearest start of the viewport.
      if (comparisonValue == 1 && prevComparisonValue == -1) {
        return (searchIndex - 1);
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
    var lastComparison = domainAxis.compareDomainValueToViewport(
        domainFn(data[data.length - 1], data.length - 1));
    return lastComparison == -1 ? (data.length - 1) : 0;
  }

  @visibleForTesting
  int findNearestViewportEnd(
      Axis domainAxis, AccessorFn<T, D> domainFn, List<T> data) {
    var start = 1;
    var end = data.length - 1;

    // Quick optimization for full viewport (likely).
    if (domainAxis.compareDomainValueToViewport(domainFn(data[end], end)) ==
        0) {
      return end;
    }
    end = end - 1; // Last index was already checked for above.

    // Binary search for the start of the viewport.
    while (end >= start) {
      int searchIndex = ((end - start) / 2).floor() + start;
      int prevIndex = searchIndex - 1;

      int comparisonValue = domainAxis.compareDomainValueToViewport(
          domainFn(data[searchIndex], searchIndex));
      int prevComparisonValue = domainAxis
          .compareDomainValueToViewport(domainFn(data[prevIndex], prevIndex));

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
    var lastComparison = domainAxis.compareDomainValueToViewport(
        domainFn(data[data.length - 1], data.length - 1));
    return lastComparison == -1 ? (data.length - 1) : 0;
  }
}

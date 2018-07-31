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

import 'dart:collection' show HashSet;
import 'legend_entry.dart';
import 'legend_entry_generator.dart';
import '../../selection_model/selection_model.dart';
import '../../../cartesian/axis/axis.dart' show Axis, measureAxisIdKey;
import '../../datum_details.dart' show MeasureFormatter;
import '../../processed_series.dart' show MutableSeries, SeriesDatum;

/// A strategy for generating a list of [LegendEntry] per series drawn.
///
/// [T] the datum class type for chart.
/// [D] the domain class type for the datum.
class PerSeriesLegendEntryGenerator<D> implements LegendEntryGenerator<D> {
  MeasureFormatter measureFormatter;
  MeasureFormatter secondaryMeasureFormatter;

  @override
  List<LegendEntry<D>> getLegendEntries(List<MutableSeries<D>> seriesList) {
    return seriesList.map((series) {
      final color = series.colorFn(0);

      return new LegendEntry<D>(series, series.displayName, color: color);
    }).toList();
  }

  @override
  void updateLegendEntries(
      List<LegendEntry<D>> legendEntries, SelectionModel<D> selectionModel) {
    // Map of series ID to the total selected measure value for that series.
    final seriesAndMeasure = <String, num>{};

    // Hash set of series ID's that use the secondary measure axis
    final secondaryAxisSeriesIDs = new HashSet<String>();

    for (SeriesDatum<D> selectedDatum in selectionModel.selectedDatum) {
      final series = selectedDatum.series;
      final seriesId = series.id;
      final measure = series.measureFn(selectedDatum.index) ?? 0;

      seriesAndMeasure[seriesId] = seriesAndMeasure.containsKey(seriesId)
          ? seriesAndMeasure[seriesId] + measure
          : measure;

      if (series.getAttr(measureAxisIdKey) == Axis.secondaryMeasureAxisId) {
        secondaryAxisSeriesIDs.add(seriesId);
      }
    }

    for (var entry in legendEntries) {
      final seriesId = entry.series.id;
      final measureValue = seriesAndMeasure[seriesId]?.toDouble();
      final formattedValue = secondaryAxisSeriesIDs.contains(seriesId)
          ? secondaryMeasureFormatter(measureValue)
          : measureFormatter(measureValue);

      entry.value = measureValue;
      entry.formattedValue = formattedValue;
      entry.isSelected = selectionModel.selectedSeries
          .any((selectedSeries) => entry.series.id == selectedSeries.id);
    }
  }

  @override
  bool operator ==(Object o) {
    return o is PerSeriesLegendEntryGenerator &&
        measureFormatter == o.measureFormatter &&
        secondaryMeasureFormatter == o.secondaryMeasureFormatter;
  }

  @override
  int get hashCode {
    int hashcode = measureFormatter?.hashCode ?? 0;
    hashcode = (hashcode * 37) + secondaryMeasureFormatter.hashCode;
    return hashcode;
  }
}

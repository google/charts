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

import 'legend_entry.dart';
import '../../selection_model/selection_model.dart';
import '../../processed_series.dart' show MutableSeries;
import 'legend_entry_generator.dart';

/// A strategy for generating a list of [LegendEntry] per series drawn.
///
/// [T] the datum class type for chart.
/// [D] the domain class type for the datum.
class PerSeriesLegendEntryGenerator<D> implements LegendEntryGenerator<D> {
  const PerSeriesLegendEntryGenerator();

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
    for (var entry in legendEntries) {
      entry.isSelected = selectionModel.selectedSeries
          .any((selectedSeries) => entry.series.id == selectedSeries.id);
    }
  }
}

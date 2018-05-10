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

import '../base_chart.dart' show BaseChart, LifecycleListener;
import '../processed_series.dart' show MutableSeries, SeriesDatum;
import '../selection_model/selection_model.dart' show SelectionModelType;
import 'chart_behavior.dart' show ChartBehavior;

/// Behavior that sets initial selection.
class InitialSelection<D> implements ChartBehavior<D> {
  final SelectionModelType selectionModelType;

  /// List of series id of initially selected series.
  final List<String> selectedSeriesConfig;

  /// List of [SeriesDatumConfig] that represents the initially selected datums.
  final List<SeriesDatumConfig> selectedDataConfig;

  BaseChart<D> _chart;
  LifecycleListener<D> _lifecycleListener;
  bool _firstDraw = true;

  // TODO : When the series changes, if the user does not also
  // change the index the wrong item could be highlighted.
  InitialSelection(
      {this.selectionModelType = SelectionModelType.info,
      this.selectedDataConfig,
      this.selectedSeriesConfig}) {
    _lifecycleListener = new LifecycleListener<D>(onData: _setInitialSelection);
  }

  void _setInitialSelection(List<MutableSeries<D>> seriesList) {
    if (!_firstDraw) {
      return;
    }
    _firstDraw = false;

    final selectionModel = _chart.getSelectionModel(selectionModelType);

    final selectedData = <SeriesDatum<D>>[];
    final selectedSeries = <MutableSeries<D>>[];
    final selectedDataMap = <String, List<D>>{};

    if (selectedDataConfig != null) {
      for (SeriesDatumConfig config in selectedDataConfig) {
        selectedDataMap[config.seriesId] ??= <D>[];
        selectedDataMap[config.seriesId].add(config.domainValue);
      }

      // Add to list of selected series.
      selectedSeries.addAll(seriesList.where((MutableSeries<D> series) =>
          selectedDataMap.keys.contains(series.id)));

      // Add to list of selected data.
      for (MutableSeries<D> series in seriesList) {
        if (selectedDataMap.containsKey(series.id)) {
          final domainFn = series.domainFn;

          for (var i = 0; i < series.data.length; i++) {
            final datum = series.data[i];

            if (selectedDataMap[series.id].contains(domainFn(i))) {
              selectedData.add(new SeriesDatum(series, datum));
            }
          }
        }
      }
    }

    // Add to list of selected series, if it does not already exist.
    if (selectedSeriesConfig != null) {
      final remainingSeriesToAdd = selectedSeriesConfig
          .where((String seriesId) => !selectedSeries.contains(seriesId))
          .toList();

      selectedSeries.addAll(seriesList.where((MutableSeries<D> series) =>
          remainingSeriesToAdd.contains(series.id)));
    }

    selectionModel.updateSelection(selectedData, selectedSeries,
        notifyListeners: false);
  }

  @override
  void attachTo(BaseChart<D> chart) {
    _chart = chart;
    chart.addLifecycleListener(_lifecycleListener);
  }

  @override
  void removeFrom(BaseChart<D> chart) {
    chart.removeLifecycleListener(_lifecycleListener);
    _chart = null;
  }

  @override
  String get role => 'InitialSelection-${selectionModelType.toString()}}';
}

/// Represents a series datum based on series id and datum index.
class SeriesDatumConfig<D> {
  final String seriesId;
  final D domainValue;

  SeriesDatumConfig(this.seriesId, this.domainValue);

  @override
  bool operator ==(Object o) {
    return o is SeriesDatumConfig &&
        seriesId == o.seriesId &&
        domainValue == o.domainValue;
  }

  @override
  int get hashCode {
    int hashcode = seriesId.hashCode;
    hashcode = hashcode * 37 + domainValue.hashCode;
    return hashcode;
  }
}

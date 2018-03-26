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

import 'dart:math' show Rectangle;
import '../../base_chart.dart' show BaseChart, LifecycleListener;
import '../../chart_context.dart' show ChartContext;
import '../../processed_series.dart' show MutableSeries;
import '../../selection_model/selection_model.dart'
    show SelectionModel, SelectionModelType;
import '../chart_behavior.dart' show ChartBehavior;
import 'legend_entry.dart';
import 'legend_entry_generator.dart';
import 'per_series_legend_entry_generator.dart';

// TODO: Allow tapping on a series to remove series from draw area.
// TODO: Allows for hovering over a series in legend to highlight
// corresponding series in draw area.

/// Series legend behavior for charts.
///
/// By default this behavior creates a legend entry per series.
class SeriesLegend<T, D> extends Legend<T, D> {
  SeriesLegend(
      {SelectionModelType selectionModelType,
      LegendEntryGenerator<T, D> legendEntryGenerator})
      : super(
            selectionModelType: selectionModelType ?? SelectionModelType.info,
            legendEntryGenerator:
                legendEntryGenerator ?? new PerSeriesLegendEntryGenerator());
}

/// Legend behavior for charts.
///
/// Since legends are desired to be customizable, building and displaying the
/// visual content of legends is done on the native platforms. This allows users
/// to specify customized content for legends using the native platform (ex. for
/// Flutter, using widgets).
abstract class Legend<T, D> implements ChartBehavior<T, D> {
  final SelectionModelType selectionModelType;
  final legendState = new LegendState();
  final LegendEntryGenerator<T, D> legendEntryGenerator;

  BaseChart _chart;
  LifecycleListener<T, D> _lifecycleListener;

  Legend({this.selectionModelType, this.legendEntryGenerator}) {
    _lifecycleListener = new LifecycleListener(onPostprocess: _postProcess);
  }

  /// Build LegendEntries from list of series.
  void _postProcess(List<MutableSeries<T, D>> seriesList) {
    legendState._legendEntries =
        legendEntryGenerator.getLegendEntries(seriesList);
    updateLegend();
  }

  /// Update the legend state with [selectionModel] and request legend update.
  void _selectionChanged(SelectionModel selectionModel) {
    legendState._selectionModel = selectionModel;
    legendEntryGenerator.updateLegendEntries(
        legendState.legendEntries, legendState.selectionModel);
    updateLegend();
  }

  ChartContext get chartContext => _chart.context;

  // Gets the draw area bounds for native legend content to position itself
  // accordingly.
  Rectangle<int> get drawAreaBounds => _chart.drawAreaBounds;

  /// Requires override to show in native platform
  void updateLegend() {}

  @override
  void attachTo(BaseChart<T, D> chart) {
    _chart = chart;
    chart.addLifecycleListener(_lifecycleListener);
    chart
        .getSelectionModel(selectionModelType)
        .addSelectionListener(_selectionChanged);
  }

  @override
  void removeFrom(BaseChart chart) {
    chart
        .getSelectionModel(selectionModelType)
        .removeSelectionListener(_selectionChanged);
    chart.removeLifecycleListener(_lifecycleListener);
  }

  @override
  String get role => 'legend-${selectionModelType.toString()}';
}

/// Stores legend data used by native legend content builder.
class LegendState<T, D> {
  List<LegendEntry<T, D>> _legendEntries;
  SelectionModel _selectionModel;

  List<LegendEntry<T, D>> get legendEntries => _legendEntries;
  SelectionModel get selectionModel => _selectionModel;
}

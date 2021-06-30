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

import '../base_chart.dart' show BaseChart;
import '../selection_model/selection_model.dart'
    show SelectionModel, SelectionModelType;
import '../../sunburst/sunburst_chart.dart' show SunburstChart;
import 'chart_behavior.dart' show ChartBehavior;

/// Expands the initially displayed outer ring to show subset of data in one
/// final ring.
class SunburstRingExpander<D> implements ChartBehavior<D> {
  final SelectionModelType selectionModelType;

  late SunburstChart<D> _chart;

  SunburstRingExpander([this.selectionModelType = SelectionModelType.action]);

  void _selectionChanged(SelectionModel<D> selectionModel) {
    if (selectionModel.selectedDatum.isNotEmpty) {
      _chart.expandNode(selectionModel.selectedDatum.first.datum);
      _chart.redraw(skipLayout: true, skipAnimation: true);
    }
  }

  @override
  void attachTo(BaseChart<D> chart) {
    if (!(chart is SunburstChart)) {
      throw ArgumentError(
          'SunburstRingExpander can only be attached to a Sunburst chart');
    }
    _chart = chart as SunburstChart<D>;
    chart
        .getSelectionModel(selectionModelType)
        .addSelectionUpdatedListener(_selectionChanged);
  }

  @override
  void removeFrom(BaseChart<D> chart) {
    chart
        .getSelectionModel(selectionModelType)
        .addSelectionUpdatedListener(_selectionChanged);
  }

  @override
  String get role => 'sunburstRingExpander-$selectionModelType';
}

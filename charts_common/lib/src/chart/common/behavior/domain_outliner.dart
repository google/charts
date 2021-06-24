// Copyright 2019 the Charts project authors. Please see the AUTHORS file
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

import 'package:charts_common/src/chart/common/base_chart.dart';
import 'package:charts_common/src/chart/common/processed_series.dart';
import 'package:charts_common/src/chart/common/selection_model/selection_model.dart';

import 'chart_behavior.dart' show ChartBehavior;

/// Chart behavior that monitors the specified [SelectionModel] and outlines the
/// selected data.
///
/// This is typically used for treemap charts to highlight nodes.
/// For bars and pies, prefers to use [DomainHighlighter] for UX consistency.
class DomainOutliner<D> implements ChartBehavior<D> {
  final SelectionModelType selectionType;

  /// Default stroke width of the outline if the series has no stroke width
  /// function.
  ///
  /// When no stroke width function is provided, this value will be used as
  /// is. [strokePaddingPx] will not be added to [defaultStrokePx].
  final double defaultStrokePx;

  /// Additional stroke width added to the outline of the selected data.
  ///
  /// This value is only used when the series has a stroke width function
  /// defined.
  final double strokePaddingPx;

  late BaseChart<D> _chart;

  late LifecycleListener<D> _lifecycleListener;

  DomainOutliner({
    this.selectionType = SelectionModelType.info,
    double? defaultStrokePx,
    double? strokePaddingPx,
  })  : defaultStrokePx = defaultStrokePx ?? 2.0,
        strokePaddingPx = strokePaddingPx ?? 1.0 {
    _lifecycleListener = LifecycleListener<D>(onPostprocess: _outline);
  }

  void _selectionChange(SelectionModel<D> selectionModel) {
    _chart.redraw(skipLayout: true, skipAnimation: true);
  }

  void _outline(List<MutableSeries<D>> seriesList) {
    final selectionModel = _chart.getSelectionModel(selectionType);

    for (var series in seriesList) {
      final strokeWidthPxFn = series.strokeWidthPxFn;
      final colorFn = series.colorFn;

      if (colorFn != null) {
        series.colorFn = (int? index) {
          final color = colorFn(index);
          return selectionModel.isDatumSelected(series, index)
              ? color.darker
              : color;
        };
      }

      if (strokeWidthPxFn != null) {
        series.strokeWidthPxFn = (int? index) {
          final strokeWidthPx = strokeWidthPxFn(index);
          if (!selectionModel.isDatumSelected(series, index)) {
            return strokeWidthPx;
          }
          return strokeWidthPx == null
              ? defaultStrokePx
              : strokeWidthPx + strokePaddingPx;
        };
      }
    }
  }

  @override
  void attachTo(BaseChart<D> chart) {
    _chart = chart;
    chart.addLifecycleListener(_lifecycleListener);
    chart
        .getSelectionModel(selectionType)
        .addSelectionChangedListener(_selectionChange);
  }

  @override
  void removeFrom(BaseChart<D> chart) {
    chart
        .getSelectionModel(selectionType)
        .removeSelectionChangedListener(_selectionChange);
    chart.removeLifecycleListener(_lifecycleListener);
  }

  @override
  String get role => 'domainOutliner-$selectionType';
}

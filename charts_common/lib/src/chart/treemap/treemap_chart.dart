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
import 'package:charts_common/src/chart/common/datum_details.dart';
import 'package:charts_common/src/chart/common/processed_series.dart';
import 'package:charts_common/src/chart/common/selection_model/selection_model.dart';
import 'package:charts_common/src/chart/common/series_renderer.dart';
import 'package:charts_common/src/chart/layout/layout_config.dart';

import 'squarified_treemap_renderer.dart';

class TreeMapChart<D> extends BaseChart<D> {
  TreeMapChart({LayoutConfig? layoutConfig})
      : super(layoutConfig: layoutConfig ?? LayoutConfig());

  @override
  void drawInternal(List<MutableSeries<D>> seriesList,
      {bool? skipAnimation, bool? skipLayout}) {
    if (seriesList.length > 1) {
      throw ArgumentError('TreeMapChart can only render a single tree.');
    }
    super.drawInternal(seriesList,
        skipAnimation: skipAnimation, skipLayout: skipLayout);
  }

  /// Squarified treemap is used as default renderer.
  @override
  SeriesRenderer<D> makeDefaultRenderer() {
    return SquarifiedTreeMapRenderer<D>()
      ..rendererId = SeriesRenderer.defaultRendererId;
  }

  /// Returns a list of datum details from the selection model of [type].
  @override
  List<DatumDetails<D>> getDatumDetails(SelectionModelType type) {
    final details = <DatumDetails<D>>[];
    final treeMapSelection = getSelectionModel(type);

    for (final seriesDatum in treeMapSelection.selectedDatum) {
      final series = seriesDatum.series;
      final datumIndex = seriesDatum.index;
      final renderer = getSeriesRenderer(series.getAttr(rendererIdKey));

      final datumDetails = renderer.addPositionToDetailsForSeriesDatum(
          DatumDetails(
              datum: seriesDatum.datum,
              domain: series.domainFn(datumIndex),
              measure: series.measureFn(datumIndex),
              series: seriesDatum.series,
              color: series.colorFn!(datumIndex)),
          seriesDatum);
      details.add(datumDetails);
    }
    return details;
  }
}

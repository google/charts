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

import '../common/base_chart.dart' show BaseChart;
import '../common/datum_details.dart' show DatumDetails;
import '../common/selection_model/selection_model.dart' show SelectionModelType;
import '../common/series_renderer.dart' show rendererIdKey, SeriesRenderer;
import '../layout/layout_config.dart' show LayoutConfig;
import '../../data/tree.dart' show TreeNode;
import 'sunburst_arc_renderer.dart' show SunburstArcRenderer;

class SunburstChart<D> extends BaseChart<D> {
  SunburstChart({LayoutConfig? layoutConfig})
      : super(layoutConfig: layoutConfig);

  @override
  SeriesRenderer<D> makeDefaultRenderer() {
    return SunburstArcRenderer<D>()
      ..rendererId = SeriesRenderer.defaultRendererId;
  }

  /// Returns a list of datum details from selection model of [type].
  @override
  List<DatumDetails<D>> getDatumDetails(SelectionModelType type) {
    final entries = <DatumDetails<D>>[];

    for (final seriesDatum in getSelectionModel(type).selectedDatum) {
      final rendererId = seriesDatum.series.getAttr(rendererIdKey);
      final renderer = getSeriesRenderer(rendererId);

      assert(renderer is SunburstArcRenderer<D>);

      final details = (renderer as SunburstArcRenderer<D>)
          .getExpandedDatumDetails(seriesDatum);

      if (details != null) {
        entries.add(details);
      }
    }

    return entries;
  }

  Rectangle<int>? get centerContentBounds {
    assert(defaultRenderer is SunburstArcRenderer<D>);
    return (defaultRenderer as SunburstArcRenderer<D>).centerContentBounds;
  }

  void expandNode(TreeNode<D> node) {
    assert(defaultRenderer is SunburstArcRenderer<D>);
    (defaultRenderer as SunburstArcRenderer<D>).expandNode(node);
  }
}

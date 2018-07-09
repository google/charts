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

import 'package:collection/collection.dart' show ListEquality;
import '../common/chart_canvas.dart' show FillPatternType;
import '../common/series_renderer_config.dart'
    show RendererAttributes, SeriesRendererConfig;
import '../layout/layout_view.dart' show LayoutViewConfig;
import '../../common/symbol_renderer.dart'
    show SymbolRenderer, RoundedRectSymbolRenderer;

/// Shared configuration for bar chart renderers.
///
/// Bar renderers support 4 different modes of rendering multiple series on the
/// chart, configured by the grouped and stacked flags.
/// * grouped - Render bars for each series that shares a domain value
///   side-by-side.
/// * stacked - Render bars for each series that shares a domain value in a
///   stack, ordered in the same order as the series list.
/// * grouped-stacked: Render bars for each series that shares a domain value in
///   a group of bar stacks. Each stack will contain all the series that share a
///   series category.
/// * floating style - When grouped and stacked are both false, all bars that
///   share a domain value will be rendered in the same domain space. Each datum
///   should be configured with a measure offset to position its bar along the
///   measure axis. Bars will freely overlap if their measure values and measure
///   offsets overlap. Note that bars for each series will be rendered in order,
///   such that bars from the last series will be "on top" of bars from previous
///   series.
abstract class BaseBarRendererConfig<D> extends LayoutViewConfig
    implements SeriesRendererConfig<D> {
  final String customRendererId;

  final SymbolRenderer symbolRenderer;

  final List<int> barWeights;

  /// Dash pattern for the stroke line around the edges of the bar.
  final List<int> dashPattern;

  /// Defines the way multiple series of bars are rendered per domain.
  final BarGroupingType groupingType;

  final int minBarLengthPx;

  final FillPatternType fillPattern;

  final double stackHorizontalSeparator;

  /// Stroke width of the target line.
  final double strokeWidthPx;

  final rendererAttributes = new RendererAttributes();

  BaseBarRendererConfig(
      {this.customRendererId,
      this.barWeights,
      this.dashPattern,
      this.groupingType = BarGroupingType.grouped,
      this.minBarLengthPx = 0,
      this.fillPattern,
      this.stackHorizontalSeparator,
      this.strokeWidthPx = 0.0,
      SymbolRenderer symbolRenderer})
      : this.symbolRenderer = symbolRenderer ?? new RoundedRectSymbolRenderer();

  /// Whether or not the bars should be organized into groups.
  bool get grouped =>
      groupingType == BarGroupingType.grouped ||
      groupingType == BarGroupingType.groupedStacked;

  /// Whether or not the bars should be organized into stacks.
  bool get stacked =>
      groupingType == BarGroupingType.stacked ||
      groupingType == BarGroupingType.groupedStacked;

  @override
  bool operator ==(o) {
    if (identical(this, o)) {
      return true;
    }
    if (!(o is BaseBarRendererConfig)) {
      return false;
    }
    return o.customRendererId == customRendererId &&
        new ListEquality().equals(o.barWeights, barWeights) &&
        o.dashPattern == dashPattern &&
        o.fillPattern == fillPattern &&
        o.groupingType == groupingType &&
        o.minBarLengthPx == minBarLengthPx &&
        o.stackHorizontalSeparator == stackHorizontalSeparator &&
        o.strokeWidthPx == strokeWidthPx &&
        o.symbolRenderer == symbolRenderer;
  }

  int get hashcode {
    var hash = 1;
    hash = hash * 31 + (customRendererId?.hashCode ?? 0);
    hash = hash * 31 + (barWeights?.hashCode ?? 0);
    hash = hash * 31 + (dashPattern?.hashCode ?? 0);
    hash = hash * 31 + (fillPattern?.hashCode ?? 0);
    hash = hash * 31 + (groupingType?.hashCode ?? 0);
    hash = hash * 31 + (minBarLengthPx?.hashCode ?? 0);
    hash = hash * 31 + (stackHorizontalSeparator?.hashCode ?? 0);
    hash = hash * 31 + (strokeWidthPx?.hashCode ?? 0);
    hash = hash * 31 + (symbolRenderer?.hashCode ?? 0);
    return hash;
  }
}

/// Defines the way multiple series of bars are renderered per domain.
///
/// * [grouped] - Render bars for each series that shares a domain value
///   side-by-side.
/// * [stacked] - Render bars for each series that shares a domain value in a
///   stack, ordered in the same order as the series list.
/// * [groupedStacked]: Render bars for each series that shares a domain value
///   in a group of bar stacks. Each stack will contain all the series that
///   share a series category.
enum BarGroupingType { grouped, groupedStacked, stacked }

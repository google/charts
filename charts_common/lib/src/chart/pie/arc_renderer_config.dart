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

import '../../common/style/style_factory.dart' show StyleFactory;
import '../../common/symbol_renderer.dart';
import '../../common/color.dart' show Color;
import '../layout/layout_view.dart' show LayoutViewConfig;
import '../common/series_renderer_config.dart'
    show RendererAttributes, SeriesRendererConfig;
import 'arc_renderer.dart' show ArcRenderer;

/// Configuration for an [ArcRenderer].
class ArcRendererConfig extends LayoutViewConfig
    implements SeriesRendererConfig {
  final String customRendererId;

  final SymbolRenderer symbolRenderer;

  final rendererAttributes = new RendererAttributes();

  /// If set, configures the arcWidth to be a percentage of the radius.
  final double arcRatio;

  /// Fixed width of the arc within the radius.
  ///
  /// If arcRatio is set, this value will be ignored.
  final int arcWidth;

  /// Stroke width of the border of the arcs.
  final double strokeWidthPx;

  /// Stroke color of the border of the arcs.
  final Color stroke;

  /// Color of the "no data" state for the chart, used when an empty series is
  /// drawn.
  final Color noDataColor;

  ArcRendererConfig(
      {this.customRendererId,
      this.arcRatio,
      this.arcWidth,
      this.strokeWidthPx = 2.0,
      this.symbolRenderer})
      : this.stroke = StyleFactory.style.white,
        this.noDataColor = StyleFactory.style.noDataColor;

  @override
  ArcRenderer build() {
    return new ArcRenderer(config: this, rendererId: customRendererId);
  }
}

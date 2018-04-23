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

import '../../common/symbol_renderer.dart';
import '../layout/layout_view.dart' show LayoutViewConfig;
import '../common/series_renderer_config.dart'
    show RendererAttributes, SeriesRendererConfig;
import 'line_renderer.dart' show LineRenderer;

/// Configuration for a line renderer.
class LineRendererConfig<T, D> extends LayoutViewConfig
    implements SeriesRendererConfig<T, D> {
  final String customRendererId;

  final SymbolRenderer symbolRenderer;

  final rendererAttributes = new RendererAttributes();

  /// Radius of points on the line, if [includePoints] is enabled.
  final double radiusPx;

  /// Stroke width of the line.
  final double strokeWidthPx;

  /// Dash pattern for the line.
  final List<int> dashPattern;

  /// Configures whether a line representing the data will be drawn.
  final bool includeLine;

  /// Configures whether points representing the data will be drawn.
  final bool includePoints;

  LineRendererConfig(
      {this.customRendererId,
      this.radiusPx = 3.5,
      this.strokeWidthPx = 2.0,
      this.dashPattern,
      this.symbolRenderer,
      this.includeLine = true,
      this.includePoints = false});

  @override
  LineRenderer<T, D> build() {
    return new LineRenderer<T, D>(config: this, rendererId: customRendererId);
  }
}

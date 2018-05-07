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
import 'point_renderer.dart' show PointRenderer, pointSymbolRendererIdKey;
import 'point_renderer_decorator.dart' show PointRendererDecorator;

/// Configuration for a line renderer.
class PointRendererConfig<D> extends LayoutViewConfig
    implements SeriesRendererConfig<D> {
  final String customRendererId;

  /// List of decorators applied to rendered points.
  final List<PointRendererDecorator> pointRendererDecorators;

  /// Renderer used to draw the points. Defaults to a circle.
  final SymbolRenderer symbolRenderer;

  /// Map of custom symbol renderers used to draw points.
  ///
  /// Each series or point can be associated with a custom renderer by
  /// specifying a [pointSymbolRendererIdKey] matching a key in the map. Any
  /// point that doesn't define one will fall back to the default
  /// [symbolRenderer].
  final Map<String, SymbolRenderer> customSymbolRenderers;

  final rendererAttributes = new RendererAttributes();

  /// Default radius of the points.
  final double radiusPx;

  PointRendererConfig(
      {this.customRendererId,
      this.pointRendererDecorators = const [],
      this.radiusPx = 3.5,
      this.symbolRenderer,
      this.customSymbolRenderers});

  @override
  PointRenderer<D> build() {
    return new PointRenderer<D>(config: this, rendererId: customRendererId);
  }
}

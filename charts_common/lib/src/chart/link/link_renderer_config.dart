// Copyright 2021 the Charts project authors. Please see the AUTHORS file
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

import 'package:charts_common/src/chart/common/series_renderer_config.dart';
import 'package:charts_common/src/chart/layout/layout_view.dart';
import 'package:charts_common/src/common/symbol_renderer.dart';

import 'link_renderer.dart';

/// Configuration for a [SankeyRenderer].
class LinkRendererConfig<D> extends LayoutViewConfig
    implements SeriesRendererConfig<D> {
  @override
  final String? customRendererId;

  @override
  final SymbolRenderer symbolRenderer;

  @override
  final rendererAttributes = RendererAttributes();

  /// The order to paint this renderer on the canvas.
  final int layoutPaintOrder;

  LinkRendererConfig(
      {this.customRendererId,
      this.layoutPaintOrder = LayoutViewPaintOrder.bar,
      SymbolRenderer? symbolRenderer})
      : symbolRenderer = symbolRenderer ?? RectSymbolRenderer();

  @override
  LinkRenderer<D> build() {
    return LinkRenderer<D>(config: this, rendererId: customRendererId);
  }
}

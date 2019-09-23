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

import 'package:charts_common/src/common/color.dart';
import 'package:charts_common/src/common/style/style_factory.dart';
import 'package:charts_common/src/common/symbol_renderer.dart';
import 'package:charts_common/src/chart/common/series_renderer_config.dart';
import 'package:charts_common/src/chart/layout/layout_view.dart';

import 'base_treemap_renderer.dart';
import 'squarified_treemap_renderer.dart';
import 'treemap_label_decorator.dart';

/// Configuration for a [BaseTreeMapRenderer].
class TreeMapRendererConfig<D> extends LayoutViewConfig
    implements SeriesRendererConfig<D> {
  final String customRendererId;

  final SymbolRenderer symbolRenderer;

  final rendererAttributes = RendererAttributes();

  /// Tiling algorithm, which is the way to divide a region into sub-regions of
  /// specified areas, in the treemap.
  final TileType tileType;

  /// The order to paint this renderer on the canvas.
  final int layoutPaintOrder;

  /// Padding of the treemap rectangle.
  final ViewMargin rectPaddingPx;

  /// Stroke width of the border of the treemap rectangle.
  final double strokeWidthPx;

  /// Stroke color of the border of the treemap rectangle.
  final Color strokeColor;

  /// Pattern stroke width of the treemap rectangle.
  final double patternStrokeWidthPx;

  /// Decorator for optionally decorating treemap rectangle label.
  final TreeMapLabelDecorator labelDecorator;

  TreeMapRendererConfig(
      {this.customRendererId,
      this.patternStrokeWidthPx = 1.0,
      this.strokeWidthPx = 1.0,
      this.layoutPaintOrder = LayoutViewPaintOrder.treeMap,
      this.rectPaddingPx = ViewMargin.empty,
      this.tileType = TileType.squarified,
      this.labelDecorator,
      Color strokeColor,
      SymbolRenderer symbolRenderer})
      : this.strokeColor = strokeColor ?? StyleFactory.style.black,
        this.symbolRenderer = symbolRenderer ?? RectSymbolRenderer();

  @override
  BaseTreeMapRenderer<D> build() {
    return tileType == TileType.squarified
        ? SquarifiedTreeMapRenderer<D>(
            config: this, rendererId: customRendererId)
        : null; // Currently only squarified tile type is supported.
  }
}

/// Tiling algorithm, which is the way to divide a region into subregions of
/// specified areas, in a treemap.
///
/// * [squarified] - Renders rectangles such that their aspect-ratios approach
/// one as close as possible.
enum TileType { squarified }

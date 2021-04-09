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

import 'package:charts_common/src/chart/common/series_renderer_config.dart';
import 'package:charts_common/src/chart/layout/layout_view.dart';
import 'package:charts_common/src/common/color.dart';
import 'package:charts_common/src/common/style/style_factory.dart';
import 'package:charts_common/src/common/symbol_renderer.dart';

import 'base_treemap_renderer.dart';
import 'dice_treemap_renderer.dart';
import 'slice_dice_treemap_renderer.dart';
import 'slice_treemap_renderer.dart';
import 'squarified_treemap_renderer.dart';
import 'treemap_label_decorator.dart';

/// Configuration for a [BaseTreeMapRenderer].
class TreeMapRendererConfig<D> extends LayoutViewConfig
    implements SeriesRendererConfig<D> {
  /// Default padding of a treemap rectangle.
  static const _defaultRectPadding =
      ViewMargin(topPx: 26, leftPx: 4, rightPx: 4, bottomPx: 4);

  @override
  final String? customRendererId;

  @override
  final SymbolRenderer symbolRenderer;

  @override
  final rendererAttributes = RendererAttributes();

  /// Tiling algorithm, which is the way to divide a region into sub-regions of
  /// specified areas, in the treemap.
  final TreeMapTileType tileType;

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
  final TreeMapLabelDecorator<D>? labelDecorator;

  TreeMapRendererConfig(
      {this.customRendererId,
      this.patternStrokeWidthPx = 1.0,
      this.strokeWidthPx = 1.0,
      this.layoutPaintOrder = LayoutViewPaintOrder.treeMap,
      this.rectPaddingPx = _defaultRectPadding,
      this.tileType = TreeMapTileType.squarified,
      this.labelDecorator,
      Color? strokeColor,
      SymbolRenderer? symbolRenderer})
      : strokeColor = strokeColor ?? StyleFactory.style.black,
        symbolRenderer = symbolRenderer ?? RectSymbolRenderer();

  @override
  BaseTreeMapRenderer<D> build() {
    switch (tileType) {
      case TreeMapTileType.dice:
        return DiceTreeMapRenderer<D>(
            config: this, rendererId: customRendererId);
      case TreeMapTileType.slice:
        return SliceTreeMapRenderer<D>(
            config: this, rendererId: customRendererId);
      case TreeMapTileType.sliceDice:
        return SliceDiceTreeMapRenderer<D>(
            config: this, rendererId: customRendererId);
      default:
        return SquarifiedTreeMapRenderer<D>(
            config: this, rendererId: customRendererId);
    }
  }
}

/// Tiling algorithm, which is the way to divide a region into subregions of
/// specified areas, in a treemap.
///
/// * [dice] - Renders rectangles in dice layout.
/// * [slice] - Renders rectangles in slice layout.
/// * [sliceDice] - Renders rectangles in slice-and-dice layout.
/// * [squarified] - Renders rectangles such that their aspect-ratios approach
/// one as close as possible.
enum TreeMapTileType { dice, slice, sliceDice, squarified }

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

import 'dart:math' show pi;

import '../../common/symbol_renderer.dart' show SymbolRenderer;
import '../layout/layout_view.dart' show LayoutViewPaintOrder;
import '../pie/arc_renderer.dart' show ArcRenderer;
import '../pie/arc_renderer_decorator.dart' show ArcRendererDecorator;
import 'sunburst_arc_renderer.dart' show SunburstArcRenderer;
import '../pie/base_arc_renderer_config.dart' show BaseArcRendererConfig;
import '../../data/tree.dart' show TreeNode;

/// Given the selected node and a list of currently expanded node, returns the
/// new set of node to be expanded (shown beyond the initialDisplayLevel).
typedef List<TreeNode<dynamic>> ExpandNodeCallback(
    TreeNode<dynamic> node, List<TreeNode<dynamic>> expandedNode);

/// Configuration for an [ArcRenderer].
class SunburstArcRendererConfig<D> extends BaseArcRendererConfig<D> {
  static const _maxInt32Value = 1 << 31;

  /// Ratio of the arc widths for each of the ring drawn in the sunburst. The
  /// arc ratio of each ring will be normalized based on the actual render area
  /// of the chart. If the maxDisplayLevel to be rendered is greater than the
  /// arcRatios provided, the last value of the arcRatios will be used to fill
  /// the rest of the levels. If neither arcRatios nor arcWidths is provided,
  /// space will be distributed evenly between levels.
  final List<int>? arcRatios;

  /// Fixed width of the arcs for each of the ring drawn in the sunburst. The
  /// arcs will be drawn exactly as the defined width, any part exceeding the
  /// chart area will not be drawn. If the maxDisplayLevel to be rendered is
  /// greater than the arcWidths provided, the last value of the arcWidths will
  /// be used to fill the rest of the levels. arcWidths has more precedence than
  /// arcRatios. If neither arcRatios nor arcWidths is provided, space will be
  /// distributed evenly between levels.
  final List<int>? arcWidths;

  /// Configures how missing colors are assigned for the Sunburst.
  final SunburstColorStrategy colorAssignmentStrategy;

  /// The initial display level of rings to render in the sunburst. Children
  /// of hovered/selected node may expand up to the maxDisplayLevel. If unset,
  /// defaults to maxDisplayLevel.
  final int initialDisplayLevel;

  /// The max level of rings to render in the sunburst. If unset, display all
  /// data.
  final int maxDisplayLevel;

  SunburstArcRendererConfig(
      {String? customRendererId,
      double arcLength = 2 * pi,
      List<ArcRendererDecorator<D>> arcRendererDecorators = const [],
      double? arcRatio,
      this.arcRatios,
      int? arcWidth,
      this.arcWidths,
      this.colorAssignmentStrategy = SunburstColorStrategy.newShadePerLevel,
      int layoutPaintOrder = LayoutViewPaintOrder.arc,
      int? maxDisplayLevel,
      int? initialDisplayLevel,
      int minHoleWidthForCenterContent = 30,
      double startAngle = -pi / 2,
      double strokeWidthPx = 2.0,
      SymbolRenderer? symbolRenderer})
      : this.maxDisplayLevel = maxDisplayLevel ?? _maxInt32Value,
        this.initialDisplayLevel =
            initialDisplayLevel ?? maxDisplayLevel ?? _maxInt32Value,
        super(
            customRendererId: customRendererId,
            arcLength: arcLength,
            arcRatio: arcRatio,
            arcWidth: arcWidth,
            layoutPaintOrder: layoutPaintOrder,
            minHoleWidthForCenterContent: minHoleWidthForCenterContent,
            startAngle: startAngle,
            strokeWidthPx: strokeWidthPx,
            arcRendererDecorators: arcRendererDecorators);

  @override
  SunburstArcRenderer<D> build() {
    return SunburstArcRenderer<D>(config: this, rendererId: customRendererId);
  }
}

/// Strategies for assinging color to the arcs if colorFn is not provided for
/// Series.
enum SunburstColorStrategy {
  /// Assign a new shade to each of the arcs.
  newShadePerArc,

  /// Assign a new shade to each ring of the sunburst.
  newShadePerLevel,
}

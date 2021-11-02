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
import '../common/chart_canvas.dart' show FillPatternType;
import '../layout/layout_view.dart' show LayoutViewPaintOrder;
import 'bar_renderer.dart' show BarRenderer;
import 'bar_renderer_decorator.dart' show BarRendererDecorator;
import 'base_bar_renderer_config.dart'
    show BarGroupingType, BaseBarRendererConfig;

/// Configuration for a bar renderer.
class BarRendererConfig<D> extends BaseBarRendererConfig<D> {
  /// Strategy for determining the corner radius of a bar.
  final CornerStrategy cornerStrategy;

  /// Decorator for optionally decorating painted bars.
  final BarRendererDecorator<D>? barRendererDecorator;

  BarRendererConfig({
    int barGroupInnerPaddingPx = 2,
    String? customRendererId,
    CornerStrategy? cornerStrategy,
    FillPatternType? fillPattern,
    BarGroupingType? groupingType,
    int layoutPaintOrder = LayoutViewPaintOrder.bar,
    int minBarLengthPx = 0,
    int? maxBarWidthPx,
    int stackedBarPaddingPx = 1,
    double strokeWidthPx = 0.0,
    this.barRendererDecorator,
    SymbolRenderer? symbolRenderer,
    List<int>? weightPattern,
  })  : cornerStrategy = cornerStrategy ?? const ConstCornerStrategy(2),
        super(
          barGroupInnerPaddingPx: barGroupInnerPaddingPx,
          customRendererId: customRendererId,
          groupingType: groupingType ?? BarGroupingType.grouped,
          layoutPaintOrder: layoutPaintOrder,
          minBarLengthPx: minBarLengthPx,
          maxBarWidthPx: maxBarWidthPx,
          fillPattern: fillPattern,
          stackedBarPaddingPx: stackedBarPaddingPx,
          strokeWidthPx: strokeWidthPx,
          symbolRenderer: symbolRenderer,
          weightPattern: weightPattern,
        );

  @override
  BarRenderer<D> build() {
    return BarRenderer<D>(config: this, rendererId: customRendererId);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is BarRendererConfig &&
        other.cornerStrategy == cornerStrategy &&
        super == other;
  }

  @override
  int get hashCode {
    var hash = super.hashCode;
    hash = hash * 31 + cornerStrategy.hashCode;
    return hash;
  }
}

abstract class CornerStrategy {
  /// Returns the radius of the rounded corners in pixels.
  int getRadius(int barWidth);
}

/// Strategy for constant corner radius.
class ConstCornerStrategy implements CornerStrategy {
  final int radius;

  const ConstCornerStrategy(this.radius);

  @override
  int getRadius(_) => radius;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is ConstCornerStrategy && other.radius == radius;
  }

  @override
  int get hashCode => radius.hashCode;
}

/// Strategy for no corner radius.
class NoCornerStrategy extends ConstCornerStrategy {
  const NoCornerStrategy() : super(0);

  @override
  bool operator ==(other) => other is NoCornerStrategy;

  @override
  int get hashCode => 31;
}

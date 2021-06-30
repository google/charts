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

import '../../common/symbol_renderer.dart';
import '../layout/layout_view.dart' show LayoutViewPaintOrder;
import 'arc_renderer.dart' show ArcRenderer;
import 'arc_renderer_decorator.dart' show ArcRendererDecorator;
import 'base_arc_renderer_config.dart' show BaseArcRendererConfig;

/// Configuration for an [ArcRenderer].
class ArcRendererConfig<D> extends BaseArcRendererConfig<D> {
  ArcRendererConfig(
      {String? customRendererId,
      double arcLength = 2 * pi,
      List<ArcRendererDecorator<D>> arcRendererDecorators = const [],
      double? arcRatio,
      int? arcWidth,
      int layoutPaintOrder = LayoutViewPaintOrder.arc,
      int minHoleWidthForCenterContent = 30,
      double startAngle = -pi / 2,
      double strokeWidthPx = 2.0,
      SymbolRenderer? symbolRenderer})
      : super(
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
  ArcRenderer<D> build() {
    return ArcRenderer<D>(config: this, rendererId: customRendererId);
  }
}

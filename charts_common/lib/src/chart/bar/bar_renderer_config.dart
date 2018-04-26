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

import 'base_bar_renderer_config.dart'
    show BarGroupingType, BaseBarRendererConfig;
import 'bar_renderer.dart' show BarRenderer;
import 'bar_renderer_decorator.dart' show BarRendererDecorator;
import '../common/chart_canvas.dart' show FillPatternType;
import '../../common/symbol_renderer.dart';

/// Configuration for a bar renderer.
class BarRendererConfig extends BaseBarRendererConfig<String> {
  /// Calculator for determining the corner radius of a bar.
  final CornerRadiusCalculator cornerRadiusCalculator;

  /// Decorator for optionally decorating painted bars.
  final BarRendererDecorator barRendererDecorator;

  BarRendererConfig({
    String customRendererId,
    List<int> barWeights,
    this.cornerRadiusCalculator,
    FillPatternType fillPattern,
    BarGroupingType groupingType,
    int minBarLengthPx = 0,
    double stackHorizontalSeparator,
    double strokeWidthPx = 0.0,
    this.barRendererDecorator,
    SymbolRenderer symbolRenderer,
  }) : super(
            customRendererId: customRendererId,
            barWeights: barWeights,
            groupingType: groupingType ?? BarGroupingType.grouped,
            minBarLengthPx: minBarLengthPx,
            fillPattern: fillPattern,
            stackHorizontalSeparator: stackHorizontalSeparator,
            strokeWidthPx: strokeWidthPx,
            symbolRenderer: symbolRenderer);

  @override
  BarRenderer<String> build() {
    return new BarRenderer<String>(config: this, rendererId: customRendererId);
  }

  @override
  bool operator ==(o) {
    if (identical(this, o)) {
      return true;
    }
    if (!(o is BarRendererConfig)) {
      return false;
    }
    return o.cornerRadiusCalculator == cornerRadiusCalculator && super == (o);
  }

  @override
  int get hashCode {
    var hash = super.hashCode;
    hash = hash * 31 + (cornerRadiusCalculator?.hashCode ?? 0);
    return hash;
  }
}

abstract class CornerRadiusCalculator {
  /// Returns the radius of the rounded corners in pixels.
  int getRadius(int barWidth);
}

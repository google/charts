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

import 'point_renderer.dart' show PointRenderer;
import '../cartesian/axis/draw_strategy/gridline_draw_strategy.dart'
    show GridlineRendererSpec;
import '../cartesian/cartesian_chart.dart' show NumericCartesianChart;
import '../common/chart_context.dart' show ChartContext;
import '../common/series_renderer.dart' show SeriesRenderer;
import '../layout/layout_config.dart' show LayoutConfig;
import '../../common/graphics_factory.dart' show GraphicsFactory;

class ScatterPlotChart extends NumericCartesianChart {
  ScatterPlotChart({bool vertical, LayoutConfig layoutConfig})
      : super(vertical: vertical, layoutConfig: layoutConfig);

  @override
  SeriesRenderer<num> makeDefaultRenderer() {
    return new PointRenderer<num>()
      ..rendererId = SeriesRenderer.defaultRendererId;
  }

  @override
  void initDomainAxis(ChartContext context, GraphicsFactory graphicsFactory) {
    domainAxis.tickDrawStrategy = new GridlineRendererSpec<num>()
        .createDrawStrategy(context, graphicsFactory);
  }
}

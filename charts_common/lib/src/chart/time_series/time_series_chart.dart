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

import '../cartesian/cartesian_chart.dart' show CartesianChart;
import '../cartesian/axis/time/date_time_axis.dart' show DateTimeAxis;
import '../cartesian/axis/draw_strategy/small_tick_draw_strategy.dart'
    show SmallTickRendererSpec;
import '../common/chart_context.dart' show ChartContext;
import '../common/series_renderer.dart' show SeriesRenderer;
import '../layout/layout_config.dart' show LayoutConfig;
import '../line/line_renderer.dart' show LineRenderer;
import '../../common/graphics_factory.dart' show GraphicsFactory;
import '../../common/date_time_factory.dart'
    show DateTimeFactory, LocalDateTimeFactory;

class TimeSeriesChart extends CartesianChart<DateTime> {
  final DateTimeAxis domainAxis;
  final DateTimeFactory dateTimeFactory;

  TimeSeriesChart(
      {bool vertical,
      LayoutConfig layoutConfig,
      this.dateTimeFactory = const LocalDateTimeFactory()})
      : domainAxis = new DateTimeAxis(dateTimeFactory),
        super(vertical: vertical, layoutConfig: layoutConfig);

  void init(ChartContext context, GraphicsFactory graphicsFactory) {
    super.init(context, graphicsFactory);
    domainAxis.context = context;
    domainAxis.tickDrawStrategy = new SmallTickRendererSpec<DateTime>()
        .createDrawStrategy(context, graphicsFactory);
    addView(domainAxis);
  }

  @override
  SeriesRenderer<DateTime> makeDefaultRenderer() {
    return new LineRenderer<DateTime>()
      ..rendererId = SeriesRenderer.defaultRendererId;
  }
}

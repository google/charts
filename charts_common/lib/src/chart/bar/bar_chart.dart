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

import '../bar/bar_renderer.dart' show BarRenderer;
import '../cartesian/cartesian_chart.dart' show OrdinalCartesianChart;
import '../common/series_renderer.dart' show SeriesRenderer;
import '../layout/layout_config.dart' show LayoutConfig;

class BarChart extends OrdinalCartesianChart {
  BarChart({bool vertical, LayoutConfig layoutConfig})
      : super(vertical: vertical, layoutConfig: layoutConfig);

  @override
  SeriesRenderer<String> makeDefaultRenderer() {
    return new BarRenderer<String>()
      ..rendererId = SeriesRenderer.defaultRendererId;
  }
}

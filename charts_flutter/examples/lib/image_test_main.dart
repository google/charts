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

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'bar_chart/horizontal.dart';
import 'bar_chart/horizontal_bar_label.dart';
import 'bar_chart/horizontal_pattern_forward_hatch.dart';
import 'bar_chart/grouped.dart';
import 'bar_chart/grouped_single_target_line.dart';
import 'bar_chart/grouped_stacked.dart';
import 'bar_chart/grouped_target_line.dart';
import 'bar_chart/pattern_forward_hatch.dart';
import 'bar_chart/simple.dart';
import 'bar_chart/stacked.dart';
import 'bar_chart/stacked_horizontal.dart';
import 'bar_chart/stacked_target_line.dart';
import 'bar_chart/spark_bar.dart';
import 'line_chart/dash_pattern.dart';
import 'line_chart/simple.dart';
import 'line_chart/range_annotation.dart';
import 'a11y/domain_a11y_explore_bar_chart.dart';
import 'axes/bar_secondary_axis.dart';
import 'axes/bar_secondary_axis_only.dart';
import 'axes/horizontal_bar_secondary_axis.dart';
import 'axes/short_tick_length_axis.dart';
import 'axes/custom_font_size_and_color.dart';
import 'axes/measure_axis_label_alignment.dart';
import 'axes/hidden_ticks_and_labels_axis.dart';
import 'axes/custom_axis_tick_formatters.dart';
import 'axes/custom_measure_tick_count.dart';
import 'axes/integer_only_measure_axis.dart';
import 'axes/nonzero_bound_measure_axis.dart';
import 'axes/statically_provided_ticks.dart';
import 'interactions/selection_bar_highlight.dart';
import 'interactions/selection_line_highlight.dart';
import 'interactions/selection_callback_example.dart';
import 'i18n/rtl_bar_chart.dart';
import 'i18n/rtl_line_chart.dart';
import 'i18n/rtl_series_legend.dart';
import 'legends/simple_series_legend.dart';
import 'legends/legend_options.dart';
import 'legends/legend_custom_symbol.dart';
import 'time_series_chart/range_annotation.dart';
import 'time_series_chart/simple.dart';
import 'image_test_only/legend.dart';
import 'image_test_only/rtl_grouped.dart';
import 'image_test_only/rtl_grouped_stacked.dart';
import 'image_test.dart';

const _appName = 'Charts Flutter Image Test';

void main() {
  enableFlutterDriverExtension();
  final app = new MaterialApp(
    debugShowCheckedModeBanner: false,
    title: _appName,
    theme: new ThemeData(
        brightness: Brightness.light, primarySwatch: Colors.lightBlue),
    home: new Home(),
  );
  runApp(app);
}

/// Main entry point of the image test app.
class Home extends StatelessWidget {
  /// List of test charts.
  final _tests = <Widget>[
    new ImageTest('bar_chart__simple', new SimpleBarChart.withSampleData()),
    new ImageTest('bar_chart__stacked', new StackedBarChart.withSampleData()),
    new ImageTest('bar_chart__grouped', new GroupedBarChart.withSampleData()),
    new ImageTest('bar_chart__grouped_stacked',
        new GroupedStackedBarChart.withSampleData()),
    new ImageTest('bar_chart__grouped_target_line',
        new GroupedBarTargetLineChart.withSampleData()),
    new ImageTest('bar_chart__grouped_single_target_line',
        new GroupedBarSingleTargetLineChart.withSampleData()),
    new ImageTest('bar_chart__stacked_horizontal',
        new StackedHorizontalBarChart.withSampleData()),
    new ImageTest('bar_chart__stacked_target_line',
        new StackedBarTargetLineChart.withSampleData()),
    new ImageTest(
        'bar_chart__horizontal', new HorizontalBarChart.withSampleData()),
    new ImageTest('bar_chart__horizontal_bar_label',
        new HorizontalBarLabelChart.withSampleData()),
    new ImageTest('bar_chart__spark_bar', new SparkBar.withSampleData()),
    new ImageTest('bar_chart__pattern_forward_hatch',
        new PatternForwardHatchBarChart.withSampleData()),
    new ImageTest('bar_chart__horizontal_pattern_forward_hatch',
        new HorizontalPatternForwardHatchBarChart.withSampleData()),
    new ImageTest('line_chart__simple', new SimpleLineChart.withSampleData()),
    new ImageTest(
        'line_chart__dash_pattern', new DashPatternLineChart.withSampleData()),
    new ImageTest('line_chart__range_annotation',
        new LineRangeAnnotationChart.withSampleData()),
    new ImageTest('axes__bar_secondary_axis',
        new BarChartWithSecondaryAxis.withSampleData()),
    new ImageTest('axes__bar_secondary_axis_only',
        new BarChartWithSecondaryAxisOnly.withSampleData()),
    new ImageTest('axes__horizontal_bar_secondary_axis',
        new HorizontalBarChartWithSecondaryAxis.withSampleData()),
    new ImageTest('axes__short_tick_length_axis',
        new ShortTickLengthAxis.withSampleData()),
    new ImageTest('axes__custom_font_size_and_color',
        new CustomFontSizeAndColor.withSampleData()),
    new ImageTest('axes__measure_axis_label_alignment',
        new MeasureAxisLabelAlignment.withSampleData()),
    new ImageTest('axes__hidden_ticks_and_labels_axis',
        new HiddenTicksAndLabelsAxis.withSampleData()),
    new ImageTest('axes__custom_axis_tick_formatters',
        new CustomAxisTickFormatters.withSampleData()),
    new ImageTest('axes__custom_measure_tick_count',
        new CustomMeasureTickCount.withSampleData()),
    new ImageTest('axes__integer_only_measure_axis',
        new IntegerOnlyMeasureAxis.withSampleData()),
    new ImageTest('axes__nonzero_bound_measure_axis',
        new NonzeroBoundMeasureAxis.withSampleData()),
    new ImageTest('axes__statically_provided_ticks',
        new StaticallyProvidedTicks.withSampleData()),
    new ImageTest('interactions__selection_bar_highlight',
        new SelectionBarHighlight.withSampleData()),
    new ImageTest('interactions__selection_line_highlight',
        new SelectionLineHighlight.withSampleData()),
    new ImageTest('interactions__selection_callback_example',
        new SelectionCallbackExample.withSampleData()),
    new ImageTest('legends__simple_series_legend',
        new SimpleSeriesLegend.withSampleData()),
    new ImageTest(
        'legends__legend_options', new LegendOptions.withSampleData()),
    new ImageTest('legends__legend_custom_symbol',
        new LegendWithCustomSymbol.withSampleData()),
    new ImageTest('time_series_chart__simple',
        new SimpleTimeSeriesChart.withSampleData()),
    new ImageTest('time_series_chart__range_annotation',
        new TimeSeriesRangeAnnotationChart.withSampleData()),
    new ImageTest('image_test_only__rtl_grouped',
        new RTLGroupedBarChart.withSampleData()),
    new ImageTest('image_test_only__rtl_grouped_stacked',
        new RTLGroupedStackedBarChart.withSampleData()),
    new ImageTest('image_test_only__legend_top',
        new ImageTestLegend.top(TextDirection.ltr)),
    new ImageTest('image_test_only__legend_bottom',
        new ImageTestLegend.bottom(TextDirection.ltr)),
    new ImageTest('image_test_only__legend_start_ltr',
        new ImageTestLegend.start(TextDirection.ltr)),
    new ImageTest('image_test_only__legend_end_ltr',
        new ImageTestLegend.end(TextDirection.ltr)),
    new ImageTest('image_test_only__legend_start_rtl',
        new ImageTestLegend.start(TextDirection.rtl)),
    new ImageTest('image_test_only__legend_end_rtl',
        new ImageTestLegend.end(TextDirection.rtl)),
    new ImageTest('i18n__rtl_bar_chart', new RTLBarChart.withSampleData()),
    new ImageTest('i18n__rtl_line_chart', new RTLLineChart.withSampleData()),
    new ImageTest(
        'i18n__rtl_series_legend', new RTLSeriesLegend.withSampleData()),
    new ImageTest('a11y__domain_a11y_explore_bar_chart',
        new DomainA11yExploreBarChart.withSampleData()),
  ];

  Home({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(title: new Text(_appName)),
        body: new ListView(children: _tests));
  }
}

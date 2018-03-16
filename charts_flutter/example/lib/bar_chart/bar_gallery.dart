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

import 'dart:math' show Random;
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import '../gallery_scaffold.dart';
import 'grouped.dart';
import 'grouped_single_target_line.dart';
import 'grouped_stacked.dart';
import 'grouped_target_line.dart';
import 'horizontal.dart';
import 'horizontal_bar_label.dart';
import 'horizontal_pattern_forward_hatch.dart';
import 'pattern_forward_hatch.dart';
import 'simple.dart';
import 'stacked.dart';
import 'stacked_horizontal.dart';
import 'stacked_target_line.dart';
import 'spark_bar.dart';

List<GalleryScaffold> buildGallery() {
  return [
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Simple Bar Chart',
      subtitle: 'Simple bar chart with a single series',
      childBuilder: (List<charts.Series> series) => new SimpleBarChart(series),
      seriesListBuilder: _createSingleSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Stacked Bar Chart',
      subtitle: 'Stacked bar chart with multiple series',
      childBuilder: (List<charts.Series> series) => new StackedBarChart(series),
      seriesListBuilder: _createMultipleSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Grouped Bar Chart',
      subtitle: 'Grouped bar chart with multiple series',
      childBuilder: (List<charts.Series> series) => new GroupedBarChart(series),
      seriesListBuilder: _createMultipleSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Grouped Stacked Bar Chart',
      subtitle: 'Grouped and stacked bar chart with multiple series',
      childBuilder: (List<charts.Series> series) =>
          new GroupedStackedBarChart(series),
      seriesListBuilder: _createMultipleSeriesWithCategories,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Grouped Bar Target Line Chart',
      subtitle: 'Grouped bar target line chart with multiple series',
      childBuilder: (List<charts.Series> series) =>
          new GroupedBarTargetLineChart(series),
      seriesListBuilder: _createMultipleSeriesMultiTarget,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Grouped Bar Single Target Line Chart',
      subtitle:
          'Grouped bar target line chart with multiple series and a single target',
      childBuilder: (List<charts.Series> series) =>
          new GroupedBarSingleTargetLineChart(series),
      seriesListBuilder: _createMultipleSeriesSingleTarget,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Stacked Bar Target Line Chart',
      subtitle: 'Stacked bar target line chart with multiple series',
      childBuilder: (List<charts.Series> series) =>
          new StackedBarTargetLineChart(series),
      seriesListBuilder: _createMultipleSeriesMultiTarget,
    ),
    new GalleryScaffold(
      listTileIcon: new Transform.rotate(
          angle: 1.5708, child: new Icon(Icons.insert_chart)),
      title: 'Horizontal Bar Chart',
      subtitle: 'Horizontal bar chart with a single series',
      childBuilder: (List<charts.Series> series) =>
          new HorizontalBarChart(series),
      seriesListBuilder: _createSingleSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Transform.rotate(
          angle: 1.5708, child: new Icon(Icons.insert_chart)),
      title: 'Stacked Horizontal Bar Chart',
      subtitle: 'Stacked horizontal bar chart with multiple series',
      childBuilder: (List<charts.Series> series) =>
          new StackedHorizontalBarChart(series),
      seriesListBuilder: _createMultipleSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Transform.rotate(
          angle: 1.5708, child: new Icon(Icons.insert_chart)),
      title: 'Horizontal Bar Chart with Bar Labels',
      subtitle: 'Horizontal bar chart with a single series and bar labels',
      childBuilder: (List<charts.Series> series) =>
          new HorizontalBarLabelChart(series),
      seriesListBuilder: _createSingleSeriesWithLabelAccessor,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Spark Bar Chart',
      subtitle: 'Spark Bar Chart',
      childBuilder: (List<charts.Series> series) => new SparkBar(series),
      seriesListBuilder: _createSingleSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Pattern Forward Hatch Bar Chart',
      subtitle: 'Pattern Forward Hatch Bar Chart',
      childBuilder: (List<charts.Series> series) =>
          new PatternForwardHatchBarChart(series),
      seriesListBuilder: _createMultipleSeriesWithForwardHatchPattern,
    ),
    new GalleryScaffold(
      listTileIcon: new Transform.rotate(
          angle: 1.5708, child: new Icon(Icons.insert_chart)),
      title: 'Horizontal Pattern Forward Hatch Bar Chart',
      subtitle: 'Horizontal Pattern Forward Hatch Bar Chart',
      childBuilder: (List<charts.Series> series) =>
          new HorizontalPatternForwardHatchBarChart(series),
      seriesListBuilder: _createMultipleSeriesWithForwardHatchPattern,
    ),
  ];
}

/// Sample ordinal data type.
class OrdinalSales {
  final String year;
  final int sales;

  OrdinalSales(this.year, this.sales);
}

/// Create one series with random data.
List<charts.Series<OrdinalSales, String>> _createSingleSeries() {
  final random = new Random();

  final data = [
    new OrdinalSales('2014', random.nextInt(100)),
    new OrdinalSales('2015', random.nextInt(100)),
    new OrdinalSales('2016', random.nextInt(100)),
    new OrdinalSales('2017', random.nextInt(100)),
  ];

  return [
    new charts.Series<OrdinalSales, String>(
      id: 'Sales',
      domainFn: (OrdinalSales sales, _) => sales.year,
      measureFn: (OrdinalSales sales, _) => sales.sales,
      data: data,
    )
  ];
}

/// Create series list with multiple series.
List<charts.Series<OrdinalSales, String>> _createMultipleSeries(
    {String suffix = '', String rendererId}) {
  final random = new Random();

  final desktopSalesData = [
    new OrdinalSales('2014', random.nextInt(100)),
    new OrdinalSales('2015', random.nextInt(100)),
    new OrdinalSales('2016', random.nextInt(100)),
    new OrdinalSales('2017', random.nextInt(100)),
  ];

  final tableSalesData = [
    new OrdinalSales('2014', random.nextInt(100)),
    new OrdinalSales('2015', random.nextInt(100)),
    new OrdinalSales('2016', random.nextInt(100)),
    new OrdinalSales('2017', random.nextInt(100)),
  ];

  final mobileSalesData = [
    new OrdinalSales('2014', random.nextInt(100)),
    new OrdinalSales('2015', random.nextInt(100)),
    new OrdinalSales('2016', random.nextInt(100)),
    new OrdinalSales('2017', random.nextInt(100)),
  ];

  return [
    new charts.Series<OrdinalSales, String>(
        id: 'Desktop${suffix}',
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: desktopSalesData)
      ..setAttribute(charts.rendererIdKey, rendererId),
    new charts.Series<OrdinalSales, String>(
        id: 'Tablet${suffix}',
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: tableSalesData)
      ..setAttribute(charts.rendererIdKey, rendererId),
    new charts.Series<OrdinalSales, String>(
        id: 'Mobile${suffix}',
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: mobileSalesData)
      ..setAttribute(charts.rendererIdKey, rendererId),
  ];
}

List<charts.Series<OrdinalSales, String>> _createMultipleSeriesMultiTarget() {
  return _createMultipleSeries()
    ..addAll(_createMultipleSeries(
        suffix: '_Target', rendererId: 'customTargetLine'));
}

List<charts.Series<OrdinalSales, String>> _createMultipleSeriesSingleTarget() {
  return _createMultipleSeries()
    ..add(_createMultipleSeries(
        suffix: '_Target', rendererId: 'customTargetLine')[0]);
}

/// Create multiple series with categories.
///
/// For group stacked bar charts.
List<charts.Series<OrdinalSales, String>>
    _createMultipleSeriesWithCategories() {
  final random = new Random();

  final desktopSalesDataA = [
    new OrdinalSales('2014', random.nextInt(100)),
    new OrdinalSales('2015', random.nextInt(100)),
    new OrdinalSales('2016', random.nextInt(100)),
    new OrdinalSales('2017', random.nextInt(100)),
  ];

  final tableSalesDataA = [
    new OrdinalSales('2014', random.nextInt(100)),
    new OrdinalSales('2015', random.nextInt(100)),
    new OrdinalSales('2016', random.nextInt(100)),
    new OrdinalSales('2017', random.nextInt(100)),
  ];

  final mobileSalesDataA = [
    new OrdinalSales('2014', random.nextInt(100)),
    new OrdinalSales('2015', random.nextInt(100)),
    new OrdinalSales('2016', random.nextInt(100)),
    new OrdinalSales('2017', random.nextInt(100)),
  ];

  final desktopSalesDataB = [
    new OrdinalSales('2014', random.nextInt(100)),
    new OrdinalSales('2015', random.nextInt(100)),
    new OrdinalSales('2016', random.nextInt(100)),
    new OrdinalSales('2017', random.nextInt(100)),
  ];

  final tableSalesDataB = [
    new OrdinalSales('2014', random.nextInt(100)),
    new OrdinalSales('2015', random.nextInt(100)),
    new OrdinalSales('2016', random.nextInt(100)),
    new OrdinalSales('2017', random.nextInt(100)),
  ];

  final mobileSalesDataB = [
    new OrdinalSales('2014', random.nextInt(100)),
    new OrdinalSales('2015', random.nextInt(100)),
    new OrdinalSales('2016', random.nextInt(100)),
    new OrdinalSales('2017', random.nextInt(100)),
  ];

  return [
    new charts.Series<OrdinalSales, String>(
      id: 'Desktop A',
      seriesCategory: 'A',
      domainFn: (OrdinalSales sales, _) => sales.year,
      measureFn: (OrdinalSales sales, _) => sales.sales,
      data: desktopSalesDataA,
    ),
    new charts.Series<OrdinalSales, String>(
      id: 'Tablet A',
      seriesCategory: 'A',
      domainFn: (OrdinalSales sales, _) => sales.year,
      measureFn: (OrdinalSales sales, _) => sales.sales,
      data: tableSalesDataA,
    ),
    new charts.Series<OrdinalSales, String>(
      id: 'Mobile A',
      seriesCategory: 'A',
      domainFn: (OrdinalSales sales, _) => sales.year,
      measureFn: (OrdinalSales sales, _) => sales.sales,
      data: mobileSalesDataA,
    ),
    new charts.Series<OrdinalSales, String>(
      id: 'Desktop B',
      seriesCategory: 'B',
      domainFn: (OrdinalSales sales, _) => sales.year,
      measureFn: (OrdinalSales sales, _) => sales.sales,
      data: desktopSalesDataB,
    ),
    new charts.Series<OrdinalSales, String>(
      id: 'Tablet B',
      seriesCategory: 'B',
      domainFn: (OrdinalSales sales, _) => sales.year,
      measureFn: (OrdinalSales sales, _) => sales.sales,
      data: tableSalesDataB,
    ),
    new charts.Series<OrdinalSales, String>(
      id: 'Mobile B',
      seriesCategory: 'B',
      domainFn: (OrdinalSales sales, _) => sales.year,
      measureFn: (OrdinalSales sales, _) => sales.sales,
      data: mobileSalesDataB,
    ),
  ];
}

/// Create one series with random data and a label accessor.
List<charts.Series<OrdinalSales, String>>
    _createSingleSeriesWithLabelAccessor() {
  final random = new Random();

  final data = [
    new OrdinalSales('2014', random.nextInt(100)),
    new OrdinalSales('2015', random.nextInt(100)),
    new OrdinalSales('2016', random.nextInt(100)),
    new OrdinalSales('2017', random.nextInt(100)),
  ];

  return [
    new charts.Series<OrdinalSales, String>(
      id: 'Sales',
      domainFn: (OrdinalSales sales, _) => sales.year,
      measureFn: (OrdinalSales sales, _) => sales.sales,
      data: data,
      labelAccessorFn: (OrdinalSales sales, _) =>
          '${sales.year}: \$${sales.sales.toString()}',
    )
  ];
}

/// Create multiple series with a forward hatch pattern on the middle series.
List<charts.Series<OrdinalSales, String>>
    _createMultipleSeriesWithForwardHatchPattern(
        {String suffix = '', String rendererId}) {
  final random = new Random();

  final desktopSalesData = [
    new OrdinalSales('2014', random.nextInt(100)),
    new OrdinalSales('2015', random.nextInt(100)),
    new OrdinalSales('2016', random.nextInt(100)),
    new OrdinalSales('2017', random.nextInt(100)),
  ];

  final tableSalesData = [
    new OrdinalSales('2014', random.nextInt(100)),
    new OrdinalSales('2015', random.nextInt(100)),
    new OrdinalSales('2016', random.nextInt(100)),
    new OrdinalSales('2017', random.nextInt(100)),
  ];

  final mobileSalesData = [
    new OrdinalSales('2014', random.nextInt(100)),
    new OrdinalSales('2015', random.nextInt(100)),
    new OrdinalSales('2016', random.nextInt(100)),
    new OrdinalSales('2017', random.nextInt(100)),
  ];

  return [
    new charts.Series<OrdinalSales, String>(
        id: 'Desktop${suffix}',
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: desktopSalesData)
      ..setAttribute(charts.rendererIdKey, rendererId),
    new charts.Series<OrdinalSales, String>(
        id: 'Tablet${suffix}',
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: tableSalesData,
        fillPatternFn: (OrdinalSales sales, _) =>
            charts.FillPatternType.forwardHatch)
      ..setAttribute(charts.rendererIdKey, rendererId),
    new charts.Series<OrdinalSales, String>(
        id: 'Mobile${suffix}',
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: mobileSalesData)
      ..setAttribute(charts.rendererIdKey, rendererId),
  ];
}

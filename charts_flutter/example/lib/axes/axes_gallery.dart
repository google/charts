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
import 'bar_secondary_axis.dart';
import 'bar_secondary_axis_only.dart';
import 'horizontal_bar_secondary_axis.dart';
import 'short_tick_length_axis.dart';
import 'custom_font_size_and_color.dart';
import 'measure_axis_label_alignment.dart';
import 'hidden_ticks_and_labels_axis.dart';
import 'custom_axis_tick_formatters.dart';
import 'custom_measure_tick_count.dart';
import 'integer_only_measure_axis.dart';
import 'nonzero_bound_measure_axis.dart';
import 'statically_provided_ticks.dart';

List<GalleryScaffold> buildGallery() {
  return [
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Bar chart with Secondary Measure Axis',
      subtitle: 'Bar chart with a series using a secondary measure axis',
      childBuilder: (List<charts.Series> series) =>
          new BarChartWithSecondaryAxis(series),
      seriesListBuilder: _createSeriesWithSecondaryAxis,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Bar chart with Secondary Measure Axis only',
      subtitle: 'Bar chart with both series using secondary measure axis',
      childBuilder: (List<charts.Series> series) =>
          new BarChartWithSecondaryAxisOnly(series),
      seriesListBuilder: _createSeriesWithSecondaryAxisOnly,
    ),
    new GalleryScaffold(
      listTileIcon: new Transform.rotate(
          angle: 1.5708, child: new Icon(Icons.insert_chart)),
      title: 'Horizontal bar chart with Secondary Measure Axis',
      subtitle:
          'Horizontal Bar chart with a series using secondary measure axis',
      childBuilder: (List<charts.Series> series) =>
          new HorizontalBarChartWithSecondaryAxis(series),
      seriesListBuilder: _createSeriesWithSecondaryAxis,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Short Ticks Axis',
      subtitle: 'Bar chart with the primary measure axis having short ticks',
      childBuilder: (List<charts.Series> series) =>
          new ShortTickLengthAxis(series),
      seriesListBuilder: _createSingleSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Custom Axis Fonts',
      subtitle: 'Bar chart with custom axis font size and color',
      childBuilder: (List<charts.Series> series) =>
          new CustomFontSizeAndColor(series),
      seriesListBuilder: _createSingleSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Label Alignment Axis',
      subtitle: 'Bar chart with custom measure axis label alignments',
      childBuilder: (List<charts.Series> series) =>
          new MeasureAxisLabelAlignment(series),
      seriesListBuilder: _createSingleSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'No Axis',
      subtitle: 'Bar chart with only the axis line drawn',
      childBuilder: (List<charts.Series> series) =>
          new HiddenTicksAndLabelsAxis(series),
      seriesListBuilder: _createSingleSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Statically Provided Ticks',
      subtitle: 'Bar chart with statically provided ticks',
      childBuilder: (List<charts.Series> series) =>
          new StaticallyProvidedTicks(series),
      seriesListBuilder: _createSingleSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.show_chart),
      title: 'Custom Formatter',
      subtitle: 'Timeseries with custom domain and measure tick formatters',
      childBuilder: (List<charts.Series> series) =>
          new CustomAxisTickFormatters(series),
      seriesListBuilder: _createDateTimeSales,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.show_chart),
      title: 'Custom Tick Count',
      subtitle: 'Timeseries with custom measure axis tick count',
      childBuilder: (List<charts.Series> series) =>
          new CustomMeasureTickCount(series),
      seriesListBuilder: _createDateTimeSales,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.show_chart),
      title: 'Integer Measure Ticks',
      subtitle: 'Timeseries with only whole number measure axis ticks',
      childBuilder: (List<charts.Series> series) =>
          new IntegerOnlyMeasureAxis(series),
      seriesListBuilder: _createDateTimeIntegers,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.show_chart),
      title: 'Non-zero bound Axis',
      subtitle: 'Timeseries with measure axis that does not include zero',
      childBuilder: (List<charts.Series> series) =>
          new NonzeroBoundMeasureAxis(series),
      seriesListBuilder: _createDateTimeLargeNumbers,
    ),
  ];
}

/// Sample ordinal data type.
class OrdinalSales {
  final String year;
  final int sales;

  OrdinalSales(this.year, this.sales);
}

/// Create single series list.
List<charts.Series<OrdinalSales, String>> _createSingleSeries() {
  final random = new Random();

  final desktopSalesData = [
    new OrdinalSales('2014', random.nextInt(1000)),
    new OrdinalSales('2015', random.nextInt(1000)),
    new OrdinalSales('2016', random.nextInt(1000)),
    new OrdinalSales('2017', random.nextInt(1000)),
  ];

  return [
    new charts.Series<OrdinalSales, String>(
      id: 'Desktop',
      domainFn: (OrdinalSales sales, _) => sales.year,
      measureFn: (OrdinalSales sales, _) => sales.sales,
      data: desktopSalesData,
    ),
  ];
}

/// Create series list with multiple series.
List<charts.Series<OrdinalSales, String>> _createSeriesWithSecondaryAxis() {
  final random = new Random();

  final desktopSalesData = [
    new OrdinalSales('2014', random.nextInt(1000)),
    new OrdinalSales('2015', random.nextInt(1000)),
    new OrdinalSales('2016', random.nextInt(1000)),
    new OrdinalSales('2017', random.nextInt(1000)),
  ];

  final tableSalesData = [
    new OrdinalSales('2014', random.nextInt(50)),
    new OrdinalSales('2015', random.nextInt(50)),
    new OrdinalSales('2016', random.nextInt(50)),
    new OrdinalSales('2017', random.nextInt(50)),
  ];

  return [
    new charts.Series<OrdinalSales, String>(
      id: 'Desktop',
      domainFn: (OrdinalSales sales, _) => sales.year,
      measureFn: (OrdinalSales sales, _) => sales.sales,
      data: desktopSalesData,
    ),
    new charts.Series<OrdinalSales, String>(
      id: 'Tablet',
      domainFn: (OrdinalSales sales, _) => sales.year,
      measureFn: (OrdinalSales sales, _) => sales.sales,
      data: tableSalesData,
    )..setAttribute(charts.measureAxisIdKey, 'secondaryMeasureAxisId'),
  ];
}

/// Create series list with multiple series.
List<charts.Series<OrdinalSales, String>> _createSeriesWithSecondaryAxisOnly() {
  final random = new Random();

  final desktopSalesData = [
    new OrdinalSales('2014', random.nextInt(1000)),
    new OrdinalSales('2015', random.nextInt(1000)),
    new OrdinalSales('2016', random.nextInt(1000)),
    new OrdinalSales('2017', random.nextInt(1000)),
  ];

  final tableSalesData = [
    new OrdinalSales('2014', random.nextInt(50)),
    new OrdinalSales('2015', random.nextInt(50)),
    new OrdinalSales('2016', random.nextInt(50)),
    new OrdinalSales('2017', random.nextInt(50)),
  ];

  return [
    new charts.Series<OrdinalSales, String>(
      id: 'Desktop',
      domainFn: (OrdinalSales sales, _) => sales.year,
      measureFn: (OrdinalSales sales, _) => sales.sales,
      data: desktopSalesData,
    )..setAttribute(charts.measureAxisIdKey, 'secondaryMeasureAxisId'),
    new charts.Series<OrdinalSales, String>(
      id: 'Tablet',
      domainFn: (OrdinalSales sales, _) => sales.year,
      measureFn: (OrdinalSales sales, _) => sales.sales,
      data: tableSalesData,
    )..setAttribute(charts.measureAxisIdKey, 'secondaryMeasureAxisId'),
  ];
}

class DateTimeSales {
  final DateTime timeStamp;
  final int sales;
  DateTimeSales(this.timeStamp, this.sales);
}

List<charts.Series<DateTimeSales, DateTime>> _createDateTimeSales() {
  final random = new Random();

  var myFakeDesktopData = [
    new DateTimeSales(new DateTime(2017, 9, 25), random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 9, 26), random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 9, 27), random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 9, 28), random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 9, 29), random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 9, 30), random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 10, 01), random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 10, 02), random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 10, 03), random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 10, 04), random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 10, 05), random.nextInt(35)),
  ];
  return [
    new charts.Series<DateTimeSales, DateTime>(
        id: 'Desktop',
        domainFn: (DateTimeSales row, _) => row.timeStamp,
        measureFn: (DateTimeSales row, _) => row.sales,
        data: myFakeDesktopData),
  ];
}

List<charts.Series<DateTimeSales, DateTime>> _createDateTimeIntegers() {
  final random = new Random();

  var myFakeDesktopData = [
    new DateTimeSales(new DateTime(2017, 9, 25), random.nextDouble().round()),
    new DateTimeSales(new DateTime(2017, 9, 26), random.nextDouble().round()),
    new DateTimeSales(new DateTime(2017, 9, 27), random.nextDouble().round()),
    new DateTimeSales(new DateTime(2017, 9, 28), random.nextDouble().round()),
    new DateTimeSales(new DateTime(2017, 9, 29), random.nextDouble().round()),
    new DateTimeSales(new DateTime(2017, 9, 30), random.nextDouble().round()),
    new DateTimeSales(new DateTime(2017, 10, 01), random.nextDouble().round()),
    new DateTimeSales(new DateTime(2017, 10, 02), random.nextDouble().round()),
    new DateTimeSales(new DateTime(2017, 10, 03), random.nextDouble().round()),
    new DateTimeSales(new DateTime(2017, 10, 04), random.nextDouble().round()),
    new DateTimeSales(new DateTime(2017, 10, 05), random.nextDouble().round()),
  ];
  return [
    new charts.Series<DateTimeSales, DateTime>(
        id: 'Desktop',
        domainFn: (DateTimeSales row, _) => row.timeStamp,
        measureFn: (DateTimeSales row, _) => row.sales,
        data: myFakeDesktopData),
  ];
}

List<charts.Series<DateTimeSales, DateTime>> _createDateTimeLargeNumbers() {
  final random = new Random();

  var myFakeDesktopData = [
    new DateTimeSales(new DateTime(2017, 9, 25), 100 + random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 9, 26), 100 + random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 9, 27), 100 + random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 9, 28), 100 + random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 9, 29), 100 + random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 9, 30), 100 + random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 10, 01), 100 + random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 10, 02), 100 + random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 10, 03), 100 + random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 10, 04), 100 + random.nextInt(35)),
    new DateTimeSales(new DateTime(2017, 10, 05), 100 + random.nextInt(35)),
  ];
  return [
    new charts.Series<DateTimeSales, DateTime>(
        id: 'Desktop',
        domainFn: (DateTimeSales row, _) => row.timeStamp,
        measureFn: (DateTimeSales row, _) => row.sales,
        data: myFakeDesktopData),
  ];
}

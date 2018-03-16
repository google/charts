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
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import '../gallery_scaffold.dart';
import 'rtl_bar_chart.dart';
import 'rtl_line_chart.dart';
import 'rtl_series_legend.dart';

List<GalleryScaffold> buildGallery() {
  return [
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.flag),
      title: 'RTL Bar Chart',
      subtitle: 'Simple bar chart in RTL',
      childBuilder: (List<charts.Series> series) => new RTLBarChart(series),
      seriesListBuilder: _createSingleOrdinalSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.flag),
      title: 'RTL Line Chart',
      subtitle: 'Simple line chart in RTL',
      childBuilder: (List<charts.Series> series) => new RTLLineChart(series),
      seriesListBuilder: _createNumericSingleSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.flag),
      title: 'RTL Series Legend',
      subtitle: 'Series legend in RTL',
      childBuilder: (List<charts.Series> series) => new RTLSeriesLegend(series),
      seriesListBuilder: _createMultipleSeries,
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
List<charts.Series<OrdinalSales, String>> _createSingleOrdinalSeries() {
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

/// Sample linear data type.
class LinearSales {
  final int year;
  final int sales;

  LinearSales(this.year, this.sales);
}

/// Create one series with random data.
List<charts.Series<LinearSales, int>> _createNumericSingleSeries() {
  final random = new Random();

  final data = [
    new LinearSales(0, random.nextInt(100)),
    new LinearSales(1, random.nextInt(100)),
    new LinearSales(2, random.nextInt(100)),
    new LinearSales(3, random.nextInt(100)),
  ];

  return [
    new charts.Series<LinearSales, int>(
      id: 'Sales',
      domainFn: (LinearSales sales, _) => sales.year,
      measureFn: (LinearSales sales, _) => sales.sales,
      data: data,
    )
  ];
}

/// Create series list with multiple series.
List<charts.Series<OrdinalSales, String>> _createMultipleSeries(
    {String suffix = ''}) {
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

  final otherSalesData = [
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
        data: desktopSalesData),
    new charts.Series<OrdinalSales, String>(
        id: 'Tablet${suffix}',
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: tableSalesData),
    new charts.Series<OrdinalSales, String>(
        id: 'Mobile${suffix}',
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: mobileSalesData),
    new charts.Series<OrdinalSales, String>(
        id: 'Other${suffix}',
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: otherSalesData),
  ];
}

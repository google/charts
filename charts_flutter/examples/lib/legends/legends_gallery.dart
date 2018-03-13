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
import 'simple_series_legend.dart';
import 'legend_options.dart';
import 'legend_custom_symbol.dart';

List<GalleryScaffold> buildGallery() {
  return [
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Series Legend',
      subtitle: 'A series legend for a bar chart with default settings',
      childBuilder: (List<charts.Series> series) =>
          new SimpleSeriesLegend(series),
      seriesListBuilder: _createMultipleSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Series Legend Options',
      subtitle:
          'A series legend with custom positioning and spacing for a bar chart',
      childBuilder: (List<charts.Series> series) => new LegendOptions(series),
      seriesListBuilder: _createMultipleSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Series Legend Custom Symbol',
      subtitle: 'A series legend using a custom symbol renderer',
      childBuilder: (List<charts.Series> series) =>
          new LegendWithCustomSymbol(series),
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

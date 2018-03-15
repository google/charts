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
import 'animation_zoom.dart';
import 'dash_pattern.dart';
import 'range_annotation.dart';
import 'simple.dart';

List<GalleryScaffold> buildGallery() {
  return [
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.show_chart),
      title: 'Simple Line Chart',
      subtitle: 'With a single series and default line point highlighter',
      childBuilder: (List<charts.Series> series) => new SimpleLineChart(series),
      seriesListBuilder: _createSingleSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.show_chart),
      title: 'Dash Pattern Line Chart',
      subtitle: 'With three series and default line point highlighter',
      childBuilder: (List<charts.Series> series) =>
          new DashPatternLineChart(series),
      seriesListBuilder: _createMultipleSeriesWithDashPattern,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.show_chart),
      title: 'Range Annotation Line Chart',
      subtitle: 'Line chart with range annotations',
      childBuilder: (List<charts.Series> series) =>
          new LineRangeAnnotationChart(series),
      seriesListBuilder: _createSingleSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.show_chart),
      title: 'Pan and Zoom Line Chart',
      subtitle: 'Simple line chart pan and zoom behaviors enabled',
      childBuilder: (List<charts.Series> series) =>
          new LineAnimationZoomChart(series),
      seriesListBuilder: _createSingleSeries,
    ),
  ];
}

/// Sample linear data type.
class LinearSales {
  final int year;
  final int sales;

  LinearSales(this.year, this.sales);
}

/// Create one series with random data.
List<charts.Series<LinearSales, int>> _createSingleSeries() {
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

/// Create multiple series with a forward hatch pattern on the middle series.
List<charts.Series<LinearSales, int>> _createMultipleSeriesWithDashPattern(
    {String rendererId}) {
  final random = new Random();

  final desktopSalesData = [
    new LinearSales(0, random.nextInt(100)),
    new LinearSales(1, random.nextInt(100)),
    new LinearSales(2, random.nextInt(100)),
    new LinearSales(3, random.nextInt(100)),
  ];

  final tableSalesData = [
    new LinearSales(0, random.nextInt(100)),
    new LinearSales(1, random.nextInt(100)),
    new LinearSales(2, random.nextInt(100)),
    new LinearSales(3, random.nextInt(100)),
  ];

  final mobileSalesData = [
    new LinearSales(0, random.nextInt(100)),
    new LinearSales(1, random.nextInt(100)),
    new LinearSales(2, random.nextInt(100)),
    new LinearSales(3, random.nextInt(100)),
  ];

  return [
    new charts.Series<LinearSales, int>(
        id: 'Desktop',
        domainFn: (LinearSales sales, _) => sales.year,
        measureFn: (LinearSales sales, _) => sales.sales,
        data: desktopSalesData)
      ..setAttribute(charts.rendererIdKey, rendererId),
    new charts.Series<LinearSales, int>(
        id: 'Tablet',
        dashPattern: [2, 2],
        domainFn: (LinearSales sales, _) => sales.year,
        measureFn: (LinearSales sales, _) => sales.sales,
        data: tableSalesData)
      ..setAttribute(charts.rendererIdKey, rendererId),
    new charts.Series<LinearSales, int>(
        id: 'Mobile',
        dashPattern: [8, 3, 2, 3],
        domainFn: (LinearSales sales, _) => sales.year,
        measureFn: (LinearSales sales, _) => sales.sales,
        data: mobileSalesData)
      ..setAttribute(charts.rendererIdKey, rendererId),
  ];
}

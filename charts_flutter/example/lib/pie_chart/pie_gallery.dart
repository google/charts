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
import 'donut.dart';
import 'simple.dart';

List<GalleryScaffold> buildGallery() {
  return [
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.pie_chart),
      title: 'Simple Pie Chart',
      subtitle: 'With a single series',
      childBuilder: (List<charts.Series> series) => new SimplePieChart(series),
      seriesListBuilder: _createSingleSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.pie_chart),
      title: 'Simple Donut Chart',
      subtitle: 'With a single series and a hole in the middle',
      childBuilder: (List<charts.Series> series) => new DonutPieChart(series),
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

  // Generate sorted data, so that the largest slice is first in the chart.
  final sales = [
    random.nextInt(100),
    random.nextInt(100),
    random.nextInt(100),
    random.nextInt(100),
  ];
  sales.sort();

  final data = [
    new LinearSales(0, sales[3]),
    new LinearSales(1, sales[2]),
    new LinearSales(2, sales[1]),
    new LinearSales(3, sales[0]),
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

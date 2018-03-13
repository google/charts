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
import 'range_annotation.dart';
import 'simple.dart';

List<GalleryScaffold> buildGallery() {
  return [
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.show_chart),
      title: 'Time Series Chart',
      subtitle: 'Simple single time series chart',
      childBuilder: (List<charts.Series> series) =>
          new SimpleTimeSeriesChart(series),
      seriesListBuilder: _createSingleSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.show_chart),
      title: 'Range Annotation Time Series Chart',
      subtitle: 'Time series chart with future range annotation',
      childBuilder: (List<charts.Series> series) =>
          new TimeSeriesRangeAnnotationChart(series),
      seriesListBuilder: _createSingleSeries,
    ),
  ];
}

/// Sample time series data type.
class TimeSeriesSales {
  final DateTime time;
  final int sales;

  TimeSeriesSales(this.time, this.sales);
}

/// Create one series with random data.
List<charts.Series<TimeSeriesSales, DateTime>> _createSingleSeries() {
  final random = new Random();

  final data = [
    new TimeSeriesSales(new DateTime(2017, 9, 19), random.nextInt(100)),
    new TimeSeriesSales(new DateTime(2017, 9, 26), random.nextInt(100)),
    new TimeSeriesSales(new DateTime(2017, 10, 3), random.nextInt(100)),
    new TimeSeriesSales(new DateTime(2017, 10, 10), random.nextInt(100)),
  ];

  return [
    new charts.Series<TimeSeriesSales, DateTime>(
      id: 'Sales',
      domainFn: (TimeSeriesSales sales, _) => sales.time,
      measureFn: (TimeSeriesSales sales, _) => sales.sales,
      data: data,
    )
  ];
}

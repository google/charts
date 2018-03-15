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
import 'package:meta/meta.dart';
import '../gallery_scaffold.dart';
import 'selection_bar_highlight.dart';
import 'selection_line_highlight.dart';
import 'selection_callback_example.dart';

List<GalleryScaffold> buildGallery() {
  return [
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.flag),
      title: 'Selection Bar Highlight',
      subtitle: 'Simple bar chart with tap activation',
      childBuilder: (List<charts.Series> series) =>
          new SelectionBarHighlight(series),
      seriesListBuilder: _createSingleOrdinalSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.flag),
      title: 'Selection Line Highlight',
      subtitle: 'Line chart with tap and drag activation',
      childBuilder: (List<charts.Series> series) =>
          new SelectionLineHighlight(series),
      seriesListBuilder: _createSingleLinearSeries,
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.flag),
      title: 'Selection Callback Example',
      subtitle: 'Timeseries that updates external components on selection',
      childBuilder: (List<charts.Series> series) =>
          new SelectionCallbackExample(series),
      seriesListBuilder: _timeSeriesFactory(count: 2),
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
List<charts.Series<LinearSales, int>> _createSingleLinearSeries() {
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

SeriesListBuilder _timeSeriesFactory({@required int count}) {
  return () {
    final seriesList = <charts.Series<TimeSeriesSales, DateTime>>[];
    final seriesNames = <String>[
      'US Sales',
      'UK Sales',
      'MX Sales',
      'JP Sales'
    ];
    final random = new Random();

    for (int i = 0; i < count; i++) {
      final data = [
        new TimeSeriesSales(new DateTime(2017, 9, 19), random.nextInt(100)),
        new TimeSeriesSales(new DateTime(2017, 9, 26), random.nextInt(100)),
        new TimeSeriesSales(new DateTime(2017, 10, 3), random.nextInt(100)),
        new TimeSeriesSales(new DateTime(2017, 10, 10), random.nextInt(100)),
      ];

      seriesList.add(new charts.Series<TimeSeriesSales, DateTime>(
        id: seriesNames[i],
        domainFn: (TimeSeriesSales sales, _) => sales.time,
        measureFn: (TimeSeriesSales sales, _) => sales.sales,
        data: data,
      ));
    }

    return seriesList;
  };
}

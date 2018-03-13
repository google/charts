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

import 'dart:developer';
import 'dart:math';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'drawer.dart';
import 'internal/internal_scaffold.dart';
import 'internal/time_series_performance.dart' show TimeSeriesPerformanceChart;

void main() {
  final app = new InternalApp();
  runApp(app);
}

class InternalApp extends StatefulWidget {
  @override
  InternalAppState createState() => new InternalAppState();
}

class InternalAppState extends State<InternalApp> {
  // Initialize app settings from the default configuration.
  bool _showPerformanceOverlay = false;

  final _timeSeriesData = _createSampleData();

  @override
  Widget build(BuildContext context) {
    _setupPerformance();

    return new MaterialApp(
      title: 'Internal Testing App',
      theme: new ThemeData(
          brightness: Brightness.light, primarySwatch: Colors.amber),
      showPerformanceOverlay: _showPerformanceOverlay,
      home: new Scaffold(
          drawer: new GalleryDrawer(
              showPerformanceOverlay: _showPerformanceOverlay,
              onShowPerformanceOverlayChanged: (bool value) {
                setState(() {
                  _showPerformanceOverlay = value;
                });
              }),
          appBar: new AppBar(title: new Text('Internal')),
          body: new _Gallery(_timeSeriesData)),
    );
  }
}

class _Gallery extends StatelessWidget {
  final List<charts.Series<_TimeSeriesSales, DateTime>> timeSeriesData;

  _Gallery(this.timeSeriesData);

  @override
  Widget build(BuildContext context) {
    return new ListView(children: [
      new InternalScaffold(
              title: 'Lots of data time series chart',
              child: new TimeSeriesPerformanceChart(timeSeriesData))
          .buildGalleryListTile(context)
    ]);
  }
}

void _setupPerformance() {
  // Change [printPerformance] to true and set the app to release mode to
  // print performance numbers to console. By default, Flutter builds in debug
  // mode and this mode is slow. To build in release mode, specify the flag
  // blaze-run flag "--define flutter_build_mode=release".
  // The build target must also be an actual device and not the emulator.
  charts.Performance.time = (String tag) => Timeline.startSync(tag);
  charts.Performance.timeEnd = (_) => Timeline.finishSync();
}

/// Create one series with sample hard coded data.
List<charts.Series<_TimeSeriesSales, DateTime>> _createSampleData() {
  const int numDataPointsToGenerate = 6000;
  const int maxVariation = 10;
  const Duration timeIncrements = const Duration(minutes: 15);
  final random = new Random();
  var startTime = new DateTime(2017, 10, 20);

  final salesData =
      new List<_TimeSeriesSales>.generate(numDataPointsToGenerate, (int index) {
    final onePoint =
        new _TimeSeriesSales(startTime, index + random.nextInt(maxVariation));
    startTime = startTime.add(timeIncrements);
    return onePoint;
  });

  final seriesList = [
    new charts.Series<_TimeSeriesSales, DateTime>(
      id: 'Sales',
      colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
      domainFn: (_TimeSeriesSales sales, _) => sales.time,
      measureFn: (_TimeSeriesSales sales, _) => sales.sales,
      data: salesData,
    ),
  ];

  // Add 10 other lines with slight offset
  for (var i = 1; i < 10; i++) {
    seriesList.add(new charts.Series<_TimeSeriesSales, DateTime>(
      id: 'Projection' + i.toString(),
      colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
      domainFn: (_TimeSeriesSales sales, _) => sales.time,
      measureFn: (_TimeSeriesSales sales, _) => sales.sales,
      data: salesData
          .map((sales) =>
              new _TimeSeriesSales(sales.time, sales.sales + 50 * (i)))
          .toList(),
    ));
  }

  return seriesList;
}

/// Sample time series data type.
class _TimeSeriesSales {
  final DateTime time;
  final int sales;

  _TimeSeriesSales(this.time, this.sales);
}

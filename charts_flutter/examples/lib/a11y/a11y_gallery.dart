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
import 'domain_a11y_explore_bar_chart.dart';

List<GalleryScaffold> buildGallery() {
  return [
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.accessibility),
      title: 'Screen reader enabled bar chart',
      subtitle: 'Requires TalkBack or Voiceover turned on to work. '
          'Bar chart with domain selection explore mode behavior.',
      childBuilder: (List<charts.Series> series) =>
          new DomainA11yExploreBarChart(series),
      seriesListBuilder: _createMultiSeriesWithMissingDomain,
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
List<charts.Series<OrdinalSales, String>>
    _createMultiSeriesWithMissingDomain() {
  final random = new Random();

  final mobileData = [
    new OrdinalSales('2014', random.nextInt(100)),
    new OrdinalSales('2015', random.nextInt(100)),
    new OrdinalSales('2016', random.nextInt(100)),
    new OrdinalSales('2017', random.nextInt(100)),
  ];

  final tabletData = [
    // Purposely missing data to show that only measures that are available
    // are vocalized.
    new OrdinalSales('2016', random.nextInt(100)),
    new OrdinalSales('2017', random.nextInt(100)),
  ];

  return [
    new charts.Series<OrdinalSales, String>(
      id: 'Mobile Sales',
      domainFn: (OrdinalSales sales, _) => sales.year,
      measureFn: (OrdinalSales sales, _) => sales.sales,
      data: mobileData,
    ),
    new charts.Series<OrdinalSales, String>(
      id: 'Tablet Sales',
      domainFn: (OrdinalSales sales, _) => sales.year,
      measureFn: (OrdinalSales sales, _) => sales.sales,
      data: tabletData,
    )
  ];
}

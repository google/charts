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

import 'package:charts_common/src/chart/common/processed_series.dart'
    show MutableSeries;
import 'package:charts_common/src/chart/scatter_plot/point_renderer.dart';
import 'package:charts_common/src/chart/scatter_plot/point_renderer_config.dart';
import 'package:charts_common/src/common/material_palette.dart'
    show MaterialPalette;
import 'package:charts_common/src/data/series.dart' show Series;

import 'package:test/test.dart';

/// Datum/Row for the chart.
class MyRow {
  final String campaignString;
  final int campaign;
  final int clickCount;
  final double radius;
  MyRow(this.campaignString, this.campaign, this.clickCount, this.radius);
}

void main() {
  PointRenderer renderer;
  List<MutableSeries<MyRow, int>> numericSeriesList;

  setUp(() {
    var myFakeDesktopData = [
      new MyRow('MyCampaign1', 0, 5, 3.0),
      new MyRow('MyCampaign2', 10, 25, 5.0),
      new MyRow('MyCampaign3', 12, 75, 4.0),
      // This datum should always get a default radiusPx value.
      new MyRow('MyCampaign4', 13, 225, null),
    ];

    final maxMeasure = 300;

    numericSeriesList = [
      new MutableSeries<MyRow, int>(new Series<MyRow, int>(
          id: 'Desktop',
          colorFn: (MyRow row, _) {
            // Color bucket the measure column value into 3 distinct colors.
            final bucket = row.clickCount / maxMeasure;

            if (bucket < 1 / 3) {
              return MaterialPalette.blue.shadeDefault;
            } else if (bucket < 2 / 3) {
              return MaterialPalette.red.shadeDefault;
            } else {
              return MaterialPalette.green.shadeDefault;
            }
          },
          domainFn: (MyRow row, _) => row.campaign,
          measureFn: (MyRow row, _) => row.clickCount,
          measureOffsetFn: (MyRow row, _) => 0,
          radiusPxFn: (MyRow row, _) => row.radius,
          data: myFakeDesktopData))
    ];
  });

  group('preprocess', () {
    test('with numeric data and simple points', () {
      renderer =
          new PointRenderer<dynamic, num>(config: new PointRendererConfig());

      renderer.preprocessSeries(numericSeriesList);

      expect(numericSeriesList.length, equals(1));

      // Validate Desktop series.
      var series = numericSeriesList[0];

      var elementsList = series.getAttr(pointElementsKey);
      expect(elementsList.length, equals(4));

      expect(elementsList[0].radiusPx, equals(3.0));
      expect(elementsList[1].radiusPx, equals(5.0));
      expect(elementsList[2].radiusPx, equals(4.0));
      expect(elementsList[3].radiusPx, equals(3.5));
    });

    test('with numeric data and missing radiusPxFn', () {
      renderer = new PointRenderer<dynamic, num>(
          config: new PointRendererConfig(radiusPx: 2.0));

      // Remove the radiusPxFn to test configured defaults.
      numericSeriesList[0].radiusPxFn = null;

      renderer.preprocessSeries(numericSeriesList);

      expect(numericSeriesList.length, equals(1));

      // Validate Desktop series.
      var series = numericSeriesList[0];

      var elementsList = series.getAttr(pointElementsKey);
      expect(elementsList.length, equals(4));

      expect(elementsList[0].radiusPx, equals(2.0));
      expect(elementsList[1].radiusPx, equals(2.0));
      expect(elementsList[2].radiusPx, equals(2.0));
      expect(elementsList[3].radiusPx, equals(2.0));
    });
  });
}

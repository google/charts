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

import 'package:charts_common/src/chart/line/line_renderer.dart';
import 'package:charts_common/src/chart/line/line_renderer_config.dart';
import 'package:charts_common/src/chart/common/processed_series.dart'
    show MutableSeries;
import 'package:charts_common/src/common/material_palette.dart'
    show MaterialPalette;
import 'package:charts_common/src/data/series.dart' show Series;

import 'package:test/test.dart';

/// Datum/Row for the chart.
class MyRow {
  final String campaignString;
  final int campaign;
  final int clickCount;
  MyRow(this.campaignString, this.campaign, this.clickCount);
}

void main() {
  LineRenderer renderer;
  List<MutableSeries<int>> numericSeriesList;
  List<MutableSeries<String>> ordinalSeriesList;

  setUp(() {
    var myFakeDesktopData = [
      new MyRow('MyCampaign1', 1, 5),
      new MyRow('MyCampaign2', 2, 25),
      new MyRow('MyCampaign3', 3, 100),
      new MyRow('MyOtherCampaign', 4, 75),
    ];

    var myFakeTabletData = [
      new MyRow('MyCampaign1', 1, 5),
      new MyRow('MyCampaign2', 2, 25),
      new MyRow('MyCampaign3', 3, 100),
      new MyRow('MyOtherCampaign', 4, 75),
    ];

    var myFakeMobileData = [
      new MyRow('MyCampaign1', 1, 5),
      new MyRow('MyCampaign2', 2, 25),
      new MyRow('MyCampaign3', 3, 100),
      new MyRow('MyOtherCampaign', 4, 75),
    ];

    numericSeriesList = [
      new MutableSeries<int>(new Series<MyRow, int>(
          id: 'Desktop',
          colorFn: (_, __) => MaterialPalette.blue.shadeDefault,
          domainFn: (dynamic row, _) => row.campaign,
          measureFn: (dynamic row, _) => row.clickCount,
          measureOffsetFn: (_, __) => 0,
          data: myFakeDesktopData)),
      new MutableSeries<int>(new Series<MyRow, int>(
          id: 'Tablet',
          colorFn: (_, __) => MaterialPalette.red.shadeDefault,
          domainFn: (dynamic row, _) => row.campaign,
          measureFn: (dynamic row, _) => row.clickCount,
          measureOffsetFn: (_, __) => 0,
          strokeWidthPxFn: (_, __) => 1.25,
          data: myFakeTabletData)),
      new MutableSeries<int>(new Series<MyRow, int>(
          id: 'Mobile',
          colorFn: (_, __) => MaterialPalette.green.shadeDefault,
          domainFn: (dynamic row, _) => row.campaign,
          measureFn: (dynamic row, _) => row.clickCount,
          measureOffsetFn: (_, __) => 0,
          strokeWidthPxFn: (_, __) => 3.0,
          data: myFakeMobileData))
    ];

    ordinalSeriesList = [
      new MutableSeries<String>(new Series<MyRow, String>(
          id: 'Desktop',
          colorFn: (_, __) => MaterialPalette.blue.shadeDefault,
          domainFn: (dynamic row, _) => row.campaignString,
          measureFn: (dynamic row, _) => row.clickCount,
          measureOffsetFn: (_, __) => 0,
          data: myFakeDesktopData)),
      new MutableSeries<String>(new Series<MyRow, String>(
          id: 'Tablet',
          colorFn: (_, __) => MaterialPalette.red.shadeDefault,
          domainFn: (dynamic row, _) => row.campaignString,
          measureFn: (dynamic row, _) => row.clickCount,
          measureOffsetFn: (_, __) => 0,
          strokeWidthPxFn: (_, __) => 1.25,
          data: myFakeTabletData)),
      new MutableSeries<String>(new Series<MyRow, String>(
          id: 'Mobile',
          colorFn: (_, __) => MaterialPalette.green.shadeDefault,
          domainFn: (dynamic row, _) => row.campaignString,
          measureFn: (dynamic row, _) => row.clickCount,
          measureOffsetFn: (_, __) => 0,
          strokeWidthPxFn: (_, __) => 3.0,
          data: myFakeMobileData))
    ];
  });

  group('preprocess', () {
    test('with numeric data and simple lines', () {
      renderer = new LineRenderer<num>(
          config: new LineRendererConfig(strokeWidthPx: 2.0));

      renderer.preprocessSeries(numericSeriesList);

      expect(numericSeriesList.length, equals(3));

      // Validate Desktop series.
      var series = numericSeriesList[0];

      var elementsList = series.getAttr(lineElementsKey);
      expect(elementsList.length, equals(1));

      var element = elementsList[0];
      expect(element.strokeWidthPx, equals(2.0));

      expect(series.measureOffsetFn(0), 0);
      expect(series.measureOffsetFn(1), 0);
      expect(series.measureOffsetFn(2), 0);
      expect(series.measureOffsetFn(3), 0);

      // Validate Tablet series.
      series = numericSeriesList[1];

      elementsList = series.getAttr(lineElementsKey);
      expect(elementsList.length, equals(1));

      element = elementsList[0];
      expect(element.strokeWidthPx, equals(1.25));

      expect(series.measureOffsetFn(0), 0);
      expect(series.measureOffsetFn(1), 0);
      expect(series.measureOffsetFn(2), 0);
      expect(series.measureOffsetFn(3), 0);

      // Validate Mobile series.
      series = numericSeriesList[2];

      elementsList = series.getAttr(lineElementsKey);
      expect(elementsList.length, equals(1));

      element = elementsList[0];
      expect(element.strokeWidthPx, equals(3.0));

      expect(series.measureOffsetFn(0), 0);
      expect(series.measureOffsetFn(1), 0);
      expect(series.measureOffsetFn(2), 0);
      expect(series.measureOffsetFn(3), 0);
    });

    test('with numeric data and stacked lines', () {
      renderer = new LineRenderer<num>(
          config: new LineRendererConfig(stacked: true, strokeWidthPx: 2.0));

      renderer.preprocessSeries(numericSeriesList);

      expect(numericSeriesList.length, equals(3));

      // Validate Desktop series.
      var series = numericSeriesList[0];

      var elementsList = series.getAttr(lineElementsKey);
      expect(elementsList.length, equals(1));

      var element = elementsList[0];
      expect(element.strokeWidthPx, equals(2.0));

      expect(series.measureOffsetFn(0), 0);
      expect(series.measureOffsetFn(1), 0);
      expect(series.measureOffsetFn(2), 0);
      expect(series.measureOffsetFn(3), 0);

      // Validate Tablet series.
      series = numericSeriesList[1];

      elementsList = series.getAttr(lineElementsKey);
      expect(elementsList.length, equals(1));

      element = elementsList[0];
      expect(element.strokeWidthPx, equals(1.25));

      expect(series.measureOffsetFn(0), 5);
      expect(series.measureOffsetFn(1), 25);
      expect(series.measureOffsetFn(2), 100);
      expect(series.measureOffsetFn(3), 75);

      // Validate Mobile series.
      series = numericSeriesList[2];

      elementsList = series.getAttr(lineElementsKey);
      expect(elementsList.length, equals(1));

      element = elementsList[0];
      expect(element.strokeWidthPx, equals(3.0));

      expect(series.measureOffsetFn(0), 10);
      expect(series.measureOffsetFn(1), 50);
      expect(series.measureOffsetFn(2), 200);
      expect(series.measureOffsetFn(3), 150);
    });

    test('with ordinal data and simple lines', () {
      renderer = new LineRenderer<String>(
          config: new LineRendererConfig(strokeWidthPx: 2.0));

      renderer.preprocessSeries(ordinalSeriesList);

      expect(ordinalSeriesList.length, equals(3));

      // Validate Desktop series.
      var series = ordinalSeriesList[0];

      var elementsList = series.getAttr(lineElementsKey);
      expect(elementsList.length, equals(1));

      var element = elementsList[0];
      expect(element.strokeWidthPx, equals(2.0));

      // Validate Tablet series.
      series = ordinalSeriesList[1];

      elementsList = series.getAttr(lineElementsKey);
      expect(elementsList.length, equals(1));

      element = elementsList[0];
      expect(element.strokeWidthPx, equals(1.25));

      // Validate Mobile series.
      series = ordinalSeriesList[2];

      elementsList = series.getAttr(lineElementsKey);
      expect(elementsList.length, equals(1));

      element = elementsList[0];
      expect(element.strokeWidthPx, equals(3.0));
    });
  });
}

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

import 'package:charts_common/src/chart/bar/bar_target_line_renderer.dart';
import 'package:charts_common/src/chart/bar/bar_target_line_renderer_config.dart';
import 'package:charts_common/src/chart/bar/base_bar_renderer.dart';
import 'package:charts_common/src/chart/bar/base_bar_renderer_config.dart';
import 'package:charts_common/src/chart/common/processed_series.dart'
    show MutableSeries;
import 'package:charts_common/src/data/series.dart' show Series;

import 'package:test/test.dart';

/// Datum/Row for the chart.
class MyRow {
  final String campaign;
  final int clickCount;
  MyRow(this.campaign, this.clickCount);
}

void main() {
  BarTargetLineRenderer renderer;
  List<MutableSeries<String>> seriesList;

  setUp(() {
    var myFakeDesktopData = [
      new MyRow('MyCampaign1', 5),
      new MyRow('MyCampaign2', 25),
      new MyRow('MyCampaign3', 100),
      new MyRow('MyOtherCampaign', 75),
    ];

    var myFakeTabletData = [
      new MyRow('MyCampaign1', 5),
      new MyRow('MyCampaign2', 25),
      new MyRow('MyCampaign3', 100),
      new MyRow('MyOtherCampaign', 75),
    ];

    var myFakeMobileData = [
      new MyRow('MyCampaign1', 5),
      new MyRow('MyCampaign2', 25),
      new MyRow('MyCampaign3', 100),
      new MyRow('MyOtherCampaign', 75),
    ];

    seriesList = [
      new MutableSeries<String>(new Series<MyRow, String>(
          id: 'Desktop',
          domainFn: (MyRow row, _) => row.campaign,
          measureFn: (MyRow row, _) => row.clickCount,
          measureOffsetFn: (MyRow row, _) => 0,
          data: myFakeDesktopData)),
      new MutableSeries<String>(new Series<MyRow, String>(
          id: 'Tablet',
          domainFn: (MyRow row, _) => row.campaign,
          measureFn: (MyRow row, _) => row.clickCount,
          measureOffsetFn: (MyRow row, _) => 0,
          data: myFakeTabletData)),
      new MutableSeries<String>(new Series<MyRow, String>(
          id: 'Mobile',
          domainFn: (MyRow row, _) => row.campaign,
          measureFn: (MyRow row, _) => row.clickCount,
          measureOffsetFn: (MyRow row, _) => 0,
          data: myFakeMobileData))
    ];
  });

  group('preprocess', () {
    test('with grouped bar target lines', () {
      renderer = new BarTargetLineRenderer(
          config: new BarTargetLineRendererConfig(
              groupingType: BarGroupingType.grouped));

      renderer.preprocessSeries(seriesList);

      expect(seriesList.length, equals(3));

      // Validate Desktop series.
      var series = seriesList[0];
      expect(series.getAttr(barGroupIndexKey), equals(0));
      expect(series.getAttr(barGroupCountKey), equals(3));
      expect(series.getAttr(stackKeyKey), equals('__defaultKey__'));

      var elementsList = series.getAttr(barElementsKey);
      expect(elementsList.length, equals(4));

      var element = elementsList[0];
      expect(element.barStackIndex, equals(0));
      expect(element.measureOffset, equals(0));
      expect(element.measureOffsetPlusMeasure, equals(null));
      expect(series.measureOffsetFn(0), equals(0));
      expect(element.strokeWidthPx, equals(3));

      // Validate Tablet series.
      series = seriesList[1];
      expect(series.getAttr(barGroupIndexKey), equals(1));
      expect(series.getAttr(barGroupCountKey), equals(3));
      expect(series.getAttr(stackKeyKey), equals('__defaultKey__'));

      elementsList = series.getAttr(barElementsKey);
      expect(elementsList.length, equals(4));

      element = elementsList[0];
      expect(element.barStackIndex, equals(0));
      expect(element.measureOffset, equals(0));
      expect(element.measureOffsetPlusMeasure, equals(null));
      expect(series.measureOffsetFn(0), equals(0));
      expect(element.strokeWidthPx, equals(3));

      // Validate Mobile series.
      series = seriesList[2];
      expect(series.getAttr(barGroupIndexKey), equals(2));
      expect(series.getAttr(barGroupCountKey), equals(3));
      expect(series.getAttr(stackKeyKey), equals('__defaultKey__'));

      elementsList = series.getAttr(barElementsKey);
      expect(elementsList.length, equals(4));

      element = elementsList[0];
      expect(element.barStackIndex, equals(0));
      expect(element.measureOffset, equals(0));
      expect(element.measureOffsetPlusMeasure, equals(null));
      expect(series.measureOffsetFn(0), equals(0));
      expect(element.strokeWidthPx, equals(3));
    });

    test('with stacked bar target lines', () {
      renderer = new BarTargetLineRenderer(
          config: new BarTargetLineRendererConfig(
              groupingType: BarGroupingType.stacked));

      renderer.preprocessSeries(seriesList);

      expect(seriesList.length, equals(3));

      // Validate Desktop series.
      var series = seriesList[0];
      expect(series.getAttr(barGroupIndexKey), equals(0));
      expect(series.getAttr(barGroupCountKey), equals(1));
      expect(series.getAttr(stackKeyKey), equals('__defaultKey__'));

      var elementsList = series.getAttr(barElementsKey);
      expect(elementsList.length, equals(4));

      var element = elementsList[0];
      expect(element.barStackIndex, equals(2));
      expect(element.measureOffset, equals(10));
      expect(element.measureOffsetPlusMeasure, equals(15));
      expect(series.measureOffsetFn(0), equals(10));
      expect(element.strokeWidthPx, equals(3));

      // Validate Tablet series.
      series = seriesList[1];
      expect(series.getAttr(barGroupIndexKey), equals(0));
      expect(series.getAttr(barGroupCountKey), equals(1));
      expect(series.getAttr(stackKeyKey), equals('__defaultKey__'));

      elementsList = series.getAttr(barElementsKey);
      expect(elementsList.length, equals(4));

      element = elementsList[0];
      expect(element.barStackIndex, equals(1));
      expect(element.measureOffset, equals(5));
      expect(element.measureOffsetPlusMeasure, equals(10));
      expect(series.measureOffsetFn(0), equals(5));
      expect(element.strokeWidthPx, equals(3));

      // Validate Mobile series.
      series = seriesList[2];
      expect(series.getAttr(barGroupIndexKey), equals(0));
      expect(series.getAttr(barGroupCountKey), equals(1));
      expect(series.getAttr(stackKeyKey), equals('__defaultKey__'));

      elementsList = series.getAttr(barElementsKey);
      expect(elementsList.length, equals(4));

      element = elementsList[0];
      expect(element.barStackIndex, equals(0));
      expect(element.measureOffset, equals(0));
      expect(element.measureOffsetPlusMeasure, equals(5));
      expect(series.measureOffsetFn(0), equals(0));
      expect(element.strokeWidthPx, equals(3));
    });

    test('with stacked bar target lines containing zero and null', () {
      // Set up some nulls and zeros in the data.
      seriesList[2].data[0] = new MyRow('MyCampaign1', null);
      seriesList[2].data[2] = new MyRow('MyCampaign3', 0);

      seriesList[1].data[1] = new MyRow('MyCampaign2', null);
      seriesList[1].data[3] = new MyRow('MyOtherCampaign', 0);

      seriesList[0].data[2] = new MyRow('MyCampaign3', 0);

      renderer = new BarTargetLineRenderer(
          config: new BarTargetLineRendererConfig(
              groupingType: BarGroupingType.stacked));

      renderer.preprocessSeries(seriesList);

      expect(seriesList.length, equals(3));

      // Validate Desktop series.
      var series = seriesList[0];
      var elementsList = series.getAttr(barElementsKey);

      var element = elementsList[0];
      expect(element.barStackIndex, equals(2));
      expect(element.measureOffset, equals(5));
      expect(element.measureOffsetPlusMeasure, equals(10));
      expect(series.measureOffsetFn(0), equals(5));
      expect(element.strokeWidthPx, equals(3));

      element = elementsList[1];
      expect(element.measureOffset, equals(25));
      expect(element.measureOffsetPlusMeasure, equals(50));
      expect(series.measureOffsetFn(1), equals(25));
      expect(element.strokeWidthPx, equals(3));

      element = elementsList[2];
      expect(element.measureOffset, equals(100));
      expect(element.measureOffsetPlusMeasure, equals(100));
      expect(series.measureOffsetFn(2), equals(100));
      expect(element.strokeWidthPx, equals(3));

      element = elementsList[3];
      expect(element.measureOffset, equals(75));
      expect(element.measureOffsetPlusMeasure, equals(150));
      expect(series.measureOffsetFn(3), equals(75));
      expect(element.strokeWidthPx, equals(3));

      // Validate Tablet series.
      series = seriesList[1];

      elementsList = series.getAttr(barElementsKey);
      expect(elementsList.length, equals(4));

      element = elementsList[0];
      expect(element.barStackIndex, equals(1));
      expect(element.measureOffset, equals(0));
      expect(element.measureOffsetPlusMeasure, equals(5));
      expect(series.measureOffsetFn(0), equals(0));
      expect(element.strokeWidthPx, equals(3));

      element = elementsList[1];
      expect(element.measureOffset, equals(25));
      expect(element.measureOffsetPlusMeasure, equals(25));
      expect(series.measureOffsetFn(1), equals(25));
      expect(element.strokeWidthPx, equals(3));

      element = elementsList[2];
      expect(element.measureOffset, equals(0));
      expect(element.measureOffsetPlusMeasure, equals(100));
      expect(series.measureOffsetFn(2), equals(0));
      expect(element.strokeWidthPx, equals(3));

      element = elementsList[3];
      expect(element.measureOffset, equals(75));
      expect(element.measureOffsetPlusMeasure, equals(75));
      expect(series.measureOffsetFn(3), equals(75));
      expect(element.strokeWidthPx, equals(3));

      // Validate Mobile series.
      series = seriesList[2];
      elementsList = series.getAttr(barElementsKey);

      element = elementsList[0];
      expect(element.barStackIndex, equals(0));
      expect(element.measureOffset, equals(0));
      expect(element.measureOffsetPlusMeasure, equals(0));
      expect(series.measureOffsetFn(0), equals(0));
      expect(element.strokeWidthPx, equals(3));

      element = elementsList[1];
      expect(element.measureOffset, equals(0));
      expect(element.measureOffsetPlusMeasure, equals(25));
      expect(series.measureOffsetFn(1), equals(0));
      expect(element.strokeWidthPx, equals(3));

      element = elementsList[2];
      expect(element.measureOffset, equals(0));
      expect(element.measureOffsetPlusMeasure, equals(0));
      expect(series.measureOffsetFn(2), equals(0));
      expect(element.strokeWidthPx, equals(3));

      element = elementsList[3];
      expect(element.measureOffset, equals(0));
      expect(element.measureOffsetPlusMeasure, equals(75));
      expect(series.measureOffsetFn(3), equals(0));
      expect(element.strokeWidthPx, equals(3));
    });
  });

  test('with stroke width target lines', () {
    renderer = new BarTargetLineRenderer(
        config: new BarTargetLineRendererConfig(
            groupingType: BarGroupingType.grouped, strokeWidthPx: 5.0));

    renderer.preprocessSeries(seriesList);

    expect(seriesList.length, equals(3));

    // Validate Desktop series.
    var series = seriesList[0];
    var elementsList = series.getAttr(barElementsKey);

    var element = elementsList[0];
    expect(element.strokeWidthPx, equals(5));

    element = elementsList[1];
    expect(element.strokeWidthPx, equals(5));

    element = elementsList[2];
    expect(element.strokeWidthPx, equals(5));

    element = elementsList[3];
    expect(element.strokeWidthPx, equals(5));

    // Validate Tablet series.
    series = seriesList[1];

    elementsList = series.getAttr(barElementsKey);
    expect(elementsList.length, equals(4));

    element = elementsList[0];
    expect(element.strokeWidthPx, equals(5));

    element = elementsList[1];
    expect(element.strokeWidthPx, equals(5));

    element = elementsList[2];
    expect(element.strokeWidthPx, equals(5));

    element = elementsList[3];
    expect(element.strokeWidthPx, equals(5));

    // Validate Mobile series.
    series = seriesList[2];
    elementsList = series.getAttr(barElementsKey);

    element = elementsList[0];
    expect(element.strokeWidthPx, equals(5));

    element = elementsList[1];
    expect(element.strokeWidthPx, equals(5));

    element = elementsList[2];
    expect(element.strokeWidthPx, equals(5));

    element = elementsList[3];
    expect(element.strokeWidthPx, equals(5));
  });
}

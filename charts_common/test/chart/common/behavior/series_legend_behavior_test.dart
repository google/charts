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

import 'package:charts_common/src/chart/common/base_chart.dart';
import 'package:charts_common/src/chart/common/processed_series.dart';
import 'package:charts_common/src/chart/common/series_renderer.dart';
import 'package:charts_common/src/chart/common/behavior/legend/legend.dart';
import 'package:charts_common/src/chart/common/behavior/legend/legend_entry_generator.dart';
import 'package:charts_common/src/chart/common/datum_details.dart';
import 'package:charts_common/src/chart/common/selection_model/selection_model.dart';
import 'package:charts_common/src/common/color.dart';
import 'package:charts_common/src/data/series.dart';
import 'package:test/test.dart';

class ConcreteChart extends BaseChart<MyRow, String> {
  @override
  SeriesRenderer<MyRow, String> makeDefaultRenderer() => null;

  @override
  List<DatumDetails<MyRow, String>> getDatumDetails(SelectionModelType _) =>
      null;

  void callOnPreProcess(List<MutableSeries<MyRow, String>> seriesList) {
    fireOnPreprocess(seriesList);
  }

  void callOnPostProcess(List<MutableSeries<MyRow, String>> seriesList) {
    fireOnPostprocess(seriesList);
  }
}

class ConcreteSeriesLegend<T, D> extends SeriesLegend<T, D> {
  ConcreteSeriesLegend(
      {SelectionModelType selectionModelType,
      LegendEntryGenerator<T, D> legendEntryGenerator})
      : super(
            selectionModelType: selectionModelType,
            legendEntryGenerator: legendEntryGenerator);

  @override
  void hideSeries(String seriesId) {
    super.hideSeries(seriesId);
  }

  @override
  void showSeries(String seriesId) {
    super.showSeries(seriesId);
  }

  @override
  bool isSeriesHidden(String seriesId) {
    return super.isSeriesHidden(seriesId);
  }
}

void main() {
  MutableSeries<MyRow, String> series1;
  final s1D1 = new MyRow('s1d1', 11);
  final s1D2 = new MyRow('s1d2', 12);
  final s1D3 = new MyRow('s1d3', 13);

  MutableSeries<MyRow, String> series2;
  final s2D1 = new MyRow('s2d1', 21);
  final s2D2 = new MyRow('s2d2', 22);
  final s2D3 = new MyRow('s2d3', 23);

  final blue = new Color(r: 0x21, g: 0x96, b: 0xF3);
  final red = new Color(r: 0xF4, g: 0x43, b: 0x36);

  ConcreteChart chart;

  setUp(() {
    chart = new ConcreteChart();

    series1 = new MutableSeries(new Series<MyRow, String>(
        id: 's1',
        data: [s1D1, s1D2, s1D3],
        domainFn: (MyRow row, _) => row.campaign,
        measureFn: (MyRow row, _) => row.count,
        colorFn: (_, __) => blue))
      ..measureFn = (_, __) => 0.0;

    series2 = new MutableSeries(new Series<MyRow, String>(
        id: 's2',
        data: [s2D1, s2D2, s2D3],
        domainFn: (MyRow row, _) => row.campaign,
        measureFn: (MyRow row, _) => row.count,
        colorFn: (_, __) => red))
      ..measureFn = (_, __) => 0.0;
  });

  test('Legend entries created on chart post process', () {
    final seriesList = [series1, series2];
    final selectionType = SelectionModelType.info;
    final legend = new SeriesLegend(selectionModelType: selectionType);

    legend.attachTo(chart);
    chart.callOnPreProcess(seriesList);
    chart.callOnPostProcess(seriesList);

    final legendEntries = legend.legendState.legendEntries;
    expect(legendEntries, hasLength(2));
    expect(legendEntries[0].series, equals(series1));
    expect(legendEntries[0].label, equals('s1'));
    expect(legendEntries[0].color, equals(blue));
    expect(legendEntries[0].isSelected, isFalse);

    expect(legendEntries[1].series, equals(series2));
    expect(legendEntries[1].label, equals('s2'));
    expect(legendEntries[1].color, equals(red));
    expect(legendEntries[1].isSelected, isFalse);
  });

  test('default hidden series are removed from list during pre process', () {
    final seriesList = [series1, series2];
    final selectionType = SelectionModelType.info;
    final legend = new ConcreteSeriesLegend(selectionModelType: selectionType);

    legend.defaultHiddenSeries = ['s2'];

    legend.attachTo(chart);
    chart.callOnPreProcess(seriesList);

    expect(legend.isSeriesHidden('s1'), isFalse);
    expect(legend.isSeriesHidden('s2'), isTrue);

    expect(seriesList, hasLength(1));
    expect(seriesList[0].id, equals('s1'));
  });

  test('hidden series are removed from list after chart pre process', () {
    final seriesList = [series1, series2];
    final selectionType = SelectionModelType.info;
    final legend = new ConcreteSeriesLegend(selectionModelType: selectionType);

    legend.attachTo(chart);
    legend.hideSeries('s1');
    chart.callOnPreProcess(seriesList);

    expect(legend.isSeriesHidden('s1'), isTrue);
    expect(legend.isSeriesHidden('s2'), isFalse);

    expect(seriesList, hasLength(1));
    expect(seriesList[0].id, equals('s2'));
  });

  test('hidden and re-shown series is in the list after chart pre process', () {
    final seriesList = [series1, series2];
    final seriesList2 = [series1, series2];
    final selectionType = SelectionModelType.info;
    final legend = new ConcreteSeriesLegend(selectionModelType: selectionType);

    legend.attachTo(chart);

    // First hide the series.
    legend.hideSeries('s1');
    chart.callOnPreProcess(seriesList);

    expect(legend.isSeriesHidden('s1'), isTrue);
    expect(legend.isSeriesHidden('s2'), isFalse);

    expect(seriesList, hasLength(1));
    expect(seriesList[0].id, equals('s2'));

    // Then un-hide the series. This second list imitates the behavior of the
    // chart, which creates a fresh copy of the original data from the user
    // during each draw cycle.
    legend.showSeries('s1');
    chart.callOnPreProcess(seriesList2);

    expect(legend.isSeriesHidden('s1'), isFalse);
    expect(legend.isSeriesHidden('s2'), isFalse);

    expect(seriesList2, hasLength(2));
    expect(seriesList2[0].id, equals('s1'));
    expect(seriesList2[1].id, equals('s2'));
  });

  test('selected series legend entry is updated', () {
    final seriesList = [series1, series2];
    final selectionType = SelectionModelType.info;
    final legend = new SeriesLegend(selectionModelType: selectionType);

    legend.attachTo(chart);
    chart.callOnPreProcess(seriesList);
    chart.callOnPostProcess(seriesList);
    chart.getSelectionModel(selectionType).updateSelection([], [series1]);

    final selectedSeries =
        legend.legendState.selectionModel.selectedSeries.first.id;
    print('selected series $selectedSeries');
    final legendEntries = legend.legendState.legendEntries;
    expect(legendEntries, hasLength(2));
    expect(legendEntries[0].series, equals(series1));
    expect(legendEntries[0].label, equals('s1'));
    expect(legendEntries[0].color, equals(blue));
    expect(legendEntries[0].isSelected, isTrue);

    expect(legendEntries[1].series, equals(series2));
    expect(legendEntries[1].label, equals('s2'));
    expect(legendEntries[1].color, equals(red));
    expect(legendEntries[1].isSelected, isFalse);
  });
}

class MyRow {
  final String campaign;
  final int count;
  MyRow(this.campaign, this.count);
}

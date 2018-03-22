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
import 'package:charts_common/src/chart/common/datum_details.dart';
import 'package:charts_common/src/chart/common/selection_model/selection_model.dart';
import 'package:charts_common/src/common/quantum_palette.dart';
import 'package:charts_common/src/data/series.dart';
import 'package:test/test.dart';

class ConcreteChart extends BaseChart<MyRow, String> {
  @override
  SeriesRenderer<MyRow, String> makeDefaultRenderer() => null;

  @override
  List<DatumDetails<MyRow, String>> getDatumDetails(SelectionModelType _) =>
      null;

  void callOnPostProcess(List<MutableSeries<MyRow, String>> seriesList) {
    fireOnPostprocess(seriesList);
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

  ConcreteChart chart;

  setUp(() {
    chart = new ConcreteChart();

    series1 = new MutableSeries(new Series<MyRow, String>(
        id: 's1',
        data: [s1D1, s1D2, s1D3],
        domainFn: (MyRow row, _) => row.campaign,
        measureFn: (MyRow row, _) => row.count,
        colorFn: (_, __) => QuantumPalette.googleBlue.shadeDefault))
      ..measureFn = (_, __) => 0.0;

    series2 = new MutableSeries(new Series<MyRow, String>(
        id: 's2',
        data: [s2D1, s2D2, s2D3],
        domainFn: (MyRow row, _) => row.campaign,
        measureFn: (MyRow row, _) => row.count,
        colorFn: (_, __) => QuantumPalette.googleRed.shadeDefault))
      ..measureFn = (_, __) => 0.0;
  });

  test('Legend entries created on chart post process', () {
    final seriesList = [series1, series2];
    final selectionType = SelectionModelType.info;
    final legend = new SeriesLegend(selectionModelType: selectionType);

    legend.attachTo(chart);
    chart.callOnPostProcess(seriesList);

    final legendEntries = legend.legendState.legendEntries;
    expect(legendEntries, hasLength(2));
    expect(legendEntries[0].series, equals(series1));
    expect(legendEntries[0].label, equals('s1'));
    expect(
        legendEntries[0].color, equals(QuantumPalette.googleBlue.shadeDefault));
    expect(legendEntries[0].isSelected, isFalse);

    expect(legendEntries[1].series, equals(series2));
    expect(legendEntries[1].label, equals('s2'));
    expect(
        legendEntries[1].color, equals(QuantumPalette.googleRed.shadeDefault));
    expect(legendEntries[1].isSelected, isFalse);
  });

  test('selected series legend entry is updated', () {
    final seriesList = [series1, series2];
    final selectionType = SelectionModelType.info;
    final legend = new SeriesLegend(selectionModelType: selectionType);

    legend.attachTo(chart);
    chart.callOnPostProcess(seriesList);
    chart.getSelectionModel(selectionType).updateSelection([], [series1]);

    final selectedSeries =
        legend.legendState.selectionModel.selectedSeries.first.id;
    print('selected series $selectedSeries');
    final legendEntries = legend.legendState.legendEntries;
    expect(legendEntries, hasLength(2));
    expect(legendEntries[0].series, equals(series1));
    expect(legendEntries[0].label, equals('s1'));
    expect(
        legendEntries[0].color, equals(QuantumPalette.googleBlue.shadeDefault));
    expect(legendEntries[0].isSelected, isTrue);

    expect(legendEntries[1].series, equals(series2));
    expect(legendEntries[1].label, equals('s2'));
    expect(
        legendEntries[1].color, equals(QuantumPalette.googleRed.shadeDefault));
    expect(legendEntries[1].isSelected, isFalse);
  });
}

class MyRow {
  final String campaign;
  final int count;
  MyRow(this.campaign, this.count);
}

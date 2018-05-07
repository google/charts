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

import 'dart:math' show Rectangle;

import 'package:charts_common/src/chart/cartesian/cartesian_chart.dart';
import 'package:charts_common/src/chart/cartesian/axis/axis.dart';
import 'package:charts_common/src/chart/cartesian/axis/numeric_tick_provider.dart';
import 'package:charts_common/src/chart/cartesian/axis/tick_formatter.dart';
import 'package:charts_common/src/chart/cartesian/axis/linear/linear_scale.dart';
import 'package:charts_common/src/chart/common/base_chart.dart';
import 'package:charts_common/src/chart/common/behavior/range_annotation.dart';
import 'package:charts_common/src/common/material_palette.dart';
import 'package:charts_common/src/data/series.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class ConcreteChart extends CartesianChart {
  LifecycleListener lastListener;

  Axis _domainAxis = new ConcreteNumericAxis();

  @override
  addLifecycleListener(LifecycleListener listener) {
    lastListener = listener;
    super.addLifecycleListener(listener);
  }

  @override
  removeLifecycleListener(LifecycleListener listener) {
    expect(listener, equals(lastListener));
    lastListener = null;
    super.removeLifecycleListener(listener);
  }

  @override
  Axis get domainAxis => _domainAxis;
}

class ConcreteNumericAxis extends Axis<num> {
  ConcreteNumericAxis()
      : super(
          tickProvider: new MockTickProvider(),
          tickFormatter: new NumericTickFormatter(),
          scale: new LinearScale(),
        );
}

class MockTickProvider extends Mock implements NumericTickProvider {}

void main() {
  ConcreteChart _chart;

  Series<MyRow, int> _series1;
  final _s1D1 = new MyRow(0, 11);
  final _s1D2 = new MyRow(1, 12);
  final _s1D3 = new MyRow(2, 13);

  Series<MyRow, int> _series2;
  final _s2D1 = new MyRow(3, 21);
  final _s2D2 = new MyRow(4, 22);
  final _s2D3 = new MyRow(5, 23);

  List<RangeAnnotationSegment<num>> _annotations1;

  List<RangeAnnotationSegment<num>> _annotations2;

  setUp(() {
    _chart = new ConcreteChart();

    _series1 = new Series<MyRow, int>(
        id: 's1',
        data: [_s1D1, _s1D2, _s1D3],
        domainFn: (dynamic row, _) => row.campaign,
        measureFn: (dynamic row, _) => row.count,
        colorFn: (_, __) => MaterialPalette.blue.shadeDefault);

    _series2 = new Series<MyRow, int>(
        id: 's2',
        data: [_s2D1, _s2D2, _s2D3],
        domainFn: (dynamic row, _) => row.campaign,
        measureFn: (dynamic row, _) => row.count,
        colorFn: (_, __) => MaterialPalette.red.shadeDefault);

    _annotations1 = [
      new RangeAnnotationSegment(1, 2, RangeAnnotationAxisType.domain),
      new RangeAnnotationSegment(4, 5, RangeAnnotationAxisType.domain,
          color: MaterialPalette.gray.shade200),
    ];

    _annotations2 = [
      new RangeAnnotationSegment(1, 2, RangeAnnotationAxisType.domain),
      new RangeAnnotationSegment(4, 5, RangeAnnotationAxisType.domain,
          color: MaterialPalette.gray.shade200),
      new RangeAnnotationSegment(8, 10, RangeAnnotationAxisType.domain,
          color: MaterialPalette.gray.shade300),
    ];
  });

  group('RangeAnnotation', () {
    test('renders the annotations', () {
      // Setup
      final behavior = new RangeAnnotation(_annotations1);
      final tester = new RangeAnnotationTester(behavior);
      behavior.attachTo(_chart);

      final seriesList = [_series1, _series2];

      // Act
      _chart.domainAxis.autoViewport = true;
      _chart.domainAxis.resetDomains();
      _chart.draw(seriesList);
      _chart.domainAxis.layout(new Rectangle<int>(0, 0, 100, 100),
          new Rectangle<int>(0, 0, 100, 100));
      _chart.lastListener.onAxisConfigured();

      // Verify
      expect(_chart.domainAxis.getLocation(2), equals(40.0));
      tester.doesAnnotationExist(20.0, 40.0, MaterialPalette.gray.shade100);
      expect(
          tester.doesAnnotationExist(20.0, 40.0, MaterialPalette.gray.shade100),
          equals(true));
      expect(
          tester.doesAnnotationExist(
              80.0, 100.0, MaterialPalette.gray.shade200),
          equals(true));
    });

    test('extends the domain axis when annotations fall outside the range', () {
      // Setup
      final behavior = new RangeAnnotation(_annotations2);
      final tester = new RangeAnnotationTester(behavior);
      behavior.attachTo(_chart);

      final seriesList = [_series1, _series2];

      // Act
      _chart.domainAxis.autoViewport = true;
      _chart.domainAxis.resetDomains();
      _chart.draw(seriesList);
      _chart.domainAxis.layout(new Rectangle<int>(0, 0, 100, 100),
          new Rectangle<int>(0, 0, 100, 100));
      _chart.lastListener.onAxisConfigured();

      // Verify
      expect(_chart.domainAxis.getLocation(2), equals(20.0));
      expect(
          tester.doesAnnotationExist(10.0, 20.0, MaterialPalette.gray.shade100),
          equals(true));
      expect(
          tester.doesAnnotationExist(40.0, 50.0, MaterialPalette.gray.shade200),
          equals(true));
      expect(
          tester.doesAnnotationExist(
              80.0, 100.0, MaterialPalette.gray.shade300),
          equals(true));
    });

    test('cleans up', () {
      // Setup
      final behavior = new RangeAnnotation(_annotations2);
      behavior.attachTo(_chart);

      // Act
      behavior.removeFrom(_chart);

      // Verify
      expect(_chart.lastListener, isNull);
    });
  });
}

class MyRow {
  final int campaign;
  final int count;
  MyRow(this.campaign, this.count);
}

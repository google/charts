// @dart=2.9

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

import 'dart:math';

import 'package:charts_common/common.dart';
import 'package:mockito/mockito.dart';

import 'package:test/test.dart';

/// Datum/Row for the chart.
class MyRow {
  final String campaignString;
  final int campaign;
  final int clickCount;
  final double radius;
  final double boundsRadius;
  final String shape;

  MyRow(this.campaignString, this.campaign, this.clickCount, this.radius,
      this.boundsRadius, this.shape);
}

class MockNumericAxis extends Mock implements Axis<num> {}

class MockCanvas extends Mock implements ChartCanvas {}

void main() {
  Rectangle<int> layout;

  MutableSeries<num> _makeSeries({String id, String seriesCategory}) {
    final data = <MyRow>[];

    final series = MutableSeries(Series<MyRow, num>(
      id: id,
      data: data,
      radiusPxFn: (row, _) => row.radius,
      domainFn: (row, _) => row.campaign,
      measureFn: (row, _) => row.clickCount,
      seriesCategory: seriesCategory,
    ));

    series.measureOffsetFn = (_) => 0.0;
    series.colorFn = (_) => Color.fromHex(code: '#000000');

    // Mock the Domain axis results.
    final domainAxis = MockNumericAxis();
    when(domainAxis.rangeBand).thenReturn(100.0);

    when(domainAxis.getLocation(any))
        .thenAnswer((input) => 1.0 * (input.positionalArguments.first as num));
    series.setAttr(domainAxisKey, domainAxis);

    // Mock the Measure axis results.
    final measureAxis = MockNumericAxis();
    when(measureAxis.getLocation(any))
        .thenAnswer((input) => 1.0 * (input.positionalArguments.first as num));
    series.setAttr(measureAxisKey, measureAxis);

    return series;
  }

  setUp(() {
    layout = Rectangle<int>(0, 0, 200, 100);
  });

  group('getNearestDatumDetailPerSeries', () {
    test(
        'with both selectOverlappingPoints and selectOverlappingPoints set to '
        'false', () {
      // Setup
      final renderer = PointRenderer(config: PointRendererConfig())
        ..layout(layout, layout);
      final seriesList = <MutableSeries<num>>[
        _makeSeries(id: 'foo')
          ..data.addAll(<MyRow>[
            MyRow('point1', 20, 30, 6, 0, ''),
            MyRow('point2', 15, 20, 3, 0, ''),
            MyRow('point3', 30, 40, 4, 0, ''),
          ]),
      ];
      renderer.configureSeries(seriesList);
      renderer.preprocessSeries(seriesList);
      renderer.update(seriesList, false);
      renderer.paint(MockCanvas(), 1.0);

      // Act
      final details = renderer.getNearestDatumDetailPerSeries(
          Point(10, 20), false, layout,
          selectExactEventLocation: false, selectOverlappingPoints: false);

      // Only the point nearest to the event location returned.
      expect(details.length, equals(1));
      expect((details.first.datum as MyRow).campaignString, 'point2');
    });

    test(
        'with both selectOverlappingPoints and selectOverlappingPoints set to '
        'true and there are points inside event', () {
      // Setup
      final renderer = PointRenderer(config: PointRendererConfig())
        ..layout(layout, layout);
      final seriesList = <MutableSeries<num>>[
        _makeSeries(id: 'foo')
          ..data.addAll(<MyRow>[
            MyRow('point1', 15, 30, 15, 0, ''),
            MyRow('point2', 10, 20, 5, 0, ''),
            MyRow('point3', 30, 40, 4, 0, ''),
          ]),
      ];
      renderer.configureSeries(seriesList);
      renderer.preprocessSeries(seriesList);
      renderer.update(seriesList, false);
      renderer.paint(MockCanvas(), 1.0);

      // Act
      final details = renderer.getNearestDatumDetailPerSeries(
          Point(13, 23), false, layout,
          selectExactEventLocation: true, selectOverlappingPoints: true);

      // Return only points inside the event location and skip other.
      expect(details.length, equals(2));
      expect((details[0].datum as MyRow).campaignString, 'point1');
      expect((details[1].datum as MyRow).campaignString, 'point2');
    });

    test(
        'with both selectOverlappingPoints and selectOverlappingPoints set to '
        'true and there are NO points inside event', () {
      // Setup
      final renderer = PointRenderer(config: PointRendererConfig())
        ..layout(layout, layout);
      final seriesList = <MutableSeries<num>>[
        _makeSeries(id: 'foo')
          ..data.addAll(<MyRow>[
            MyRow('point1', 15, 30, 2, 0, ''),
            MyRow('point2', 10, 20, 3, 0, ''),
            MyRow('point3', 30, 40, 4, 0, ''),
          ]),
      ];
      renderer.configureSeries(seriesList);
      renderer.preprocessSeries(seriesList);
      renderer.update(seriesList, false);
      renderer.paint(MockCanvas(), 1.0);

      // Act
      final details = renderer.getNearestDatumDetailPerSeries(
          Point(5, 10), false, layout,
          selectExactEventLocation: true, selectOverlappingPoints: true);

      // Since there are no points inside event, empty list is returned.
      expect(details.length, equals(0));
    });

    test(
        'with both selectOverlappingPoints == true and '
        'selectOverlappingPoints == false and there are points inside event',
        () {
      // Setup
      final renderer = PointRenderer(config: PointRendererConfig())
        ..layout(layout, layout);
      final seriesList = <MutableSeries<num>>[
        _makeSeries(id: 'foo')
          ..data.addAll(<MyRow>[
            MyRow('point1', 15, 30, 15, 0, ''),
            MyRow('point2', 10, 20, 5, 0, ''),
            MyRow('point3', 30, 40, 4, 0, ''),
          ]),
      ];
      renderer.configureSeries(seriesList);
      renderer.preprocessSeries(seriesList);
      renderer.update(seriesList, false);
      renderer.paint(MockCanvas(), 1.0);

      // Act
      final details = renderer.getNearestDatumDetailPerSeries(
          Point(13, 23), false, layout,
          selectExactEventLocation: false, selectOverlappingPoints: true);

      // Points inside the event location are returned.
      expect(details.length, equals(2));
      expect((details[0].datum as MyRow).campaignString, 'point1');
      expect((details[1].datum as MyRow).campaignString, 'point2');
    });

    test(
        'with both selectOverlappingPoints == true and '
        'selectOverlappingPoints == false and there are NO points inside event',
        () {
      // Setup
      final renderer = PointRenderer(config: PointRendererConfig())
        ..layout(layout, layout);
      final seriesList = <MutableSeries<num>>[
        _makeSeries(id: 'foo')
          ..data.addAll(<MyRow>[
            MyRow('point1', 15, 30, 2, 0, ''),
            MyRow('point2', 10, 20, 3, 0, ''),
            MyRow('point3', 30, 40, 4, 0, ''),
          ]),
      ];
      renderer.configureSeries(seriesList);
      renderer.preprocessSeries(seriesList);
      renderer.update(seriesList, false);
      renderer.paint(MockCanvas(), 1.0);

      // Act
      final details = renderer.getNearestDatumDetailPerSeries(
          Point(5, 10), false, layout,
          selectExactEventLocation: false, selectOverlappingPoints: true);

      // There are no points inside, so single nearest point is returned.
      expect(details.length, equals(1));
      expect((details[0].datum as MyRow).campaignString, 'point2');
    });

    test(
        'with both selectOverlappingPoints == false and '
        'selectOverlappingPoints == true and there are points inside event',
        () {
      // Setup
      final renderer = PointRenderer(config: PointRendererConfig())
        ..layout(layout, layout);
      final seriesList = <MutableSeries<num>>[
        _makeSeries(id: 'foo')
          ..data.addAll(<MyRow>[
            MyRow('point1', 15, 30, 15, 0, ''),
            MyRow('point2', 10, 20, 5, 0, ''),
            MyRow('point3', 30, 40, 4, 0, ''),
          ]),
      ];
      renderer.configureSeries(seriesList);
      renderer.preprocessSeries(seriesList);
      renderer.update(seriesList, false);
      renderer.paint(MockCanvas(), 1.0);

      // Act
      final details = renderer.getNearestDatumDetailPerSeries(
          Point(13, 23), false, layout,
          selectExactEventLocation: true, selectOverlappingPoints: false);

      // Only the nearest point from inside event location is returned.
      expect(details.length, equals(1));
      expect((details[0].datum as MyRow).campaignString, 'point2');
    });

    test(
        'with both selectOverlappingPoints == false and '
        'selectOverlappingPoints == true and there are NO points inside event',
        () {
      // Setup
      final renderer = PointRenderer(config: PointRendererConfig())
        ..layout(layout, layout);
      final seriesList = <MutableSeries<num>>[
        _makeSeries(id: 'foo')
          ..data.addAll(<MyRow>[
            MyRow('point1', 15, 30, 2, 0, ''),
            MyRow('point2', 10, 20, 3, 0, ''),
            MyRow('point3', 30, 40, 4, 0, ''),
          ]),
      ];
      renderer.configureSeries(seriesList);
      renderer.preprocessSeries(seriesList);
      renderer.update(seriesList, false);
      renderer.paint(MockCanvas(), 1.0);

      // Act
      final details = renderer.getNearestDatumDetailPerSeries(
          Point(5, 10), false, layout,
          selectExactEventLocation: true, selectOverlappingPoints: false);

      // No points inside event, so empty list is returned.
      expect(details.length, equals(0));
    });
  });
}

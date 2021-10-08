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

import 'dart:math' show Rectangle;
import 'package:charts_common/src/chart/common/processed_series.dart'
    show ImmutableSeries;
import 'package:charts_common/src/common/color.dart' show Color;
import 'package:charts_common/src/common/graphics_factory.dart'
    show GraphicsFactory;
import 'package:charts_common/src/common/line_style.dart' show LineStyle;
import 'package:charts_common/src/common/text_element.dart'
    show TextDirection, TextElement, MaxWidthStrategy;
import 'package:charts_common/src/common/text_measurement.dart'
    show TextMeasurement;
import 'package:charts_common/src/common/text_style.dart' show TextStyle;
import 'package:charts_common/src/chart/bar/bar_renderer.dart'
    show ImmutableBarRendererElement;
import 'package:charts_common/src/chart/cartesian/axis/spec/axis_spec.dart'
    show TextStyleSpec;
import 'package:charts_common/src/chart/common/chart_canvas.dart'
    show ChartCanvas;
import 'package:charts_common/src/chart/bar/bar_label_decorator.dart'
    show
        BarLabelDecorator,
        BarLabelAnchor,
        BarLabelPlacement,
        BarLabelPosition,
        BarLabelVerticalPosition;
import 'package:charts_common/src/data/series.dart' show AccessorFn;

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockCanvas extends Mock implements ChartCanvas {}

/// A fake [GraphicsFactory] that returns [FakeTextStyle] and [FakeTextElement].
class FakeGraphicsFactory extends GraphicsFactory {
  @override
  TextStyle createTextPaint() => FakeTextStyle();

  @override
  TextElement createTextElement(String text) => FakeTextElement(text);

  @override
  LineStyle createLinePaint() => MockLinePaint();
}

/// Stores [TextStyle] properties for test to verify.
class FakeTextStyle implements TextStyle {
  @override
  Color color;

  @override
  int fontSize;

  @override
  String fontFamily;

  @override
  double lineHeight;

  @override
  String fontWeight;
}

/// Fake [TextElement] which returns text length as [horizontalSliceWidth].
///
/// Font size is returned for [verticalSliceWidth] and [baseline].
class FakeTextElement implements TextElement {
  @override
  final String text;

  @override
  TextStyle textStyle;

  @override
  int maxWidth;

  @override
  MaxWidthStrategy maxWidthStrategy;

  @override
  TextDirection textDirection;

  double opacity;

  FakeTextElement(this.text);

  @override
  TextMeasurement get measurement => TextMeasurement(
      horizontalSliceWidth: text.length.toDouble(),
      verticalSliceWidth: textStyle.fontSize.toDouble(),
      baseline: textStyle.fontSize.toDouble());
}

class MockLinePaint extends Mock implements LineStyle {}

class FakeBarRendererElement implements ImmutableBarRendererElement<String> {
  final _series = MockImmutableSeries<String>();
  final AccessorFn<String> labelAccessor;
  final AccessorFn<num> measureFn;
  final List<String> data;

  @override
  final String datum;

  @override
  final Rectangle<int> bounds;

  @override
  int index;

  FakeBarRendererElement(this.datum, this.bounds, this.labelAccessor, this.data,
      {this.measureFn}) {
    index = data.indexOf(datum);
    when(_series.labelAccessorFn).thenReturn(labelAccessor);
    when(_series.measureFn).thenReturn(measureFn ?? (_) => 1.0);
    when(_series.data).thenReturn(data);
  }

  @override
  ImmutableSeries<String> get series => _series;
}

class MockImmutableSeries<D> extends Mock implements ImmutableSeries<D> {}

void main() {
  ChartCanvas canvas;
  GraphicsFactory graphicsFactory;
  Rectangle<int> drawBounds;

  setUpAll(() {
    canvas = MockCanvas();
    graphicsFactory = FakeGraphicsFactory();
    drawBounds = Rectangle(0, 0, 200, 100);
  });

  group('vertical bar chart', () {
    test('Paint labels with default settings', () {
      final data = ['A', 'B', 'C'];
      final leftPositionA = 0;
      final leftPositionB = 25;
      final leftPositionC = 50;
      final topPositionA = 50;
      final topPositionB = 95;
      final topPositionC = 50;
      final barWidthA = 20;
      final barWidthB = 20;
      final barWidthC = 4;
      final barElements = [
        // 'LabelA' fits, default to inside end.
        // 'LabelB' does not fit because of the height, default to outside.
        // 'LabelC' does not fit because of the width, default to outside.
        FakeBarRendererElement(
            'A',
            Rectangle(
                leftPositionA, topPositionA, barWidthA, 100 - topPositionA),
            (_) => 'LabelA',
            data),
        FakeBarRendererElement(
            'B',
            Rectangle(
                leftPositionB, topPositionB, barWidthB, 100 - topPositionB),
            (_) => 'LabelB',
            data),
        FakeBarRendererElement(
            'C',
            Rectangle(
                leftPositionC, topPositionC, barWidthC, 100 - topPositionC),
            (_) => 'LabelC',
            data)
      ];
      final decorator = BarLabelDecorator<String>();

      decorator.decorate(barElements, canvas, graphicsFactory,
          drawBounds: drawBounds,
          animationPercent: 1.0,
          renderingVertically: true);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      // Draw text is called three times (once for each bar) and all 3
      // parameters were captured. Total parameters captured expected to be 9.
      expect(captured, hasLength(9));
      // Bar 'A' checks.
      var textElement = captured[0] as TextElement;
      var offsetX = captured[1] as int;
      var offsetY = captured[2] as int;
      var labelWidth = textElement.measurement.horizontalSliceWidth;
      var labelHeight = textElement.measurement.verticalSliceWidth;
      expect(labelWidth, equals(6));
      expect(labelHeight, equals(12));
      expect(textElement.maxWidth, equals(barWidthA));
      expect(offsetX, equals(leftPositionA + barWidthA / 2 - labelWidth / 2));
      expect(offsetY, equals(topPositionA + decorator.labelPadding));
      // Bar 'B' checks.
      textElement = captured[3] as TextElement;
      offsetX = captured[4] as int;
      offsetY = captured[5] as int;
      labelWidth = textElement.measurement.horizontalSliceWidth;
      labelHeight = textElement.measurement.verticalSliceWidth;
      expect(labelWidth, equals(6));
      expect(labelHeight, equals(12));
      expect(textElement.maxWidth, equals(barWidthB));
      expect(offsetX, equals(leftPositionB + barWidthB / 2 - labelWidth / 2));
      expect(
          offsetY, equals(topPositionB - decorator.labelPadding - labelHeight));
      // Bar 'C' checks.
      textElement = captured[6] as TextElement;
      offsetX = captured[7] as int;
      offsetY = captured[8] as int;
      labelWidth = textElement.measurement.horizontalSliceWidth;
      labelHeight = textElement.measurement.verticalSliceWidth;
      expect(labelWidth, equals(6));
      expect(labelHeight, equals(12));
      expect(textElement.maxWidth, equals(barWidthC));
      expect(offsetX, equals(leftPositionC + barWidthC / 2 - labelWidth / 2));
      expect(
          offsetY, equals(topPositionC - decorator.labelPadding - labelHeight));
    });

    test('LabelPosition.inside always paints inside the bar', () {
      final barElements = [
        // 'LabelABC' would not fit inside the bar in auto setting because it
        // has a width of 8.
        FakeBarRendererElement(
            'A', Rectangle(10, 80, 6, 20), (_) => 'LabelABC', ['A']),
      ];

      BarLabelDecorator<String>(
              labelPosition: BarLabelPosition.inside,
              labelPadding: 0, // Turn off label padding for testing.
              insideLabelStyleSpec: TextStyleSpec(fontSize: 10))
          .decorate(barElements, canvas, graphicsFactory,
              drawBounds: drawBounds,
              animationPercent: 1.0,
              renderingVertically: true);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      expect(captured, hasLength(3));
      expect(captured[0].measurement.horizontalSliceWidth, equals(8));
      expect(captured[0].measurement.verticalSliceWidth, equals(10));
      expect(captured[1],
          equals(9)); // left position + bar width / 2 - text width / 2
      expect(captured[2], equals(80)); // top position + label padding
    });

    test('LabelPosition.outside always paints outside the bar', () {
      final barElements = [
        FakeBarRendererElement(
            'A', Rectangle(10, 80, 10, 20), (_) => 'LabelA', ['A']),
      ];

      BarLabelDecorator<String>(
              labelPosition: BarLabelPosition.outside,
              labelPadding: 0, // Turn off label padding for testing.
              outsideLabelStyleSpec: TextStyleSpec(fontSize: 10))
          .decorate(barElements, canvas, graphicsFactory,
              drawBounds: drawBounds,
              animationPercent: 1.0,
              renderingVertically: true);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      expect(captured, hasLength(3));
      expect(captured[0].measurement.horizontalSliceWidth, equals(6));
      expect(captured[0].measurement.verticalSliceWidth, equals(10));
      expect(captured[1],
          equals(12)); // left position + bar width / 2 - text width / 2
      expect(captured[2],
          equals(70)); // top position - label padding - text height
    });

    test('Outside label with new lines draws multiline labels', () {
      final barElements = [
        FakeBarRendererElement(
            'A', Rectangle(10, 80, 10, 20), (_) => 'LabelA\n(50)', ['A']),
      ];

      BarLabelDecorator<String>(
              labelPosition: BarLabelPosition.outside,
              labelPadding: 0, // Turn off label padding for testing.
              outsideLabelStyleSpec: TextStyleSpec(fontSize: 10))
          .decorate(barElements, canvas, graphicsFactory,
              drawBounds: drawBounds,
              animationPercent: 1.0,
              renderingVertically: true);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      // Draw text is called 2 times (once for each label line) and all 3
      // parameters were captured.
      expect(captured, hasLength(6));
      expect(captured[0].measurement.horizontalSliceWidth, equals(6));
      expect(captured[0].measurement.verticalSliceWidth, equals(10));
      expect(captured[1],
          equals(12)); // left position + bar width / 2 - text width / 2
      // top position - label padding - text height * 2 - multiline padding
      expect(captured[2], equals(58));
      expect(captured[3].measurement.horizontalSliceWidth, equals(4));
      expect(captured[3].measurement.verticalSliceWidth, equals(10));
      expect(captured[4],
          equals(13)); // left position + bar width / 2 - text width / 2
      expect(captured[5],
          equals(70)); // top position - label padding - text height
    });

    test('Inside and outside label styles are applied', () {
      final data = ['A', 'B'];
      final barElements = [
        // 'LabelA' and 'LabelB' both have lengths of 6.
        // 'LabelB' would not fit inside the bar in auto setting because it has
        // width of 4.
        FakeBarRendererElement(
            'A', Rectangle(10, 80, 10, 20), (_) => 'LabelA', data),
        FakeBarRendererElement(
            'B', Rectangle(25, 80, 4, 20), (_) => 'LabelB', data)
      ];
      final insideColor = Color(r: 0, g: 0, b: 0);
      final outsideColor = Color(r: 255, g: 255, b: 255);
      final decorator = BarLabelDecorator<String>(
          labelPadding: 0,
          insideLabelStyleSpec: TextStyleSpec(
              fontSize: 10, fontFamily: 'insideFont', color: insideColor),
          outsideLabelStyleSpec: TextStyleSpec(
              fontSize: 8, fontFamily: 'outsideFont', color: outsideColor));

      decorator.decorate(barElements, canvas, graphicsFactory,
          drawBounds: drawBounds,
          animationPercent: 1.0,
          renderingVertically: true);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      // Draw text is called twice (once for each bar) and all 3 parameters were
      // captured. Total parameters captured expected to be 6.
      expect(captured, hasLength(6));
      // For bar 'A'.
      expect(captured[0].maxWidth, equals(10));
      expect(captured[0].textStyle.fontFamily, equals('insideFont'));
      expect(captured[0].textStyle.color, equals(insideColor));
      expect(captured[1],
          equals(12)); // left position + bar width / 2 - text width / 2
      expect(captured[2], equals(80)); // top position + label padding
      // For bar 'B'.
      expect(captured[3].maxWidth, equals(4));
      expect(captured[3].textStyle.fontFamily, equals('outsideFont'));
      expect(captured[3].textStyle.color, equals(outsideColor));
      expect(captured[4],
          equals(24)); // left position + bar width / 2 - text width / 2
      expect(captured[5],
          equals(72)); // top position - label padding - text height
    });

    group('Null and empty label scenarios', () {
      test('Skip label if label accessor does not exist', () {
        final barElements = [
          FakeBarRendererElement('A', Rectangle(0, 0, 10, 20), null, ['A'])
        ];

        BarLabelDecorator<String>().decorate(
            barElements, canvas, graphicsFactory,
            drawBounds: drawBounds,
            animationPercent: 1.0,
            renderingVertically: true);

        verifyNever(canvas.drawText(any, any, any));
      });

      test('Skip label if label is null or empty', () {
        final data = ['A', 'B'];
        final barElements = [
          FakeBarRendererElement('A', Rectangle(0, 0, 10, 20), null, data),
          FakeBarRendererElement(
              'B', Rectangle(0, 50, 10, 20), (_) => '', data),
        ];

        BarLabelDecorator<String>().decorate(
            barElements, canvas, graphicsFactory,
            drawBounds: drawBounds,
            animationPercent: 1.0,
            renderingVertically: true);

        verifyNever(canvas.drawText(any, any, any));
      });
    });

    group('BarLabelPlacement.opposeAxisBaseline', () {
      test('Paints positive outside labels', () {
        final barElements = [
          FakeBarRendererElement(
              'A', Rectangle(10, 80, 10, 20), (_) => 'LabelA', ['A']),
        ];

        BarLabelDecorator<String>(
                labelPosition: BarLabelPosition.outside,
                labelPlacement: BarLabelPlacement.opposeAxisBaseline,
                labelPadding: 0, // Turn off label padding for testing.
                outsideLabelStyleSpec: TextStyleSpec(fontSize: 10))
            .decorate(barElements, canvas, graphicsFactory,
                drawBounds: drawBounds,
                animationPercent: 1.0,
                renderingVertically: true);

        final captured =
            verify(canvas.drawText(captureAny, captureAny, captureAny))
                .captured;
        expect(captured, hasLength(3));
        expect(captured[0].measurement.horizontalSliceWidth, equals(6));
        expect(captured[0].measurement.verticalSliceWidth, equals(10));
        expect(captured[1],
            equals(12)); // left position + bar width / 2 - text width / 2
        expect(captured[2],
            equals(70)); // top position - label padding - text height
      });

      test('Paints negative outside labels', () {
        final barElements = [
          FakeBarRendererElement(
              'A', Rectangle(10, 80, 10, 20), (_) => 'LabelA', ['A'],
              measureFn: (_) => -1.0),
        ];

        BarLabelDecorator<String>(
                labelPosition: BarLabelPosition.outside,
                labelPlacement: BarLabelPlacement.opposeAxisBaseline,
                labelPadding: 0, // Turn off label padding for testing.
                outsideLabelStyleSpec: TextStyleSpec(fontSize: 10))
            .decorate(barElements, canvas, graphicsFactory,
                drawBounds: drawBounds,
                animationPercent: 1.0,
                renderingVertically: true);

        final captured =
            verify(canvas.drawText(captureAny, captureAny, captureAny))
                .captured;
        expect(captured, hasLength(3));
        expect(captured[0].measurement.horizontalSliceWidth, equals(6));
        expect(captured[0].measurement.verticalSliceWidth, equals(10));
        expect(captured[1],
            equals(12)); // left position + bar width / 2 - text width / 2
        expect(captured[2], equals(100)); // top position + bar height
      });

      test('Paints positive inside labels', () {
        final barElements = [
          FakeBarRendererElement(
              'A', Rectangle(10, 80, 10, 20), (_) => 'LabelA', ['A']),
        ];

        BarLabelDecorator<String>(
                labelPosition: BarLabelPosition.inside,
                labelPlacement: BarLabelPlacement.opposeAxisBaseline,
                labelPadding: 0, // Turn off label padding for testing.
                outsideLabelStyleSpec: TextStyleSpec(fontSize: 10))
            .decorate(barElements, canvas, graphicsFactory,
                drawBounds: drawBounds,
                animationPercent: 1.0,
                renderingVertically: true);

        final captured =
            verify(canvas.drawText(captureAny, captureAny, captureAny))
                .captured;
        expect(captured, hasLength(3));
        expect(captured[0].measurement.horizontalSliceWidth, equals(6));
        expect(captured[0].measurement.verticalSliceWidth, equals(12));
        expect(captured[1],
            equals(12)); // left position + bar width / 2 - text width / 2
        expect(captured[2], equals(80)); // top position
      });

      test('Paints negative inside labels', () {
        final barElements = [
          FakeBarRendererElement(
              'A', Rectangle(10, 80, 10, 20), (_) => 'LabelA', ['A'],
              measureFn: (_) => -1.0),
        ];

        BarLabelDecorator<String>(
                labelPosition: BarLabelPosition.inside,
                labelPlacement: BarLabelPlacement.opposeAxisBaseline,
                labelPadding: 0, // Turn off label padding for testing.
                outsideLabelStyleSpec: TextStyleSpec(fontSize: 10))
            .decorate(barElements, canvas, graphicsFactory,
                drawBounds: drawBounds,
                animationPercent: 1.0,
                renderingVertically: true);

        final captured =
            verify(canvas.drawText(captureAny, captureAny, captureAny))
                .captured;
        expect(captured, hasLength(3));
        expect(captured[0].measurement.horizontalSliceWidth, equals(6));
        expect(captured[0].measurement.verticalSliceWidth, equals(12));
        expect(captured[1],
            equals(12)); // left position + bar width / 2 - text width / 2
        expect(
            captured[2], equals(88)); // top position + bar height - text height
      });
    });
  });

  group('horizontal bar chart', () {
    test('Paint labels with default settings', () {
      final data = ['A', 'B'];
      final barElements = [
        // 'LabelA' and 'LabelB' both have lengths of 6.
        // 'LabelB' would not fit inside the bar in auto setting because it has
        // width of 5.
        FakeBarRendererElement(
            'A', Rectangle(0, 20, 50, 20), (_) => 'LabelA', data),
        FakeBarRendererElement(
            'B', Rectangle(0, 70, 5, 20), (_) => 'LabelB', data)
      ];
      final decorator = BarLabelDecorator<String>();

      decorator.decorate(barElements, canvas, graphicsFactory,
          drawBounds: drawBounds,
          animationPercent: 1.0,
          renderingVertically: false);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      // Draw text is called twice (once for each bar) and all 3 parameters were
      // captured. Total parameters captured expected to be 6.
      expect(captured, hasLength(6));
      // For bar 'A'.
      expect(captured[0].maxWidth, equals(50 - decorator.labelPadding * 2));
      expect(captured[0].textDirection, equals(TextDirection.ltr));
      expect(captured[1], equals(decorator.labelPadding));
      expect(captured[2],
          equals(30 - decorator.insideLabelStyleSpec.fontSize ~/ 2));
      // For bar 'B'.
      expect(
          captured[3].maxWidth, equals(200 - 5 - decorator.labelPadding * 2));
      expect(captured[3].textDirection, equals(TextDirection.ltr));
      expect(captured[4], equals(5 + decorator.labelPadding));
      expect(captured[5],
          equals(80 - decorator.outsideLabelStyleSpec.fontSize ~/ 2));
    });

    test('LabelPosition.auto paints inside bar if outside bar has less width',
        () {
      final barElements = [
        // 'LabelABC' would not fit inside the bar in auto setting because it
        // has a width of 8.
        FakeBarRendererElement(
            'A', Rectangle(0, 0, 8, 20), (_) => 'LabelABC', ['A']),
      ];
      // Draw bounds with width of 14 means that space inside the bar is larger.
      final smallDrawBounds = Rectangle(0, 0, 14, 20);

      BarLabelDecorator<String>(
              labelPadding: 0, // Turn off label padding for testing.
              insideLabelStyleSpec: TextStyleSpec(fontSize: 10))
          .decorate(barElements, canvas, graphicsFactory,
              drawBounds: smallDrawBounds,
              animationPercent: 1.0,
              renderingVertically: false);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      expect(captured, hasLength(3));
      expect(captured[0].maxWidth, equals(8));
      expect(captured[0].textDirection, equals(TextDirection.ltr));
      expect(captured[1], equals(0));
      expect(captured[2], equals(5));
    });

    test('LabelPosition.inside always paints inside the bar', () {
      final barElements = [
        // 'LabelABC' would not fit inside the bar in auto setting because it
        // has a width of 8.
        FakeBarRendererElement(
            'A', Rectangle(0, 0, 8, 20), (_) => 'LabelABC', ['A']),
      ];

      BarLabelDecorator<String>(
              labelPosition: BarLabelPosition.inside,
              labelPadding: 0, // Turn off label padding for testing.
              insideLabelStyleSpec: TextStyleSpec(fontSize: 10))
          .decorate(barElements, canvas, graphicsFactory,
              drawBounds: drawBounds,
              animationPercent: 1.0,
              renderingVertically: false);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      expect(captured, hasLength(3));
      expect(captured[0].maxWidth, equals(8));
      expect(captured[0].textDirection, equals(TextDirection.ltr));
      expect(captured[1], equals(0));
      expect(captured[2], equals(5));
    });

    test('Do not paint labels if they do not fit', () {
      final barElements = [
        // 'LabelABC' would not fit inside the bar in auto setting because it
        // has a width of 8.
        FakeBarRendererElement(
            'A', Rectangle(0, 0, 6, 20), (_) => 'LabelABC', ['A']),
      ];

      // Draw bounds with width of 12 means that label can fit neither inside
      // nor outside.
      final smallDrawBounds = Rectangle(0, 0, 12, 20);

      BarLabelDecorator<String>(
              labelPadding: 0, // Turn off label padding for testing.
              insideLabelStyleSpec: TextStyleSpec(fontSize: 10))
          .decorate(barElements, canvas, graphicsFactory,
              drawBounds: smallDrawBounds,
              animationPercent: 1.0,
              renderingVertically: false);

      verifyNever(canvas.drawText(captureAny, captureAny, captureAny));
    });

    test('LabelPosition.outside always paints outside the bar', () {
      final barElements = [
        FakeBarRendererElement(
            'A', Rectangle(0, 0, 10, 20), (_) => 'Label', ['A']),
      ];

      BarLabelDecorator<String>(
              labelPosition: BarLabelPosition.outside,
              labelPadding: 0, // Turn off label padding for testing.
              outsideLabelStyleSpec: TextStyleSpec(fontSize: 10))
          .decorate(barElements, canvas, graphicsFactory,
              drawBounds: drawBounds,
              animationPercent: 1.0,
              renderingVertically: false);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      expect(captured, hasLength(3));
      expect(captured[0].maxWidth, equals(190));
      expect(captured[0].textDirection, equals(TextDirection.ltr));
      expect(captured[1], equals(10));
      expect(captured[2], equals(5));
    });

    test('Inside and outside label styles are applied', () {
      final data = ['A', 'B'];
      final barElements = [
        // 'LabelA' and 'LabelB' both have lengths of 6.
        // 'LabelB' would not fit inside the bar in auto setting because it has
        // width of 5.
        FakeBarRendererElement(
            'A', Rectangle(0, 20, 50, 20), (_) => 'LabelA', data),
        FakeBarRendererElement(
            'B', Rectangle(0, 70, 5, 20), (_) => 'LabelB', data)
      ];
      final insideColor = Color(r: 0, g: 0, b: 0);
      final outsideColor = Color(r: 255, g: 255, b: 255);
      final decorator = BarLabelDecorator<String>(
          labelPadding: 0,
          insideLabelStyleSpec: TextStyleSpec(
              fontSize: 10, fontFamily: 'insideFont', color: insideColor),
          outsideLabelStyleSpec: TextStyleSpec(
              fontSize: 8, fontFamily: 'outsideFont', color: outsideColor));

      decorator.decorate(barElements, canvas, graphicsFactory,
          drawBounds: drawBounds,
          animationPercent: 1.0,
          renderingVertically: false);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      // Draw text is called twice (once for each bar) and all 3 parameters were
      // captured. Total parameters captured expected to be 6.
      expect(captured, hasLength(6));
      // For bar 'A'.
      expect(captured[0].maxWidth, equals(50));
      expect(captured[0].textDirection, equals(TextDirection.ltr));
      expect(captured[0].textStyle.fontFamily, equals('insideFont'));
      expect(captured[0].textStyle.color, equals(insideColor));
      expect(captured[1], equals(0));
      expect(captured[2], equals(30 - 5));
      // For bar 'B'.
      expect(captured[3].maxWidth, equals(200 - 5));
      expect(captured[3].textDirection, equals(TextDirection.ltr));
      expect(captured[3].textStyle.fontFamily, equals('outsideFont'));
      expect(captured[3].textStyle.color, equals(outsideColor));
      expect(captured[4], equals(5));
      expect(captured[5], equals(80 - 4));
    });

    test('TextAnchor.end starts on the right most of bar', () {
      final barElements = [
        FakeBarRendererElement(
            'A', Rectangle(0, 0, 10, 20), (_) => 'LabelA', ['A'])
      ];

      BarLabelDecorator<String>(
              labelAnchor: BarLabelAnchor.end,
              labelPosition: BarLabelPosition.inside,
              labelPadding: 0, // Turn off label padding for testing.
              insideLabelStyleSpec: TextStyleSpec(fontSize: 10))
          .decorate(barElements, canvas, graphicsFactory,
              drawBounds: drawBounds,
              animationPercent: 1.0,
              renderingVertically: false);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      expect(captured, hasLength(3));
      expect(captured[0].maxWidth, equals(10));
      expect(captured[0].textDirection, equals(TextDirection.rtl));
      expect(captured[1], equals(10));
      expect(captured[2], equals(5));
    });

    test('RTL TextAnchor.start starts on the right', () {
      final barElements = [
        FakeBarRendererElement(
            'A', Rectangle(0, 0, 10, 20), (_) => 'LabelA', ['A'])
      ];

      BarLabelDecorator<String>(
              labelAnchor: BarLabelAnchor.start,
              labelPosition: BarLabelPosition.inside,
              labelPadding: 0, // Turn off label padding for testing.
              insideLabelStyleSpec: TextStyleSpec(fontSize: 10))
          .decorate(barElements, canvas, graphicsFactory,
              drawBounds: drawBounds,
              animationPercent: 1.0,
              renderingVertically: false,
              rtl: true);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      expect(captured, hasLength(3));
      expect(captured[0].maxWidth, equals(10));
      expect(captured[0].textDirection, equals(TextDirection.rtl));
      expect(captured[1], equals(10));
      expect(captured[2], equals(5));
    });

    test('RTL TextAnchor.end starts on the left', () {
      final barElements = [
        FakeBarRendererElement(
            'A', Rectangle(0, 0, 10, 20), (_) => 'LabelA', ['A'])
      ];

      BarLabelDecorator<String>(
              labelAnchor: BarLabelAnchor.end,
              labelPosition: BarLabelPosition.inside,
              labelPadding: 0, // Turn off label padding for testing.
              insideLabelStyleSpec: TextStyleSpec(fontSize: 10))
          .decorate(barElements, canvas, graphicsFactory,
              drawBounds: drawBounds,
              animationPercent: 1.0,
              renderingVertically: false,
              rtl: true);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      expect(captured, hasLength(3));
      expect(captured[0].maxWidth, equals(10));
      expect(captured[0].textDirection, equals(TextDirection.ltr));
      expect(captured[1], equals(0));
      expect(captured[2], equals(5));
    });

    test('RTL right label position', () {
      final barElements = [
        FakeBarRendererElement(
            'A', Rectangle(0, 0, 10, 20), (_) => 'LabelA', ['A'])
      ];

      BarLabelDecorator<String>(
              labelPosition: BarLabelPosition.right,
              labelPadding: 0, // Turn off label padding for testing.
              insideLabelStyleSpec: TextStyleSpec(fontSize: 10))
          .decorate(barElements, canvas, graphicsFactory,
              drawBounds: drawBounds,
              animationPercent: 1.0,
              renderingVertically: false,
              rtl: true);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      expect(captured, hasLength(3));
      expect(captured[0].maxWidth, equals(190));
      expect(captured[1], equals(194));
      expect(captured[2], equals(4));
    });

    test('RTL top right label position', () {
      final barElements = [
        FakeBarRendererElement(
            'A', Rectangle(0, 0, 10, 20), (_) => 'LabelA', ['A'])
      ];

      BarLabelDecorator<String>(
              labelPosition: BarLabelPosition.right,
              labelVerticalPosition: BarLabelVerticalPosition.top,
              labelPadding: 0, // Turn off label padding for testing.
              insideLabelStyleSpec: TextStyleSpec(fontSize: 10))
          .decorate(barElements, canvas, graphicsFactory,
              drawBounds: drawBounds,
              animationPercent: 1.0,
              renderingVertically: false,
              rtl: true);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      expect(captured, hasLength(3));
      expect(captured[0].maxWidth, equals(190));
      expect(captured[1], equals(194));
      expect(captured[2], equals(-12));
    });

    group('Null and empty label scenarios', () {
      test('Skip label if label accessor does not exist', () {
        final barElements = [
          FakeBarRendererElement('A', Rectangle(0, 0, 10, 20), null, ['A']),
        ];

        BarLabelDecorator<String>().decorate(
            barElements, canvas, graphicsFactory,
            drawBounds: drawBounds,
            animationPercent: 1.0,
            renderingVertically: false);

        verifyNever(canvas.drawText(any, any, any));
      });

      test('Skip label if label is null or empty', () {
        final data = ['A', 'B'];
        final barElements = [
          FakeBarRendererElement('A', Rectangle(0, 0, 10, 20), null, data),
          FakeBarRendererElement(
              'B', Rectangle(0, 50, 10, 20), (_) => '', data),
        ];

        BarLabelDecorator<String>().decorate(
            barElements, canvas, graphicsFactory,
            drawBounds: drawBounds,
            animationPercent: 1.0,
            renderingVertically: false);

        verifyNever(canvas.drawText(any, any, any));
      });

      test('Skip label if no width available', () {
        final barElements = [
          FakeBarRendererElement(
              'A', Rectangle(0, 0, 200, 20), (_) => 'a', ['A'])
        ];

        BarLabelDecorator<String>(
          labelPadding: 0,
          labelPosition: BarLabelPosition.outside,
        ).decorate(barElements, canvas, graphicsFactory,
            drawBounds: drawBounds,
            animationPercent: 1.0,
            renderingVertically: false);

        verifyNever(canvas.drawText(any, any, any));
      });
    });

    group('BarLabelPlacement.opposeAxisBaseline', () {
      test('Paints positive outside labels', () {
        final barElements = [
          FakeBarRendererElement(
              'A', Rectangle(10, 80, 10, 20), (_) => 'LabelA', ['A']),
        ];

        BarLabelDecorator<String>(
                labelPosition: BarLabelPosition.outside,
                labelPlacement: BarLabelPlacement.opposeAxisBaseline,
                labelPadding: 0, // Turn off label padding for testing.
                outsideLabelStyleSpec: TextStyleSpec(fontSize: 10))
            .decorate(barElements, canvas, graphicsFactory,
                drawBounds: drawBounds,
                animationPercent: 1.0,
                renderingVertically: false);

        final captured =
            verify(canvas.drawText(captureAny, captureAny, captureAny))
                .captured;
        expect(captured, hasLength(3));
        expect(captured[0].measurement.horizontalSliceWidth, equals(6));
        expect(captured[0].measurement.verticalSliceWidth, equals(10));
        expect(captured[1], equals(20)); // left position + bar width
        expect(captured[2],
            equals(85)); // top position + bar height / 2 - text height / 2
      });

      test('Paints negative outside labels', () {
        final barElements = [
          FakeBarRendererElement(
              'A', Rectangle(10, 80, 10, 20), (_) => 'LabelA', ['A'],
              measureFn: (_) => -1.0),
        ];

        BarLabelDecorator<String>(
                labelPosition: BarLabelPosition.outside,
                labelPlacement: BarLabelPlacement.opposeAxisBaseline,
                labelPadding: 0, // Turn off label padding for testing.
                outsideLabelStyleSpec: TextStyleSpec(fontSize: 10))
            .decorate(barElements, canvas, graphicsFactory,
                drawBounds: drawBounds,
                animationPercent: 1.0,
                renderingVertically: false);

        final captured =
            verify(canvas.drawText(captureAny, captureAny, captureAny))
                .captured;
        expect(captured, hasLength(3));
        expect(captured[0].measurement.horizontalSliceWidth, equals(6));
        expect(captured[0].measurement.verticalSliceWidth, equals(10));
        expect(captured[1], equals(10)); // left position
        expect(captured[2],
            equals(85)); // top position + bar height / 2 - text height / 2
      });

      test('Paints positive inside labels', () {
        final barElements = [
          FakeBarRendererElement(
              'A', Rectangle(10, 80, 10, 20), (_) => 'LabelA', ['A']),
        ];

        BarLabelDecorator<String>(
                labelPosition: BarLabelPosition.inside,
                labelPlacement: BarLabelPlacement.opposeAxisBaseline,
                labelPadding: 0, // Turn off label padding for testing.
                outsideLabelStyleSpec: TextStyleSpec(fontSize: 10))
            .decorate(barElements, canvas, graphicsFactory,
                drawBounds: drawBounds,
                animationPercent: 1.0,
                renderingVertically: false);

        final captured =
            verify(canvas.drawText(captureAny, captureAny, captureAny))
                .captured;
        expect(captured, hasLength(3));
        expect(captured[0].measurement.horizontalSliceWidth, equals(6));
        expect(captured[0].measurement.verticalSliceWidth, equals(12));
        expect(captured[1], equals(10)); // left position
        expect(captured[2],
            equals(84)); // top position + bar height / 2 - text height / 2
      });

      test('Paints negative inside labels', () {
        final barElements = [
          FakeBarRendererElement(
              'A', Rectangle(10, 80, 10, 20), (_) => 'LabelA', ['A'],
              measureFn: (_) => -1.0),
        ];

        BarLabelDecorator<String>(
                labelPosition: BarLabelPosition.inside,
                labelPlacement: BarLabelPlacement.opposeAxisBaseline,
                labelPadding: 0, // Turn off label padding for testing.
                outsideLabelStyleSpec: TextStyleSpec(fontSize: 10))
            .decorate(barElements, canvas, graphicsFactory,
                drawBounds: drawBounds,
                animationPercent: 1.0,
                renderingVertically: false);

        final captured =
            verify(canvas.drawText(captureAny, captureAny, captureAny))
                .captured;
        expect(captured, hasLength(3));
        expect(captured[0].measurement.horizontalSliceWidth, equals(6));
        expect(captured[0].measurement.verticalSliceWidth, equals(12));
        expect(captured[1], equals(20)); // left position + bar width
        expect(captured[2],
            equals(84)); // top position + bar height / 2 - text height / 2
      });
    });
  });
}

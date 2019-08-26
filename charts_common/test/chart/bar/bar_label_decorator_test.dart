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
    show BarLabelDecorator, BarLabelAnchor, BarLabelPosition;
import 'package:charts_common/src/data/series.dart' show AccessorFn;

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

class MockCanvas extends Mock implements ChartCanvas {}

/// A fake [GraphicsFactory] that returns [FakeTextStyle] and [FakeTextElement].
class FakeGraphicsFactory extends GraphicsFactory {
  @override
  TextStyle createTextPaint() => new FakeTextStyle();

  @override
  TextElement createTextElement(String text) => new FakeTextElement(text);

  @override
  LineStyle createLinePaint() => new MockLinePaint();
}

/// Stores [TextStyle] properties for test to verify.
class FakeTextStyle implements TextStyle {
  Color color;
  int fontSize;
  String fontFamily;
  double lineHeight;
}

/// Fake [TextElement] which returns text length as [horizontalSliceWidth].
///
/// Font size is returned for [verticalSliceWidth] and [baseline].
class FakeTextElement implements TextElement {
  final String text;
  TextStyle textStyle;
  int maxWidth;
  MaxWidthStrategy maxWidthStrategy;
  TextDirection textDirection;
  double opacity;

  FakeTextElement(this.text);

  TextMeasurement get measurement => new TextMeasurement(
      horizontalSliceWidth: text.length.toDouble(),
      verticalSliceWidth: textStyle.fontSize.toDouble(),
      baseline: textStyle.fontSize.toDouble());
}

class MockLinePaint extends Mock implements LineStyle {}

class FakeBarRendererElement implements ImmutableBarRendererElement<String> {
  final _series = new MockImmutableSeries<String>();
  final AccessorFn<String> labelAccessor;
  final String datum;
  final Rectangle<int> bounds;
  final List<String> data;
  int index;

  FakeBarRendererElement(
      this.datum, this.bounds, this.labelAccessor, this.data) {
    index = data.indexOf(datum);
    when(_series.labelAccessorFn).thenReturn(labelAccessor);
    when(_series.data).thenReturn(data);
  }

  ImmutableSeries<String> get series => _series;
}

class MockImmutableSeries<D> extends Mock implements ImmutableSeries<D> {}

void main() {
  ChartCanvas canvas;
  GraphicsFactory graphicsFactory;
  Rectangle<int> drawBounds;

  setUpAll(() {
    canvas = new MockCanvas();
    graphicsFactory = new FakeGraphicsFactory();
    drawBounds = new Rectangle(0, 0, 200, 100);
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
      final decorator = BarLabelDecorator();

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
      var labelWidth = captured[0].measurement.horizontalSliceWidth;
      var labelHeight = captured[0].measurement.verticalSliceWidth;
      expect(labelWidth, equals(6));
      expect(labelHeight, equals(12));
      expect(captured[0].maxWidth, equals(barWidthA));
      expect(
          captured[1], equals(leftPositionA + barWidthA / 2 - labelWidth / 2));
      expect(captured[2], equals(topPositionA + decorator.labelPadding));
      // Bar 'B' checks.
      labelWidth = captured[3].measurement.horizontalSliceWidth;
      labelHeight = captured[3].measurement.verticalSliceWidth;
      expect(labelWidth, equals(6));
      expect(labelHeight, equals(12));
      expect(captured[3].maxWidth, equals(barWidthB));
      expect(
          captured[4], equals(leftPositionB + barWidthB / 2 - labelWidth / 2));
      expect(captured[5],
          equals(topPositionB - decorator.labelPadding - labelHeight));
      // Bar 'C' checks.
      labelWidth = captured[6].measurement.horizontalSliceWidth;
      labelHeight = captured[6].measurement.verticalSliceWidth;
      expect(labelWidth, equals(6));
      expect(labelHeight, equals(12));
      expect(captured[6].maxWidth, equals(barWidthC));
      expect(
          captured[7], equals(leftPositionC + barWidthC / 2 - labelWidth / 2));
      expect(captured[8],
          equals(topPositionC - decorator.labelPadding - labelHeight));
    });

    test('LabelPosition.inside always paints inside the bar', () {
      final barElements = [
        // 'LabelABC' would not fit inside the bar in auto setting because it
        // has a width of 8.
        FakeBarRendererElement(
            'A', Rectangle(10, 80, 6, 20), (_) => 'LabelABC', ['A']),
      ];

      BarLabelDecorator(
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

      BarLabelDecorator(
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

      BarLabelDecorator(
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
      final decorator = BarLabelDecorator(
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

        BarLabelDecorator().decorate(barElements, canvas, graphicsFactory,
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

        BarLabelDecorator().decorate(barElements, canvas, graphicsFactory,
            drawBounds: drawBounds,
            animationPercent: 1.0,
            renderingVertically: true);

        verifyNever(canvas.drawText(any, any, any));
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
        new FakeBarRendererElement(
            'A', new Rectangle(0, 20, 50, 20), (_) => 'LabelA', data),
        new FakeBarRendererElement(
            'B', new Rectangle(0, 70, 5, 20), (_) => 'LabelB', data)
      ];
      final decorator = new BarLabelDecorator();

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
        new FakeBarRendererElement(
            'A', new Rectangle(0, 0, 6, 20), (_) => 'LabelABC', ['A']),
      ];
      // Draw bounds with width of 10 means that space inside the bar is larger.
      final smallDrawBounds = new Rectangle(0, 0, 10, 20);

      new BarLabelDecorator(
              labelPadding: 0, // Turn off label padding for testing.
              insideLabelStyleSpec: new TextStyleSpec(fontSize: 10))
          .decorate(barElements, canvas, graphicsFactory,
              drawBounds: smallDrawBounds,
              animationPercent: 1.0,
              renderingVertically: false);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      expect(captured, hasLength(3));
      expect(captured[0].maxWidth, equals(6));
      expect(captured[0].textDirection, equals(TextDirection.ltr));
      expect(captured[1], equals(0));
      expect(captured[2], equals(5));
    });

    test('LabelPosition.inside always paints inside the bar', () {
      final barElements = [
        // 'LabelABC' would not fit inside the bar in auto setting because it
        // has a width of 8.
        new FakeBarRendererElement(
            'A', new Rectangle(0, 0, 6, 20), (_) => 'LabelABC', ['A']),
      ];

      new BarLabelDecorator(
              labelPosition: BarLabelPosition.inside,
              labelPadding: 0, // Turn off label padding for testing.
              insideLabelStyleSpec: new TextStyleSpec(fontSize: 10))
          .decorate(barElements, canvas, graphicsFactory,
              drawBounds: drawBounds,
              animationPercent: 1.0,
              renderingVertically: false);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      expect(captured, hasLength(3));
      expect(captured[0].maxWidth, equals(6));
      expect(captured[0].textDirection, equals(TextDirection.ltr));
      expect(captured[1], equals(0));
      expect(captured[2], equals(5));
    });

    test('LabelPosition.outside always paints outside the bar', () {
      final barElements = [
        new FakeBarRendererElement(
            'A', new Rectangle(0, 0, 10, 20), (_) => 'Label', ['A']),
      ];

      new BarLabelDecorator(
              labelPosition: BarLabelPosition.outside,
              labelPadding: 0, // Turn off label padding for testing.
              outsideLabelStyleSpec: new TextStyleSpec(fontSize: 10))
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
        new FakeBarRendererElement(
            'A', new Rectangle(0, 20, 50, 20), (_) => 'LabelA', data),
        new FakeBarRendererElement(
            'B', new Rectangle(0, 70, 5, 20), (_) => 'LabelB', data)
      ];
      final insideColor = new Color(r: 0, g: 0, b: 0);
      final outsideColor = new Color(r: 255, g: 255, b: 255);
      final decorator = new BarLabelDecorator(
          labelPadding: 0,
          insideLabelStyleSpec: new TextStyleSpec(
              fontSize: 10, fontFamily: 'insideFont', color: insideColor),
          outsideLabelStyleSpec: new TextStyleSpec(
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
        new FakeBarRendererElement(
            'A', new Rectangle(0, 0, 10, 20), (_) => 'LabelA', ['A'])
      ];

      new BarLabelDecorator(
              labelAnchor: BarLabelAnchor.end,
              labelPosition: BarLabelPosition.inside,
              labelPadding: 0, // Turn off label padding for testing.
              insideLabelStyleSpec: new TextStyleSpec(fontSize: 10))
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
        new FakeBarRendererElement(
            'A', new Rectangle(0, 0, 10, 20), (_) => 'LabelA', ['A'])
      ];

      new BarLabelDecorator(
              labelAnchor: BarLabelAnchor.start,
              labelPosition: BarLabelPosition.inside,
              labelPadding: 0, // Turn off label padding for testing.
              insideLabelStyleSpec: new TextStyleSpec(fontSize: 10))
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
        new FakeBarRendererElement(
            'A', new Rectangle(0, 0, 10, 20), (_) => 'LabelA', ['A'])
      ];

      new BarLabelDecorator(
              labelAnchor: BarLabelAnchor.end,
              labelPosition: BarLabelPosition.inside,
              labelPadding: 0, // Turn off label padding for testing.
              insideLabelStyleSpec: new TextStyleSpec(fontSize: 10))
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

    group('Null and empty label scenarios', () {
      test('Skip label if label accessor does not exist', () {
        final barElements = [
          new FakeBarRendererElement(
              'A', new Rectangle(0, 0, 10, 20), null, ['A'])
        ];

        new BarLabelDecorator().decorate(barElements, canvas, graphicsFactory,
            drawBounds: drawBounds,
            animationPercent: 1.0,
            renderingVertically: false);

        verifyNever(canvas.drawText(any, any, any));
      });

      test('Skip label if label is null or empty', () {
        final data = ['A', 'B'];
        final barElements = [
          new FakeBarRendererElement(
              'A', new Rectangle(0, 0, 10, 20), null, data),
          new FakeBarRendererElement(
              'B', new Rectangle(0, 50, 10, 20), (_) => '', data),
        ];

        new BarLabelDecorator().decorate(barElements, canvas, graphicsFactory,
            drawBounds: drawBounds,
            animationPercent: 1.0,
            renderingVertically: false);

        verifyNever(canvas.drawText(any, any, any));
      });

      test('Skip label if no width available', () {
        final barElements = [
          new FakeBarRendererElement(
              'A', new Rectangle(0, 0, 200, 20), (_) => 'a', ['A'])
        ];

        new BarLabelDecorator(
          labelPadding: 0,
          labelPosition: BarLabelPosition.outside,
        ).decorate(barElements, canvas, graphicsFactory,
            drawBounds: drawBounds,
            animationPercent: 1.0,
            renderingVertically: false);

        verifyNever(canvas.drawText(any, any, any));
      });
    });
  });
}

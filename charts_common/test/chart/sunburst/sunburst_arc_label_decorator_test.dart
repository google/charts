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

import 'dart:math' show pi, Point, Rectangle;
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
import 'package:charts_common/src/chart/cartesian/axis/spec/axis_spec.dart'
    show TextStyleSpec;
import 'package:charts_common/src/chart/common/chart_canvas.dart'
    show ChartCanvas;
import 'package:charts_common/src/chart/pie/arc_label_decorator.dart'
    show ArcLabelPosition;
import 'package:charts_common/src/chart/sunburst/sunburst_arc_label_decorator.dart'
    show SunburstArcLabelDecorator;
import 'package:charts_common/src/chart/pie/arc_renderer_element.dart'
    show ArcRendererElementList;
import 'package:charts_common/src/chart/sunburst/sunburst_arc_renderer.dart'
    show SunburstArcRendererElement;
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

class FakeArcRendererElement extends SunburstArcRendererElement<String> {
  final _series = MockImmutableSeries<String>();
  final AccessorFn<String> labelAccessor;
  final List<String> data;

  FakeArcRendererElement(this.labelAccessor, this.data) {
    when(_series.labelAccessorFn).thenReturn(labelAccessor);
    when(_series.data).thenReturn(data);
  }

  @override
  ImmutableSeries<String> get series => _series;
}

class MockImmutableSeries<D> extends Mock implements ImmutableSeries<D> {}

/// Test for SunburstArcLabelDecorator. It should behave the mostly the same as
/// the ArcLabelDecorator except:
/// If ArcLabelPosition is set tooutside, only label the outer most ring will be
/// drawn.
/// If ArcLabelPosition is set to auto, the label on the outer most ring will
/// follow the computation of the ArcLabelDecorator and the label of the inner
/// rings will be forced to render inside.
void main() {
  ChartCanvas canvas;
  GraphicsFactory graphicsFactory;
  Rectangle<int> drawBounds;

  setUpAll(() {
    canvas = MockCanvas();
    graphicsFactory = FakeGraphicsFactory();
    drawBounds = Rectangle(0, 0, 200, 200);
  });

  group('sunburst chart', () {
    test('Paint labels with default settings', () {
      final data = ['A', 'B', 'C'];
      final arcElements = ArcRendererElementList(
        arcs: [
          // 'A' is small enough to fit inside the arc.
          // 'LongLabelB' should not fit inside the arc because it has length
          // greater than 10.
          FakeArcRendererElement((_) => 'A', data)
            ..startAngle = -pi / 2
            ..endAngle = pi / 2,
          FakeArcRendererElement((_) => 'LongLabelB', data)
            ..startAngle = pi / 2
            ..endAngle = 3 * pi / 2
            ..isOuterMostRing = true,
          FakeArcRendererElement((_) => 'LongLabelC', data)
            ..startAngle = -pi / 2
            ..endAngle = pi / 2,
        ],
        center: Point(100.0, 100.0),
        innerRadius: 30.0,
        radius: 40.0,
        startAngle: -pi / 2,
      );

      final decorator = SunburstArcLabelDecorator();

      decorator.decorate([arcElements], canvas, graphicsFactory,
          drawBounds: drawBounds, animationPercent: 1.0);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      // Draw text is called three times (once for each arc) and all 3
      // parameters were captured. Total parameters captured expected to be 9.
      expect(captured, hasLength(9));
      // For arc 'A'.
      expect(captured[0].maxWidth, equals(10 - decorator.labelPadding));
      expect(captured[0].textDirection, equals(TextDirection.center));
      expect(captured[1], equals(135));
      expect(captured[2],
          equals(100 - decorator.insideLabelStyleSpec.fontSize ~/ 2));
      // For arc 'B'.
      expect(captured[3].maxWidth, equals(20));
      expect(captured[3].textDirection, equals(TextDirection.rtl));
      expect(
          captured[4],
          equals(60 -
              decorator.leaderLineStyleSpec.length -
              decorator.labelPadding * 3));
      expect(captured[5],
          equals(100 - decorator.outsideLabelStyleSpec.fontSize ~/ 2));

      // For arc 'C', forced inside and ellipsed since it is not the on the
      // outer most ring.
      expect(captured[6].maxWidth, equals(10 - decorator.labelPadding));
      expect(captured[6].textDirection, equals(TextDirection.center));
      expect(captured[7], equals(135));
      expect(captured[8],
          equals(100 - decorator.insideLabelStyleSpec.fontSize ~/ 2));
    });

    test('setting outerRingArcLabelPosition inside paints inside the arc', () {
      final arcElements = ArcRendererElementList(
        arcs: [
          // 'LongLabelABC' would not fit inside the arc because it has length
          // greater than 10. [ArcLabelPosition.inside] should override this.
          FakeArcRendererElement((_) => 'LongLabelABC', ['A'])
            ..startAngle = -pi / 2
            ..endAngle = pi / 2,
        ],
        center: Point(100.0, 100.0),
        innerRadius: 30.0,
        radius: 40.0,
        startAngle: -pi / 2,
      );

      final decorator = SunburstArcLabelDecorator(
          outerRingArcLabelPosition: ArcLabelPosition.inside,
          insideLabelStyleSpec: TextStyleSpec(fontSize: 10));

      decorator.decorate([arcElements], canvas, graphicsFactory,
          drawBounds: drawBounds, animationPercent: 1.0);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      expect(captured, hasLength(3));
      expect(captured[0].maxWidth, equals(10 - decorator.labelPadding));
      expect(captured[0].textDirection, equals(TextDirection.center));
      expect(captured[1], equals(135));
      expect(captured[2],
          equals(100 - decorator.insideLabelStyleSpec.fontSize ~/ 2));
    });

    test(
        'LabelPosition.outside paints outside the arc for the outer most '
        'rings', () {
      final arcElements = ArcRendererElementList(
        arcs: [
          // 'A' will fit inside the arc because it has length less than 10.
          // [ArcLabelPosition.outside] should override this.
          FakeArcRendererElement((_) => 'A', ['A'])
            ..startAngle = -pi / 2
            ..endAngle = pi / 2
            ..isLeaf = true,
          // Non leaf arcs will not be rendered for [ArcLabelPosition.outside].
          FakeArcRendererElement((_) => 'B', ['B'])
            ..startAngle = pi / 2
            ..endAngle = 3 * pi / 2
        ],
        center: Point(100.0, 100.0),
        innerRadius: 30.0,
        radius: 40.0,
        startAngle: -pi / 2,
      );

      final decorator = SunburstArcLabelDecorator(
          innerRingArcLabelPosition: ArcLabelPosition.outside,
          innerRingLeafArcLabelPosition: ArcLabelPosition.outside,
          outerRingArcLabelPosition: ArcLabelPosition.outside,
          outsideLabelStyleSpec: TextStyleSpec(fontSize: 10));

      decorator.decorate([arcElements], canvas, graphicsFactory,
          drawBounds: drawBounds, animationPercent: 1.0);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      // Since 'B' is not drawn, captured length is 3 instead of 6.
      expect(captured, hasLength(3));
      expect(captured[0].maxWidth, equals(20));
      expect(captured[0].textDirection, equals(TextDirection.ltr));
      expect(
          captured[1],
          equals(140 +
              decorator.leaderLineStyleSpec.length +
              decorator.labelPadding * 3));
      expect(captured[2],
          equals(100 - decorator.outsideLabelStyleSpec.fontSize ~/ 2));
    });

    test('Inside and outside label styles are applied', () {
      final data = ['A', 'B'];
      final arcElements = ArcRendererElementList(
        arcs: [
          // 'A' is small enough to fit inside the arc.
          // 'LongLabelB' should not fit inside the arc because it has length
          // greater than 10.
          FakeArcRendererElement((_) => 'A', data)
            ..startAngle = -pi / 2
            ..endAngle = pi / 2,
          FakeArcRendererElement((_) => 'LongLabelB', data)
            ..startAngle = pi / 2
            ..endAngle = 3 * pi / 2
            ..isLeaf = true
        ],
        center: Point(100.0, 100.0),
        innerRadius: 30.0,
        radius: 40.0,
        startAngle: -pi / 2,
      );

      final insideColor = Color(r: 0, g: 0, b: 0);
      final outsideColor = Color(r: 255, g: 255, b: 255);
      final decorator = SunburstArcLabelDecorator(
          labelPadding: 0,
          innerRingLeafArcLabelPosition: ArcLabelPosition.auto,
          insideLabelStyleSpec: TextStyleSpec(
              fontSize: 10, fontFamily: 'insideFont', color: insideColor),
          outsideLabelStyleSpec: TextStyleSpec(
              fontSize: 8, fontFamily: 'outsideFont', color: outsideColor));

      decorator.decorate([arcElements], canvas, graphicsFactory,
          drawBounds: drawBounds, animationPercent: 1.0);

      final captured =
          verify(canvas.drawText(captureAny, captureAny, captureAny)).captured;
      // Draw text is called twice (once for each arc) and all 3 parameters were
      // captured. Total parameters captured expected to be 6.
      expect(captured, hasLength(6));
      // For arc 'A'.
      expect(captured[0].maxWidth, equals(10 - decorator.labelPadding));
      expect(captured[0].textDirection, equals(TextDirection.center));
      expect(captured[0].textStyle.fontFamily, equals('insideFont'));
      expect(captured[0].textStyle.color, equals(insideColor));
      expect(captured[1], equals(135));
      expect(captured[2],
          equals(100 - decorator.insideLabelStyleSpec.fontSize ~/ 2));
      // For arc 'B'.
      expect(captured[3].maxWidth, equals(30));
      expect(captured[3].textDirection, equals(TextDirection.rtl));
      expect(captured[3].textStyle.fontFamily, equals('outsideFont'));
      expect(captured[3].textStyle.color, equals(outsideColor));
      expect(
          captured[4],
          equals(50 -
              decorator.leaderLineStyleSpec.length -
              decorator.labelPadding * 3));
      expect(captured[5],
          equals(100 - decorator.outsideLabelStyleSpec.fontSize ~/ 2));
    });
  });

  group('Null and empty label scenarios', () {
    test('Skip label if label accessor does not exist', () {
      final arcElements = ArcRendererElementList(
        arcs: [
          FakeArcRendererElement(null, ['A'])
            ..startAngle = -pi / 2
            ..endAngle = pi / 2,
        ],
        center: Point(100.0, 100.0),
        innerRadius: 30.0,
        radius: 40.0,
        startAngle: -pi / 2,
      );

      SunburstArcLabelDecorator().decorate(
          [arcElements], canvas, graphicsFactory,
          drawBounds: drawBounds, animationPercent: 1.0);

      verifyNever(canvas.drawText(any, any, any));
    });

    test('Skip label if label is null or empty', () {
      final data = ['A', 'B'];
      final arcElements = ArcRendererElementList(
        arcs: [
          FakeArcRendererElement(null, data)
            ..startAngle = -pi / 2
            ..endAngle = pi / 2,
          FakeArcRendererElement((_) => '', data)
            ..startAngle = pi / 2
            ..endAngle = 3 * pi / 2,
        ],
        center: Point(100.0, 100.0),
        innerRadius: 30.0,
        radius: 40.0,
        startAngle: -pi / 2,
      );

      SunburstArcLabelDecorator().decorate(
          [arcElements], canvas, graphicsFactory,
          drawBounds: drawBounds, animationPercent: 1.0);

      verifyNever(canvas.drawText(any, any, any));
    });
  });
}

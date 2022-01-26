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

import 'package:charts_common/src/common/color.dart' show Color;
import 'package:charts_common/src/common/graphics_factory.dart'
    show GraphicsFactory;
import 'package:charts_common/src/common/line_style.dart' show LineStyle;
import 'package:charts_common/src/common/text_element.dart'
    show TextDirection, TextElement, MaxWidthStrategy;
import 'package:charts_common/src/common/text_measurement.dart'
    show TextMeasurement;
import 'package:charts_common/src/common/text_style.dart' show TextStyle;
import 'package:charts_common/src/common/text_utils.dart';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

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
  String fontWeight;

  @override
  double lineHeight;
}

/// Fake [TextElement] which returns text length as [horizontalSliceWidth].
///
/// Font size is returned for [verticalSliceWidth] and [baseline].
class FakeTextElement implements TextElement {
  final String _text;

  @override
  String get text {
    if (maxWidthStrategy == MaxWidthStrategy.ellipsize) {
      var width = measureTextWidth(_text);
      var ellipsis = '...';
      var ellipsisWidth = measureTextWidth(ellipsis);
      if (width <= maxWidth || width <= ellipsisWidth) {
        return _text;
      } else {
        var len = _text.length;
        var ellipsizedText = _text;
        while (width >= maxWidth - ellipsisWidth && len-- > 0) {
          ellipsizedText = ellipsizedText.substring(0, len);
          width = measureTextWidth(ellipsizedText);
        }
        return ellipsizedText + ellipsis;
      }
    }
    return _text;
  }

  @override
  TextStyle textStyle;

  @override
  int maxWidth;

  @override
  MaxWidthStrategy maxWidthStrategy;

  @override
  TextDirection textDirection;

  double opacity;

  FakeTextElement(this._text);

  @override
  TextMeasurement get measurement => TextMeasurement(
      horizontalSliceWidth: _text.length.toDouble(),
      verticalSliceWidth: textStyle.fontSize.toDouble(),
      baseline: textStyle.fontSize.toDouble());

  double measureTextWidth(String text) {
    return text.length.toDouble();
  }
}

class MockLinePaint extends Mock implements LineStyle {}

const _defaultFontSize = 12;
const _defaultLineHeight = 12.0;

void main() {
  GraphicsFactory graphicsFactory;
  num maxWidth;
  num maxHeight;
  FakeTextStyle textStyle;

  setUpAll(() {
    graphicsFactory = FakeGraphicsFactory();
    maxWidth = 10;
    maxHeight = _defaultLineHeight * 2;
    textStyle = FakeTextStyle()
      ..color = Color.black
      ..fontSize = _defaultFontSize;
  });

  group('tree map', () {
    test(
        'when label can fit in a single line, enable allowLabelOverflow, '
        'disable multiline, return full text', () {
      final textElement = FakeTextElement('text')..textStyle = textStyle;
      final textElements = wrapLabelLines(
          textElement, graphicsFactory, maxWidth, maxHeight,
          allowLabelOverflow: true, multiline: false);

      expect(textElements, hasLength(1));
      expect(textElements.first.text, 'text');
    });

    test(
        'when label can not fit in a single line, enable allowLabelOverflow, '
        'disable multiline, return ellipsized text', () {
      final textElement = FakeTextElement('texttexttexttext')
        ..textStyle = textStyle;
      final textElements = wrapLabelLines(
          textElement, graphicsFactory, maxWidth, maxHeight,
          allowLabelOverflow: true, multiline: false);

      expect(textElements, hasLength(1));
      expect(textElements.first.text, 'textte...');
    });

    test(
        'when label can not fit in a single line, enable allowLabelOverflow '
        'and multiline, return two textElements', () {
      final textElement = FakeTextElement('texttexttexttext')
        ..textStyle = textStyle;
      final textElements = wrapLabelLines(
          textElement, graphicsFactory, maxWidth, maxHeight,
          allowLabelOverflow: true, multiline: true);

      expect(textElements, hasLength(2));
      expect(textElements.first.text, 'texttextte');
      expect(textElements.last.text, 'xttext');
    });

    test(
        'when both label and ellpisis can not fit in a single line, disable '
        'allowLabelOverflow and multiline, return empty', () {
      final maxWidth = 2;
      final textElement = FakeTextElement('texttexttexttext')
        ..textStyle = textStyle;
      final textElements = wrapLabelLines(
          textElement, graphicsFactory, maxWidth, maxHeight,
          allowLabelOverflow: false, multiline: false);

      expect(textElements, isEmpty);
    });

    test(
        'when both label and ellpisis can not fit in a single line, disable '
        'allowLabelOverflow but enable multiline, return textElements', () {
      final maxWidth = 2;
      final textElement = FakeTextElement('t ex text')..textStyle = textStyle;
      final textElements = wrapLabelLines(
          textElement, graphicsFactory, maxWidth, maxHeight,
          allowLabelOverflow: false, multiline: true);

      expect(textElements, hasLength(2));
      expect(textElements.first.text, 't');
      expect(textElements.last.text, 'ex');
    });
  });
}

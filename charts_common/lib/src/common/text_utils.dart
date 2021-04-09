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

import 'dart:collection';

import 'package:charts_common/src/common/graphics_factory.dart';
import 'package:charts_common/src/common/text_element.dart';

/// This function breaks original [labelElement] into multiple
/// [TextElement] when [multiline] is true and the width of
/// [labelElement] is larger than [maxWidth], maximum height is
/// limited by [maxHeight]. Otherwise, ellipsize [labelElement] by
/// [maxWidth]
///
/// Returns a list of [TextElement] with given [textStyle].
const _defaultlabelDelimiter = ' ';

List<TextElement> wrapLabelLines(TextElement labelElement,
    GraphicsFactory graphicsFactory, num maxWidth, num maxHeight,
    {required bool allowLabelOverflow,
    required bool multiline,
    String labelDelimiter = _defaultlabelDelimiter}) {
  final textStyle = labelElement.textStyle;
  final textDirection = labelElement.textDirection;
  final labelLineHeight = labelElement.measurement.verticalSliceWidth;
  final maxLines = (maxHeight / labelLineHeight).floor();
  final maxWidthStrategy =
      labelElement.maxWidthStrategy ?? MaxWidthStrategy.ellipsize;

  if (maxWidth.toInt() <= 0 || maxLines <= 0) return <TextElement>[];

  final createTextElement =
      (String text) => graphicsFactory.createTextElement(text)
        ..textStyle = textStyle
        ..textDirection = textDirection;

  if (!multiline) {
    labelElement
      ..maxWidthStrategy = maxWidthStrategy
      ..maxWidth = maxWidth.toInt();

    final labelFits = _doesLabelFit(
        allowLabelOverflow, labelElement, maxWidth, createTextElement);

    return [
      if (labelFits) labelElement,
    ];
  }

  final delimiterElement = createTextElement(labelDelimiter);

  final delimiterElementWidth =
      delimiterElement.measurement.horizontalSliceWidth;

  final labelPartElements = Queue<TextElement>()
    ..addAll(labelElement.text.split(labelDelimiter).map(createTextElement));

  final labelElements = <TextElement>[];
  var currentLineElements = <TextElement>[];
  var currentLineNumber = 0;
  var currentWidth = 0.0;

  while (labelPartElements.isNotEmpty && currentLineNumber < maxLines) {
    final currentElement = labelPartElements.removeFirst();
    var width = currentElement.measurement.horizontalSliceWidth +
        (currentLineElements.isEmpty
            ? 0
            : currentWidth + delimiterElementWidth);

    // If the new word can fit in the left space of the line.
    if (width < maxWidth) {
      currentWidth = width;
      if (currentLineElements.isNotEmpty) {
        currentLineElements.add(delimiterElement);
      }
      currentLineElements.add(currentElement);
    } else {
      // If the new word can not fit in the left space of the line.
      var currentLineString =
          currentLineElements.map((element) => element.text).join();
      currentLineNumber++;
      currentLineElements = [];
      currentWidth = 0;

      // If this is the last line, ellipsize the string of current line and
      // new word.
      if (currentLineNumber == maxLines) {
        if (currentLineString != '') currentLineString += labelDelimiter;
        currentLineString += currentElement.text;
        final truncatedLabelElement = createTextElement(currentLineString)
          ..maxWidthStrategy = maxWidthStrategy
          ..maxWidth = maxWidth.toInt();

        if (_doesLabelFit(allowLabelOverflow, truncatedLabelElement, maxWidth,
            createTextElement)) {
          labelElements.add(truncatedLabelElement);
        }
        break;
      } else {
        // This is not the last line.
        if (currentLineString == '') {
          // When currentElement cannot fit in a whole line.
          final results =
              _splitLabel(currentElement.text, createTextElement, maxWidth);
          labelPartElements.addFirst(results[1]);
          labelElements.add(results[0]);
        } else {
          // Starts a new line.
          final currentLineTextElement = createTextElement(currentLineString);
          labelElements.add(currentLineTextElement);
          labelPartElements.addFirst(currentElement);
        }
      }
    }
  }

  if (currentLineElements.isNotEmpty) {
    final currentLineString =
        currentLineElements.map((element) => element.text).join();

    final labelElement = createTextElement(currentLineString);
    labelElements.add(labelElement);
  }
  return labelElements;
}

/// Split label into two pieces, the first part should exactly fit into a
/// single line.
///
/// Returns a list of [TextElement] with length of 2.
List<TextElement> _splitLabel(
    String text, TextElement Function(String) createTextElement, num maxWidth) {
  var l = 0;
  var r = text.length - 1;
  var m = ((l + r) / 2).floor();

  while (l < r - 1) {
    final labelElement = createTextElement(text.substring(0, m));
    if (labelElement.measurement.horizontalSliceWidth < maxWidth) {
      l = m;
      m = ((l + r) / 2).floor();
    } else if (labelElement.measurement.horizontalSliceWidth == maxWidth) {
      l = m;
      break;
    } else {
      r = m;
      m = ((l + r) / 2).floor();
    }
  }

  return <TextElement>[
    createTextElement(text.substring(0, l)),
    createTextElement(text.substring(l, text.length))
  ];
}

/// Tests whether or not a given text element fits in the available space.
bool _doesLabelFit(bool allowLabelOverflow, TextElement textElement,
    num maxWidth, TextElement Function(String) createTextElement) {
  if (textElement.maxWidthStrategy != MaxWidthStrategy.ellipsize ||
      allowLabelOverflow) {
    return true;
  }

  // When allowLabelOverflow is disabled and maxWidthStrategy is ellipsize,
  // compares [textElement] width with [maxWidth].
  final ellipsizedText = textElement.text;
  final ellipsizedElementWidth = (createTextElement(ellipsizedText)
        ..textStyle = textElement.textStyle)
      .measurement
      .horizontalSliceWidth;

  return ellipsizedElementWidth <= maxWidth;
}

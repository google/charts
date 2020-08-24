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

import 'package:charts_common/common.dart';
import 'package:charts_common/src/common/text_element.dart';

/// This function breaks original [labelElement] into multiple
/// [TextElement] when [multiline] is true and the width of
/// [labelElement] is larger than [maxWidth], maximum height is
/// limited by [maxHeight]. Otherwise, ellipsize [labelElement] by
/// [maxWidth]
///
/// Returns a list of [TextElement] with given [textStyle].
const _defaultlabelDelimiter = ' ';

List<TextElement> wrapLabelLines(
    TextElement labelElement,
    GraphicsFactory graphicsFactory,
    num maxWidth,
    num maxHeight,
    bool multiline,
    {String labelDelimiter = _defaultlabelDelimiter}) {
  final textStyle = labelElement.textStyle;
  final textDirection = labelElement.textDirection;
  final labelLineHeight = labelElement.measurement.verticalSliceWidth;
  final maxLines = (maxHeight / labelLineHeight).floor();

  if (maxWidth.toInt() == 0 || maxLines == 0) return <TextElement>[];

  if (!multiline) {
    return [
      labelElement
        ..maxWidthStrategy = MaxWidthStrategy.ellipsize
        ..maxWidth = maxWidth.toInt()
    ];
  }

  final createTextElement =
      (String text) => graphicsFactory.createTextElement(text)
        ..textStyle = textStyle
        ..textDirection = textDirection;

  final delimiterElement = createTextElement(labelDelimiter);

  final delimiterElementWidth =
      delimiterElement.measurement.horizontalSliceWidth;

  final labelPartElements = Queue<TextElement>()
    ..addAll(labelElement.text.split(labelDelimiter).map(createTextElement));

  final labelElements = <TextElement>[];
  var currentLineElements = <TextElement>[];
  var currentLineNumber = 0;
  var currentWidth = 0.0;
  var newLine = true;

  while (labelPartElements.isNotEmpty && currentLineNumber < maxLines) {
    final currentElement = labelPartElements.removeFirst();
    if (newLine) {
      // New word can fit into a new line
      if (currentElement.measurement.horizontalSliceWidth <= maxWidth) {
        currentWidth = currentElement.measurement.horizontalSliceWidth;
        currentLineElements.add(currentElement);
        newLine = false;
      } else {
        currentLineNumber++;
        currentLineElements = [];
        currentWidth = 0;

        // If this is the last line, ellipsize the word
        if (currentLineNumber == maxLines) {
          labelElements.add(currentElement
            ..maxWidthStrategy = MaxWidthStrategy.ellipsize
            ..maxWidth = maxWidth.toInt());

          break;
        } else {
          // If this is not the last line, truncate the word into two pieces.
          final results =
              _splitLabel(currentElement.text, createTextElement, maxWidth);
          labelPartElements.addFirst(results[1]);
          labelElements.add(results[0]);
        }
      }
    } else {
      // If there are already words in the same line.
      var width = currentWidth +
          delimiterElementWidth +
          currentElement.measurement.horizontalSliceWidth;

      // If the new word can fit in the left space of the line.
      if (width < maxWidth) {
        currentWidth = width;
        currentLineElements.add(delimiterElement);
        currentLineElements.add(currentElement);
      } else {
        // If the new word can not fit in the left space of the line.
        var currentLineString = '';
        currentLineElements.forEach((element) {
          currentLineString += element.text;
        });
        currentLineNumber++;
        currentLineElements = [];
        currentWidth = 0;

        // If this is the last line, ellipsize the string of current line and
        // new word.
        if (currentLineNumber == maxLines) {
          currentLineString += labelDelimiter;
          currentLineString += currentElement.text;
          final truncatedLabelElement = createTextElement(currentLineString)
            ..maxWidthStrategy = MaxWidthStrategy.ellipsize
            ..maxWidth = maxWidth.toInt();

          labelElements.add(truncatedLabelElement);
          break;
        } else {
          // If this is not the last line, start a new line.
          final currentLineTextElement = createTextElement(currentLineString);
          labelElements.add(currentLineTextElement);
          labelPartElements.addFirst(currentElement);
        }
        newLine = true;
      }
    }
  }

  if (currentLineElements.isNotEmpty) {
    var currentLineString = '';
    currentLineElements.forEach((element) {
      currentLineString += element.text;
    });

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
    String text, Function createTextElement, num maxWidth) {
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

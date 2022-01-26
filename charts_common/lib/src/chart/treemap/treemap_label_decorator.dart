// Copyright 2019 the Charts project authors. Please see the AUTHORS file
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

import 'dart:math' show Rectangle, pi;

import 'package:charts_common/src/chart/cartesian/axis/spec/axis_spec.dart';
import 'package:charts_common/src/chart/common/chart_canvas.dart';
import 'package:charts_common/src/common/color.dart';
import 'package:charts_common/src/common/graphics_factory.dart';
import 'package:charts_common/src/common/text_element.dart';
import 'package:charts_common/src/common/text_style.dart';
import 'package:charts_common/src/common/text_utils.dart';
import 'package:charts_common/src/data/series.dart';

import 'treemap_renderer_decorator.dart';
import 'treemap_renderer_element.dart';

/// Decorator that renders label for treemap renderer element.
class TreeMapLabelDecorator<D> extends TreeMapRendererDecorator<D> {
  // Default configuration
  static const _defaultLabelPadding = 4;
  static const _defaultFontSize = 12;
  static final _defaultLabelStyle =
      TextStyleSpec(fontSize: _defaultFontSize, color: Color.black);

  /// Rotation value of 90 degrees clockwise.
  static const _90DegreeClockwise = pi / 2;

  /// Text style spec for labels.
  final TextStyleSpec labelStyleSpec;

  /// Padding of the label text.
  final int labelPadding;

  /// Whether or not to allow labels to draw outside of their bounding box.
  final bool allowLabelOverflow;

  /// Whether or not drawing a label in multiple lines if there is enough
  /// space.
  final bool enableMultiline;

  TreeMapLabelDecorator(
      {TextStyleSpec? labelStyleSpec,
      this.labelPadding = _defaultLabelPadding,
      this.allowLabelOverflow = true,
      this.enableMultiline = false})
      : labelStyleSpec = labelStyleSpec ?? _defaultLabelStyle;

  @override
  void decorate(TreeMapRendererElement<D> rendererElement, ChartCanvas canvas,
      GraphicsFactory graphicsFactory,
      {required Rectangle drawBounds,
      required double animationPercent,
      bool rtl = false,
      bool renderVertically = false,
      bool renderMultiline = false}) {
    // Decorates the renderer elements when animation is completed.
    if (animationPercent != 1.0) return;

    // Creates [TextStyle] from [TextStyleSpec] to be used by all the elements.
    // The [GraphicsFactory] is needed since it cannot be created earlier.
    final labelStyle = _asTextStyle(graphicsFactory, labelStyleSpec);

    final labelFn = rendererElement.series.labelAccessorFn;
    final datumIndex = rendererElement.index;
    final label = labelFn != null ? labelFn(datumIndex) : null;

    // Skips if this element has no label.
    if (label == null || label.isEmpty) return;

    // Uses datum specific label style if provided.
    final datumLabelStyle = _datumStyle(
        rendererElement.series.insideLabelStyleAccessorFn,
        datumIndex,
        graphicsFactory,
        defaultStyle: labelStyle);
    final rect = rendererElement.boundingRect;
    final labelElement = graphicsFactory.createTextElement(label)
      ..textStyle = datumLabelStyle
      ..textDirection = rtl ? TextDirection.rtl : TextDirection.ltr;
    final labelHeight = labelElement.measurement.verticalSliceWidth;
    final maxLabelHeight =
        (renderVertically ? rect.width : rect.height) - (labelPadding * 2);
    final maxLabelWidth =
        (renderVertically ? rect.height : rect.width) - (labelPadding * 2);
    final multiline = enableMultiline && renderMultiline;
    final parts = wrapLabelLines(
        labelElement, graphicsFactory, maxLabelWidth, maxLabelHeight,
        allowLabelOverflow: allowLabelOverflow, multiline: multiline);

    for (var index = 0; index < parts.length; index++) {
      final segment = _createLabelSegment(
          rect, labelHeight, parts[index], index,
          rtl: rtl, rotate: renderVertically);

      // Draws a label inside of a treemap renderer element.
      canvas.drawText(segment.text, segment.xOffet, segment.yOffset,
          rotation: segment.rotationAngle);
    }
  }

  /// Converts [TextStyleSpec] to [TextStyle].
  TextStyle _asTextStyle(
          GraphicsFactory graphicsFactory, TextStyleSpec labelSpec) =>
      graphicsFactory.createTextPaint()
        ..color = labelSpec.color ?? Color.black
        ..fontFamily = labelSpec.fontFamily
        ..fontSize = labelSpec.fontSize ?? _defaultFontSize
        ..lineHeight = labelSpec.lineHeight;

  /// Gets datum specific style.
  TextStyle _datumStyle(AccessorFn<TextStyleSpec>? labelStyleFn, int datumIndex,
      GraphicsFactory graphicsFactory,
      {required TextStyle defaultStyle}) {
    final styleSpec = labelStyleFn?.call(datumIndex);
    return (styleSpec != null)
        ? _asTextStyle(graphicsFactory, styleSpec)
        : defaultStyle;
  }

  _TreeMapLabelSegment _createLabelSegment(Rectangle elementBoundingRect,
      num labelHeight, TextElement labelElement, int position,
      {bool rtl = false, bool rotate = false}) {
    num xOffset;
    num yOffset;

    // Set x offset for each line.
    if (rotate) {
      xOffset = elementBoundingRect.right -
          labelPadding -
          2 * labelElement.textStyle!.fontSize! -
          labelHeight * position;
    } else if (rtl) {
      xOffset = elementBoundingRect.right - labelPadding;
    } else {
      xOffset = elementBoundingRect.left + labelPadding;
    }

    // Set y offset for each line.
    if (!rotate) {
      yOffset =
          elementBoundingRect.top + labelPadding + (labelHeight * position);
    } else if (rtl) {
      yOffset = elementBoundingRect.bottom - labelPadding;
    } else {
      yOffset = elementBoundingRect.top + labelPadding;
    }

    return _TreeMapLabelSegment(labelElement, xOffset.toInt(), yOffset.toInt(),
        rotate ? _90DegreeClockwise : 0.0);
  }
}

/// Represents a segment of a label that will be drawn in a single line.
class _TreeMapLabelSegment {
  /// Text to be drawn on the canvas.
  final TextElement text;

  /// x-coordinate offset for [text].
  final int xOffet;

  /// y-coordinate offset for [text].
  final int yOffset;

  /// Rotation angle for drawing [text].
  final double rotationAngle;

  _TreeMapLabelSegment(
      this.text, this.xOffet, this.yOffset, this.rotationAngle);
}

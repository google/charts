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

import 'dart:math' show Point, Rectangle, max;
import 'package:charts_common/common.dart' as common
    show
        ChartCanvas,
        CanvasBarStack,
        CanvasPie,
        Color,
        FillPatternType,
        StyleFactory,
        TextElement,
        TextDirection;
import 'package:flutter/material.dart';
import 'text_element.dart' show TextElement;
import 'canvas/circle_sector_painter.dart' show CircleSectorPainter;
import 'canvas/line_painter.dart' show LinePainter;
import 'canvas/pie_painter.dart' show PiePainter;
import 'canvas/point_painter.dart' show PointPainter;
import 'canvas/polygon_painter.dart' show PolygonPainter;

class ChartCanvas implements common.ChartCanvas {
  final Canvas canvas;
  final _paint = new Paint();

  CircleSectorPainter _circleSectorPainter;
  LinePainter _linePainter;
  PiePainter _piePainter;
  PointPainter _pointPainter;
  PolygonPainter _polygonPainter;

  ChartCanvas(this.canvas);

  @override
  void drawCircleSector(Point center, double radius, double innerRadius,
      double startAngle, double endAngle,
      {common.Color fill, common.Color stroke, double strokeWidthPx}) {
    _circleSectorPainter ??= new CircleSectorPainter();
    _circleSectorPainter.draw(
        canvas: canvas,
        paint: _paint,
        center: center,
        radius: radius,
        innerRadius: innerRadius,
        startAngle: startAngle,
        endAngle: endAngle,
        fill: fill,
        stroke: stroke,
        strokeWidthPx: strokeWidthPx);
  }

  @override
  void drawLine(
      {List<Point> points,
      Rectangle<num> clipBounds,
      common.Color fill,
      common.Color stroke,
      bool smoothLine,
      bool roundEndCaps,
      double strokeWidthPx,
      List<int> dashPattern}) {
    _linePainter ??= new LinePainter();
    _linePainter.draw(
        canvas: canvas,
        paint: _paint,
        points: points,
        clipBounds: clipBounds,
        fill: fill,
        stroke: stroke,
        smoothLine: smoothLine,
        roundEndCaps: roundEndCaps,
        strokeWidthPx: strokeWidthPx,
        dashPattern: dashPattern);
  }

  @override
  void drawPie(common.CanvasPie canvasPie) {
    _piePainter ??= new PiePainter();
    _piePainter.draw(canvas, _paint, canvasPie);
  }

  @override
  void drawPoint(
      {Point point,
      double radius,
      common.Color fill,
      common.Color stroke,
      double strokeWidthPx}) {
    _pointPainter ??= new PointPainter();
    _pointPainter.draw(
        canvas: canvas,
        paint: _paint,
        point: point,
        radius: radius,
        fill: fill,
        stroke: stroke,
        strokeWidthPx: strokeWidthPx);
  }

  @override
  void drawPolygon(
      {List<Point> points,
      Rectangle<num> clipBounds,
      common.Color fill,
      common.Color stroke,
      double strokeWidthPx}) {
    _polygonPainter ??= new PolygonPainter();
    _polygonPainter.draw(
        canvas: canvas,
        paint: _paint,
        points: points,
        clipBounds: clipBounds,
        fill: fill,
        stroke: stroke,
        strokeWidthPx: strokeWidthPx);
  }

  @override
  void drawRect(Rectangle<num> bounds,
      {common.Color fill,
      common.FillPatternType pattern,
      common.Color stroke,
      double strokeWidthPx}) {
    final drawStroke =
        (strokeWidthPx != null && strokeWidthPx > 0.0 && stroke != null);

    final strokeWidthOffset = (drawStroke ? strokeWidthPx : 0);

    // Factor out stroke width, if a stroke is enabled.
    final myBounds = new Rectangle<num>(
        bounds.left + strokeWidthOffset / 2,
        bounds.top + strokeWidthOffset / 2,
        bounds.width - strokeWidthOffset,
        bounds.height - strokeWidthOffset);

    switch (pattern) {
      case common.FillPatternType.forwardHatch:
        _drawForwardHatchPattern(myBounds, canvas, fill: fill);
        break;

      case common.FillPatternType.solid:
      default:
        // Use separate rect for drawing stroke
        _paint.color = new Color.fromARGB(fill.a, fill.r, fill.g, fill.b);
        _paint.style = PaintingStyle.fill;

        canvas.drawRect(_getRect(myBounds), _paint);
        break;
    }

    // [Canvas.drawRect] does not support drawing a rectangle with both a fill
    // and a stroke at this time. Use a separate rect for the stroke.
    if (drawStroke) {
      _paint.color = new Color.fromARGB(stroke.a, stroke.r, stroke.g, stroke.b);
      _paint.strokeJoin = StrokeJoin.round;
      _paint.strokeWidth = strokeWidthPx;
      _paint.style = PaintingStyle.stroke;

      canvas.drawRect(_getRect(myBounds), _paint);
    }
  }

  @override
  void drawRRect(Rectangle<num> bounds,
      {common.Color fill,
      common.Color stroke,
      num radius,
      bool roundTopLeft,
      bool roundTopRight,
      bool roundBottomLeft,
      bool roundBottomRight}) {
    // Use separate rect for drawing stroke
    _paint.color = new Color.fromARGB(fill.a, fill.r, fill.g, fill.b);
    _paint.style = PaintingStyle.fill;

    canvas.drawRRect(
        _getRRect(bounds,
            radius: radius,
            roundTopLeft: roundTopLeft,
            roundTopRight: roundTopRight,
            roundBottomLeft: roundBottomLeft,
            roundBottomRight: roundBottomRight),
        _paint);
  }

  @override
  void drawBarStack(common.CanvasBarStack barStack) {
    // only clip if rounded rect.

    // Clip a rounded rect for the whole region if rounded bars.
    final roundedCorners = 0 < barStack.radius;

    if (roundedCorners) {
      canvas
        ..save()
        ..clipRRect(_getRRect(
          barStack.fullStackRect,
          radius: barStack.radius.toDouble(),
          roundTopLeft: barStack.roundTopLeft,
          roundTopRight: barStack.roundTopRight,
          roundBottomLeft: barStack.roundBottomLeft,
          roundBottomRight: barStack.roundBottomRight,
        ));
    }

    // Draw each bar.
    for (var barIndex = 0; barIndex < barStack.segments.length; barIndex++) {
      // TODO: Add configuration for hiding stack line.
      // TODO: Don't draw stroke on bottom of bars.
      final segment = barStack.segments[barIndex];
      drawRect(segment.bounds,
          fill: segment.fill,
          pattern: segment.pattern,
          stroke: segment.stroke,
          strokeWidthPx: segment.strokeWidthPx);
    }

    if (roundedCorners) {
      canvas.restore();
    }
  }

  @override
  void drawText(common.TextElement textElement, int offsetX, int offsetY,
      {double rotation = 0.0}) {
    // Must be Flutter TextElement.
    assert(textElement is TextElement);

    final flutterTextElement = textElement as TextElement;
    final textDirection = flutterTextElement.textDirection;
    final measurement = flutterTextElement.measurement;

    if (rotation != 0) {
      // TODO: Remove once textAnchor works.
      if (textDirection == common.TextDirection.rtl) {
        offsetY += measurement.horizontalSliceWidth.toInt();
      }

      offsetX -= flutterTextElement.verticalFontShift;

      canvas.save();
      canvas.translate(offsetX.toDouble(), offsetY.toDouble());
      canvas.rotate(rotation);

      (textElement as TextElement)
          .textPainter
          .paint(canvas, new Offset(0.0, 0.0));

      canvas.restore();
    } else {
      // TODO: Remove once textAnchor works.
      if (textDirection == common.TextDirection.rtl) {
        offsetX -= measurement.horizontalSliceWidth.toInt();
      }

      // Account for missing center alignment.
      if (textDirection == common.TextDirection.center) {
        offsetX -= (measurement.horizontalSliceWidth / 2).ceil();
      }

      offsetY -= flutterTextElement.verticalFontShift;

      (textElement as TextElement)
          .textPainter
          .paint(canvas, new Offset(offsetX.toDouble(), offsetY.toDouble()));
    }
  }

  @override
  void setClipBounds(Rectangle<int> clipBounds) {
    canvas
      ..save()
      ..clipRect(_getRect(clipBounds));
  }

  @override
  void resetClipBounds() {
    canvas.restore();
  }

  /// Convert dart:math [Rectangle] to Flutter [Rect].
  Rect _getRect(Rectangle<num> rectangle) {
    return new Rect.fromLTWH(
        rectangle.left.toDouble(),
        rectangle.top.toDouble(),
        rectangle.width.toDouble(),
        rectangle.height.toDouble());
  }

  /// Convert dart:math [Rectangle] and to Flutter [RRect].
  RRect _getRRect(
    Rectangle<num> rectangle, {
    double radius,
    bool roundTopLeft = false,
    bool roundTopRight = false,
    bool roundBottomLeft = false,
    bool roundBottomRight = false,
  }) {
    final cornerRadius =
        radius == 0 ? Radius.zero : new Radius.circular(radius);

    return new RRect.fromLTRBAndCorners(
        rectangle.left.toDouble(),
        rectangle.top.toDouble(),
        rectangle.right.toDouble(),
        rectangle.bottom.toDouble(),
        topLeft: roundTopLeft ? cornerRadius : Radius.zero,
        topRight: roundTopRight ? cornerRadius : Radius.zero,
        bottomLeft: roundBottomLeft ? cornerRadius : Radius.zero,
        bottomRight: roundBottomRight ? cornerRadius : Radius.zero);
  }

  /// Draws a forward hatch pattern in the given bounds.
  _drawForwardHatchPattern(
    Rectangle<num> bounds,
    Canvas canvas, {
    common.Color background,
    common.Color fill,
    double fillWidthPx = 4.0,
  }) {
    background ??= common.StyleFactory.style.white;
    fill ??= common.StyleFactory.style.black;

    // Fill in the shape with a solid background color.
    _paint.color = new Color.fromARGB(
        background.a, background.r, background.g, background.b);
    _paint.style = PaintingStyle.fill;
    canvas.drawRect(_getRect(bounds), _paint);

    // As a simplification, we will treat the bounds as a large square and fill
    // it up with lines from the bottom-left corner to the top-right corner.
    // Get the longer side of the bounds here for the size of this square.
    final size = max(bounds.width, bounds.height);

    final x0 = bounds.left + size + fillWidthPx;
    final x1 = bounds.left - fillWidthPx;
    final y0 = bounds.bottom - size - fillWidthPx;
    final y1 = bounds.bottom + fillWidthPx;
    final offset = 8;

    final isVertical = bounds.height >= bounds.width;

    _linePainter ??= new LinePainter();

    // The "first" line segment will be drawn from the bottom left corner of the
    // bounds, up and towards the right. Start the loop N iterations "back" to
    // draw partial line segments beneath (or to the left) of this segment,
    // where N is the number of offsets that fit inside the smaller dimension of
    // the bounds.
    final smallSide = isVertical ? bounds.width : bounds.height;
    final start = -(smallSide / offset).round() * offset;

    // Keep going until we reach the top or right of the bounds, depending on
    // whether the rectangle is oriented vertically or horizontally.
    final end = size + offset;

    for (int i = start; i < end; i = i + offset) {
      // For vertical bounds, we need to draw lines from top to bottom. For
      // bounds, we need to draw lines from left to right.
      final modifier = isVertical ? -1 * i : i;

      // Draw a line segment in the bottom right corner of the pattern.
      _linePainter.draw(
          canvas: canvas,
          paint: _paint,
          points: [
            new Point(x0 + modifier, y0),
            new Point(x1 + modifier, y1),
          ],
          stroke: fill,
          strokeWidthPx: fillWidthPx);
    }
  }

  @override
  set drawingView(String viewName) {}
}

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
import 'package:charts_common/common.dart' as common
    show ChartCanvas, Color, SymbolRenderer, RoundedRectSymbolRenderer;
import 'package:flutter/widgets.dart';
import 'chart_canvas.dart' show ChartCanvas;

// TODO: Add line symbol renderer for line charts.

/// Strategy for rendering a symbol.
abstract class SymbolRenderer implements common.SymbolRenderer {
  /// Used by Charts Flutter library implementation only.
  ///
  /// Used by SymbolRenderers that wrap a common symbol renderer.
  @override
  void paint(
      common.ChartCanvas canvas, Rectangle<int> bounds, common.Color color) {}

  /// Used by Charts Flutter library implementation only.
  ///
  /// Used by SymbolRenderers that wrap a common symbol renderer.
  @override
  bool shouldRepaint(covariant common.SymbolRenderer oldRenderer) => false;

  /// Build a symbol widget.
  ///
  /// [size] suggested size of the symbol provided by [LegendEntryLayout].
  /// [color] color of the legend entry.
  Widget build(BuildContext context, {Size size, Color color});
}

class RoundedRectSymbolRenderer extends common.RoundedRectSymbolRenderer
    implements SymbolRenderer {
  RoundedRectSymbolRenderer({double radius}) : super(radius: radius);

  @override
  Widget build(BuildContext context, {Size size, Color color}) {
    return new SizedBox.fromSize(
        size: size,
        child: new CustomPaint(painter: new _SymbolCustomPaint(this, color)));
  }
}

class _SymbolCustomPaint extends CustomPainter {
  final common.SymbolRenderer symbolRenderer;
  final Color color;

  _SymbolCustomPaint(this.symbolRenderer, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final bounds =
        new Rectangle<int>(0, 0, size.width.toInt(), size.height.toInt());
    final commonColor = new common.Color(
        r: color.red, g: color.green, b: color.blue, a: color.alpha);
    symbolRenderer.paint(new ChartCanvas(canvas), bounds, commonColor);
  }

  @override
  bool shouldRepaint(_SymbolCustomPaint oldDelegate) {
    return symbolRenderer.shouldRepaint(oldDelegate.symbolRenderer);
  }
}

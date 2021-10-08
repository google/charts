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

import 'dart:math' show Rectangle;

import 'package:charts_common/src/chart/common/chart_canvas.dart';
import 'package:charts_common/src/common/graphics_factory.dart';

import 'treemap_renderer_element.dart';

/// Decorator that gets rendered after [TreeMapRendererElement]s are rendered.
abstract class TreeMapRendererDecorator<D> {
  const TreeMapRendererDecorator();

  /// Paints decorator on top of [rendererElement].
  void decorate(TreeMapRendererElement<D> rendererElement, ChartCanvas canvas,
      GraphicsFactory graphicsFactory,
      {required Rectangle drawBounds,
      required double animationPercent,
      bool rtl = false,
      bool renderVertically = false,
      bool renderMultiline = false});
}

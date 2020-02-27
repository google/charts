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
import 'package:charts_common/src/chart/common/processed_series.dart';
import 'package:charts_common/src/common/color.dart';

/// A renderer element that represents a TreeNode.
class TreeMapRendererElement<D> {
  /// Bounding rectangle of this element.
  Rectangle boundingRect;

  /// Occupied area of this element in pixel.
  num area;

  /// Fill color of this element.
  Color fillColor;

  /// Fill pattern of the background of the treemap rectangle.
  FillPatternType fillPattern;

  /// Pattern color of this element.
  Color patternColor;

  /// Stroke color of this element.
  Color strokeColor;

  /// Whether this element is a leaf in the treemap.
  bool isLeaf;

  /// Stroke width of this element.
  num strokeWidthPx;

  /// Associated index in the [series].
  int index;

  /// Original series.
  ImmutableSeries<D> series;

  /// Domain of this element.
  D domain;

  /// Measure of this element.
  num measure;

  /// Clones a new renderer element with the same properties.
  TreeMapRendererElement<D> clone() => TreeMapRendererElement()
    ..boundingRect =
        Rectangle.fromPoints(boundingRect.topLeft, boundingRect.bottomRight)
    ..area = area
    ..fillPattern = fillPattern
    ..fillColor = Color.fromOther(color: fillColor)
    ..patternColor = Color.fromOther(color: patternColor)
    ..strokeColor = Color.fromOther(color: strokeColor)
    ..strokeWidthPx = strokeWidthPx
    ..isLeaf = isLeaf
    ..index = index
    ..series = series
    ..domain = domain
    ..measure = measure;

  /// Refreshes paint properties by invoking series accessor functions again.
  ///
  /// This is useful when series accessor functions are updated by behaviors
  /// and redraw of this element is triggered.
  void refreshPaintProperties() {
    strokeColor = series.colorFn(index);
    strokeWidthPx = series.strokeWidthPxFn(index);
    fillColor = series.fillColorFn(index);
    fillPattern = series.fillPatternFn == null
        ? FillPatternType.solid
        : series.fillPatternFn(index);
    patternColor = series.patternColorFn(index);
  }

  /// Updates properties of this element based on [animationPercent].
  ///
  /// Used when animation is in progress.
  void updateAnimationPercent(TreeMapRendererElement<D> previous,
      TreeMapRendererElement<D> target, double animationPercent) {
    // TODO: Implements animation based on animationPercent.
    boundingRect = target.boundingRect;
    area = target.area;
  }

  @override
  String toString() =>
      '$runtimeType' +
      {
        'boundingRect': boundingRect,
        'area': area,
        'strokeColor': strokeColor,
        'strokeWidthPx': strokeWidthPx,
        'fillColor': fillColor,
        'fillPattern': fillPattern,
        'patternColor': patternColor,
        'isLeaf': isLeaf,
        'index': index,
        'domain': domain,
        'measure': measure,
      }.toString();
}

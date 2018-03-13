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
import 'package:meta/meta.dart';

import '../../common/graphics_factory.dart' show GraphicsFactory;
import '../common/chart_canvas.dart' show ChartCanvas;

/// Position of a [LayoutView].
enum LayoutPosition {
  Bottom,
  FullBottom,

  Top,
  FullTop,

  Left,
  FullLeft,

  Right,
  FullRight,

  DrawArea,
}

/// A configuration for margin (empty space) around a layout child view.
class ViewMargin {
  /// A [ViewMargin] with all zero px.
  static const empty =
      const ViewMargin(topPx: 0, bottomPx: 0, rightPx: 0, leftPx: 0);

  final int topPx;
  final int bottomPx;
  final int rightPx;
  final int leftPx;

  const ViewMargin({int topPx, int bottomPx, int rightPx, int leftPx})
      : topPx = topPx ?? 0,
        bottomPx = bottomPx ?? 0,
        rightPx = rightPx ?? 0,
        leftPx = leftPx ?? 0;

  /// Total width.
  int get width => leftPx + rightPx;

  /// Total height.
  int get height => topPx + bottomPx;
}

/// Configuration of an [LayoutView].
class LayoutViewConfig {
  String id;

  /// The position of a [LayoutView] defining where to place the view.
  LayoutPosition position;

  /// The order to place and draw the [LayoutView].
  ///
  /// The smaller number is closer to the draw area.
  int positionOrder;

  /// Defines the space around a layout component.
  ViewMargin viewMargin;

  /// Creates new [LayoutParams].
  ///
  /// [position] the [ComponentPosition] of this component.
  /// [positionOrder] the smaller the p
  LayoutViewConfig(
      {@required this.position,
      @required this.positionOrder,
      ViewMargin viewMargin})
      : viewMargin = viewMargin ?? ViewMargin.empty;

  /// Returns true if it is a full position.
  bool get isFullPosition =>
      position == LayoutPosition.FullBottom ||
      position == LayoutPosition.FullTop ||
      position == LayoutPosition.FullRight ||
      position == LayoutPosition.FullLeft;
}

/// Size measurements of one component.
///
/// The measurement is tight to the component, without adding [ComponentBuffer].
class ViewMeasuredSizes {
  /// All zeroes component size.
  static const zero = const ViewMeasuredSizes(
      preferredWidth: 0, preferredHeight: 0, minWidth: 0, minHeight: 0);

  final int preferredWidth;
  final int preferredHeight;
  final int minWidth;
  final int minHeight;

  /// Create a new [ViewSizes].
  ///
  /// [preferredWidth] the component's preferred width.
  /// [preferredHeight] the component's preferred width.
  /// [minWidth] the component's minimum width. If not set, default to 0.
  /// [minHeight] the component's minimum height. If not set, default to 0.
  const ViewMeasuredSizes(
      {@required int preferredWidth,
      @required int preferredHeight,
      int minWidth,
      int minHeight})
      : preferredWidth = preferredWidth,
        preferredHeight = preferredHeight,
        minWidth = minWidth ?? 0,
        minHeight = minHeight ?? 0;
}

/// A component that measures its size and accepts bounds to complete layout.
abstract class LayoutView {
  GraphicsFactory get graphicsFactory;

  set graphicsFactory(GraphicsFactory value);

  /// Layout params for this component.
  LayoutViewConfig get layoutConfig;

  /// Measure and return the size of this component.
  ///
  /// This measurement is without the [ComponentBuffer], which is added by the
  /// layout manager.
  ViewMeasuredSizes measure(int maxWidth, int maxHeight);

  /// Layout this component.
  void layout(Rectangle<int> componentBounds, Rectangle<int> drawAreaBounds);

  void paint(ChartCanvas canvas, double animationPercent);

  Rectangle<int> get componentBounds;
}

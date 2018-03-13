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

import 'package:meta/meta.dart' show required;
import 'dart:math' show Point, Rectangle, max;
import 'layout_view.dart' show LayoutView, LayoutPosition;
import 'layout_config.dart' show LayoutConfig;
import 'layout_manager.dart';
import 'layout_margin_strategy.dart';

/// Default Layout manager for [LayoutView]s.
class LayoutManagerImpl implements LayoutManager {
  static const _minDrawWidth = 20;
  static const _minDrawHeight = 20;

  // Allow [Layoutconfig] to be mutable so it can be modified without requiring
  // a new copy of [DefaultLayoutManager] to be created.
  LayoutConfig config;

  final _views = <LayoutView>[];

  _MeasuredSizes _measurements;

  Rectangle<int> _drawAreaBounds;
  bool _drawAreaBoundsOutdated = true;
  bool _viewsNeedSort = true;

  /// Create a new [LayoutManager].
  LayoutManagerImpl({LayoutConfig config})
      : this.config = config ?? new LayoutConfig();

  /// Add one [LayoutView].
  void addView(LayoutView view) {
    _views.add(view);
    _drawAreaBoundsOutdated = true;
    _viewsNeedSort = true;
  }

  /// Remove one [LayoutView].
  void removeView(LayoutView view) {
    if (_views.remove(view)) {
      _drawAreaBoundsOutdated = true;
      _viewsNeedSort = true;
    }
  }

  /// Returns true if [view] is already attached.
  bool isAttached(LayoutView view) => _views.contains(view);

  /// Get all layout components in the order to be visited/drawn.
  @override
  List<LayoutView> get paintOrderedViews {
    if (_viewsNeedSort) {
      // In place sort the views.
      _views.sort((LayoutView v1, LayoutView v2) => v1
          .layoutConfig.positionOrder
          .compareTo(v2.layoutConfig.positionOrder));
      _viewsNeedSort = false;
    }
    return _views;
  }

  @override
  Rectangle<int> get drawAreaBounds {
    assert(_drawAreaBoundsOutdated == false);
    return _drawAreaBounds;
  }

  @override
  withinDrawArea(Point<num> point) {
    return _drawAreaBounds.containsPoint(point);
  }

  /// Measure and layout with given [width] and [height].
  @override
  void measure(int width, int height) {
    var topViews =
        _viewsForPositions(LayoutPosition.Top, LayoutPosition.FullTop);
    var rightViews =
        _viewsForPositions(LayoutPosition.Right, LayoutPosition.FullRight);
    var bottomViews =
        _viewsForPositions(LayoutPosition.Bottom, LayoutPosition.FullBottom);
    var leftViews =
        _viewsForPositions(LayoutPosition.Left, LayoutPosition.FullLeft);

    // Assume the full width and height of the chart is available when measuring
    // for the first time but adjust the maximum if margin spec is set.
    var measurements = _measure(width, height,
        topViews: topViews,
        rightViews: rightViews,
        bottomViews: bottomViews,
        leftViews: leftViews,
        useMax: true);

    // Measure a second time but pass in the preferred width and height from
    // the first measure cycle.
    // Allow views to report a different size than the previously measured max.
    final secondMeasurements = _measure(width, height,
        topViews: topViews,
        rightViews: rightViews,
        bottomViews: bottomViews,
        leftViews: leftViews,
        previousMeasurements: measurements,
        useMax: true);

    // If views need more space with the 2nd pass, perform a third pass.
    if (measurements.leftWidth != secondMeasurements.leftWidth ||
        measurements.rightWidth != secondMeasurements.rightWidth ||
        measurements.topHeight != secondMeasurements.topHeight ||
        measurements.bottomHeight != secondMeasurements.bottomHeight) {
      final thirdMeasurements = _measure(width, height,
          topViews: topViews,
          rightViews: rightViews,
          bottomViews: bottomViews,
          leftViews: leftViews,
          previousMeasurements: secondMeasurements,
          useMax: false);

      measurements = thirdMeasurements;
    } else {
      measurements = secondMeasurements;
    }

    _measurements = measurements;

    // Draw area size.
    // Set to a minimum size if there is not enough space for the draw area.
    // Prevents the app from crashing by rendering overlapping content instead.
    final drawAreaWidth = max(
      _minDrawWidth,
      (width - measurements.leftWidth - measurements.rightWidth),
    );
    final drawAreaHeight = max(
      _minDrawHeight,
      (height - measurements.bottomHeight - measurements.topHeight),
    );

    // Bounds for the draw area.
    _drawAreaBounds = new Rectangle(measurements.leftWidth,
        measurements.topHeight, drawAreaWidth, drawAreaHeight);
    _drawAreaBoundsOutdated = false;
  }

  @override
  void layout(int width, int height) {
    var topViews =
        _viewsForPositions(LayoutPosition.Top, LayoutPosition.FullTop);
    var rightViews =
        _viewsForPositions(LayoutPosition.Right, LayoutPosition.FullRight);
    var bottomViews =
        _viewsForPositions(LayoutPosition.Bottom, LayoutPosition.FullBottom);
    var leftViews =
        _viewsForPositions(LayoutPosition.Left, LayoutPosition.FullLeft);
    var drawAreaViews = _viewsForPositions(LayoutPosition.DrawArea);

    final fullBounds = new Rectangle(0, 0, width, height);

    // Layout the margins.
    new LeftMarginLayoutStrategy()
        .layout(leftViews, _measurements.leftSizes, fullBounds, drawAreaBounds);
    new RightMarginLayoutStrategy().layout(
        rightViews, _measurements.rightSizes, fullBounds, drawAreaBounds);
    new BottomMarginLayoutStrategy().layout(
        bottomViews, _measurements.bottomSizes, fullBounds, drawAreaBounds);
    new TopMarginLayoutStrategy()
        .layout(topViews, _measurements.topSizes, fullBounds, drawAreaBounds);

    // Layout the drawArea.
    drawAreaViews.forEach(
        (LayoutView view) => view.layout(_drawAreaBounds, _drawAreaBounds));
  }

  Iterable<LayoutView> _viewsForPositions(LayoutPosition p1,
      [LayoutPosition p2]) {
    return paintOrderedViews.where((LayoutView view) =>
        (view.layoutConfig.position == p1 ||
            (p2 != null && view.layoutConfig.position == p2)));
  }

  /// Measure and return size measurements.
  /// [width] full width of chart
  /// [height] full height of chart
  _MeasuredSizes _measure(
    int width,
    int height, {
    Iterable<LayoutView> topViews,
    Iterable<LayoutView> rightViews,
    Iterable<LayoutView> bottomViews,
    Iterable<LayoutView> leftViews,
    _MeasuredSizes previousMeasurements,
    @required bool useMax,
  }) {
    final maxLeftWidth = config.leftSpec.getMaxPixels(width);
    final maxRightWidth = config.rightSpec.getMaxPixels(width);
    final maxBottomHeight = config.bottomSpec.getMaxPixels(height);
    final maxTopHeight = config.topSpec.getMaxPixels(height);

    // Assume the full width and height of the chart is available when measuring
    // for the first time but adjust the maximum if margin spec is set.
    var leftWidth = previousMeasurements?.leftWidth ?? maxLeftWidth;
    var rightWidth = previousMeasurements?.rightWidth ?? maxRightWidth;
    var bottomHeight = previousMeasurements?.bottomHeight ?? maxBottomHeight;
    var topHeight = previousMeasurements?.topHeight ?? maxTopHeight;

    // Only adjust the height if we have previous measurements.
    final adjustedHeight = (previousMeasurements != null)
        ? height - bottomHeight - topHeight
        : height;

    var leftSizes = new LeftMarginLayoutStrategy().measure(leftViews,
        maxWidth: useMax ? maxLeftWidth : leftWidth,
        height: adjustedHeight,
        fullHeight: height);

    leftWidth = max(leftSizes.total, config.leftSpec.getMinPixels(width));

    var rightSizes = new RightMarginLayoutStrategy().measure(rightViews,
        maxWidth: useMax ? maxRightWidth : rightWidth,
        height: adjustedHeight,
        fullHeight: height);
    rightWidth = max(rightSizes.total, config.rightSpec.getMinPixels(width));

    final adjustedWidth = width - leftWidth - rightWidth;

    var bottomSizes = new BottomMarginLayoutStrategy().measure(bottomViews,
        maxHeight: useMax ? maxBottomHeight : bottomHeight,
        width: adjustedWidth,
        fullWidth: width);
    bottomHeight = max(bottomSizes.total, config.topSpec.getMinPixels(height));

    var topSizes = new TopMarginLayoutStrategy().measure(topViews,
        maxHeight: useMax ? maxTopHeight : topHeight,
        width: adjustedWidth,
        fullWidth: width);
    topHeight = max(topSizes.total, config.topSpec.getMinPixels(height));

    return new _MeasuredSizes(
        leftWidth: leftWidth,
        leftSizes: leftSizes,
        rightWidth: rightWidth,
        rightSizes: rightSizes,
        topHeight: topHeight,
        topSizes: topSizes,
        bottomHeight: bottomHeight,
        bottomSizes: bottomSizes);
  }

  @override
  void applyToViews(void apply(LayoutView view)) {
    _views.forEach((view) => apply(view));
  }
}

/// Helper class that stores measured width and height during measure cycles.
class _MeasuredSizes {
  final int leftWidth;
  final SizeList leftSizes;

  final int rightWidth;
  final SizeList rightSizes;

  final int topHeight;
  final SizeList topSizes;

  final int bottomHeight;
  final SizeList bottomSizes;

  _MeasuredSizes(
      {this.leftWidth,
      this.leftSizes,
      this.rightWidth,
      this.rightSizes,
      this.topHeight,
      this.topSizes,
      this.bottomHeight,
      this.bottomSizes});
}

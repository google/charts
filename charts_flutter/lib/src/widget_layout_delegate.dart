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

import 'dart:ui' show Offset;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'behaviors/chart_behavior.dart'
    show
        BuildableBehavior,
        BuildablePosition,
        InsideJustification,
        OutsideJustification;

/// Layout delegate that layout chart widget with [BuildableBehavior] widgets.
class WidgetLayoutDelegate extends MultiChildLayoutDelegate {
  /// ID of the common chart widget.
  final String chartID;

  /// Directionality of the widget.
  final isRTL;

  /// ID and [BuildableBehavior] of the widgets for calculating offset.
  final Map<String, BuildableBehavior> idAndBehavior;

  WidgetLayoutDelegate(this.chartID, this.idAndBehavior, this.isRTL);

  @override
  void performLayout(Size size) {
    // TODO: Change this to a layout manager that supports more
    // than one buildable behavior that changes chart size. Remove assert when
    // this is possible.
    assert(idAndBehavior.keys.isEmpty || idAndBehavior.keys.length == 1);

    // Size available for the chart widget.
    var availableWidth = size.width;
    var availableHeight = size.height;
    var chartOffset = Offset.zero;

    // Measure the first buildable behavior.
    final behaviorID =
        idAndBehavior.keys.isNotEmpty ? idAndBehavior.keys.first : null;
    var behaviorSize = Size.zero;
    if (behaviorID != null) {
      if (hasChild(behaviorID)) {
        final leftPosition =
            isRTL ? BuildablePosition.end : BuildablePosition.start;
        final rightPosition =
            isRTL ? BuildablePosition.start : BuildablePosition.end;
        final behaviorPosition = idAndBehavior[behaviorID].position;

        behaviorSize = layoutChild(behaviorID, new BoxConstraints.loose(size));
        if (behaviorPosition == BuildablePosition.top) {
          chartOffset = new Offset(0.0, behaviorSize.height);
          availableHeight -= behaviorSize.height;
        } else if (behaviorPosition == BuildablePosition.bottom) {
          availableHeight -= behaviorSize.height;
        } else if (behaviorPosition == leftPosition) {
          chartOffset = new Offset(behaviorSize.width, 0.0);
          availableWidth -= behaviorSize.width;
        } else if (behaviorPosition == rightPosition) {
          availableWidth -= behaviorSize.width;
        }
      }
    }

    // Layout chart.
    final chartSize = new Size(availableWidth, availableHeight);
    if (hasChild(chartID)) {
      layoutChild(chartID, new BoxConstraints.tight(chartSize));
      positionChild(chartID, chartOffset);
    }

    // Position buildable behavior.
    if (behaviorID != null) {
      // TODO: Unable to relayout with new smaller width.
      // In the delegate, all children are required to have layout called
      // exactly once.
      final behaviorOffset = _getBehaviorOffset(idAndBehavior[behaviorID],
          behaviorSize: behaviorSize, chartSize: chartSize, isRTL: isRTL);

      positionChild(behaviorID, behaviorOffset);
    }
  }

  @override
  bool shouldRelayout(MultiChildLayoutDelegate oldDelegate) {
    // TODO: Deep equality check because the instance will not be
    // the same on each build, even if the buildable behavior has not changed.
    return idAndBehavior != (oldDelegate as WidgetLayoutDelegate).idAndBehavior;
  }

  // Calculate buildable behavior's offset.
  Offset _getBehaviorOffset(BuildableBehavior behavior,
      {Size behaviorSize, Size chartSize, bool isRTL}) {
    Offset behaviorOffset;

    final behaviorPosition = behavior.position;
    final outsideJustification = behavior.outsideJustification;
    final insideJustification = behavior.insideJustification;

    if (behaviorPosition == BuildablePosition.top ||
        behaviorPosition == BuildablePosition.bottom) {
      final heightOffset =
          behaviorPosition == BuildablePosition.bottom ? chartSize.height : 0.0;

      final horizontalJustification =
          getOutsideJustification(outsideJustification, isRTL);

      switch (horizontalJustification) {
        case _HorizontalJustification.leftDrawArea:
          behaviorOffset =
              new Offset(behavior.drawAreaBounds.left.toDouble(), heightOffset);
          break;
        case _HorizontalJustification.left:
          behaviorOffset = new Offset(0.0, heightOffset);
          break;
        case _HorizontalJustification.rightDrawArea:
          behaviorOffset = new Offset(
              behavior.drawAreaBounds.right - behaviorSize.width, heightOffset);
          break;
        case _HorizontalJustification.right:
          behaviorOffset =
              new Offset(chartSize.width - behaviorSize.width, heightOffset);
          break;
      }
    } else if (behaviorPosition == BuildablePosition.start ||
        behaviorPosition == BuildablePosition.end) {
      final widthOffset =
          (isRTL && behaviorPosition == BuildablePosition.start) ||
                  (!isRTL && behaviorPosition == BuildablePosition.end)
              ? chartSize.width
              : 0.0;

      switch (outsideJustification) {
        case OutsideJustification.startDrawArea:
          behaviorOffset =
              new Offset(widthOffset, behavior.drawAreaBounds.top.toDouble());
          break;
        case OutsideJustification.start:
          behaviorOffset = new Offset(widthOffset, 0.0);
          break;
        case OutsideJustification.endDrawArea:
          behaviorOffset = new Offset(widthOffset,
              behavior.drawAreaBounds.bottom - behaviorSize.height);
          break;
        case OutsideJustification.end:
          behaviorOffset =
              new Offset(widthOffset, chartSize.height - behaviorSize.height);
          break;
      }
    } else if (behaviorPosition == BuildablePosition.inside) {
      var rightOffset = new Offset(chartSize.width - behaviorSize.width, 0.0);

      switch (insideJustification) {
        case InsideJustification.topStart:
          behaviorOffset = isRTL ? rightOffset : Offset.zero;
          break;
        case InsideJustification.topEnd:
          behaviorOffset = isRTL ? Offset.zero : rightOffset;
          break;
      }
    }

    return behaviorOffset;
  }

  _HorizontalJustification getOutsideJustification(
      OutsideJustification justification, bool isRTL) {
    _HorizontalJustification mappedJustification;

    switch (justification) {
      case OutsideJustification.startDrawArea:
        mappedJustification = isRTL
            ? _HorizontalJustification.rightDrawArea
            : _HorizontalJustification.leftDrawArea;
        break;
      case OutsideJustification.start:
        mappedJustification = isRTL
            ? _HorizontalJustification.right
            : _HorizontalJustification.left;
        break;
      case OutsideJustification.endDrawArea:
        mappedJustification = isRTL
            ? _HorizontalJustification.leftDrawArea
            : _HorizontalJustification.rightDrawArea;
        break;
      case OutsideJustification.end:
        mappedJustification = isRTL
            ? _HorizontalJustification.left
            : _HorizontalJustification.right;
        break;
    }

    return mappedJustification;
  }
}

enum _HorizontalJustification {
  leftDrawArea,
  left,
  rightDrawArea,
  right,
}

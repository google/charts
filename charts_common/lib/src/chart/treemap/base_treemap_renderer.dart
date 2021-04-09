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

import 'dart:collection' show Queue;
import 'dart:math' show MutableRectangle, Point, Rectangle, min;

import 'package:charts_common/src/chart/common/base_chart.dart';
import 'package:charts_common/src/chart/common/chart_canvas.dart';
import 'package:charts_common/src/chart/common/datum_details.dart';
import 'package:charts_common/src/chart/common/processed_series.dart';
import 'package:charts_common/src/chart/common/series_datum.dart';
import 'package:charts_common/src/chart/common/series_renderer.dart';
import 'package:charts_common/src/common/math.dart' show NullablePoint;
import 'package:charts_common/src/common/style/style_factory.dart';
import 'package:charts_common/src/data/series.dart';
import 'package:charts_common/src/data/tree.dart';
import 'package:meta/meta.dart';

import 'treemap_label_decorator.dart';
import 'treemap_renderer_config.dart';
import 'treemap_renderer_element.dart';

/// Key for storing a list of treemap renderer elements.
///
/// Each element contains a bounding rectangle for rendering.
const treeMapElementsKey =
    AttributeKey<Iterable<TreeMapRendererElement<Object>>>(
        'TreeMapRenderer.elements');

abstract class BaseTreeMapRenderer<D> extends BaseSeriesRenderer<D> {
  /// Default renderer ID for treemap.
  static const defaultRendererId = 'treemap';

  /// A hash map that allows accessing the renderer element drawn on the chart
  /// from a treemap node.
  final _treeNodeToRendererElement =
      <TreeNode<Object>, TreeMapRendererElement<D>>{};

  /// An ordered map of [_AnimatedTreeMapRect] that will get drawn on the
  /// canvas.
  final _animatedTreeMapRects = <D, _AnimatedTreeMapRect<D>>{};

  /// Renderer configuration.
  final TreeMapRendererConfig<D> config;

  /// Decorator for rendering treemap node label.
  final TreeMapLabelDecorator<D>? labelDecorator;

  BaseChart<D>? _chart;

  BaseTreeMapRenderer({required this.config, String? rendererId})
      : labelDecorator = config.labelDecorator,
        super(
          rendererId: rendererId ?? defaultRendererId,
          layoutPaintOrder: config.layoutPaintOrder,
          symbolRenderer: config.symbolRenderer,
        );

  @override
  void onAttach(BaseChart<D> chart) {
    super.onAttach(chart);
    _chart = chart;
  }

  /// Rtl direction setting from chart context.
  bool get isRtl => _chart?.context.isRtl ?? false;

  @override
  void configureSeries(List<MutableSeries<D>> seriesList) {
    assignMissingColors(seriesList, emptyCategoryUsesSinglePalette: true);
    assignMissingStrokeWidths(seriesList);
  }

  @override
  void preprocessSeries(List<MutableSeries<D>> seriesList) {
    _ensureSingleTree(seriesList);

    // Clears [_treeNodeToRendererElement] map when a new seriesList is passed
    // in for preprocessing. The order in this map matters because the first
    // entry is expected to be the root.
    _treeNodeToRendererElement.clear();

    for (final series in seriesList) {
      final count = series.data.length;

      // Populates [treeNodeToRendererElement] map entries.
      for (var i = 0; i < count; i++) {
        final node = series.data[i] as TreeNode<Object>;
        _treeNodeToRendererElement[node] =
            _createRendererElement(series, i, isLeaf: !node.hasChildren);
      }
      series.setAttr(treeMapElementsKey, _treeNodeToRendererElement.values);
    }
  }

  /// Tiling algorithm for dividing a region into subregions of specified areas.
  void tile(TreeNode<Object> node);

  @override
  void update(List<ImmutableSeries<D>> seriesList, bool isAnimating) {
    // _visibleTreeMapRectKeys is used to remove any [_AnimatedTreeMapRect]s
    // that were rendered in the previous draw cycles, but no longer have a
    // corresponding datum in the new series data.
    final _visibleTreeMapRectKeys = <D>{};

    for (final series in seriesList) {
      if (series.data.isNotEmpty) {
        final root = series.data.first as TreeNode<Object>;
        // Configures the renderer element for root node.
        _configureRootRendererElement(root);

        // Applies tiling algorithm to each node.
        for (final datum in series.data) {
          final node = datum as TreeNode<Object>;
          tile(node);
          final element = _getRendererElement(node)..refreshPaintProperties();
          final rect = _createAnimatedTreeMapRect(element);
          _visibleTreeMapRectKeys.add(rect.key);
        }
      }
    }

    _animatedTreeMapRects.forEach((_, rect) {
      if (!_visibleTreeMapRectKeys.contains(rect.key)) {
        rect.animateOut();
      }
    });
  }

  @override
  void paint(ChartCanvas canvas, double animationPercent) {
    if (animationPercent == 1.0) {
      _animatedTreeMapRects.removeWhere((_, rect) => rect.animatingOut);
    }

    _animatedTreeMapRects.forEach((_, animatedRect) {
      final element = animatedRect.getCurrentRect(animationPercent);
      final rect = element.boundingRect;

      // canvas.drawRRect is used instead of canvas.drawRect because drawRRect
      // supports FillPatternType.forwardHatch.
      canvas.drawRRect(
        rect,
        fill: element.fillColor,
        fillPattern: element.fillPattern,
        patternStrokeWidthPx: config.patternStrokeWidthPx,
        patternColor: element.patternColor,
        stroke: element.strokeColor,
        strokeWidthPx: element.strokeWidthPx!.toDouble(),
        radius: 0,
        roundTopLeft: false,
        roundTopRight: false,
        roundBottomLeft: false,
        roundBottomRight: false,
      );

      // Paint label.
      labelDecorator?.decorate(element, canvas, graphicsFactory!,
          drawBounds: drawBounds!,
          animationPercent: animationPercent,
          rtl: isRtl,
          // only leaf node could possibly render label vertically.
          renderVertically: element.isLeaf && rect.width < rect.height,
          renderMultiline: element.isLeaf);
    });
  }

  /// Datum details of nearest rectangles in the treemap.
  @override
  List<DatumDetails<D>> getNearestDatumDetailPerSeries(
    Point<double> chartPoint,
    bool byDomain,
    Rectangle<int>? boundsOverride, {
    bool selectOverlappingPoints = false,
    bool selectExactEventLocation = false,
  }) {
    final nearest = <DatumDetails<D>>[];

    // Checks if the [chartPoint] is within bounds.
    if (!isPointWithinBounds(chartPoint, boundsOverride)) return nearest;

    final root = _treeNodeToRendererElement.entries.first.key;
    final queue = Queue<TreeNode<Object>>()..add(root);

    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      final element = _getRendererElement(node);

      if (element.boundingRect.containsPoint(chartPoint)) {
        nearest.add(DatumDetails<D>(
          index: element.index,
          series: element.series,
          datum: node,
          domain: element.domain,
          measure: element.measure,
          domainDistance: 0.0,
          measureDistance: 0.0,
        ));
        // No need to verify remaining siblings.
        queue.clear();

        // Only processes nodes whose parents contain the [chartPoint].
        // This reduces the number of nodes to verify.
        queue.addAll(node.children);
      }
    }

    // Prioritizes nodes with larger depth;
    nearest.sort((a, b) {
      final nodeA = a.datum as TreeNode<Object>;
      final nodeB = b.datum as TreeNode<Object>;
      return nodeB.depth.compareTo(nodeA.depth);
    });
    return nearest;
  }

  @override
  DatumDetails<D> addPositionToDetailsForSeriesDatum(
      DatumDetails<D> details, SeriesDatum<D> seriesDatum) {
    final bounds =
        _getRendererElement(seriesDatum.datum as TreeNode<Object>).boundingRect;
    final chartPosition = Point<double>(
        (isRtl ? bounds.left : bounds.right).toDouble(),
        (bounds.top + (bounds.height / 2)).toDouble());
    return DatumDetails.from(details,
        chartPosition: NullablePoint.from(chartPosition));
  }

  /// Assigns missing colors in case when color accessor functions are not set.
  ///
  /// Assigned color is based on the depth of each node.
  @override
  void assignMissingColors(Iterable<MutableSeries<D>> seriesList,
      {required bool emptyCategoryUsesSinglePalette}) {
    for (final series in seriesList) {
      final colorPalettes =
          StyleFactory.style.getOrderedPalettes(series.data.length);
      final count = colorPalettes.length;

      series.fillColorFn ??= (int? index) {
        var node = series.data[index!] as TreeNode<Object>;
        return colorPalettes[node.depth % count].shadeDefault;
      };

      // Pattern color and stroke color defaults to the default config stroke
      // color if no accessor is provided.
      series.colorFn ??= (index) => config.strokeColor;
      series.patternColorFn ??= (index) => config.strokeColor;
    }
  }

  /// Assigns missing stroke widths in case when strokeWidthPx accessor
  /// functions are not set.
  @protected
  void assignMissingStrokeWidths(Iterable<MutableSeries<D>> seriesList) {
    for (final series in seriesList) {
      series.strokeWidthPxFn ??= (_) => config.strokeWidthPx;
    }
  }

  /// Available bounding rectangle that can be used to lay out the child
  /// renderer elements.
  ///
  /// Available bounding rectangle is computed after padding is applied.
  @protected
  MutableRectangle availableLayoutBoundingRect(TreeNode<Object> node) {
    final element = _getRendererElement(node);
    final rect = element.boundingRect;
    final padding = config.rectPaddingPx;

    var top = rect.top + padding.topPx;
    var left = rect.left + padding.leftPx;
    var width = rect.width - padding.leftPx - padding.rightPx;
    var height = rect.height - padding.topPx - padding.bottomPx;

    // Handles an edge case when width or height is negative.
    if (width < 0) {
      left += width / 2;
      width = 0;
    }
    if (height < 0) {
      top += height / 2;
      height = 0;
    }
    return MutableRectangle(left, top, width, height);
  }

  /// Scales the area of each renderer element in [children] by a [scaleFactor].
  ///
  /// [scaleFactor] should be calculated based on the available layout area and
  /// the measure which the available layout area represents.
  @protected
  void scaleArea(Iterable<TreeNode<Object>> children, num scaleFactor) {
    for (final child in children) {
      final element = _getRendererElement(child);
      final area = element.measure * (scaleFactor < 0 ? 0 : scaleFactor);
      element.area = area <= 0 ? 0 : area;
    }
  }

  /// Gets the measure for a tree [node].
  @protected
  num measureForTreeNode(TreeNode<Object> node) =>
      _getRendererElement(node).measure;

  /// Gets the area of a [Rectangle].
  @protected
  num areaForRectangle(Rectangle rect) => rect.height * rect.width;

  /// Gets the area for a tree [node].
  @protected
  num areaForTreeNode(TreeNode<Object> node) => _getRendererElement(node).area;

  /// Positions each renderer element in [nodes] within the [boundingRect].
  ///
  /// [side] is defined as the smallest side of the [layoutArea].
  ///
  /// Consider the following boundingRect:
  /// ```
  /// boundingRect:
  ///          ------------------
  ///         |************|     |
  ///  (side) |*layoutArea*|     | height
  ///         |************|     |
  ///          ------------------
  ///                 width
  /// ```
  @protected
  void position(Iterable<TreeNode<Object>> nodes, MutableRectangle boundingRect,
      num side, num layoutArea) {
    var top = boundingRect.top;
    var left = boundingRect.left;
    var length = side > 0 ? (layoutArea / side) : 0;

    // [side] is equal to the height of the boundingRect, so stacks rectangles
    // vertically. [length] is the width of the stacking rectangles.
    if (side == boundingRect.height) {
      // Truncates the length since it is out of bounds.
      if (length > boundingRect.width) length = boundingRect.width.toInt();
      for (final node in nodes) {
        final element = _getRendererElement(node);
        final height = min(boundingRect.top + boundingRect.height - top,
            length > 0 ? (element.area / length) : 0);
        element.boundingRect = Rectangle(left, top, length, height);
        top += height;
      }
      boundingRect.left += length;
      boundingRect.width -= length;
    } else {
      // Positions rectangles horizontally.
      if (length > boundingRect.height) length = boundingRect.height.toInt();
      for (final node in nodes) {
        final element = _getRendererElement(node);
        final width = min(boundingRect.left + boundingRect.width - left,
            length > 0 ? (element.area / length) : 0);
        element.boundingRect = Rectangle(left, top, width, length);
        left += width;
      }
      boundingRect.top += length;
      boundingRect.height -= length;
    }
  }

  void _configureRootRendererElement(TreeNode<Object> root) {
    // Root should take up the entire [drawBounds] area.
    final drawBounds = this.drawBounds!;
    _getRendererElement(root)
      ..boundingRect = drawBounds
      ..area = areaForRectangle(drawBounds);
  }

  /// Creates an [_AnimatedTreeMapRect].
  ///
  /// This object contains previous, current, and target animation state of
  /// treemap renderer [element].
  _AnimatedTreeMapRect<D> _createAnimatedTreeMapRect(
      TreeMapRendererElement<D> element) {
    final key = element.domain;
    // Creates a new _AnimatedTreeMapRect if not exists. Otherwise, moves the
    // existing one to the end of the list so that the iteration order of
    // _AnimatedTreeMapRects is preserved. This is important because the order
    // of rects in _animatedTreeMapRects determines the painting order.
    final rect = _animatedTreeMapRects.containsKey(key)
        ? _animatedTreeMapRects.remove(key)!
        : _AnimatedTreeMapRect<D>(key: key);

    _animatedTreeMapRects[key] = rect;
    return rect..setNewTarget(element);
  }

  /// Creates a basic [TreeMapRendererElement].
  ///
  /// `boundingRect` and `area` are set after tile function is applied.
  TreeMapRendererElement<D> _createRendererElement(
    MutableSeries<D> series,
    int index, {
    required bool isLeaf,
  }) =>
      TreeMapRendererElement<D>(
        domain: series.domainFn(index),
        measure: series.measureFn(index)!,
        isLeaf: isLeaf,
        index: index,
        series: series,
      );

  TreeMapRendererElement<D> _getRendererElement(TreeNode<Object> node) {
    final element = _treeNodeToRendererElement[node];
    assert(
        element != null, 'There is no associated renderer element for $node.');
    return element!;
  }

  void _ensureSingleTree(List<ImmutableSeries<D>> seriesList) {
    assert(seriesList.length <= 1,
        'TreeMapRenderer only supports a single series at most.');
  }
}

/// A representation of the animation state of [TreeMapRendererElement].
class _AnimatedTreeMapRect<D> {
  final D key;

  /// A previous [TreeMapRendererElement] before animation.
  TreeMapRendererElement<D>? _previousRect;

  /// A target [TreeMapRendererElement] after animation is performed.
  late TreeMapRendererElement<D> _targetRect;

  /// Current [TreeMapRendererElement] at a given animation percent time.
  TreeMapRendererElement<D>? _currentRect;

  // Flag indicating whether this rect is being animated out of the chart.
  bool animatingOut = false;

  _AnimatedTreeMapRect({required this.key});

  /// Animates a rect that was removed from the tree out of the view.
  ///
  /// Animates the height and width of the rect down to zero, centered in the
  /// middle of the original rect.
  void animateOut() {
    final newTarget = _currentRect!.clone();
    final rect = newTarget.boundingRect;
    newTarget.boundingRect = Rectangle(
        rect.left + (rect.width / 2), rect.top + (rect.height / 2), 0, 0);
    newTarget.strokeWidthPx = 0.0;

    setNewTarget(newTarget);
    animatingOut = true;
  }

  void setNewTarget(TreeMapRendererElement<D> newTarget) {
    animatingOut = false;
    // Only when [currentRect] is null, [currentRect] should be [newTarget].
    _currentRect ??= newTarget.clone();
    _previousRect = _currentRect!.clone();
    _targetRect = newTarget;
  }

  /// Current [TreeMapRendererElement] at a given animation percent time.
  TreeMapRendererElement<D> getCurrentRect(double animationPercent) {
    if (animationPercent == 1.0 || _previousRect == null) {
      _currentRect = _targetRect;
      _previousRect = _targetRect;
      return _currentRect!;
    }

    _currentRect!
        .updateAnimationPercent(_previousRect!, _targetRect, animationPercent);
    return _currentRect!;
  }
}

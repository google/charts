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

import 'dart:collection';

import 'package:charts_common/src/chart/cartesian/axis/spec/axis_spec.dart';
import 'package:charts_common/src/chart/common/chart_canvas.dart';
import 'package:charts_common/src/common/color.dart';
import 'package:charts_common/src/common/typed_registry.dart';
import 'package:meta/meta.dart';

import 'series.dart' show AttributeKey, Series, TypedAccessorFn;

/// A tree structure that contains metadata of a rendering tree.
class Tree<T, D> {
  /// Unique identifier for this [tree].
  final String id;

  /// Root node of this tree.
  final TreeNode<T> root;

  /// Accessor function that returns the domain for a tree node.
  final TypedAccessorFn<TreeNode<T>, D> domainFn;

  /// Accessor function that returns the measure for a tree node.
  final TypedAccessorFn<TreeNode<T>, num?> measureFn;

  /// Accessor function that returns the rendered stroke color for a tree node.
  final TypedAccessorFn<TreeNode<T>, Color>? colorFn;

  /// Accessor function that returns the rendered fill color for a tree node.
  /// If not provided, then [colorFn] will be used as a fallback.
  final TypedAccessorFn<TreeNode<T>, Color>? fillColorFn;

  /// Accessor function that returns the pattern color for a tree node
  /// If not provided, then background color is used as default.
  final TypedAccessorFn<TreeNode<T>, Color>? patternColorFn;

  /// Accessor function that returns the fill pattern for a tree node.
  final TypedAccessorFn<TreeNode<T>, FillPatternType>? fillPatternFn;

  /// Accessor function that returns the stroke width in pixel for a tree node.
  final TypedAccessorFn<TreeNode<T>, num>? strokeWidthPxFn;

  /// Accessor function that returns the label for a tree node.
  final TypedAccessorFn<TreeNode<T>, String>? labelFn;

  /// Accessor function that returns the style spec for a tree node label.
  final TypedAccessorFn<TreeNode<T>, TextStyleSpec>? labelStyleFn;

  /// [attributes] stores additional key-value pairs of attributes this tree is
  /// associated with (e.g. rendererIdKey to renderer).
  final TreeAttributes attributes = TreeAttributes();

  factory Tree({
    required String id,
    required TreeNode<T> root,
    required TypedAccessorFn<T, D> domainFn,
    required TypedAccessorFn<T, num?> measureFn,
    TypedAccessorFn<T, Color>? colorFn,
    TypedAccessorFn<T, Color>? fillColorFn,
    TypedAccessorFn<T, Color>? patternColorFn,
    TypedAccessorFn<T, FillPatternType>? fillPatternFn,
    TypedAccessorFn<T, num>? strokeWidthPxFn,
    TypedAccessorFn<T, String>? labelFn,
    TypedAccessorFn<T, TextStyleSpec>? labelStyleFn,
  }) {
    return Tree._(
      id: id,
      root: root,
      domainFn: _castFrom<T, D>(domainFn)!,
      measureFn: _castFrom<T, num?>(measureFn)!,
      colorFn: _castFrom<T, Color>(colorFn),
      fillColorFn: _castFrom<T, Color>(fillColorFn),
      fillPatternFn: _castFrom<T, FillPatternType>(fillPatternFn),
      patternColorFn: _castFrom<T, Color>(patternColorFn),
      strokeWidthPxFn: _castFrom<T, num>(strokeWidthPxFn),
      labelFn: _castFrom<T, String>(labelFn),
      labelStyleFn: _castFrom<T, TextStyleSpec>(labelStyleFn),
    );
  }

  Tree._({
    required this.id,
    required this.root,
    required this.domainFn,
    required this.measureFn,
    required this.colorFn,
    required this.fillColorFn,
    required this.fillPatternFn,
    required this.patternColorFn,
    required this.strokeWidthPxFn,
    required this.labelFn,
    required this.labelStyleFn,
  });

  /// Creates a [Series] that contains all [TreeNode]s traversing from the
  /// [root] of this tree.
  ///
  /// Considers the following tree:
  /// ```
  ///       A
  ///     / | \
  ///    B  C  D      --->    [A, B, C, D, E, F]
  ///         / \
  ///        E   F
  /// ```
  /// This method traverses from root node "A" in breadth-first order and
  /// adds all its children to a list. The order of [TreeNode]s in the list
  /// is based on the insertion order to children of a particular node.
  /// All [TreeNode]s are accessible through [Series].data.
  Series<TreeNode<T>, D> toSeries() {
    final data = <TreeNode<T>>[];
    root.visit(data.add);

    return Series(
      id: id,
      data: data,
      domainFn: domainFn,
      measureFn: measureFn,
      colorFn: colorFn,
      fillColorFn: fillColorFn,
      fillPatternFn: fillPatternFn,
      patternColorFn: patternColorFn,
      strokeWidthPxFn: strokeWidthPxFn,
      labelAccessorFn: labelFn,
      insideLabelStyleAccessorFn: labelStyleFn,
    )..attributes.mergeFrom(attributes);
  }

  void setAttribute<R>(AttributeKey<R> key, R value) {
    attributes.setAttr(key, value);
  }

  R? getAttribute<R>(AttributeKey<R> key) {
    return attributes.getAttr<R>(key);
  }
}

class TreeNode<T> {
  /// Associated data this node stores.
  final T data;

  final List<TreeNode<T>> _children = [];

  int _depth = 0;

  TreeNode<T>? parent;

  TreeNode(this.data);

  /// Distance between this node and the root node.
  int get depth => _depth;

  @protected
  set depth(int val) {
    _depth = val;
  }

  /// List of child nodes.
  Iterable<TreeNode<T>> get children => _children;

  /// Whether or not this node has any children.
  bool get hasChildren => _children.isNotEmpty;

  /// Adds a single child to this node.
  void addChild(TreeNode<T> child) {
    child.parent = this;
    final delta = depth - child.depth + 1;
    if (delta != 0) child.visit((node) => node.depth += delta);
    _children.add(child);
  }

  /// Adds a list of children to this node.
  void addChildren(Iterable<TreeNode<T>> newChildren) {
    newChildren.forEach(addChild);
  }

  /// Applies the function [f] to all child nodes rooted from this node in
  /// breadth first order.
  void visit(void Function(TreeNode<T> node) f) {
    final queue = Queue<TreeNode<T>>()..add(this);

    while (queue.isNotEmpty) {
      final node = queue.removeFirst();
      f(node);
      queue.addAll(node.children);
    }
  }
}

/// A registry that stores key-value pairs of attributes.
class TreeAttributes extends TypedRegistry {}

/// Adapts a TypedAccessorFn<T, R> type to a TypedAccessorFn<TreeNode<T>, R>.
TypedAccessorFn<TreeNode<T>, R>? _castFrom<T, R>(TypedAccessorFn<T, R>? f) {
  return f == null
      ? null
      : (TreeNode<T> node, int? index) => f(node.data, index);
}

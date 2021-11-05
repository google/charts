// Copyright 2021 the Charts project authors. Please see the AUTHORS file
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

import 'package:built_value/built_value.dart';

import 'series.dart' show TypedAccessorFn;

part 'graph_utils.g.dart';

const graphCycleErrorMsg = 'The given graph contains a cycle.';

const nodeMappingErrorMsg =
    'The given node is not in the provided node mapping';

/// If the node accessor is not null return a function to act on a graph [Node].
TypedAccessorFn<Node<N, L>, R>? actOnNodeData<N, L, R>(
    TypedAccessorFn<N, R>? f) {
  return f == null
      ? null
      : (Node<N, L> node, int? index) => f(node.data, index);
}

/// If the node accessor is not null return a function to act on a graph [Link].
TypedAccessorFn<Link<N, L>, R>? actOnLinkData<N, L, R>(
    TypedAccessorFn<L, R>? f) {
  return f == null
      ? null
      : (Link<N, L> link, int? index) => f(link.data, index);
}

/// Add an incoming or outgoing link to a [Node].
Node<N, L> addLinkToNode<N, L>(Node<N, L> node, Link<N, L> link,
    {required bool isIncomingLink}) {
  if (isIncomingLink) {
    node.incomingLinks.add(link);
  } else {
    node.outgoingLinks.add(link);
  }

  return node;
}

/// Construct a new [Node] with the added [Link].
Node<N, L> addLinkToAbsentNode<N, L>(Link<N, L> link,
    {required bool isIncomingLink}) {
  var node = isIncomingLink ? link.target : link.source;

  return addLinkToNode(node, link, isIncomingLink: isIncomingLink);
}

/// Call an accessor if it exists on input else return null.
R? accessorIfExists<T, R>(TypedAccessorFn<T, R>? method, T input, int index) {
  return method == null ? null : method(input, index);
}

/// A node in a graph containing user defined data and connected links.
@BuiltValue(instantiable: false)
abstract class Node<N, L> extends Object with GraphElement<N> {
  /// All links that flow into this SankeyNode. Calculated from graph links.
  List<Link<N, L>> get incomingLinks;

  /// All links that flow from this SankeyNode. Calculated from graph links.
  List<Link<N, L>> get outgoingLinks;

  Node<N, L> rebuild(void Function(NodeBuilder<N, L>) updates);
  NodeBuilder<N, L> toBuilder();
}

/// A link in a graph connecting a source node and target node.
@BuiltValue(instantiable: false)
abstract class Link<N, L> extends Object with GraphElement<L> {
  /// The source Node for this Link.
  Node<N, L> get source;

  /// The target Node for this Link.
  Node<N, L> get target;

  Link<N, L> rebuild(void Function(LinkBuilder<N, L>) updates);
  LinkBuilder<N, L> toBuilder();
}

/// A [Link] or [Node] element in a graph containing user defined data.
abstract class GraphElement<G> {
  /// Data associated with this graph element.
  G get data;
}

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
import 'dart:collection' show LinkedHashMap;

import 'package:charts_common/src/chart/common/chart_canvas.dart';
import 'package:charts_common/src/common/color.dart';
import 'package:charts_common/src/common/typed_registry.dart';

import 'series.dart' show AttributeKey, Series, TypedAccessorFn;

class Graph<N, L, D> {
  /// Unique identifier for this graph
  final String id;

  /// All nodes in the graph.
  final List<Node<N, L>> nodes;

  /// All links in the graph.
  final List<Link<N, L>> links;

  /// Accessor function that returns the domain for a node.
  ///
  /// The domain should be a unique identifier for the node
  final TypedAccessorFn<Node<N, L>, D> nodeDomainFn;

  /// Accessor function that returns the domain for a link.
  ///
  /// The domain should be a unique identifier for the link
  final TypedAccessorFn<Link<N, L>, D> linkDomainFn;

  /// Accessor function that returns the measure for a node.
  ///
  /// The measure should be the numeric value at the node.
  final TypedAccessorFn<Node<N, L>, num?> nodeMeasureFn;

  /// Accessor function that returns the measure for a link.
  ///
  /// The measure should be the numeric value through the link.
  final TypedAccessorFn<Link<N, L>, num?> linkMeasureFn;

  /// Accessor function that returns the stroke color of a node
  final TypedAccessorFn<Node<N, L>, Color>? nodeColorFn;

  /// Accessor function that returns the fill color of a node
  final TypedAccessorFn<Node<N, L>, Color>? nodeFillColorFn;

  /// Accessor function that returns the fill pattern of a node
  final TypedAccessorFn<Node<N, L>, FillPatternType>? nodeFillPatternFn;

  /// Accessor function that returns the stroke width of a node
  final TypedAccessorFn<Node<N, L>, num>? nodeStrokeWidthPxFn;

  /// Accessor function that returns the fill color of a node
  final TypedAccessorFn<Link<N, L>, Color>? linkFillColorFn;

  /// Store additional key-value pairs for node attributes
  final NodeAttributes nodeAttributes = NodeAttributes();

  /// Store additional key-value pairs for link attributes
  final LinkAttributes linkAttributes = LinkAttributes();

  factory Graph(
      {required String id,
      required List<N> nodes,
      required List<L> links,
      required TypedAccessorFn<N, D> nodeDomainFn,
      required TypedAccessorFn<L, D> linkDomainFn,
      required TypedAccessorFn<L, N> sourceFn,
      required TypedAccessorFn<L, N> targetFn,
      required TypedAccessorFn<N, num?> nodeMeasureFn,
      required TypedAccessorFn<L, num?> linkMeasureFn,
      TypedAccessorFn<N, Color>? nodeColorFn,
      TypedAccessorFn<N, Color>? nodeFillColorFn,
      TypedAccessorFn<N, FillPatternType>? nodeFillPatternFn,
      TypedAccessorFn<N, num>? nodeStrokeWidthPxFn,
      TypedAccessorFn<L, Color>? linkFillColorFn}) {
    return Graph._(
      id: id,
      nodes: _convertGraphNodes<N, L, D>(
          nodes, links, sourceFn, targetFn, nodeDomainFn),
      links: _convertGraphLinks<N, L>(links, sourceFn, targetFn),
      nodeDomainFn: _actOnNodeData<N, L, D>(nodeDomainFn)!,
      linkDomainFn: _actOnLinkData<N, L, D>(linkDomainFn)!,
      nodeMeasureFn: _actOnNodeData<N, L, num?>(nodeMeasureFn)!,
      linkMeasureFn: _actOnLinkData<N, L, num?>(linkMeasureFn)!,
      nodeColorFn: _actOnNodeData<N, L, Color>(nodeColorFn),
      nodeFillColorFn: _actOnNodeData<N, L, Color>(nodeFillColorFn),
      nodeFillPatternFn:
          _actOnNodeData<N, L, FillPatternType>(nodeFillPatternFn),
      nodeStrokeWidthPxFn: _actOnNodeData<N, L, num>(nodeStrokeWidthPxFn),
      linkFillColorFn: _actOnLinkData<N, L, Color>(linkFillColorFn),
    );
  }

  Graph._({
    required this.id,
    required this.nodes,
    required this.links,
    required this.nodeDomainFn,
    required this.linkDomainFn,
    required this.nodeMeasureFn,
    required this.linkMeasureFn,
    required this.nodeColorFn,
    required this.nodeFillColorFn,
    required this.nodeFillPatternFn,
    required this.nodeStrokeWidthPxFn,
    required this.linkFillColorFn,
  });

  /// Transform graph data given by links and nodes into a [Series] list.
  ///
  /// Output should contain two [Series] with the format:
  /// `[Series<Node<N,L>> nodeSeries, Series<Link<N,L>> linkSeries]`
  List<Series<GraphElement, D>> toSeriesList() {
    Series<Node<N, L>, D> nodeSeries = Series(
      id: '${id}_nodes',
      data: nodes,
      domainFn: nodeDomainFn,
      measureFn: nodeMeasureFn,
      colorFn: nodeColorFn,
      fillColorFn: nodeFillColorFn,
      fillPatternFn: nodeFillPatternFn,
      strokeWidthPxFn: nodeStrokeWidthPxFn,
    )..attributes.mergeFrom(nodeAttributes);

    Series<Link<N, L>, D> linkSeries = Series(
      id: '${id}_links',
      data: links,
      domainFn: linkDomainFn,
      measureFn: linkMeasureFn,
      fillColorFn: linkFillColorFn,
    )..attributes.mergeFrom(linkAttributes);
    return [nodeSeries, linkSeries];
  }

  /// Set attribute of given generic type R for a node series
  void setNodeAttribute<R>(AttributeKey<R> key, R value) {
    nodeAttributes.setAttr(key, value);
  }

  /// Get attribute of given generic type R for a node series
  R? getNodeAttribute<R>(AttributeKey<R> key) {
    return nodeAttributes.getAttr<R>(key);
  }

  /// Set attribute of given generic type R for a link series
  void setLinkAttribute<R>(AttributeKey<R> key, R value) {
    linkAttributes.setAttr(key, value);
  }

  /// Get attribute of given generic type R for a link series
  R? getLinkAttribute<R>(AttributeKey<R> key) {
    return linkAttributes.getAttr<R>(key);
  }
}

TypedAccessorFn<Node<N, L>, R>? _actOnNodeData<N, L, R>(
    TypedAccessorFn<N, R>? f) {
  return f == null
      ? null
      : (Node<N, L> node, int? index) => f(node.data, index);
}

TypedAccessorFn<Link<N, L>, R>? _actOnLinkData<N, L, R>(
    TypedAccessorFn<L, R>? f) {
  return f == null
      ? null
      : (Link<N, L> link, int? index) => f(link.data, index);
}

/// Return a list of links from the generic link data type
List<Link<N, L>> _convertGraphLinks<N, L>(List<L> links,
    TypedAccessorFn<L, N> sourceFn, TypedAccessorFn<L, N> targetFn) {
  List<Link<N, L>> graphLinks = [];
  for (var i = 0; i < links.length; i++) {
    N sourceNode = sourceFn(links[i], i);
    N targetNode = targetFn(links[i], i);
    graphLinks.add(Link(Node(sourceNode), Node(targetNode), links[i]));
  }
  return graphLinks;
}

/// Return a list of nodes from the generic node data type
List<Node<N, L>> _convertGraphNodes<N, L, D>(
    List<N> nodes,
    List<L> links,
    TypedAccessorFn<L, N> sourceFn,
    TypedAccessorFn<L, N> targetFn,
    TypedAccessorFn<N, D> nodeDomainFn) {
  List<Node<N, L>> graphNodes = [];
  List<Link<N, L>> graphLinks = _convertGraphLinks(links, sourceFn, targetFn);
  TypedAccessorFn<Node<N, L>, D> nodeClassDomainFn =
      _actOnNodeData<N, L, D>(nodeDomainFn)!;
  LinkedHashMap<D, Node<N, L>> nodeMap = LinkedHashMap<D, Node<N, L>>();

  // Populate nodeMap with user provided nodes
  for (var node in nodes) {
    nodeMap.putIfAbsent(nodeDomainFn(node, 0), () => Node(node));
  }

  // Add ingoing and outgoing links to the nodes in nodeMap
  for (var link in graphLinks) {
    nodeMap.update(nodeClassDomainFn(link.target, 0),
        (node) => _addLinkToNode(node, link, isIncomingLink: true),
        ifAbsent: () => _addLinkToAbsentNode(link, isIncomingLink: true));
    nodeMap.update(nodeClassDomainFn(link.source, 0),
        (node) => _addLinkToNode(node, link, isIncomingLink: false),
        ifAbsent: () => _addLinkToAbsentNode(link, isIncomingLink: false));
  }

  nodeMap.forEach((domainId, node) => graphNodes.add(node));
  return graphNodes;
}

Node<N, L> _addLinkToNode<N, L>(Node<N, L> node, Link<N, L> link,
    {required bool isIncomingLink}) {
  if (isIncomingLink) {
    node.incomingLinks.add(link);
  } else {
    node.outgoingLinks.add(link);
  }

  return node;
}

Node<N, L> _addLinkToAbsentNode<N, L>(Link<N, L> link,
    {required bool isIncomingLink}) {
  Node<N, L> node = isIncomingLink ? link.target : link.source;

  return _addLinkToNode(node, link, isIncomingLink: isIncomingLink);
}

/// A registry that stores key-value pairs of attributes for nodes, links.
class NodeAttributes extends TypedRegistry {}

class LinkAttributes extends TypedRegistry {}

class Node<N, L> extends GraphElement<N> {
  /// All links that flow into this SankeyNode. Calculated from graph links.
  List<Link<N, L>> incomingLinks;

  /// All links that flow from this SankeyNode. Calculated from graph links.
  List<Link<N, L>> outgoingLinks;

  Node(
    N data, {
    List<Link<N, L>>? incomingLinks,
    List<Link<N, L>>? outgoingLinks,
  })  : incomingLinks = incomingLinks ?? [],
        outgoingLinks = outgoingLinks ?? [],
        super(data);
}

class Link<N, L> extends GraphElement<L> {
  /// The source Node for this Link.
  final Node<N, L> source;

  /// The target Node for this Link.
  final Node<N, L> target;

  Link(this.source, this.target, L data) : super(data);
}

abstract class GraphElement<G> {
  /// Data associated with this graph element
  final G data;

  GraphElement(this.data);
}

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
import 'dart:math' show max;

import 'package:built_value/built_value.dart';
import 'package:meta/meta.dart';

import '../chart/common/chart_canvas.dart' show FillPatternType;
import '../common/color.dart';
import 'graph.dart';
import 'graph_utils.dart';
import 'series.dart' show TypedAccessorFn;

part 'sankey_graph.g.dart';

/// Directed acyclic graph with Sankey diagram related data.
class SankeyGraph<N, L, D> extends Graph<N, L, D> {
  @override
  final List<SankeyNode<N, L>> nodes;

  @override
  final List<SankeyLink<N, L>> links;

  factory SankeyGraph(
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
      TypedAccessorFn<L, Color>? linkFillColorFn,
      TypedAccessorFn<L, num>? secondaryLinkMeasureFn,
      TypedAccessorFn<N, int>? columnFn}) {
    return SankeyGraph._(
      id: id,
      nodes: _convertSankeyNodes<N, L, D>(nodes, links, sourceFn, targetFn,
          nodeDomainFn, linkDomainFn, columnFn),
      links: _convertSankeyLinks<N, L>(
          links, sourceFn, targetFn, secondaryLinkMeasureFn),
      nodeDomainFn: actOnNodeData<N, L, D>(nodeDomainFn)!,
      linkDomainFn: actOnLinkData<N, L, D>(linkDomainFn)!,
      nodeMeasureFn: actOnNodeData<N, L, num?>(nodeMeasureFn)!,
      linkMeasureFn: actOnLinkData<N, L, num?>(linkMeasureFn)!,
      nodeColorFn: actOnNodeData<N, L, Color>(nodeColorFn),
      nodeFillColorFn: actOnNodeData<N, L, Color>(nodeFillColorFn),
      nodeFillPatternFn:
          actOnNodeData<N, L, FillPatternType>(nodeFillPatternFn),
      nodeStrokeWidthPxFn: actOnNodeData<N, L, num>(nodeStrokeWidthPxFn),
      linkFillColorFn: actOnLinkData<N, L, Color>(linkFillColorFn),
    );
  }

  SankeyGraph._({
    required this.nodes,
    required this.links,
    required String id,
    required TypedAccessorFn<Node<N, L>, D> nodeDomainFn,
    required TypedAccessorFn<Link<N, L>, D> linkDomainFn,
    required TypedAccessorFn<Node<N, L>, num?> nodeMeasureFn,
    required TypedAccessorFn<Link<N, L>, num?> linkMeasureFn,
    TypedAccessorFn<Node<N, L>, Color>? nodeColorFn,
    TypedAccessorFn<Node<N, L>, Color>? nodeFillColorFn,
    TypedAccessorFn<Node<N, L>, FillPatternType>? nodeFillPatternFn,
    TypedAccessorFn<Node<N, L>, num>? nodeStrokeWidthPxFn,
    TypedAccessorFn<Link<N, L>, Color>? linkFillColorFn,
  }) : super.base(
            id: id,
            nodes: nodes,
            links: links,
            nodeDomainFn: nodeDomainFn,
            nodeMeasureFn: nodeMeasureFn,
            linkDomainFn: linkDomainFn,
            linkMeasureFn: linkMeasureFn,
            nodeColorFn: nodeColorFn,
            nodeFillColorFn: nodeFillColorFn,
            nodeFillPatternFn: nodeFillPatternFn,
            nodeStrokeWidthPxFn: nodeStrokeWidthPxFn,
            linkFillColorFn: linkFillColorFn);
}

/// Return a list of links from the Sankey link data type
List<SankeyLink<N, L>> _convertSankeyLinks<N, L>(List<L> links,
    TypedAccessorFn<L, N> sourceFn, TypedAccessorFn<L, N> targetFn,
    [TypedAccessorFn<L, num>? secondaryLinkMeasureFn]) {
  var graphLinks = <SankeyLink<N, L>>[];
  for (var link in links) {
    var sourceNode = sourceFn(link, indexNotRelevant);
    var targetNode = targetFn(link, indexNotRelevant);
    var secondaryLinkMeasure = accessorIfExists<L, num>(
        secondaryLinkMeasureFn, link, indexNotRelevant);
    graphLinks.add(SankeyLink<N, L>((b) => b
      ..data = link
      ..source = SankeyNode<N, L>((b) => b
        ..data = sourceNode
        ..incomingLinks = <SankeyLink<N, L>>[]
        ..outgoingLinks = <SankeyLink<N, L>>[])
      ..target = SankeyNode<N, L>((b) => b
        ..data = targetNode
        ..incomingLinks = <SankeyLink<N, L>>[]
        ..outgoingLinks = <SankeyLink<N, L>>[])
      ..secondaryLinkMeasure = secondaryLinkMeasure));
  }
  return graphLinks;
}

/// Return a list of nodes from the Sankey node data type
List<SankeyNode<N, L>> _convertSankeyNodes<N, L, D>(
    List<N> nodes,
    List<L> links,
    TypedAccessorFn<L, N> sourceFn,
    TypedAccessorFn<L, N> targetFn,
    TypedAccessorFn<N, D> nodeDomainFn,
    TypedAccessorFn<L, D> linkDomainFn,
    TypedAccessorFn<N, int>? columnFn) {
  var graphLinks = _convertSankeyLinks<N, L>(links, sourceFn, targetFn);
  var reverseLinks = _convertSankeyLinks<N, L>(links, targetFn, sourceFn);
  var nodeClassDomainFn = actOnNodeData<N, L, D>(nodeDomainFn)!;
  var linkClassDomainFn = actOnLinkData<N, L, D>(linkDomainFn)!;
  var columnClassFn = actOnNodeData<N, L, int>(columnFn);
  var nodeMap = <D, SankeyNodeBuilder<N, L>>{};

  var graphNodes = _connectNodes<N, L, D>(
      nodes, nodeDomainFn, nodeClassDomainFn, graphLinks);
  var sortedNodes = topologicalNodeSort<N, L, D>(
          graphNodes, nodeClassDomainFn, linkClassDomainFn)
      .map((node) => (node as SankeyNode<N, L>).toBuilder())
      .toList();

  // Create reverse graph for node height calculations with topological sort
  var reverseNodes = _connectNodes<N, L, D>(
      nodes, nodeDomainFn, nodeClassDomainFn, reverseLinks);
  var reverseSort = topologicalNodeSort<N, L, D>(
          reverseNodes, nodeClassDomainFn, linkClassDomainFn)
      .map((node) => (node as SankeyNode<N, L>).toBuilder())
      .toList();

  for (var node in sortedNodes) {
    nodeMap.putIfAbsent(nodeClassDomainFn(node.build(), 0), () => node);
  }

  _addNodeDepths<N, L, D>(sortedNodes, nodeClassDomainFn, nodeMap);
  _addNodeColumns<N, L, D>(sortedNodes, columnClassFn);
  _addNodeHeights<N, L, D>(reverseSort, nodeClassDomainFn, nodeMap);

  return sortedNodes.map((node) => node.build()).toList();
}

void _addNodeDepths<N, L, D>(
    List<SankeyNodeBuilder<N, L>> sortedNodes,
    TypedAccessorFn<Node<N, L>, D> nodeClassDomainFn,
    Map<D, SankeyNodeBuilder<N, L>> nodeMap) {
  D sourceId(link) => nodeClassDomainFn(link.source, 0);
  for (var node in sortedNodes) {
    if (node.incomingLinks!.isEmpty) {
      node.update((b) => b..depth = 0);
      continue;
    }
    var parentDepths = node.incomingLinks!.map((link) {
      if (!nodeMap.containsKey(sourceId(link))) {
        throw UnsupportedError(nodeMappingErrorMsg);
      }
      return nodeMap[sourceId(link)]!.depth as int;
    }).toList();
    node.update((b) => b..depth = parentDepths.reduce(max) + 1);
  }
}

/// Returns a list of nodes sorted topologically for a directed acyclic graph.
@visibleForTesting
List<Node<N, L>> topologicalNodeSort<N, L, D>(
    List<Node<N, L>> givenNodes,
    TypedAccessorFn<Node<N, L>, D> nodeDomainFn,
    TypedAccessorFn<Link<N, L>, D> linkDomainFn) {
  var nodeMap = <D, Node<N, L>>{};
  var givenNodeMap = <D, Node<N, L>>{};
  var sortedNodes = <Node<N, L>>[];
  var sourceNodes = <Node<N, L>>[];
  var nodes = _cloneNodeList(givenNodes);

  for (var i = 0; i < nodes.length; i++) {
    nodeMap.putIfAbsent(
        nodeDomainFn(nodes[i], indexNotRelevant), () => nodes[i]);
    givenNodeMap.putIfAbsent(
        nodeDomainFn(givenNodes[i], indexNotRelevant), () => givenNodes[i]);
    if (nodes[i].incomingLinks.isEmpty) {
      sourceNodes.add(nodes[i]);
    }
  }

  while (sourceNodes.isNotEmpty) {
    var source = sourceNodes.removeLast();
    sortedNodes.add(givenNodeMap[nodeDomainFn(source, indexNotRelevant)]!);
    while (source.outgoingLinks.isNotEmpty) {
      var toRemove = source.outgoingLinks.removeLast();
      nodeMap[nodeDomainFn(toRemove.target, indexNotRelevant)]!
          .incomingLinks
          .removeWhere((link) =>
              linkDomainFn(link, indexNotRelevant) ==
              linkDomainFn(toRemove, indexNotRelevant));
      if (nodeMap[nodeDomainFn(toRemove.target, indexNotRelevant)]!
          .incomingLinks
          .isEmpty) {
        sourceNodes
            .add(nodeMap[nodeDomainFn(toRemove.target, indexNotRelevant)]!);
      }
    }
  }

  if (nodeMap.values.any((node) =>
      node.incomingLinks.isNotEmpty || node.outgoingLinks.isNotEmpty)) {
    throw UnsupportedError(graphCycleErrorMsg);
  }

  return sortedNodes;
}

List<Node<N, L>> _cloneNodeList<N, L>(List<Node<N, L>> nodeList) {
  return nodeList
      .map((node) => node.rebuild((b) => b
        ..incomingLinks = _cloneLinkList(node.incomingLinks)
        ..outgoingLinks = _cloneLinkList(node.outgoingLinks)))
      .toList();
}

List<Link<N, L>> _cloneLinkList<N, L>(List<Link<N, L>> linkList) {
  return linkList.map((link) => link.rebuild((b) => b)).toList();
}

/// Calculates a node's height.
///
/// Traverses topological sort of graph with link directions reversed to
/// ensure child node heights are calculated before a node is processed.
void _addNodeHeights<N, L, D>(
    List<SankeyNodeBuilder<N, L>> reverseSort,
    TypedAccessorFn<Node<N, L>, D> nodeClassDomainFn,
    Map<D, SankeyNodeBuilder<N, L>> nodeMap) {
  D sourceId(link) => nodeClassDomainFn(link.source, 0);
  D nodeId(node) => nodeClassDomainFn(node.build(), 0);
  for (var node in reverseSort) {
    if (node.incomingLinks!.isEmpty) {
      nodeMap[nodeId(node)]!.update((b) => b..height = 0);
      continue;
    }
    List<int> parentDepths = node.incomingLinks!.map((link) {
      if (!nodeMap.containsKey(sourceId(link))) {
        throw UnsupportedError(nodeMappingErrorMsg);
      }
      return nodeMap[sourceId(link)]!.height as int;
    }).toList();
    nodeMap[nodeId(node)]!
        .update((b) => b..height = parentDepths.reduce(max) + 1);
  }
}

void _addNodeColumns<N, L, D>(
  List<SankeyNodeBuilder<N, L>> sortedNodes,
  TypedAccessorFn<Node<N, L>, int>? columnFn,
) {
  for (var node in sortedNodes) {
    node.update((b) =>
        b..column = columnFn == null ? node.depth : columnFn(node.build(), 0));
  }
}

List<SankeyNode<N, L>> _connectNodes<N, L, D>(
  List<N> nodes,
  TypedAccessorFn<N, D> nodeDomainFn,
  TypedAccessorFn<Node<N, L>, D> nodeClassDomainFn,
  List<SankeyLink<N, L>> graphLinks,
) {
  var graphNodes = <SankeyNode<N, L>>[];
  var nodeMap = <D, SankeyNode<N, L>>{};
  D sourceId(link) => nodeClassDomainFn(link.source, indexNotRelevant);
  D targetId(link) => nodeClassDomainFn(link.target, indexNotRelevant);
  D nodeId(node) => nodeDomainFn(node, indexNotRelevant);

  for (var node in nodes) {
    nodeMap.putIfAbsent(
        nodeId(node),
        () => SankeyNode<N, L>((b) => b
          ..data = node
          ..incomingLinks = <SankeyLink<N, L>>[]
          ..outgoingLinks = <SankeyLink<N, L>>[]));
  }

  for (var link in graphLinks) {
    nodeMap.update(targetId(link),
        (node) => _addLinkToSankeyNode(node, link, isIncomingLink: true),
        ifAbsent: () => _addLinkToAbsentSankeyNode(link, isIncomingLink: true));
    nodeMap.update(sourceId(link),
        (node) => _addLinkToSankeyNode(node, link, isIncomingLink: false),
        ifAbsent: () =>
            _addLinkToAbsentSankeyNode(link, isIncomingLink: false));
  }
  nodeMap.forEach((domainId, node) => graphNodes.add(node));
  return graphNodes;
}

SankeyNode<N, L> _addLinkToSankeyNode<N, L>(
    SankeyNode<N, L> node, SankeyLink<N, L> link,
    {required bool isIncomingLink}) {
  return addLinkToNode(node, link, isIncomingLink: isIncomingLink)
      as SankeyNode<N, L>;
}

SankeyNode<N, L> _addLinkToAbsentSankeyNode<N, L>(SankeyLink<N, L> link,
    {required bool isIncomingLink}) {
  return addLinkToAbsentNode(link, isIncomingLink: isIncomingLink)
      as SankeyNode<N, L>;
}

/// A Sankey specific [Node] in the graph.
///
/// We store the Sankey specific column, and the depth and height given that a
/// [SankeyGraph] is directed and acyclic. These cannot be stored on a [Series].
abstract class SankeyNode<N, L>
    implements Node<N, L>, Built<SankeyNode<N, L>, SankeyNodeBuilder<N, L>> {
  /// Number of links from node to nearest root.
  ///
  /// Calculated from graph structure.
  int get depth;

  /// Number of links on the longest path to a leaf node.
  ///
  /// Calculated from graph structure.
  int get height;

  /// The column this node occupies in the Sankey graph.
  ///
  /// Sankey column may or may not be equal to depth. It can be assigned to
  /// height or defined to align nodes left or right, depending on if they are
  /// roots or leaves.
  int get column;

  @BuiltValueHook(initializeBuilder: true)
  static void _setDefaults(SankeyNodeBuilder b) => b
    ..depth = 0
    ..height = 0
    ..column = 0;

  factory SankeyNode([void Function(SankeyNodeBuilder<N, L>) updates]) =
      _$SankeyNode<N, L>;
  SankeyNode._();
}

/// A Sankey specific [Link] in the graph.
///
/// We store the optional Sankey exclusive secondary link measure on the
/// [SankeyLink] for variable links since it cannot be stored on a [Series].
abstract class SankeyLink<N, L>
    implements Link<N, L>, Built<SankeyLink<N, L>, SankeyLinkBuilder<N, L>> {
  /// Measure of a link at the target node if the link has variable value.
  ///
  /// Standard series measure will be the source value.
  num? get secondaryLinkMeasure;

  factory SankeyLink([void Function(SankeyLinkBuilder<N, L>) updates]) =
      _$SankeyLink<N, L>;
  SankeyLink._();
}

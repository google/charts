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

import 'package:charts_common/src/common/color.dart';
import 'package:charts_common/src/chart/common/chart_canvas.dart'
    show FillPatternType;

import 'series.dart' show TypedAccessorFn;

import 'graph.dart';
import 'graph_utils.dart';

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
      nodes: _convertSankeyNodes<N, L, D>(
          nodes, links, sourceFn, targetFn, nodeDomainFn),
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
  List<SankeyLink<N, L>> graphLinks = [];
  for (var link in links) {
    N sourceNode = sourceFn(link, indexNotRelevant);
    N targetNode = targetFn(link, indexNotRelevant);
    num? secondaryLinkMeasure = accessorIfExists<L, num>(
        secondaryLinkMeasureFn, link, indexNotRelevant);
    graphLinks.add(SankeyLink(
        SankeyNode(sourceNode), SankeyNode(targetNode), link,
        secondaryLinkMeasure: secondaryLinkMeasure));
  }
  return graphLinks;
}

/// Return a list of nodes from the Sankey node data type
List<SankeyNode<N, L>> _convertSankeyNodes<N, L, D>(
    List<N> nodes,
    List<L> links,
    TypedAccessorFn<L, N> sourceFn,
    TypedAccessorFn<L, N> targetFn,
    TypedAccessorFn<N, D> nodeDomainFn) {
  List<SankeyNode<N, L>> graphNodes = [];
  var graphLinks = _convertSankeyLinks(links, sourceFn, targetFn);
  var nodeClassDomainFn = actOnNodeData<N, L, D>(nodeDomainFn)!;
  var nodeMap = LinkedHashMap<D, SankeyNode<N, L>>();

  for (var node in nodes) {
    nodeMap.putIfAbsent(
        nodeDomainFn(node, indexNotRelevant), () => SankeyNode(node));
  }

  for (var link in graphLinks) {
    nodeMap.update(nodeClassDomainFn(link.target, indexNotRelevant),
        (node) => _addLinkToSankeyNode(node, link, isIncomingLink: true),
        ifAbsent: () => _addLinkToAbsentSankeyNode(link, isIncomingLink: true));
    nodeMap.update(nodeClassDomainFn(link.source, indexNotRelevant),
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
class SankeyNode<N, L> extends Node<N, L> {
  /// Number of links from node to nearest root.
  /// Calculated from graph structure.
  int? depth;

  /// Number of links on the longest path to a leaf node.
  /// Calculated from graph structure.
  int? height;

  /// The column this node occupies in the Sankey graph.
  int? column;

  SankeyNode(N data,
      {List<SankeyLink<N, L>>? incomingLinks,
      List<SankeyLink<N, L>>? outgoingLinks,
      this.depth,
      this.height,
      this.column})
      : super(data, incomingLinks: incomingLinks, outgoingLinks: outgoingLinks);
}

/// A Sankey specific [Link] in the graph.
///
/// We store the optional Sankey exclusive secondary link measure on the
/// [SankeyLink] for variable links since it cannot be stored on a [Series].
class SankeyLink<N, L> extends Link<N, L> {
  /// Measure of a link at the target node if the link has variable value.
  /// Standard series measure will be the source value.
  num? secondaryLinkMeasure;

  SankeyLink(SankeyNode<N, L> source, SankeyNode<N, L> target, L data,
      {this.secondaryLinkMeasure})
      : super(source, target, data);
}

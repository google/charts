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

import 'package:charts_common/common.dart';
import 'package:charts_common/src/data/graph.dart';
import 'package:charts_common/src/data/graph_utils.dart' as utils;
import 'package:charts_common/src/data/sankey_graph.dart';
import 'package:test/test.dart';

class MyNode {
  final String domainId;
  final num measure;

  MyNode(this.domainId, this.measure);
}

class MyLink {
  final String domainId;
  final num measure;
  final MyNode sourceNode;
  final MyNode targetNode;

  MyLink(this.domainId, this.sourceNode, this.targetNode, this.measure);
}

const nodeIds = [
  'Node 0',
  'Node 1',
  'Node 2',
  'Node 3',
  'Node 4',
  'Node 5',
  'Node 6',
];

const linkIds = [
  'Link 0',
  'Link 1',
  'Link 2',
  'Link 3',
  'Link 4',
  'Link 5',
  'Link 6',
  'Link 7',
  'Link 8',
  'Link 9',
];

SankeyGraph<MyNode, MyLink, String> mockLinearGraph() {
  var myNodes = [
    MyNode(nodeIds[1], 4),
    MyNode(nodeIds[2], 5),
    MyNode(nodeIds[3], 6),
  ];

  var myLinks = [
    MyLink(linkIds[1], myNodes[0], myNodes[1], 1),
    MyLink(linkIds[2], myNodes[1], myNodes[2], 2),
  ];

  var myGraph = SankeyGraph<MyNode, MyLink, String>(
      id: 'MyGraph',
      nodes: myNodes,
      links: myLinks,
      nodeDomainFn: (node, _) => node.domainId,
      linkDomainFn: (link, _) => link.domainId,
      sourceFn: (link, _) => link.sourceNode,
      targetFn: (link, _) => link.targetNode,
      nodeMeasureFn: (node, _) => node.measure,
      linkMeasureFn: (link, _) => link.measure,
      secondaryLinkMeasureFn: (link, _) => 1);

  return myGraph;
}

SankeyGraph<MyNode, MyLink, String> mockStructureGraph() {
  var myNodes = [
    MyNode(nodeIds[1], 4),
    MyNode(nodeIds[2], 5),
    MyNode(nodeIds[3], 6),
    MyNode(nodeIds[4], 7),
    MyNode(nodeIds[5], 8),
    MyNode(nodeIds[6], 9),
  ];

  var myLinks = [
    MyLink(linkIds[1], myNodes[5], myNodes[0], 1),
    MyLink(linkIds[2], myNodes[4], myNodes[0], 2),
    MyLink(linkIds[3], myNodes[5], myNodes[2], 1),
    MyLink(linkIds[4], myNodes[4], myNodes[1], 1),
    MyLink(linkIds[5], myNodes[2], myNodes[3], 1),
    MyLink(linkIds[6], myNodes[3], myNodes[1], 2),
  ];

  var myGraph = SankeyGraph<MyNode, MyLink, String>(
      id: 'MyGraph',
      nodes: myNodes,
      links: myLinks,
      nodeDomainFn: (node, _) => node.domainId,
      linkDomainFn: (link, _) => link.domainId,
      sourceFn: (link, _) => link.sourceNode,
      targetFn: (link, _) => link.targetNode,
      nodeMeasureFn: (node, _) => node.measure,
      linkMeasureFn: (link, _) => link.measure);

  return myGraph;
}

String nodeDomain(Graph<MyNode, MyLink, String> myGraph,
        utils.Node<MyNode, MyLink> node) =>
    myGraph.nodeDomainFn(node, indexNotRelevant);

String linkDomain(Graph<MyNode, MyLink, String> myGraph,
        utils.Link<MyNode, MyLink> link) =>
    myGraph.linkDomainFn(link, indexNotRelevant);

num nodeMeasure(Graph<MyNode, MyLink, String> myGraph,
        utils.Node<MyNode, MyLink> node) =>
    myGraph.nodeMeasureFn(node, indexNotRelevant)!;

num linkMeasure(Graph<MyNode, MyLink, String> myGraph,
        utils.Link<MyNode, MyLink> link) =>
    myGraph.linkMeasureFn(link, indexNotRelevant)!;

void main() {
  group('GraphTopologyFunctions', () {
    test('sort a simple graph', () {
      var myGraph = mockLinearGraph();
      var simpleSort = topologicalNodeSort(
          myGraph.nodes, myGraph.nodeDomainFn, myGraph.linkDomainFn);
      expect(simpleSort.map((node) => nodeDomain(myGraph, node)).toList(),
          [nodeIds[1], nodeIds[2], nodeIds[3]]);
    });

    test('returns one of many valid topological sorts for complex graph', () {
      var myNodes = [
        MyNode(nodeIds[1], 4),
        MyNode(nodeIds[2], 5),
        MyNode(nodeIds[3], 6),
        MyNode(nodeIds[4], 7),
        MyNode(nodeIds[5], 8),
        MyNode(nodeIds[6], 9),
      ];

      var myLinks = [
        MyLink(linkIds[1], myNodes[5], myNodes[0], 1),
        MyLink(linkIds[2], myNodes[4], myNodes[0], 2),
        MyLink(linkIds[3], myNodes[5], myNodes[2], 1),
        MyLink(linkIds[4], myNodes[4], myNodes[1], 1),
        MyLink(linkIds[5], myNodes[2], myNodes[3], 1),
        MyLink(linkIds[6], myNodes[3], myNodes[1], 2),
      ];

      var myGraph = Graph<MyNode, MyLink, String>(
          id: 'MyGraph',
          nodes: myNodes,
          links: myLinks,
          nodeDomainFn: (node, _) => node.domainId,
          linkDomainFn: (link, _) => link.domainId,
          sourceFn: (link, _) => link.sourceNode,
          targetFn: (link, _) => link.targetNode,
          nodeMeasureFn: (node, _) => node.measure,
          linkMeasureFn: (link, _) => link.measure);

      var multiSort = topologicalNodeSort(
          myGraph.nodes, myGraph.nodeDomainFn, myGraph.linkDomainFn);

      var firstIndex = multiSort
          .indexWhere((node) => nodeDomain(myGraph, node) == nodeIds[1]);
      var secondIndex = multiSort
          .indexWhere((node) => nodeDomain(myGraph, node) == nodeIds[2]);
      var thirdIndex = multiSort
          .indexWhere((node) => nodeDomain(myGraph, node) == nodeIds[3]);
      var fourthIndex = multiSort
          .indexWhere((node) => nodeDomain(myGraph, node) == nodeIds[4]);
      var fifthIndex = multiSort
          .indexWhere((node) => nodeDomain(myGraph, node) == nodeIds[5]);
      var sixthIndex = multiSort
          .indexWhere((node) => nodeDomain(myGraph, node) == nodeIds[6]);

      expect([
        firstIndex > sixthIndex,
        firstIndex > fifthIndex,
        thirdIndex > sixthIndex,
        fourthIndex > thirdIndex,
        secondIndex > fourthIndex,
        secondIndex > fifthIndex
      ], everyElement(isTrue));
    });

    test('throws UnsupportedError when graph contains a cycle', () {
      var myNodes = [
        MyNode(nodeIds[1], 4),
        MyNode(nodeIds[2], 5),
        MyNode(nodeIds[3], 6),
      ];

      var myLinks = [
        MyLink(linkIds[1], myNodes[0], myNodes[1], 1),
        MyLink(linkIds[2], myNodes[1], myNodes[2], 2),
        MyLink(linkIds[3], myNodes[2], myNodes[0], 3),
      ];

      var myGraph = Graph<MyNode, MyLink, String>(
          id: 'MyGraph',
          nodes: myNodes,
          links: myLinks,
          nodeDomainFn: (node, _) => node.domainId,
          linkDomainFn: (link, _) => link.domainId,
          sourceFn: (link, _) => link.sourceNode,
          targetFn: (link, _) => link.targetNode,
          nodeMeasureFn: (node, _) => node.measure,
          linkMeasureFn: (link, _) => link.measure);

      expect(
          () => topologicalNodeSort(
              myGraph.nodes, myGraph.nodeDomainFn, myGraph.linkDomainFn),
          throwsUnsupportedError);
    });

    test('throws UnsupportedError when graph contains long cycle', () {
      var myNodes = [
        MyNode(nodeIds[1], 4),
        MyNode(nodeIds[2], 5),
        MyNode(nodeIds[3], 6),
        MyNode(nodeIds[4], 7),
        MyNode(nodeIds[5], 8),
        MyNode(nodeIds[6], 9),
      ];

      var myLinks = [
        MyLink(linkIds[1], myNodes[5], myNodes[0], 1),
        MyLink(linkIds[2], myNodes[4], myNodes[0], 2),
        MyLink(linkIds[3], myNodes[5], myNodes[2], 1),
        MyLink(linkIds[4], myNodes[4], myNodes[1], 1),
        MyLink(linkIds[5], myNodes[2], myNodes[3], 1),
        MyLink(linkIds[6], myNodes[3], myNodes[1], 2),
        MyLink(linkIds[7], myNodes[1], myNodes[0], 1),
        MyLink(linkIds[8], myNodes[0], myNodes[2], 1),
      ];

      var myGraph = Graph<MyNode, MyLink, String>(
          id: 'MyGraph',
          nodes: myNodes,
          links: myLinks,
          nodeDomainFn: (node, _) => node.domainId,
          linkDomainFn: (link, _) => link.domainId,
          sourceFn: (link, _) => link.sourceNode,
          targetFn: (link, _) => link.targetNode,
          nodeMeasureFn: (node, _) => node.measure,
          linkMeasureFn: (link, _) => link.measure);

      expect(
          () => topologicalNodeSort(
              myGraph.nodes, myGraph.nodeDomainFn, myGraph.linkDomainFn),
          throwsUnsupportedError);
    });
  });

  group('SankeyGraphDataClass', () {
    test('returns null for null accessor functions', () {
      var myGraph = mockLinearGraph();

      expect(myGraph.nodeFillColorFn, null);
      expect(myGraph.linkFillColorFn, null);
      expect(myGraph.nodeFillPatternFn, null);
      expect(myGraph.nodeStrokeWidthPxFn, null);
    });

    test('executes accessor functions on a given node', () {
      var myGraph = mockLinearGraph();

      expect(nodeDomain(myGraph, myGraph.nodes[0]), nodeIds[1]);
      expect(nodeMeasure(myGraph, myGraph.nodes[0]), 4);
    });

    test('executes accessor functions on a given link', () {
      var myGraph = mockLinearGraph();

      expect(linkDomain(myGraph, myGraph.links[1]), linkIds[2]);
      expect(linkMeasure(myGraph, myGraph.links[0]), 1);
    });

    test('converts generic link into sankey graph link', () {
      var myGraph = mockLinearGraph();

      expect(nodeDomain(myGraph, myGraph.links[0].source),
          nodeDomain(myGraph, myGraph.nodes[0]));
      expect(nodeDomain(myGraph, myGraph.links[0].target),
          nodeDomain(myGraph, myGraph.nodes[1]));
      expect(myGraph.links[0].secondaryLinkMeasure, 1);
    });
    test('converts generic node into sankey graph node', () {
      var myGraph = mockLinearGraph();

      expect(myGraph.nodes[0].incomingLinks.length, 0);
      expect(linkDomain(myGraph, myGraph.nodes[0].outgoingLinks[0]),
          linkDomain(myGraph, myGraph.links[0]));
      expect(linkDomain(myGraph, myGraph.nodes[1].incomingLinks[0]),
          linkDomain(myGraph, myGraph.links[0]));
      expect(linkDomain(myGraph, myGraph.nodes[1].outgoingLinks[0]),
          linkDomain(myGraph, myGraph.links[1]));
      expect(myGraph.nodes[2].outgoingLinks.length, 0);
    });

    test('converts sankey graph data to series data', () {
      var myNodes = [
        MyNode(nodeIds[1], 4),
        MyNode(nodeIds[2], 5),
      ];

      var myLinks = [
        MyLink(linkIds[1], myNodes[0], myNodes[1], 1),
      ];

      var myGraph = SankeyGraph<MyNode, MyLink, String>(
          id: 'MyGraph',
          nodes: myNodes,
          links: myLinks,
          nodeDomainFn: (node, _) => node.domainId,
          linkDomainFn: (link, _) => link.domainId,
          sourceFn: (link, _) => link.sourceNode,
          targetFn: (link, _) => link.targetNode,
          nodeMeasureFn: (node, _) => node.measure,
          linkMeasureFn: (link, _) => link.measure,
          secondaryLinkMeasureFn: (link, _) => 1);

      List<Series<dynamic, String>> mySeriesList = myGraph.toSeriesList();

      expect(mySeriesList[0].domainFn(0), nodeIds[1]);
      expect(mySeriesList[0].measureFn(0), 4);
      expect(mySeriesList[0].id, 'MyGraph_nodes');
      expect(mySeriesList[1].domainFn(0), linkIds[1]);
      expect(mySeriesList[1].measureFn(0), 1);
      expect(mySeriesList[1].id, 'MyGraph_links');
      expect(nodeDomain(myGraph, mySeriesList[1].data[0].source), nodeIds[1]);
      expect(nodeDomain(myGraph, mySeriesList[1].data[0].target), nodeIds[2]);
      ;
      expect(mySeriesList[0].data[0].incomingLinks.length, 0);
      expect(mySeriesList[1].data[0].secondaryLinkMeasure, 1);
      expect(linkDomain(myGraph, mySeriesList[0].data[0].outgoingLinks[0]),
          linkDomain(myGraph, myGraph.links[0]));
      expect(linkDomain(myGraph, mySeriesList[0].data[1].incomingLinks[0]),
          linkDomain(myGraph, myGraph.links[0]));
      expect(mySeriesList[0].data[1].outgoingLinks.length, 0);
    });

    test('returns the height of a source node, which here is 3', () {
      var myGraph = mockStructureGraph();
      var sixthIndex = myGraph.nodes.indexWhere(
          (node) => myGraph.nodeDomainFn(node, indexNotRelevant) == nodeIds[6]);

      expect(myGraph.nodes[sixthIndex].height, 3);
    });

    test('returns the height of a sink node, which is zero', () {
      var myGraph = mockStructureGraph();
      var firstIndex = myGraph.nodes.indexWhere(
          (node) => myGraph.nodeDomainFn(node, indexNotRelevant) == nodeIds[1]);

      expect(myGraph.nodes[firstIndex].height, 0);
    });

    test('returns the depth of a source node, which is zero', () {
      var myGraph = mockStructureGraph();
      var fifthIndex = myGraph.nodes.indexWhere(
          (node) => myGraph.nodeDomainFn(node, indexNotRelevant) == nodeIds[5]);

      expect(myGraph.nodes[fifthIndex].depth, 0);
    });

    test('returns the depth of a graph node with depth 2', () {
      var myGraph = mockStructureGraph();
      var fourthIndex = myGraph.nodes.indexWhere(
          (node) => myGraph.nodeDomainFn(node, indexNotRelevant) == nodeIds[4]);

      expect(myGraph.nodes[fourthIndex].depth, 2);
    });

    test('returns the column of a node, which here should be 2', () {
      var myGraph = mockStructureGraph();
      var fourthIndex = myGraph.nodes.indexWhere(
          (node) => myGraph.nodeDomainFn(node, indexNotRelevant) == nodeIds[4]);

      expect(myGraph.nodes[fourthIndex].column, 2);
    });
  });
}

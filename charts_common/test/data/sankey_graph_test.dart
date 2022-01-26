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
import 'package:charts_common/src/data/graph.dart' as graph_structure
    show indexNotRelevant, Node;
import 'package:charts_common/src/data/sankey_graph.dart';
import 'package:test/test.dart';

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

SankeyGraph<MyNode, MyLink, String> mockLinearGraph() {
  var myNodes = [
    MyNode('Node 1', 4),
    MyNode('Node 2', 5),
    MyNode('Node 3', 6),
  ];

  var myLinks = [
    MyLink('Link A', myNodes[0], myNodes[1], 1),
    MyLink('Link B', myNodes[1], myNodes[2], 2),
  ];

  SankeyGraph<MyNode, MyLink, String> myGraph = SankeyGraph(
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

String nodeDomain(Graph<MyNode, MyLink, String> myGraph,
        graph_structure.Node<MyNode, MyLink> node) =>
    myGraph.nodeDomainFn(node, graph_structure.indexNotRelevant);

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

      expect(
          myGraph.nodeDomainFn(
              myGraph.nodes[0], graph_structure.indexNotRelevant),
          'Node 1');
      expect(
          myGraph.nodeMeasureFn(
              myGraph.nodes[0], graph_structure.indexNotRelevant),
          4);
    });

    test('executes accessor functions on a given link', () {
      var myGraph = mockLinearGraph();

      expect(
          myGraph.linkDomainFn(
              myGraph.links[1], graph_structure.indexNotRelevant),
          'Link B');
      expect(
          myGraph.linkMeasureFn(
              myGraph.links[0], graph_structure.indexNotRelevant),
          1);
    });

    test('converts generic link into sankey graph link', () {
      var myGraph = mockLinearGraph();

      expect(
          myGraph.nodeDomainFn(
              myGraph.links[0].source, graph_structure.indexNotRelevant),
          myGraph.nodeDomainFn(
              myGraph.nodes[0], graph_structure.indexNotRelevant));
      expect(
          myGraph.nodeDomainFn(
              myGraph.links[0].target, graph_structure.indexNotRelevant),
          myGraph.nodeDomainFn(
              myGraph.nodes[1], graph_structure.indexNotRelevant));
      expect(myGraph.links[0].secondaryLinkMeasure, 1);
    });

    test('converts generic node into sankey graph node', () {
      var myGraph = mockLinearGraph();

      expect(myGraph.nodes[0].incomingLinks.length, 0);
      expect(
          myGraph.linkDomainFn(myGraph.nodes[0].outgoingLinks[0],
              graph_structure.indexNotRelevant),
          myGraph.linkDomainFn(
              myGraph.links[0], graph_structure.indexNotRelevant));
      expect(
          myGraph.linkDomainFn(myGraph.nodes[1].incomingLinks[0],
              graph_structure.indexNotRelevant),
          myGraph.linkDomainFn(
              myGraph.links[0], graph_structure.indexNotRelevant));
      expect(
          myGraph.linkDomainFn(myGraph.nodes[1].outgoingLinks[0],
              graph_structure.indexNotRelevant),
          myGraph.linkDomainFn(
              myGraph.links[1], graph_structure.indexNotRelevant));
      expect(myGraph.nodes[2].outgoingLinks.length, 0);
    });

    test('converts sankey graph data to series data', () {
      var myNodes = [
        MyNode('Node 1', 4),
        MyNode('Node 2', 5),
      ];

      var myLinks = [
        MyLink('Link A', myNodes[0], myNodes[1], 1),
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

      expect(mySeriesList[0].domainFn(0), 'Node 1');
      expect(mySeriesList[0].measureFn(0), 4);
      expect(mySeriesList[0].id, 'MyGraph_nodes');
      expect(mySeriesList[1].domainFn(0), 'Link A');
      expect(mySeriesList[1].measureFn(0), 1);
      expect(mySeriesList[1].id, 'MyGraph_links');
      expect(
          myGraph.nodeDomainFn(
              mySeriesList[1].data[0].source, graph_structure.indexNotRelevant),
          'Node 1');
      expect(
          myGraph.nodeDomainFn(
              mySeriesList[1].data[0].target, graph_structure.indexNotRelevant),
          'Node 2');
      expect(mySeriesList[0].data[0].incomingLinks.length, 0);
      expect(mySeriesList[1].data[0].secondaryLinkMeasure, 1);
      expect(
          myGraph.linkDomainFn(mySeriesList[0].data[0].outgoingLinks[0],
              graph_structure.indexNotRelevant),
          myGraph.linkDomainFn(
              myGraph.links[0], graph_structure.indexNotRelevant));
      expect(
          myGraph.linkDomainFn(mySeriesList[0].data[1].incomingLinks[0],
              graph_structure.indexNotRelevant),
          myGraph.linkDomainFn(
              myGraph.links[0], graph_structure.indexNotRelevant));
      expect(mySeriesList[0].data[1].outgoingLinks.length, 0);
    });
  });
}

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
    show indexNotRelevant, Link, Node;
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

var myMockNodes = [
  MyNode(nodeIds[1], 4),
  MyNode(nodeIds[2], 5),
  MyNode(nodeIds[3], 6),
];

var myMockLinks = [
  MyLink(linkIds[1], myMockNodes[0], myMockNodes[1], 1),
  MyLink(linkIds[2], myMockNodes[1], myMockNodes[2], 2),
];

Graph<MyNode, MyLink, String> mockLinearGraph() {
  var myGraph = Graph<MyNode, MyLink, String>(
      id: 'MyGraph',
      nodes: myMockNodes,
      links: myMockLinks,
      nodeDomainFn: (node, _) => node.domainId,
      linkDomainFn: (link, _) => link.domainId,
      sourceFn: (link, _) => link.sourceNode,
      targetFn: (link, _) => link.targetNode,
      nodeMeasureFn: (node, _) => node.measure,
      linkMeasureFn: (link, _) => link.measure);

  return myGraph;
}

String nodeDomain(Graph<MyNode, MyLink, String> myGraph,
        graph_structure.Node<MyNode, MyLink> node) =>
    myGraph.nodeDomainFn(node, graph_structure.indexNotRelevant);

String linkDomain(Graph<MyNode, MyLink, String> myGraph,
        graph_structure.Link<MyNode, MyLink> link) =>
    myGraph.linkDomainFn(link, graph_structure.indexNotRelevant);

num nodeMeasure(Graph<MyNode, MyLink, String> myGraph,
        graph_structure.Node<MyNode, MyLink> node) =>
    myGraph.nodeMeasureFn(node, graph_structure.indexNotRelevant)!;

num linkMeasure(Graph<MyNode, MyLink, String> myGraph,
        graph_structure.Link<MyNode, MyLink> link) =>
    myGraph.linkMeasureFn(link, graph_structure.indexNotRelevant)!;

void main() {
  group('GraphDataClass', () {
    test('returns null for null accessor functions', () {
      var myGraph = mockLinearGraph();

      expect(myGraph.nodeFillColorFn, null);
      expect(myGraph.linkFillColorFn, null);
      expect(myGraph.nodeFillPatternFn, null);
      expect(myGraph.nodeStrokeWidthPxFn, null);
    });

    test('converts generic node into standard graph node', () {
      var myGraph = mockLinearGraph();
      expect(myGraph.nodes.map((node) => nodeDomain(myGraph, node)).toList(),
          [nodeIds[1], nodeIds[2], nodeIds[3]]);
      expect(myGraph.nodes.length, 3);
      expect(myGraph.nodes.map((node) => nodeMeasure(myGraph, node)).toList(),
          [4, 5, 6]);
    });

    test('executes accessor functions on a given link', () {
      var myGraph = mockLinearGraph();

      expect(linkDomain(myGraph, myGraph.links[1]), linkIds[2]);
      expect(linkMeasure(myGraph, myGraph.links[0]), 1);
    });

    test('converts generic link into standard graph link', () {
      var myGraph = mockLinearGraph();

      expect(nodeDomain(myGraph, myGraph.links[0].source),
          nodeDomain(myGraph, myGraph.nodes[0]));
      expect(nodeDomain(myGraph, myGraph.links[0].target),
          nodeDomain(myGraph, myGraph.nodes[1]));
      expect(linkDomain(myGraph, myGraph.links[0]), linkIds[1]);
      expect(linkDomain(myGraph, myGraph.links[1]), linkIds[2]);
      expect(linkMeasure(myGraph, myGraph.links[0]), 1);
      expect(linkMeasure(myGraph, myGraph.links[1]), 2);
      expect(myGraph.links.length, 2);
    });
    test('add ingoing and outgoing links to node', () {
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
    test('preserves graph specific data when converting to series', () {
      var myNodes = [
        MyNode(nodeIds[1], 4),
        MyNode(nodeIds[2], 5),
      ];

      var myLinks = [
        MyLink(linkIds[1], myNodes[0], myNodes[1], 1),
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

      List<Series<dynamic, String>> mySeriesList = myGraph.toSeriesList();

      expect(mySeriesList[0].domainFn(0), nodeIds[1]);
      expect(mySeriesList[0].measureFn(0), 4);
      expect(mySeriesList[0].id, 'MyGraph_nodes');
      expect(mySeriesList[1].domainFn(0), linkIds[1]);
      expect(mySeriesList[1].measureFn(0), 1);
      expect(mySeriesList[1].id, 'MyGraph_links');
      expect(nodeDomain(myGraph, mySeriesList[1].data[0].source), nodeIds[1]);
      expect(nodeDomain(myGraph, mySeriesList[1].data[0].target), nodeIds[2]);
      expect(mySeriesList[0].data[0].incomingLinks.length, 0);
      expect(linkDomain(myGraph, mySeriesList[0].data[0].outgoingLinks[0]),
          linkDomain(myGraph, myGraph.links[0]));
      expect(linkDomain(myGraph, mySeriesList[0].data[1].incomingLinks[0]),
          linkDomain(myGraph, myGraph.links[0]));
      expect(mySeriesList[0].data[1].outgoingLinks.length, 0);
    });
  });
}

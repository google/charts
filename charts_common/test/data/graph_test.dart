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

Graph<MyNode, MyLink, String> mockLinearGraph() {
  List<MyNode> myNodes = [
    MyNode('Node 1', 4),
    MyNode('Node 2', 5),
    MyNode('Node 3', 6),
  ];

  List<MyLink> myLinks = [
    MyLink('Link A', myNodes[0], myNodes[1], 1),
    MyLink('Link B', myNodes[1], myNodes[2], 2),
  ];

  Graph<MyNode, MyLink, String> myGraph = Graph(
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

void main() {
  group('GraphDataClass', () {
    test('returns null for null accessor functions', () {
      Graph<MyNode, MyLink, String> myGraph = mockLinearGraph();

      expect(myGraph.nodeFillColorFn, null);
      expect(myGraph.linkFillColorFn, null);
      expect(myGraph.nodeFillPatternFn, null);
      expect(myGraph.nodeStrokeWidthPxFn, null);
    });

    test('converts generic node into standard graph node', () {
      Graph<MyNode, MyLink, String> myGraph = mockLinearGraph();

      expect(myGraph.nodeDomainFn(myGraph.nodes[0], 1), 'Node 1');
      expect(myGraph.nodeDomainFn(myGraph.nodes[1], 1), 'Node 2');
      expect(myGraph.nodeDomainFn(myGraph.nodes[2], 1), 'Node 3');
      expect(myGraph.nodes.length, 3);
      expect(myGraph.nodeMeasureFn(myGraph.nodes[0], 1), 4);
      expect(myGraph.nodeMeasureFn(myGraph.nodes[1], 1), 5);
      expect(myGraph.nodeMeasureFn(myGraph.nodes[2], 1), 6);
    });

    test('executes accessor functions on a given link', () {
      Graph<MyNode, MyLink, String> myGraph = mockLinearGraph();

      expect(myGraph.linkDomainFn(myGraph.links[1], 1), 'Link B');
      expect(myGraph.linkMeasureFn(myGraph.links[0], 1), 1);
    });

    test('converts generic link into standard graph link', () {
      Graph<MyNode, MyLink, String> myGraph = mockLinearGraph();

      expect(myGraph.nodeDomainFn(myGraph.links[0].source, 0),
          myGraph.nodeDomainFn(myGraph.nodes[0], 0));
      expect(myGraph.nodeDomainFn(myGraph.links[0].target, 0),
          myGraph.nodeDomainFn(myGraph.nodes[1], 0));
      expect(myGraph.linkDomainFn(myGraph.links[0], 1), 'Link A');
      expect(myGraph.linkDomainFn(myGraph.links[1], 1), 'Link B');
      expect(myGraph.linkMeasureFn(myGraph.links[0], 1), 1);
      expect(myGraph.linkMeasureFn(myGraph.links[1], 1), 2);
      expect(myGraph.links.length, 2);
    });
    test('add ingoing and outgoing links to node', () {
      Graph<MyNode, MyLink, String> myGraph = mockLinearGraph();

      expect(myGraph.nodes[0].incomingLinks.length, 0);
      expect(myGraph.linkDomainFn(myGraph.nodes[0].outgoingLinks[0], 0),
          myGraph.linkDomainFn(myGraph.links[0], 0));
      expect(myGraph.linkDomainFn(myGraph.nodes[1].incomingLinks[0], 0),
          myGraph.linkDomainFn(myGraph.links[0], 0));
      expect(myGraph.linkDomainFn(myGraph.nodes[1].outgoingLinks[0], 0),
          myGraph.linkDomainFn(myGraph.links[1], 0));
      expect(myGraph.nodes[2].outgoingLinks.length, 0);
    });
    test('preserves graph specific data when converting to series', () {
      // Create a list of nodes
      List<MyNode> myNodes = [
        MyNode('Node 1', 4),
        MyNode('Node 2', 5),
      ];

      // Create a list of links
      List<MyLink> myLinks = [
        MyLink('Link A', myNodes[0], myNodes[1], 1),
      ];

      // Create a Graph
      Graph<MyNode, MyLink, String> myGraph = Graph(
          id: 'MyGraph',
          nodes: myNodes,
          links: myLinks,
          nodeDomainFn: (node, _) => node.domainId,
          linkDomainFn: (link, _) => link.domainId,
          sourceFn: (link, _) => link.sourceNode,
          targetFn: (link, _) => link.targetNode,
          nodeMeasureFn: (node, _) => node.measure,
          linkMeasureFn: (link, _) => link.measure);

      // Convert graph into a SeriesList
      List<Series<dynamic, String>> mySeriesList = myGraph.toSeriesList();

      expect(mySeriesList[0].domainFn(0), 'Node 1');
      expect(mySeriesList[0].measureFn(0), 4);
      expect(mySeriesList[0].id, 'MyGraph_nodes');
      expect(mySeriesList[1].domainFn(0), 'Link A');
      expect(mySeriesList[1].measureFn(0), 1);
      expect(mySeriesList[1].id, 'MyGraph_links');
      expect(myGraph.nodeDomainFn(mySeriesList[1].data[0].source, 0), 'Node 1');
      expect(myGraph.nodeDomainFn(mySeriesList[1].data[0].target, 0), 'Node 2');
      expect(mySeriesList[0].data[0].incomingLinks.length, 0);
      expect(myGraph.linkDomainFn(mySeriesList[0].data[0].outgoingLinks[0], 0),
          myGraph.linkDomainFn(myGraph.links[0], 0));
      expect(myGraph.linkDomainFn(mySeriesList[0].data[1].incomingLinks[0], 0),
          myGraph.linkDomainFn(myGraph.links[0], 0));
      expect(mySeriesList[0].data[1].outgoingLinks.length, 0);
    });
  });
}

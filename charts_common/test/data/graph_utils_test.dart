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
import 'package:charts_common/src/data/graph_utils.dart' as utils;
import 'package:charts_common/src/data/graph.dart';

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

var myMockNodes = [
  MyNode('Node 1', 4),
  MyNode('Node 2', 5),
  MyNode('Node 3', 6),
];

var myMockLinks = [
  MyLink('Link A', myMockNodes[0], myMockNodes[1], 1),
  MyLink('Link B', myMockNodes[1], myMockNodes[2], 2),
];

var testLink1 = GraphLink<MyNode, MyLink>((b) => b
  ..source = GraphNode<MyNode, MyLink>((b) => b
    ..data = myMockNodes[0]
    ..incomingLinks = <GraphLink<MyNode, MyLink>>[]
    ..outgoingLinks = <GraphLink<MyNode, MyLink>>[])
  ..target = GraphNode<MyNode, MyLink>((b) => b
    ..data = myMockNodes[1]
    ..incomingLinks = <GraphLink<MyNode, MyLink>>[]
    ..outgoingLinks = <GraphLink<MyNode, MyLink>>[])
  ..data = myMockLinks[0]);
var testLink2 = GraphLink<MyNode, MyLink>((b) => b
  ..source = GraphNode<MyNode, MyLink>((b) => b
    ..data = myMockNodes[1]
    ..incomingLinks = <GraphLink<MyNode, MyLink>>[]
    ..outgoingLinks = <GraphLink<MyNode, MyLink>>[])
  ..target = GraphNode<MyNode, MyLink>((b) => b
    ..data = myMockNodes[2]
    ..incomingLinks = <GraphLink<MyNode, MyLink>>[]
    ..outgoingLinks = <GraphLink<MyNode, MyLink>>[])
  ..data = myMockLinks[1]);

void main() {
  group('actOnNodes', () {
    test('returns null for null functions', () {
      var nullMeasure = utils.actOnNodeData<MyNode, MyLink, num>(null);

      expect(nullMeasure, null);
    });

    test('returns data for non-null functions', () {
      TypedAccessorFn<MyNode, String> getDomain = (node, _) => node.domainId;
      TypedAccessorFn<MyNode, num> getMeasure = (node, _) => node.measure;
      var domainFn = utils.actOnNodeData<MyNode, MyLink, String>(getDomain)!;
      var measureFn = utils.actOnNodeData<MyNode, MyLink, num>(getMeasure)!;

      expect(
          domainFn(
              GraphNode((b) => b
                ..data = myMockNodes[0]
                ..incomingLinks = <GraphLink<MyNode, MyLink>>[]
                ..outgoingLinks = <GraphLink<MyNode, MyLink>>[]),
              indexNotRelevant),
          getDomain(myMockNodes[0], indexNotRelevant));
      expect(
          measureFn(
              GraphNode((b) => b
                ..data = myMockNodes[0]
                ..incomingLinks = <GraphLink<MyNode, MyLink>>[]
                ..outgoingLinks = <GraphLink<MyNode, MyLink>>[]),
              indexNotRelevant),
          getMeasure(myMockNodes[0], indexNotRelevant));
    });
  });

  group('actOnLinks', () {
    test('returns null for null functions', () {
      var nullMeasure = utils.actOnLinkData<MyNode, MyLink, num>(null);

      expect(nullMeasure, null);
    });

    test('returns data for non-null functions', () {
      TypedAccessorFn<MyLink, String> getDomain = (link, _) => link.domainId;
      TypedAccessorFn<MyLink, num> getMeasure = (link, _) => link.measure;
      var domainFn = utils.actOnLinkData<MyNode, MyLink, String>(getDomain)!;
      var measureFn = utils.actOnLinkData<MyNode, MyLink, num>(getMeasure)!;

      expect(domainFn(testLink1, indexNotRelevant),
          getDomain(myMockLinks[0], indexNotRelevant));
      expect(measureFn(testLink1, indexNotRelevant),
          getMeasure(myMockLinks[0], indexNotRelevant));
    });
  });

  group('utils.addLinkToNode', () {
    test('adds link to corresponding list on node', () {
      utils.Node<MyNode, MyLink> node = GraphNode<MyNode, MyLink>((b) => b
        ..data = myMockNodes[2]
        ..incomingLinks = <GraphLink<MyNode, MyLink>>[]
        ..outgoingLinks = <GraphLink<MyNode, MyLink>>[]);
      node = utils.addLinkToNode(node, testLink1, isIncomingLink: true);
      node = utils.addLinkToNode(node, testLink2, isIncomingLink: false);

      expect(node.incomingLinks.length, 1);
      expect(node.outgoingLinks.length, 1);
      expect(node.incomingLinks[0], testLink1);
      expect(node.outgoingLinks[0], testLink2);
    });

    test('adds link to corresponding list on absent node', () {
      var nodeWithIncoming =
          utils.addLinkToAbsentNode(testLink2, isIncomingLink: true);
      var nodeWithOutgoing =
          utils.addLinkToAbsentNode(testLink1, isIncomingLink: false);

      expect(nodeWithIncoming.incomingLinks.length, 1);
      expect(nodeWithIncoming.outgoingLinks.length, 0);
      expect(nodeWithOutgoing.outgoingLinks.length, 1);
      expect(nodeWithOutgoing.incomingLinks.length, 0);
      expect(nodeWithIncoming.incomingLinks[0], testLink2);
      expect(nodeWithOutgoing.outgoingLinks[0], testLink1);
    });
  });

  group('utils.accessorIfExists', () {
    test('calls function when not null', () {
      TypedAccessorFn<MyNode, String> getDomain = (node, _) => node.domainId;
      TypedAccessorFn<MyNode, num> getMeasure = (node, _) => node.measure;

      expect(
          utils.accessorIfExists(getDomain, myMockNodes[0], indexNotRelevant),
          'Node 1');
      expect(
          utils.accessorIfExists(getMeasure, myMockNodes[0], indexNotRelevant),
          4);
      expect(
          utils.accessorIfExists(null, myMockNodes[1], indexNotRelevant), null);
    });
  });
}

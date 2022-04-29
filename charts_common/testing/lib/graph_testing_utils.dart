/// Contains utilities for testing Charts graphs.
///
/// Intended to reduce boilerplate by providing implementations and sample
/// collections of nodes, links, etc.
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

var nodeIds = List.generate(6, (index) => 'Node $index');

var linkIds = List.generate(9, (index) => 'Link $index');

var mockLinearNodes = [
  MyNode(nodeIds[0], 4),
  MyNode(nodeIds[1], 5),
  MyNode(nodeIds[2], 6),
];

var mockLinearLinks = [
  MyLink(linkIds[0], mockLinearNodes[0], mockLinearNodes[1], 1),
  MyLink(linkIds[1], mockLinearNodes[1], mockLinearNodes[2], 2),
];

/// A simple node implementation for use in testing charts.
class MyNode {
  /// An identifier that differentiates this Node from others.
  final String domainId;

  /// A quantity associated with this node.
  final num measure;

  MyNode(this.domainId, this.measure);
}

/// A simple link implementation for use in testing charts.
class MyLink {
  /// An identifier that differentiates this Link from others.
  final String domainId;

  /// A quantity associated with this link.
  final num measure;

  /// The beginning node of this link.
  final MyNode source;

  /// The end node of this link.
  final MyNode target;

  MyLink(this.domainId, this.source, this.target, this.measure);
}

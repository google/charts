// Copyright 2018 the Charts project authors. Please see the AUTHORS file
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

import 'package:flutter/material.dart';
import '../gallery_scaffold.dart';
import 'initial_selection.dart';
import 'selection_bar_highlight.dart';
import 'selection_line_highlight.dart';
import 'selection_callback_example.dart';

List<GalleryScaffold> buildGallery() {
  return [
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.flag),
      title: 'Selection Bar Highlight',
      subtitle: 'Simple bar chart with tap activation',
      childBuilder: () => new SelectionBarHighlight.withRandomData(),
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.flag),
      title: 'Selection Line Highlight',
      subtitle: 'Line chart with tap and drag activation',
      childBuilder: () => new SelectionLineHighlight.withRandomData(),
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.flag),
      title: 'Selection Callback Example',
      subtitle: 'Timeseries that updates external components on selection',
      childBuilder: () => new SelectionCallbackExample.withRandomData(),
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.insert_chart),
      title: 'Bar Chart with initial selection',
      subtitle: 'Single series with initial selection',
      childBuilder: () => new InitialSelection.withRandomData(),
    ),
  ];
}

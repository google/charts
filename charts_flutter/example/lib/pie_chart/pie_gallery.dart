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
import 'donut.dart';
import 'auto_label.dart';
import 'simple.dart';
import 'outside_label.dart';
import 'radar.dart';
import 'radar_donut.dart';

List<GalleryScaffold> buildGallery() {
  return [
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.pie_chart),
      title: 'Simple Pie Chart',
      subtitle: 'With a single series',
      childBuilder: () => new SimplePieChart.withRandomData(),
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.pie_chart),
      title: 'Outside Label Pie Chart',
      subtitle: 'With a single series and labels outside the arcs',
      childBuilder: () => new PieOutsideLabelChart.withRandomData(),
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.pie_chart),
      title: 'Simple Donut Chart',
      subtitle: 'With a single series and a hole in the middle',
      childBuilder: () => new DonutPieChart.withRandomData(),
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.pie_chart),
      title: 'Auto Label Donut Chart',
      subtitle:
          'With a single series, a hole in the middle, and auto-positioned labels',
      childBuilder: () => new DonutAutoLabelChart.withRandomData(),
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.pie_chart_outlined),
      title: 'Radar Pie Chart',
      subtitle: 'With a single series and labels outside the arcs',
      childBuilder: () => new RadarPieChart.withRandomData(),
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.pie_chart_outlined),
      title: 'Radar Donut Chart',
      subtitle: 'With a single series and a hole in the middle',
      childBuilder: () => new RadarDonutPieChart.withRandomData(),
    ),
  ];
}

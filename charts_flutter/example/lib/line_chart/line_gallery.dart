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
import 'animation_zoom.dart';
import 'area_and_line.dart';
import 'dash_pattern.dart';
import 'points.dart';
import 'range_annotation.dart';
import 'simple.dart';
import 'stacked_area.dart';

List<GalleryScaffold> buildGallery() {
  return [
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.show_chart),
      title: 'Simple Line Chart',
      subtitle: 'With a single series and default line point highlighter',
      childBuilder: () => new SimpleLineChart.withRandomData(),
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.show_chart),
      title: 'Stacked Area Chart',
      subtitle: 'Stacked area chart with three series',
      childBuilder: () => new StackedAreaLineChart.withRandomData(),
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.show_chart),
      title: 'Area and Line Combo Chart',
      subtitle: 'Combo chart with one line series and one area series',
      childBuilder: () => new AreaAndLineChart.withRandomData(),
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.show_chart),
      title: 'Points Line Chart',
      subtitle: 'Line chart with points on a single series',
      childBuilder: () => new PointsLineChart.withRandomData(),
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.show_chart),
      title: 'Dash Pattern Line Chart',
      subtitle: 'With three series and default line point highlighter',
      childBuilder: () => new DashPatternLineChart.withRandomData(),
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.show_chart),
      title: 'Range Annotation Line Chart',
      subtitle: 'Line chart with range annotations',
      childBuilder: () => new LineRangeAnnotationChart.withRandomData(),
    ),
    new GalleryScaffold(
      listTileIcon: new Icon(Icons.show_chart),
      title: 'Pan and Zoom Line Chart',
      subtitle: 'Simple line chart pan and zoom behaviors enabled',
      childBuilder: () => new LineAnimationZoomChart.withRandomData(),
    ),
  ];
}

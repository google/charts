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
import 'dash_pattern.dart';
import 'range_annotation.dart';
import 'simple.dart';

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

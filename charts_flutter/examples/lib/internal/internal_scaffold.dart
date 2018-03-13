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

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

typedef Widget GalleryWidgetBuilder(List<charts.Series> seriesList);
typedef List<charts.Series> SeriesListBuilder();

/// Helper to build gallery.
class InternalScaffold extends StatelessWidget {
  /// The widget used for leading in a [ListTile].
  final String title;
  final Widget child;

  InternalScaffold({this.title, this.child});

  /// Gets the gallery
  Widget buildGalleryListTile(BuildContext context) => new ListTile(
      title: new Text(title),
      onTap: () {
        Navigator.push(context, new MaterialPageRoute(builder: (_) => this));
      });

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text(title)),
      body: new Padding(
          padding: const EdgeInsets.all(8.0),
          child: new ListView(children: <Widget>[
            new SizedBox(height: 250.0, child: child),
          ])),
    );
  }
}

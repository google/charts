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

class ImageTest extends StatelessWidget {
  static const _chartHeight = 220.0;

  /// The title for this chart used to navigate to the chart.
  final String title;

  /// The chart widget.
  final Widget child;

  ImageTest(this.title, this.child);

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
        child: new Text(title),
        onTap: () {
          Navigator.push(context,
              new _LowTransitionMaterialPageRouter(builder: (_) {
            return new Scaffold(
              appBar: new AppBar(
                title: new Text(title, style: new TextStyle(fontSize: 14.0)),
                elevation: 0.0,
                backgroundColor: Colors.transparent,
              ),
              body: new ListView(
                padding: kMaterialListPadding,
                children: [
                  new SizedBox(
                    height: _chartHeight,
                    child: child,
                  ),
                ],
              ),
            );
          }));
        });
  }
}

/// Hack the existing [MaterialPageRoute] with low transition for image tests.
class _LowTransitionMaterialPageRouter extends MaterialPageRoute {
  _LowTransitionMaterialPageRouter({WidgetBuilder builder})
      : super(builder: builder);

  /// Transition duration needs to be non zero or else the animation dismissed
  /// is not set.
  @override
  Duration get transitionDuration => const Duration(milliseconds: 1);
}

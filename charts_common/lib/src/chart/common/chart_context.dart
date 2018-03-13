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

import '../../common/date_time_factory.dart';
import '../../common/rtl_spec.dart' show RTLSpec;
import '../common/behavior/a11y/a11y_node.dart' show A11yNode;

abstract class ChartContext {
  bool get rtl;

  RTLSpec get rtlSpec;

  double get pixelsPerDp;

  DateTimeFactory get dateTimeFactory;

  void requestRedraw();

  void requestAnimation(Duration transition);

  void requestPaint();

  void enableA11yExploreMode(List<A11yNode> nodes, {String announcement});

  void disableA11yExploreMode({String announcement});
}

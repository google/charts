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

import '../base_chart.dart';

/// Interface for adding behavior to a chart.
///
/// For example pan and zoom are implemented via behavior strategies.
abstract class ChartBehavior<T, D> {
  String get role;

  /// Injects the behavior into a chart.
  void attachTo(BaseChart<T, D> chart);

  /// Removes the behavior from a chart.
  void removeFrom(BaseChart<T, D> chart);
}

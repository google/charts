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

import 'package:charts_common/src/chart/common/base_chart.dart';
import 'package:charts_common/src/chart/common/datum_details.dart';
import 'package:charts_common/src/chart/common/selection_model/selection_model.dart';
import 'package:charts_common/src/chart/common/series_renderer.dart';
import 'package:charts_common/src/chart/layout/layout_config.dart';

import 'package:charts_common/src/chart/link/link_renderer.dart';

class LinkChart<D> extends BaseChart<D> {
  LinkChart({LayoutConfig? layoutConfig})
      : super(layoutConfig: layoutConfig ?? LayoutConfig());

  /// Uses LinkRenderer as the default renderer.
  @override
  SeriesRenderer<D> makeDefaultRenderer() {
    return LinkRenderer<D>()..rendererId = SeriesRenderer.defaultRendererId;
  }

  /// Returns a list of datum details from the selection model of [type].
  @override
  List<DatumDetails<D>> getDatumDetails(SelectionModelType type) {
    return <DatumDetails<D>>[];
  }
}

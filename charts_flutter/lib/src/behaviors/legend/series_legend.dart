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

import 'package:charts_common/common.dart' as common
    show
        BehaviorPosition,
        InsideJustification,
        LegendEntry,
        LegendTapHandling,
        OutsideJustification,
        SeriesLegend,
        SelectionModelType;
import 'package:collection/collection.dart' show ListEquality;
import 'package:flutter/widgets.dart'
    show BuildContext, EdgeInsets, Widget, hashValues;
import 'package:meta/meta.dart' show immutable;
import '../../chart_container.dart' show ChartContainerRenderObject;
import '../chart_behavior.dart'
    show BuildableBehavior, ChartBehavior, GestureType;
import 'legend.dart' show TappableLegend;
import 'legend_content_builder.dart'
    show LegendContentBuilder, TabularLegendContentBuilder;
import 'legend_layout.dart' show TabularLegendLayout;

/// Series legend behavior for charts.
@immutable
class SeriesLegend extends ChartBehavior<common.SeriesLegend> {
  final desiredGestures = new Set<GestureType>();

  final common.SelectionModelType selectionModelType;

  /// Builder for creating custom legend content.
  final LegendContentBuilder contentBuilder;

  /// Position of the legend relative to the chart.
  final common.BehaviorPosition position;

  /// Justification of the legend relative to the chart
  final common.OutsideJustification outsideJustification;
  final common.InsideJustification insideJustification;

  static const defaultCellPadding = const EdgeInsets.all(8.0);

  final List<String> defaultHiddenSeries;

  /// Create a new tabular layout legend.
  ///
  /// By default, the legend is place above the chart and horizontally aligned
  /// to the start of the draw area.
  ///
  /// [position] the legend will be positioned relative to the chart. Default
  /// position is top.
  ///
  /// [outsideJustification] justification of the legend relative to the chart
  /// if the position is top, bottom, left, right. Default to start of the draw
  /// area.
  ///
  /// [insideJustification] justification of the legend relative to the chart if
  /// the position is inside. Default to top of the chart, start of draw area.
  /// Start of draw area means left for LTR directionality, and right for RTL.
  ///
  /// [horizontalFirst] if true, legend entries will grow horizontally first
  /// instead of vertically first. If the position is top, bottom, or inside,
  /// this defaults to true. Otherwise false.
  ///
  /// [desiredMaxRows] the max rows to use before layout out items in a new
  /// column. By default there is no limit. The max columns created is the
  /// smaller of desiredMaxRows and number of legend entries.
  ///
  /// [desiredMaxColumns] the max columns to use before laying out items in a
  /// new row. By default there is no limit. The max columns created is the
  /// smaller of desiredMaxColumns and number of legend entries.
  ///
  /// [defaultHiddenSeries] lists the IDs of series that should be hidden on
  /// first chart draw.
  factory SeriesLegend({
    common.BehaviorPosition position,
    common.OutsideJustification outsideJustification,
    common.InsideJustification insideJustification,
    bool horizontalFirst,
    int desiredMaxRows,
    int desiredMaxColumns,
    EdgeInsets cellPadding,
    List<String> defaultHiddenSeries,
  }) {
    // Set defaults if empty.
    position ??= common.BehaviorPosition.top;
    outsideJustification ??= common.OutsideJustification.startDrawArea;
    insideJustification ??= common.InsideJustification.topStart;
    cellPadding ??= defaultCellPadding;

    // Set the tabular layout settings to match the position if it is not
    // specified.
    horizontalFirst ??= (position == common.BehaviorPosition.top ||
        position == common.BehaviorPosition.bottom ||
        position == common.BehaviorPosition.inside);
    final layoutBuilder = horizontalFirst
        ? new TabularLegendLayout.horizontalFirst(
            desiredMaxColumns: desiredMaxColumns, cellPadding: cellPadding)
        : new TabularLegendLayout.verticalFirst(
            desiredMaxRows: desiredMaxRows, cellPadding: cellPadding);

    return new SeriesLegend._internal(
        contentBuilder:
            new TabularLegendContentBuilder(legendLayout: layoutBuilder),
        selectionModelType: common.SelectionModelType.info,
        position: position,
        outsideJustification: outsideJustification,
        insideJustification: insideJustification,
        defaultHiddenSeries: defaultHiddenSeries);
  }

  SeriesLegend._internal(
      {this.contentBuilder,
      this.selectionModelType,
      this.position,
      this.outsideJustification,
      this.insideJustification,
      this.defaultHiddenSeries});

  @override
  common.SeriesLegend<D> createCommonBehavior<D>() =>
      new _FlutterSeriesLegend<D>(this);

  @override
  void updateCommonBehavior(common.SeriesLegend commonBehavior) {
    (commonBehavior as _FlutterSeriesLegend).config = this;
  }

  @override
  String get role => 'legend-${selectionModelType.toString()}';

  @override
  bool operator ==(Object o) {
    return o is SeriesLegend &&
        selectionModelType == o.selectionModelType &&
        contentBuilder == o.contentBuilder &&
        position == o.position &&
        outsideJustification == o.outsideJustification &&
        insideJustification == o.insideJustification &&
        new ListEquality().equals(defaultHiddenSeries, o.defaultHiddenSeries);
  }

  @override
  int get hashCode {
    return hashValues(selectionModelType, contentBuilder, position,
        outsideJustification, insideJustification, defaultHiddenSeries);
  }
}

/// Flutter specific wrapper on the common Legend for building content.
class _FlutterSeriesLegend<D> extends common.SeriesLegend<D>
    implements BuildableBehavior, TappableLegend {
  SeriesLegend config;

  _FlutterSeriesLegend(this.config)
      : super(selectionModelType: config.selectionModelType) {
    super.defaultHiddenSeries = config.defaultHiddenSeries;
  }

  @override
  void updateLegend() {
    (chartContext as ChartContainerRenderObject).requestRebuild();
  }

  @override
  common.BehaviorPosition get position => config.position;

  @override
  common.OutsideJustification get outsideJustification =>
      config.outsideJustification;

  @override
  common.InsideJustification get insideJustification =>
      config.insideJustification;

  @override
  Widget build(BuildContext context) =>
      config.contentBuilder.build(context, legendState, this);

  @override
  onLegendEntryTapUp(common.LegendEntry detail) {
    switch (legendTapHandling) {
      case common.LegendTapHandling.hide:
        _hideSeries(detail);
        break;

      case common.LegendTapHandling.none:
      default:
        break;
    }
  }

  /// Handles tap events by hiding or un-hiding entries tapped in the legend.
  ///
  /// Tapping on a visible series in the legend will hide it. Tapping on a
  /// hidden series will make it visible again.
  void _hideSeries(common.LegendEntry detail) {
    final seriesId = detail.series.id;

    // Handle the event by toggling the hidden state of the target.
    if (isSeriesHidden(seriesId)) {
      showSeries(seriesId);
    } else {
      hideSeries(seriesId);
    }

    // Redraw the chart to actually hide hidden series.
    chart.redraw(skipLayout: true, skipAnimation: false);
  }
}

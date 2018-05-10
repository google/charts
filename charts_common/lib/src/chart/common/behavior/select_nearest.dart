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

import 'dart:math';

import '../base_chart.dart' show BaseChart;
import '../datum_details.dart' show DatumDetails;
import '../behavior/chart_behavior.dart' show ChartBehavior;
import '../processed_series.dart' show ImmutableSeries, SeriesDatum;
import '../selection_model/selection_model.dart' show SelectionModelType;
import '../../../common/gesture_listener.dart' show GestureListener;

enum SelectNearestTrigger {
  hover,
  tap,
  tapAndDrag,
  pressHold,
  longPressHold,
}

/// Chart behavior that listens to the given eventTrigger and updates the
/// specified [SelectionModel]. This is used to pair input events to behaviors
/// that listen to selection changes.
///
/// Input event types:
///   hover (default) - Mouse over/near data.
///   tap - Mouse/Touch on/near data.
///   pressHold - Mouse/Touch and drag across the data instead of panning.
///   longPressHold - Mouse/Touch for a while in one place then drag across the
///       data.
///
/// SelectionModels that can be updated:
///   info - To view the details of the selected items (ie: hover for web).
///   action - To select an item as an input, drill, or other selection.
///
/// Other options available
///   expandToDomain - all data points that match the domain value of the
///       closest data point will be included in the selection. (Default: true)
///   selectClosestSeries - mark the series for the closest data point as
///       selected. (Default: true)
///
/// You can add one SelectNearest for each model type that you are updating.
/// Any previous SelectNearest behavior for that selection model will be
/// removed.
class SelectNearest<D> implements ChartBehavior<D> {
  GestureListener _listener;

  final SelectionModelType selectionModelType;
  final SelectNearestTrigger eventTrigger;
  final bool expandToDomain;
  final bool selectClosestSeries;
  BaseChart<D> _chart;

  bool delaySelect = false;

  SelectNearest(
      {this.selectionModelType = SelectionModelType.info,
      this.expandToDomain = true,
      this.selectClosestSeries = true,
      this.eventTrigger = SelectNearestTrigger.hover}) {
    // Setup the appropriate gesture listening.
    switch (this.eventTrigger) {
      case SelectNearestTrigger.tap:
        _listener =
            new GestureListener(onTapTest: _onTapTest, onTap: _onSelect);
        break;
      case SelectNearestTrigger.tapAndDrag:
        _listener = new GestureListener(
          onTapTest: _onTapTest,
          onTap: _onSelect,
          onDragStart: _onSelect,
          onDragUpdate: _onSelect,
        );
        break;
      case SelectNearestTrigger.pressHold:
        _listener = new GestureListener(
            onTapTest: _onTapTest,
            onLongPress: _onSelect,
            onDragStart: _onSelect,
            onDragUpdate: _onSelect,
            onDragEnd: _onDeselectAll);
        break;
      case SelectNearestTrigger.longPressHold:
        _listener = new GestureListener(
            onTapTest: _onTapTest,
            onLongPress: _onLongPressSelect,
            onDragStart: _onSelect,
            onDragUpdate: _onSelect,
            onDragEnd: _onDeselectAll);
        break;
      case SelectNearestTrigger.hover:
      default:
        _listener = new GestureListener(onHover: _onSelect);
        break;
    }
  }

  bool _onTapTest(Point<double> chartPoint) {
    // If the tap is within the drawArea, then claim the event from others.
    delaySelect = eventTrigger == SelectNearestTrigger.longPressHold;
    return _chart.pointWithinRenderer(chartPoint);
  }

  bool _onLongPressSelect(Point<double> chartPoint) {
    delaySelect = false;
    return _onSelect(chartPoint);
  }

  bool _onSelect(Point<double> chartPoint, [double ignored]) {
    // If the selection is delayed (waiting for long press), then quit early.
    if (delaySelect) {
      return false;
    }

    var details = _chart.getNearestDatumDetailPerSeries(chartPoint);

    final seriesList = <ImmutableSeries<D>>[];
    final seriesDatumList = <SeriesDatum<D>>[];

    if (details.isNotEmpty) {
      details = expandToDomain ? _expandToDomain(details) : [details.first];
    }

    details.forEach((DatumDetails details) {
      seriesDatumList.add(new SeriesDatum<D>(details.series, details.datum));

      if (selectClosestSeries && seriesList.isEmpty) {
        seriesList.add(details.series);
      }
    });

    return _chart
        .getSelectionModel(selectionModelType)
        .updateSelection(seriesDatumList, seriesList);
  }

  bool _onDeselectAll(_, __, ___) {
    // If the selection is delayed (waiting for long press), then quit early.
    if (delaySelect) {
      return false;
    }

    _chart
        .getSelectionModel(selectionModelType)
        .updateSelection(<SeriesDatum<D>>[], <ImmutableSeries<D>>[]);
    return false;
  }

  List<DatumDetails<D>> _expandToDomain(List<DatumDetails<D>> details) =>
      details
          .where(
              (DatumDetails<D> detail) => detail.domain == details.first.domain)
          .toList();

  @override
  void attachTo(BaseChart<D> chart) {
    _chart = chart;
    chart.addGestureListener(_listener);
  }

  @override
  void removeFrom(BaseChart<D> chart) {
    chart.removeGestureListener(_listener);
    _chart = null;
  }

  @override
  String get role => 'SelectNearest-${selectionModelType.toString()}}';
}

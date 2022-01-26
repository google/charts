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

import '../../../../common/gesture_listener.dart' show GestureListener;
import '../../../../common/rate_limit_utils.dart' show throttle;
import '../../base_chart.dart' show BaseChart;
import '../../behavior/chart_behavior.dart' show ChartBehavior;
import '../../datum_details.dart' show DatumDetails;
import '../../processed_series.dart' show ImmutableSeries;
import '../../selection_model/selection_model.dart' show SelectionModelType;
import '../../series_datum.dart' show SeriesDatum;
import 'selection_trigger.dart' show SelectionTrigger;

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
///   [selectionMode] - Optional mode for expanding the selection beyond the
///       nearest datum. Defaults to selecting just the nearest datum.
///
///   [selectAcrossAllSeriesRendererComponents] - Events in any component that
///       draw Series data will propagate to other components that draw Series
///       data to get a union of points that match across all series renderer
///       components. This is useful when components in the margins draw series
///       data and a selection is supposed to bridge the two adjacent
///       components. (Default: true)
///   [selectClosestSeries] - If true, the closest Series itself will be marked
///       as selected in addition to the datum. This is useful for features like
///       highlighting the closest Series. (Default: true)
///
/// You can add one SelectNearest for each model type that you are updating.
/// Any previous SelectNearest behavior for that selection model will be
/// removed.
class SelectNearest<D> implements ChartBehavior<D> {
  late GestureListener _listener;

  /// Type of selection model that should be updated by input events.
  final SelectionModelType selectionModelType;

  /// Type of input event that should trigger selection.
  final SelectionTrigger eventTrigger;

  /// Optional mode for expanding the selection beyond the nearest datum.
  /// Defaults to selecting just the nearest datum.
  final SelectionMode selectionMode;

  /// Whether or not events in any component that draw Series data will
  /// propagate to other components that draw Series data to get a union of
  /// points that match across all series renderer components.
  ///
  /// This is useful when components in the margins draw series data and a
  /// selection is supposed to bridge the two adjacent components.
  final bool selectAcrossAllSeriesRendererComponents;

  /// Whether or not the closest Series itself will be marked as selected in
  /// addition to the datum.
  final bool selectClosestSeries;

  /// The farthest away a domain value can be from the mouse position on the
  /// domain axis before we'll ignore the datum.
  ///
  /// This allows sparse data to not get selected until the mouse is some
  /// reasonable distance. Defaults to no maximum distance.
  final int? maximumDomainDistancePx;

  /// Wait time in milliseconds for when the next event can be called.
  final int? hoverEventDelay;

  BaseChart<D>? _chart;

  bool _delaySelect = false;

  SelectNearest(
      {this.selectionModelType = SelectionModelType.info,
      this.selectionMode = SelectionMode.expandToDomain,
      this.selectAcrossAllSeriesRendererComponents = true,
      this.selectClosestSeries = true,
      this.eventTrigger = SelectionTrigger.hover,
      this.maximumDomainDistancePx,
      this.hoverEventDelay}) {
    // Setup the appropriate gesture listening.
    switch (eventTrigger) {
      case SelectionTrigger.tap:
        _listener = GestureListener(onTapTest: _onTapTest, onTap: _onSelect);
        break;
      case SelectionTrigger.tapAndDrag:
        _listener = GestureListener(
          onTapTest: _onTapTest,
          onTap: _onSelect,
          onDragStart: _onSelect,
          onDragUpdate: _onSelect,
        );
        break;
      case SelectionTrigger.pressHold:
        _listener = GestureListener(
            onTapTest: _onTapTest,
            onLongPress: _onSelect,
            onDragStart: _onSelect,
            onDragUpdate: _onSelect,
            onDragEnd: _onDeselectAll);
        break;
      case SelectionTrigger.longPressHold:
        _listener = GestureListener(
            onTapTest: _onTapTest,
            onLongPress: _onLongPressSelect,
            onDragStart: _onSelect,
            onDragUpdate: _onSelect,
            onDragEnd: _onDeselectAll);
        break;
      case SelectionTrigger.hover:
      default:
        _listener = GestureListener(
            onHover: hoverEventDelay == null
                ? _onSelect
                : throttle<Point<double>, bool>(_onSelect,
                    delay: Duration(milliseconds: hoverEventDelay!),
                    defaultReturn: false));
        break;
    }
  }

  bool _onTapTest(Point<double> chartPoint) {
    // If the tap is within the drawArea, then claim the event from others.
    _delaySelect = eventTrigger == SelectionTrigger.longPressHold;
    return _chart!.pointWithinRenderer(chartPoint);
  }

  bool _onLongPressSelect(Point<double> chartPoint) {
    _delaySelect = false;
    return _onSelect(chartPoint);
  }

  bool _onSelect(Point<double> chartPoint, [double? ignored]) {
    // If _chart has not yet been attached, then quit.
    if (_chart == null) return false;

    // If the selection is delayed (waiting for long press), then quit early.
    if (_delaySelect) return false;

    var details = _chart!.getNearestDatumDetailPerSeries(
        chartPoint, selectAcrossAllSeriesRendererComponents);

    final seriesList = <ImmutableSeries<D>>[];
    var seriesDatumList = <SeriesDatum<D>>[];

    if (details != null && details.isNotEmpty) {
      details.sort((a, b) => a.domainDistance!.compareTo(b.domainDistance!));

      if (maximumDomainDistancePx == null ||
          details[0].domainDistance! <= maximumDomainDistancePx!) {
        seriesDatumList = _extractSeriesFromNearestSelection(details);

        // Filter out points from overlay series.
        seriesDatumList
            .removeWhere((SeriesDatum<D> datum) => datum.series.overlaySeries);

        if (selectClosestSeries && seriesList.isEmpty) {
          if (details.first.series!.overlaySeries) {
            // If the closest "details" was from an overlay series, grab the
            // closest remaining series instead. In this case, we need to sort a
            // copy of the list by domain distance because we do not want to
            // re-order the actual return values here.
            final sortedSeriesDatumList =
                List<SeriesDatum<D>>.from(seriesDatumList);
            sortedSeriesDatumList.sort((a, b) {
              final detailsA = a.datum as DatumDetails<D>;
              final detailsB = b.datum as DatumDetails<D>;
              return detailsA.domainDistance!
                  .compareTo(detailsB.domainDistance!);
            });
            seriesList.add(sortedSeriesDatumList.first.series);
          } else {
            seriesList.add(details.first.series!);
          }
        }
      }
    }

    return _chart!
        .getSelectionModel(selectionModelType)
        .updateSelection(seriesDatumList, seriesList);
  }

  List<SeriesDatum<D>> _extractSeriesFromNearestSelection(
      List<DatumDetails<D>> details) {
    switch (selectionMode) {
      case SelectionMode.expandToDomain:
        return _expandToDomain(details.first);
      case SelectionMode.selectOverlapping:
        return details
            .map((datumDetails) =>
                SeriesDatum<D>(datumDetails.series!, datumDetails.datum))
            .toList();
      case SelectionMode.single:
        return [SeriesDatum<D>(details.first.series!, details.first.datum)];
    }
  }

  bool _onDeselectAll(Point<double> _, double __, double ___) {
    // If the selection is delayed (waiting for long press), then quit early.
    if (_delaySelect) {
      return false;
    }

    _chart!
        .getSelectionModel(selectionModelType)
        .updateSelection(<SeriesDatum<D>>[], <ImmutableSeries<D>>[]);
    return false;
  }

  List<SeriesDatum<D>> _expandToDomain(DatumDetails<D> nearestDetails) {
    // Make sure that the "nearest" datum is at the top of the list.
    final data = <SeriesDatum<D>>[
      SeriesDatum(nearestDetails.series!, nearestDetails.datum)
    ];
    final nearestDomain = nearestDetails.domain;

    for (ImmutableSeries<D> series in _chart!.currentSeriesList) {
      final domainFn = series.domainFn;
      final domainLowerBoundFn = series.domainLowerBoundFn;
      final domainUpperBoundFn = series.domainUpperBoundFn;
      // TODO: remove this explicit `bool` type when no longer
      // needed to work around https://github.com/dart-lang/language/issues/1785
      final bool testBounds =
          domainLowerBoundFn != null && domainUpperBoundFn != null;

      for (var i = 0; i < series.data.length; i++) {
        final Object? datum = series.data[i];
        final domain = domainFn(i);

        // Don't re-add the nearest details.
        if (nearestDetails.series == series && nearestDetails.datum == datum) {
          continue;
        }

        if (domain == nearestDomain) {
          data.add(SeriesDatum(series, datum));
        } else if (testBounds) {
          final domainLowerBound = domainLowerBoundFn(i);
          final domainUpperBound = domainUpperBoundFn(i);

          var addDatum = false;
          if (domainLowerBound != null && domainUpperBound != null) {
            if (domain is int) {
              addDatum = (domainLowerBound as int) <= (nearestDomain as int) &&
                  (nearestDomain as int) <= (domainUpperBound as int);
            } else if (domain is double) {
              addDatum =
                  (domainLowerBound as double) <= (nearestDomain as double) &&
                      (nearestDomain as double) <= (domainUpperBound as double);
            } else if (domain is DateTime) {
              addDatum = domainLowerBound == nearestDomain ||
                  domainUpperBound == nearestDomain ||
                  ((domainLowerBound as DateTime)
                          .isBefore(nearestDomain as DateTime) &&
                      (nearestDomain as DateTime)
                          .isBefore(domainUpperBound as DateTime));
            }
          }

          if (addDatum) {
            data.add(SeriesDatum(series, datum));
          }
        }
      }
    }

    return data;
  }

  @override
  void attachTo(BaseChart<D> chart) {
    _chart = chart;
    chart.addGestureListener(_listener);

    // TODO: Update this dynamically based on tappable location.
    switch (eventTrigger) {
      case SelectionTrigger.tap:
      case SelectionTrigger.tapAndDrag:
      case SelectionTrigger.pressHold:
      case SelectionTrigger.longPressHold:
        chart.registerTappable(this);
        break;
      case SelectionTrigger.hover:
      default:
        chart.unregisterTappable(this);
        break;
    }
  }

  @override
  void removeFrom(BaseChart<D> chart) {
    chart.removeGestureListener(_listener);
    chart.unregisterTappable(this);
    _chart = null;
  }

  @override
  String get role => 'SelectNearest-$selectionModelType';
}

/// Mode for expanding the selection beyond just the nearest datum.
enum SelectionMode {
  /// All data sharing the same domain value as the nearest datum will be
  /// selected (in charts that have a concept of domain).
  expandToDomain,

  /// All data for overlapping points in a series will be selected.
  selectOverlapping,

  /// Select only the nearest datum selected by the chart. This is the default
  /// mode.
  single,
}

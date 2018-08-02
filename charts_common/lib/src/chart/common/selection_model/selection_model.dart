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

import 'package:collection/collection.dart' show ListEquality;

import '../processed_series.dart' show ImmutableSeries, SeriesDatum;

/// Holds the state of interaction or selection for the chart to coordinate
/// between various event sources and things that wish to act upon the selection
/// state (highlight, drill, etc).
///
/// There is one instance per interaction type (ex: info, action) with each
/// maintaining their own state. Info is typically used to update a hover/touch
/// card while action is used in case of a secondary selection/action.
///
/// The series selection state is kept separate from datum selection state to
/// allow more complex highlighting. For example: a Hovercard that shows entries
/// for each datum for a given domain/time, but highlights the closest entry to
/// match up with highlighting/bolding of the line and legend.
class SelectionModel<D> {
  final _listeners = <SelectionModelListener<D>>[];
  var _selectedDatum = <SeriesDatum<D>>[];
  var _selectedSeries = <ImmutableSeries<D>>[];

  /// When set to true, prevents the model from being updated.
  bool locked = false;

  /// Clears the selection state.
  bool clearSelection({bool notifyListeners = true}) {
    return updateSelection([], [], notifyListeners: notifyListeners);
  }

  /// Updates the selection state. If mouse driven, [datumSelection] should be
  /// ordered by distance from mouse, closest first.
  bool updateSelection(
      List<SeriesDatum<D>> datumSelection, List<ImmutableSeries<D>> seriesList,
      {bool notifyListeners = true}) {
    if (locked) {
      return false;
    }

    final origSelectedDatum = _selectedDatum;
    final origSelectedSeries = _selectedSeries;

    _selectedDatum = datumSelection;
    _selectedSeries = seriesList;

    final changed =
        !new ListEquality().equals(origSelectedDatum, _selectedDatum) ||
            !new ListEquality().equals(origSelectedSeries, _selectedSeries);
    if (notifyListeners && changed) {
      _listeners.forEach((listener) => listener(this));
    }
    return changed;
  }

  /// Returns true if this [SelectionModel] has a selected datum.
  bool get hasDatumSelection => _selectedDatum.isNotEmpty;

  bool isDatumSelected(ImmutableSeries<D> series, int index) {
    final datum = index == null ? null : series.data[index];
    return _selectedDatum.contains(new SeriesDatum(series, datum));
  }

  /// Returns the selected [SeriesDatum] for this [SelectionModel].
  ///
  /// This is empty by default.
  List<SeriesDatum<D>> get selectedDatum => _selectedDatum;

  /// Returns true if this [SelectionModel] has a selected series.
  bool get hasSeriesSelection => _selectedSeries.isNotEmpty;

  /// Returns the selected [ImmutableSeries] for this [SelectionModel].
  ///
  /// This is empty by default.
  List<ImmutableSeries<D>> get selectedSeries => _selectedSeries;

  /// Returns true if this [SelectionModel] has a selected datum or series.
  bool get hasAnySelection =>
      _selectedDatum.isNotEmpty || selectedSeries.isNotEmpty;

  /// Add a listener to be notified when this [SelectionModel] changes.
  ///
  /// Note: the listener will not be triggered if [updateSelection] is called
  /// resulting in the same selection state.
  addSelectionListener(SelectionModelListener<D> listener) {
    _listeners.add(listener);
  }

  /// Remove listener from being notified when this [SelectionModel] changes.
  removeSelectionListener(SelectionModelListener<D> listener) {
    _listeners.remove(listener);
  }

  clearListeners() {
    _listeners.clear();
  }
}

/// Callback for SelectionModel. It is triggered when the selection state
/// changes.
typedef SelectionModelListener<D>(SelectionModel<D> model);

enum SelectionModelType {
  /// Typical Hover or Details event for viewing the details of the selected
  /// items.
  info,

  /// Typical Selection, Drill or Input event likely updating some external
  /// content.
  action,
}

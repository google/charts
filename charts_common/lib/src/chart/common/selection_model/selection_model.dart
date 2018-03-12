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
class SelectionModel<T, D> {
  final _listeners = <SelectionModelListener<T, D>>[];
  var _selectedDatum = <SeriesDatum<T, D>>[];
  var _selectedSeries = <ImmutableSeries<T, D>>[];

  /// When set to true, prevents the model from being updated.
  bool locked = false;

  /// Updates the selection state. If mouse driven, [datumSelection] should be
  /// ordered by distance from mouse, closest first.
  bool updateSelection(List<SeriesDatum<T, D>> datumSelection,
      List<ImmutableSeries<T, D>> seriesList) {
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
    if (changed) {
      _listeners.forEach((listener) => listener(this));
    }
    return changed;
  }

  /// Returns true if this [SelectionModel] has a selected datum.
  bool get hasDatumSelection => _selectedDatum.isNotEmpty;

  bool isDatumSelected(ImmutableSeries<T, D> series, T datum) =>
      _selectedDatum.contains(new SeriesDatum(series, datum));

  /// Returns the selected [SeriesDatum] for this [SelectionModel].
  ///
  /// This is empty by default.
  List<SeriesDatum<T, D>> get selectedDatum => _selectedDatum;

  /// Returns true if this [SelectionModel] has a selected series.
  bool get hasSeriesSelection => _selectedSeries.isNotEmpty;

  /// Returns the selected [ImmutableSeries] for this [SelectionModel].
  ///
  /// This is empty by default.
  List<ImmutableSeries<T, D>> get selectedSeries => _selectedSeries;

  /// Add a listener to be notified when this [SelectionModel] changes.
  ///
  /// Note: the listener will not be triggered if [updateSelection] is called
  /// resulting in the same selection state.
  addSelectionListener(SelectionModelListener<T, D> listener) {
    _listeners.add(listener);
  }

  /// Remove listener from being notified when this [SelectionModel] changes.
  removeSelectionListener(SelectionModelListener<T, D> listener) {
    _listeners.remove(listener);
  }

  clearListeners() {
    _listeners.clear();
  }
}

/// Callback for SelectionModel. It is triggered when the selection state
/// changes.
typedef SelectionModelListener<T, D>(SelectionModel<T, D> model);

enum SelectionModelType {
  /// Typical Hover or Details event for viewing the details of the selected
  /// items.
  info,

  /// Typical Selection, Drill or Input event likely updating some external
  /// content.
  action,
}

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

import 'package:meta/meta.dart' show protected;

import '../../../cartesian/cartesian_chart.dart' show CartesianChart;
import '../../base_chart.dart' show BaseChart, LifecycleListener;
import '../../processed_series.dart' show MutableSeries;
import '../../selection_model/selection_model.dart' show SelectionModelType;
import '../../series_datum.dart' show SeriesDatum;
import '../chart_behavior.dart' show ChartBehavior;

/// Enable keyboard navigation of the chart when focused using the directional
/// keys.
///
/// This behavior enables keyboard navigation over the domains of the chart when
/// focused using the following keys:
/// - Arrow left/right keys will move the hover selection over the chart
///   domains.
/// - Escape will clear both hover and click selections.
/// - Enter/space will update the click selection to the hover selection.
///
/// This behavior does not add any visual cues or accessibility text, so it is
/// ideally used along with other behaviors that handle hover/click selections
/// and add these types of visual and/or accessibility cues.
///
/// Note that using this behavior requires configuring the tabIndex of your
/// chart component. Using the default value of 0 makes the chart focusable in
/// the natural order of the page, but you have the option to use whatever
/// fine-tuned order works best.
abstract class KeyboardDomainNavigator<D> implements ChartBehavior<D> {
  late BaseChart<D> _chart;
  late final LifecycleListener<D> _lifecycleListener;

  /// An ordered list of the available domains.
  List<D>? _domains;

  /// An ordered list of selectable domains, the domains will be selected based
  /// on the order in this list, going back and fort with right and left keys.
  Map<int, List<SeriesDatum<D>>>? _datumPairs;

  /// Currently selected domain index.
  int _currentIndex = NO_SELECTION;

  KeyboardDomainNavigator() {
    _lifecycleListener = LifecycleListener<D>(onData: onData);
  }

  @override
  void attachTo(BaseChart<D> chart) {
    _chart = chart;
    chart.addLifecycleListener(_lifecycleListener);
  }

  @override
  void removeFrom(BaseChart<D> chart) {
    chart.removeLifecycleListener(_lifecycleListener);
  }

  /// Resets any hidden series data when new data is drawn on the chart.
  @protected
  void onData(List<MutableSeries<D>> _) {
    _domains = null;
    _datumPairs = null;
    _currentIndex = NO_SELECTION;
  }

  @protected
  bool handleEscape() {
    _currentIndex = NO_SELECTION;
    clearSelection();
    return true;
  }

  @protected
  bool handleEnter() {
    _currentIndex = _getActiveHoverDomainIndex();
    selectDomain(_currentIndex);
    return true;
  }

  @protected
  bool handlePreviousDomain() {
    // Lazily initialize selection domains when a key is pressed after a draw.
    if (_datumPairs == null) {
      _generateSelectionDomains();
    }

    final domainsLength = _datumPairs!.length;
    if (domainsLength == 0) {
      return false;
    }

    _currentIndex = _getActiveHoverDomainIndex();

    // Navigate to the last domain when current index is NO_SELECTION.
    if (_currentIndex == NO_SELECTION) {
      _currentIndex = domainsLength - 1;
    } else {
      // Navigate to the previous index, or to NO_SELECTION when it would
      // outreach the domain index.
      _currentIndex = _currentIndex == 0 ? NO_SELECTION : _currentIndex - 1;
    }

    _doNavigate(_currentIndex);

    return true;
  }

  @protected
  bool handleNextDomain() {
    // Lazily initialize selection domains when a key is pressed after a draw.
    if (_datumPairs == null) {
      _generateSelectionDomains();
    }

    final domainsLength = _datumPairs!.length;
    if (domainsLength == 0) {
      return false;
    }

    _currentIndex = _getActiveHoverDomainIndex();

    // Navigate to the first domain when current index is NO_SELECTION.
    if (_currentIndex == NO_SELECTION) {
      _currentIndex = 0;
    } else {
      // Set to NO_SELECTION when the next index would outreach the domains.
      _currentIndex =
          _currentIndex == domainsLength - 1 ? NO_SELECTION : _currentIndex + 1;
    }

    _doNavigate(_currentIndex);

    return true;
  }

  /// Triggers when the left or right arrow keys are pressed.
  void _doNavigate(int domainIndex) {
    _selectDomainIndex(SelectionModelType.info, domainIndex);
  }

  /// Triggers when the Enter or Space key is pressed.
  void selectDomain(int domainIndex) {
    _selectDomainIndex(SelectionModelType.action, domainIndex);
  }

  /// Triggers when the Escape key is pressed or the chart loses focus.
  void clearSelection() {
    _selectDomainIndex(SelectionModelType.info, NO_SELECTION);
  }

  /// Updates the selection of the attached chart with the data at the given
  /// domain index. If the chart doesn't support the given model, this is a
  /// no-op.
  @protected
  bool _selectDomainIndex(
      SelectionModelType selectionModelType, int domainIndex) {
    final selectionModel = _chart.getSelectionModel(selectionModelType);
    if (selectionModel == null) {
      return false;
    }

    if (domainIndex == NO_SELECTION) {
      selectionModel.clearSelection();
    } else {
      final datumPairs = _getDatumPairs(domainIndex);

      final seriesDatumList = <SeriesDatum<D>>[];
      final seriesList = <MutableSeries<D>>[];

      for (final seriesDatum in datumPairs) {
        seriesDatumList
            .add(SeriesDatum<D>(seriesDatum.series, seriesDatum.datum));

        if (!seriesList.contains(seriesDatum.series)) {
          seriesList.add(seriesDatum.series as MutableSeries<D>);
        }
      }

      selectionModel.updateSelection(seriesDatumList, seriesList);
    }

    return true;
  }

  /// Reads the current active index of the hover selection.
  int _getActiveHoverDomainIndex() {
    // If enter is pressed before an arrow key, we don't have any selection
    // domains available. Bail out.
    final _domains = this._domains;
    if (_domains == null || _domains.isEmpty) {
      return NO_SELECTION;
    }

    final selectionModel = _chart.getSelectionModel(SelectionModelType.info);

    if (!selectionModel.hasAnySelection) {
      return NO_SELECTION;
    }

    final details = _chart.getSelectedDatumDetails(SelectionModelType.info);

    if (details.isEmpty) {
      return NO_SELECTION;
    }

    // If the currentIndex is the same as the firstSelectedDetail we don't have
    // to do a linear seach to find the domain.
    final firstDomain = details.first.domain!;

    if (0 <= _currentIndex &&
        _currentIndex <= _domains.length - 1 &&
        _domains[_currentIndex] == firstDomain) {
      return _currentIndex;
    }

    return _domains.indexOf(firstDomain);
  }

  /// Processes chart data and generates a mapping of domain index to datum
  /// details at that domain.
  void _generateSelectionDomains() {
    _domains = <D>[];

    final allSeriesDatum = _chart.getAllDatumDetails();

    if (_chart is CartesianChart) {
      final localChart = _chart as CartesianChart;
      if (localChart.vertical) {
        allSeriesDatum.sort((a, b) {
          if (a.chartPosition!.x == b.chartPosition!.x) {
            return a.series!.seriesIndex.compareTo(b.series!.seriesIndex);
          }
          return a.chartPosition!.x!.compareTo(b.chartPosition!.x!);
        });
      } else {
        allSeriesDatum.sort((a, b) {
          if (a.chartPosition!.y == b.chartPosition!.y) {
            return a.series!.seriesIndex.compareTo(b.series!.seriesIndex);
          }
          return a.chartPosition!.y!.compareTo(b.chartPosition!.y!);
        });
      }
    }

    final detailsByDomain = <D, List<SeriesDatum<D>>>{};
    for (final datumDetails in allSeriesDatum) {
      // The hovercard is closed when the closest detail has a null measure.
      // Also, on hovercard close the current selection is cleared, so unless
      // the details with null measure are skipped, the next domain visited
      // after a datum with null measure will always be the first one, making
      // all data after a datum with null measure not accessible by keyboard.
      // LINT.IfChange
      if (datumDetails.measure != null) {
        final domain = datumDetails.domain!;

        if (detailsByDomain[domain] == null) {
          _domains!.add(domain);
          detailsByDomain[domain] = [];
        }

        detailsByDomain[domain]!
            .add(SeriesDatum<D>(datumDetails.series!, datumDetails.datum));
      }
      // LINT.ThenChange(//depot/google3/third_party/dart/charts_web/lib/src/common/behaviors/hovercard/hovercard.dart)
    }

    _datumPairs = <int, List<SeriesDatum<D>>>{};

    var i = 0;
    detailsByDomain.forEach((key, value) {
      _datumPairs!.putIfAbsent(i, () => value);
      i++;
    });

    _currentIndex = NO_SELECTION;
  }

  /// Gets the datum/series pairs for the given domainIndex.
  List<SeriesDatum<D>> _getDatumPairs(int domainIndex) =>
      _datumPairs![domainIndex] ?? <SeriesDatum<D>>[];

  @override
  String get role => 'keyboard-domain-navigator';
}

const NO_SELECTION = -1;

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

import 'dart:math' show Rectangle;

import '../../../../common/graphics_factory.dart' show GraphicsFactory;
import '../../../layout/layout_view.dart'
    show LayoutPosition, LayoutView, LayoutViewConfig, ViewMeasuredSizes;
import '../../base_chart.dart' show BaseChart, LifecycleListener;
import '../../chart_canvas.dart' show ChartCanvas;
import '../../chart_context.dart' show ChartContext;
import '../../processed_series.dart' show MutableSeries;
import '../../selection_model/selection_model.dart'
    show SelectionModel, SelectionModelType;
import '../chart_behavior.dart'
    show
        BehaviorPosition,
        ChartBehavior,
        InsideJustification,
        OutsideJustification;
import 'legend_entry.dart';
import 'legend_entry_generator.dart';
import 'per_series_legend_entry_generator.dart';

// TODO: Allow tapping on a series to remove series from draw area.
// TODO: Allows for hovering over a series in legend to highlight
// corresponding series in draw area.

/// Series legend behavior for charts.
///
/// By default this behavior creates a legend entry per series.
class SeriesLegend<T, D> extends Legend<T, D> {
  SeriesLegend(
      {SelectionModelType selectionModelType,
      LegendEntryGenerator<T, D> legendEntryGenerator})
      : super(
            selectionModelType: selectionModelType ?? SelectionModelType.info,
            legendEntryGenerator:
                legendEntryGenerator ?? new PerSeriesLegendEntryGenerator());
}

/// Legend behavior for charts.
///
/// Since legends are desired to be customizable, building and displaying the
/// visual content of legends is done on the native platforms. This allows users
/// to specify customized content for legends using the native platform (ex. for
/// Flutter, using widgets).
abstract class Legend<T, D> implements ChartBehavior<T, D>, LayoutView {
  final SelectionModelType selectionModelType;
  final legendState = new LegendState();
  final LegendEntryGenerator<T, D> legendEntryGenerator;

  String _title;

  BaseChart _chart;
  LifecycleListener<T, D> _lifecycleListener;

  Rectangle<int> _componentBounds;
  Rectangle<int> _drawAreaBounds;
  GraphicsFactory _graphicsFactory;

  BehaviorPosition _behaviorPosition = BehaviorPosition.end;
  OutsideJustification _outsideJustification =
      OutsideJustification.startDrawArea;
  InsideJustification _insideJustification = InsideJustification.topStart;
  LegendCellPadding _cellPadding;
  LegendCellPadding _legendPadding;

  Legend({this.selectionModelType, this.legendEntryGenerator}) {
    _lifecycleListener = new LifecycleListener(onPostprocess: _postProcess);
  }

  String get title => _title;

  /// Sets title text to display before legend entries.
  set title(String title) {
    _title = title;
  }

  BehaviorPosition get behaviorPosition => _behaviorPosition;

  set behaviorPosition(BehaviorPosition behaviorPosition) {
    _behaviorPosition = behaviorPosition;
  }

  OutsideJustification get outsideJustification => _outsideJustification;

  set outsideJustification(OutsideJustification outsideJustification) {
    _outsideJustification = outsideJustification;
  }

  InsideJustification get insideJustification => _insideJustification;

  set insideJustification(InsideJustification insideJustification) {
    _insideJustification = insideJustification;
  }

  LegendCellPadding get cellPadding => _cellPadding;

  set cellPadding(LegendCellPadding cellPadding) {
    _cellPadding = cellPadding;
  }

  LegendCellPadding get legendPadding => _legendPadding;

  set legendPadding(LegendCellPadding legendPadding) {
    _legendPadding = legendPadding;
  }

  /// Build LegendEntries from list of series.
  void _postProcess(List<MutableSeries<T, D>> seriesList) {
    legendState._legendEntries =
        legendEntryGenerator.getLegendEntries(seriesList);
    updateLegend();
  }

  /// Update the legend state with [selectionModel] and request legend update.
  void _selectionChanged(SelectionModel selectionModel) {
    legendState._selectionModel = selectionModel;
    legendEntryGenerator.updateLegendEntries(
        legendState.legendEntries, legendState.selectionModel);
    updateLegend();
  }

  ChartContext get chartContext => _chart.context;

  /// Requires override to show in native platform
  void updateLegend() {}

  @override
  void attachTo(BaseChart<T, D> chart) {
    _chart = chart;
    chart.addLifecycleListener(_lifecycleListener);
    chart
        .getSelectionModel(selectionModelType)
        .addSelectionListener(_selectionChanged);

    chart.addView(this);
  }

  @override
  void removeFrom(BaseChart chart) {
    chart
        .getSelectionModel(selectionModelType)
        .removeSelectionListener(_selectionChanged);
    chart.removeLifecycleListener(_lifecycleListener);

    chart.removeView(this);
  }

  @override
  String get role => 'legend-${selectionModelType.toString()}';

  bool get rtl => _chart.context.rtl;

  @override
  GraphicsFactory get graphicsFactory => _graphicsFactory;

  @override
  set graphicsFactory(GraphicsFactory value) {
    _graphicsFactory = value;
  }

  @override
  LayoutViewConfig get layoutConfig {
    return new LayoutViewConfig(position: _layoutPosition, positionOrder: 1);
  }

  /// Get layout position from legend position.
  LayoutPosition get _layoutPosition {
    LayoutPosition position;
    switch (_behaviorPosition) {
      case BehaviorPosition.bottom:
        position = LayoutPosition.Bottom;
        break;
      case BehaviorPosition.end:
        position = rtl ? LayoutPosition.Left : LayoutPosition.Right;
        break;
      case BehaviorPosition.inside:
        position = LayoutPosition.DrawArea;
        break;
      case BehaviorPosition.start:
        position = rtl ? LayoutPosition.Right : LayoutPosition.Left;
        position = rtl ? LayoutPosition.Right : LayoutPosition.Left;
        break;
      case BehaviorPosition.top:
        position = LayoutPosition.Top;
        break;
    }

    return position;
  }

  @override
  ViewMeasuredSizes measure(int maxWidth, int maxHeight) {
    // Native child classes should override this method to return real
    // measurements.
    return new ViewMeasuredSizes(preferredWidth: 0, preferredHeight: 0);
  }

  @override
  void layout(Rectangle<int> componentBounds, Rectangle<int> drawAreaBounds) {
    _componentBounds = componentBounds;
    _drawAreaBounds = drawAreaBounds;
  }

  @override
  void paint(ChartCanvas canvas, double animationPercent) {}

  @override
  Rectangle<int> get componentBounds => _componentBounds;

  // Gets the draw area bounds for native legend content to position itself
  // accordingly.
  Rectangle<int> get drawAreaBounds => _drawAreaBounds;
}

/// Stores legend data used by native legend content builder.
class LegendState<T, D> {
  List<LegendEntry<T, D>> _legendEntries;
  SelectionModel _selectionModel;

  List<LegendEntry<T, D>> get legendEntries => _legendEntries;
  SelectionModel get selectionModel => _selectionModel;
}

/// Stores legend cell padding, in percents or pixels.
///
/// If a percent is specified, it takes precedence over a flat pixel value.
class LegendCellPadding {
  final double bottomPct;
  final double bottomPx;
  final double leftPct;
  final double leftPx;
  final double rightPct;
  final double rightPx;
  final double topPct;
  final double topPx;

  /// Creates padding in percents from the left, top, right, and bottom.
  const LegendCellPadding.fromLTRBPct(
      this.leftPct, this.topPct, this.rightPct, this.bottomPct)
      : leftPx = null,
        topPx = null,
        rightPx = null,
        bottomPx = null;

  /// Creates padding in pixels from the left, top, right, and bottom.
  const LegendCellPadding.fromLTRBPx(
      this.leftPx, this.topPx, this.rightPx, this.bottomPx)
      : leftPct = null,
        topPct = null,
        rightPct = null,
        bottomPct = null;

  /// Creates padding in percents from the top, right, bottom, and left.
  const LegendCellPadding.fromTRBLPct(
      this.topPct, this.rightPct, this.bottomPct, this.leftPct)
      : topPx = null,
        rightPx = null,
        bottomPx = null,
        leftPx = null;

  /// Creates padding in pixels from the top, right, bottom, and left.
  const LegendCellPadding.fromTRBLPx(
      this.topPx, this.rightPx, this.bottomPx, this.leftPx)
      : topPct = null,
        rightPct = null,
        bottomPct = null,
        leftPct = null;

  /// Creates cell padding where all the offsets are `value` in percent.
  ///
  /// ## Sample code
  ///
  /// Typical eight percent margin on all sides:
  ///
  /// ```dart
  /// const LegendCellPadding.allPct(8.0)
  /// ```
  const LegendCellPadding.allPct(double value)
      : leftPct = value,
        topPct = value,
        rightPct = value,
        bottomPct = value,
        leftPx = null,
        topPx = null,
        rightPx = null,
        bottomPx = null;

  /// Creates cell padding where all the offsets are `value` in pixels.
  ///
  /// ## Sample code
  ///
  /// Typical eight-pixel margin on all sides:
  ///
  /// ```dart
  /// const LegendCellPadding.allPx(8.0)
  /// ```
  const LegendCellPadding.allPx(double value)
      : leftPx = value,
        topPx = value,
        rightPx = value,
        bottomPx = value,
        leftPct = null,
        topPct = null,
        rightPct = null,
        bottomPct = null;

  double bottom(num height) =>
      bottomPct != null ? bottomPct * height : bottomPx;

  double left(num width) => leftPct != null ? leftPct * width : leftPx;

  double right(num width) => rightPct != null ? rightPct * width : rightPx;

  double top(num height) => topPct != null ? topPct * height : topPx;
}

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

import 'dart:math' show Point, Rectangle, max;
import 'package:meta/meta.dart';
import 'base_chart.dart' show BaseChart;
import 'chart_canvas.dart' show ChartCanvas;
import 'datum_details.dart' show DatumDetails;
import 'processed_series.dart' show ImmutableSeries, MutableSeries;
import '../layout/layout_view.dart'
    show LayoutView, LayoutPosition, LayoutViewConfig, ViewMeasuredSizes;
import '../../common/color.dart' show Color;
import '../../common/graphics_factory.dart' show GraphicsFactory;
import '../../common/symbol_renderer.dart' show SymbolRenderer;
import '../../common/style/style_factory.dart' show StyleFactory;
import '../../data/series.dart' show AttributeKey;

const AttributeKey<String> rendererIdKey =
    const AttributeKey<String>('SeriesRenderer.rendererId');

const AttributeKey<SeriesRenderer> rendererKey =
    const AttributeKey<SeriesRenderer>('SeriesRenderer.renderer');

abstract class SeriesRenderer<D> extends LayoutView {
  static const defaultRendererId = 'default';

  SymbolRenderer get symbolRenderer;
  set symbolRenderer(SymbolRenderer symbolRenderer);

  /// Symbol renderer for this renderer.
  ///
  /// The default is set natively by the platform. This is because in Flutter,
  /// the [SymbolRenderer] has to be a Flutter wrapped version to support
  /// building widget based symbols.
  String get rendererId;
  set rendererId(String rendererId);

  void onAttach(BaseChart<D> chart);

  void onDetach(BaseChart<D> chart);

  /// Performs basic configuration for the series, before it is pre-processed.
  ///
  /// Typically, a series renderer should assign color mapping functions to
  /// series that do not have them.
  void configureSeries(List<MutableSeries<D>> seriesList);

  /// Pre-calculates some details for the series that will be needed later
  /// during the drawing phase.
  void preprocessSeries(List<MutableSeries<D>> seriesList);

  void configureDomainAxes(List<MutableSeries<D>> seriesList);

  void configureMeasureAxes(List<MutableSeries<D>> seriesList);

  void update(List<ImmutableSeries<D>> seriesList, bool isAnimating);

  void paint(ChartCanvas canvas, double animationPercent);

  List<DatumDetails<D>> getNearestDatumDetailPerSeries(
      Point<double> chartPoint);
}

abstract class BaseSeriesRenderer<D> implements SeriesRenderer<D> {
  final LayoutViewConfig layoutConfig;

  String rendererId;

  SymbolRenderer symbolRenderer;

  Rectangle<int> _drawAreaBounds;
  Rectangle<int> get drawBounds => _drawAreaBounds;

  GraphicsFactory _graphicsFactory;

  BaseSeriesRenderer({
    @required this.rendererId,
    @required int layoutPositionOrder,
    this.symbolRenderer,
  }) : this.layoutConfig = new LayoutViewConfig(
            position: LayoutPosition.DrawArea,
            positionOrder: layoutPositionOrder);

  @override
  GraphicsFactory get graphicsFactory => _graphicsFactory;

  @override
  set graphicsFactory(GraphicsFactory value) {
    _graphicsFactory = value;
  }

  @override
  void onAttach(BaseChart<D> chart) {}

  @override
  void onDetach(BaseChart<D> chart) {}

  /// Assigns colors to series that are missing their colorFn.
  ///
  /// [emptyCategoryUsesSinglePalette] Flag indicating whether having all
  ///     series with no categories will use the same or separate palettes.
  ///     Setting it to true uses various Blues for each series.
  ///     Setting it to false used different palettes (ie: s1 uses Blue500,
  ///     s2 uses Red500),
  @protected
  assignMissingColors(Iterable<MutableSeries<D>> seriesList,
      {@required bool emptyCategoryUsesSinglePalette}) {
    const defaultCategory = '__default__';

    // Count up the number of missing series per category, keeping a max across
    // categories.
    final missingColorCountPerCategory = <String, int>{};
    int maxMissing = 0;
    bool hasSpecifiedCategory = false;

    seriesList.forEach((MutableSeries<D> series) {
      if (series.colorFn == null) {
        // If there is no category, give it a default category to match logic.
        String category = series.seriesCategory;
        if (category == null) {
          category = defaultCategory;
        } else {
          hasSpecifiedCategory = true;
        }

        // Increment the missing counts for the category.
        final missingCnt = (missingColorCountPerCategory[category] ?? 0) + 1;
        missingColorCountPerCategory[category] = missingCnt;
        maxMissing = max(maxMissing, missingCnt);
      }
    });

    if (maxMissing > 0) {
      // Special handling of only series with empty categories when we want
      // to use different palettes.
      if (!emptyCategoryUsesSinglePalette && !hasSpecifiedCategory) {
        final palettes = StyleFactory.style.getOrderedPalettes(maxMissing);
        int index = 0;
        seriesList.forEach((MutableSeries series) {
          if (series.colorFn == null) {
            final color = palettes[index % palettes.length].shadeDefault;
            index++;
            series.colorFn = (_) => color;
          }
        });
        return;
      }

      // Get a list of palettes to use given the number of categories we've
      // seen. One palette per category (but might need to repeat).
      final colorPalettes = StyleFactory.style
          .getOrderedPalettes(missingColorCountPerCategory.length);

      // Create a map of Color palettes for each category. Each Palette uses
      // the max for any category to ensure that the gradients look appropriate.
      final colorsByCategory = <String, List<Color>>{};
      int index = 0;
      missingColorCountPerCategory.keys.forEach((String category) {
        colorsByCategory[category] =
            colorPalettes[index % colorPalettes.length].makeShades(maxMissing);
        index++;

        // Reset the count so we can use it to count as we set the colorFn.
        missingColorCountPerCategory[category] = 0;
      });

      seriesList.forEach((MutableSeries series) {
        if (series.colorFn == null) {
          final category = series.seriesCategory ?? defaultCategory;

          // Get the current index into the color list.
          final colorIndex = missingColorCountPerCategory[category];
          missingColorCountPerCategory[category] = colorIndex + 1;

          final color = colorsByCategory[category][colorIndex];
          series.colorFn = (_) => color;
        }

        // Fill color defaults to the series color if no accessor is provided.
        series.fillColorFn ??= (int index) => series.colorFn(index);
      });
    } else {
      seriesList.forEach((MutableSeries series) {
        // Fill color defaults to the series color if no accessor is provided.
        series.fillColorFn ??= (int index) => series.colorFn(index);
      });
    }
  }

  @override
  ViewMeasuredSizes measure(int maxWidth, int maxHeight) {
    return null;
  }

  @override
  void layout(Rectangle<int> componentBounds, Rectangle<int> drawAreaBounds) {
    this._drawAreaBounds = drawAreaBounds;
  }

  @override
  Rectangle<int> get componentBounds => this._drawAreaBounds;

  @override
  void configureSeries(List<MutableSeries<D>> seriesList) {}

  @override
  void preprocessSeries(List<MutableSeries<D>> seriesList) {}

  @override
  void configureDomainAxes(List<MutableSeries<D>> seriesList) {}

  @override
  void configureMeasureAxes(List<MutableSeries<D>> seriesList) {}
}

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

import 'dart:math' show Rectangle, Point;

import 'package:meta/meta.dart' show protected;

import '../../common/gesture_listener.dart' show GestureListener;
import '../../common/graphics_factory.dart' show GraphicsFactory;
import '../../common/proxy_gesture_listener.dart' show ProxyGestureListener;
import '../../data/series.dart' show Series;
import '../layout/layout_config.dart' show LayoutConfig;
import '../layout/layout_manager.dart' show LayoutManager;
import '../layout/layout_manager_impl.dart' show LayoutManagerImpl;
import '../layout/layout_view.dart' show LayoutView;
import 'behavior/chart_behavior.dart' show ChartBehavior;
import 'chart_canvas.dart' show ChartCanvas;
import 'chart_context.dart' show ChartContext;
import 'datum_details.dart' show DatumDetails;
import 'processed_series.dart' show MutableSeries;
import 'selection_model/selection_model.dart'
    show MutableSelectionModel, SelectionModelType;
import 'series_datum.dart' show SeriesDatum;
import 'series_renderer.dart' show SeriesRenderer, rendererIdKey, rendererKey;

typedef BehaviorCreator = ChartBehavior<D> Function<D>();

abstract class BaseChart<D> {
  late ChartContext context;

  /// Internal use only.
  GraphicsFactory? graphicsFactory;

  final LayoutManager _layoutManager;

  int? _chartWidth;
  int? _chartHeight;

  Duration transition = const Duration(milliseconds: 300);

  /// A value in the range \[0.0, 1.0\] that indicates the animation progress.
  double animationPercent = 0;

  bool _animationsTemporarilyDisabled = false;

  /// List of series that were passed into the previous draw call.
  ///
  /// This list will be used when redraw is called, to reset the state of all
  /// behaviors to the original list.
  late List<MutableSeries<D>> _originalSeriesList;

  /// List of series that are currently drawn on the chart.
  ///
  /// This list should be used by interactive behaviors between chart draw
  /// cycles. It may be filtered or modified by some behaviors during the
  /// initial draw cycle (e.g. a [Legend] may hide some series).
  List<MutableSeries<D>>? _currentSeriesList;

  Set<String> _usingRenderers = <String>{};
  Map<String, List<MutableSeries<D>>>? _rendererToSeriesList;

  final _seriesRenderers = <String, SeriesRenderer<D>>{};

  /// Map of named chart behaviors attached to this chart.
  final _behaviorRoleMap = <String, ChartBehavior<D>>{};
  final _behaviorStack = <ChartBehavior<D>>[];

  final _behaviorTappableMap = <String, ChartBehavior<D>>{};

  /// Whether or not the chart will respond to tap events.
  ///
  /// This will generally be true if there is a behavior attached to the chart
  /// that does something with tap events, such as "click to select data."
  bool get isTappable => _behaviorTappableMap.isNotEmpty;

  final _gestureProxy = ProxyGestureListener();

  final _selectionModels = <SelectionModelType, MutableSelectionModel<D>>{};

  /// Whether selected data should be restricted to only have points that
  /// cover this event location.
  ///
  /// When this is true, selection logic would ignore points that are close to
  /// event location but does not cover event location.
  bool get selectExactEventLocation => false;

  /// Whether data should be selected by nearest domain distance, or by relative
  /// distance.
  ///
  /// This should generally be true for chart types that are intended to be
  /// aggregated by domain, and false for charts that plot arbitrary x,y data.
  /// Scatter plots, for example, may have many overlapping data with the same
  /// domain value.
  bool get selectNearestByDomain => true;

  /// Whether data should be expanded by to include all points overlapping the
  /// selection point
  ///
  /// Should be true for Scatter plots.
  bool get selectOverlappingPoints => false;

  final _lifecycleListeners = <LifecycleListener<D>>[];

  BaseChart({LayoutConfig? layoutConfig})
      : _layoutManager = LayoutManagerImpl(config: layoutConfig);

  void init(ChartContext context, GraphicsFactory graphicsFactory) {
    this.context = context;

    // When graphics factory is updated, update all the views.
    if (this.graphicsFactory != graphicsFactory) {
      this.graphicsFactory = graphicsFactory;

      _layoutManager.applyToViews(
          (LayoutView view) => view.graphicsFactory = graphicsFactory);
    }

    configurationChanged();
  }

  /// Updates the layout configuration used inside the layout manager.
  void updateConfig(LayoutConfig layoutConfig) {
    _layoutManager.updateConfig(layoutConfig);
  }

  bool _chartIsDirty = false;

  /// If the chart configuration has changed and requires a redraw.
  bool get chartIsDirty => _chartIsDirty;

  /// Resets the chart dirty flag to `false`.
  void resetChartDirtyFlag() {
    _chartIsDirty = false;
  }

  /// Marks the chart as dirty.
  ///
  /// When a chart axis or configurable is changed and will require a redraw
  /// next frame the chart must be marked dirty.
  void markChartDirty() {
    _chartIsDirty = true;
  }

  /// Finish configuring components that require context and graphics factory.
  ///
  /// Some components require context and graphics factory to be set again when
  /// configuration has changed but the configuration is set prior to the
  /// chart first calling init with the context.
  void configurationChanged() {}

  int? get chartWidth => _chartWidth;

  int? get chartHeight => _chartHeight;

  //
  // Gesture proxy methods
  //
  ProxyGestureListener get gestureProxy => _gestureProxy;

  /// Add a [GestureListener] to this chart.
  GestureListener addGestureListener(GestureListener listener) {
    _gestureProxy.add(listener);
    return listener;
  }

  /// Remove a [GestureListener] from this chart.
  void removeGestureListener(GestureListener listener) {
    _gestureProxy.remove(listener);
  }

  LifecycleListener<D> addLifecycleListener(LifecycleListener<D> listener) {
    _lifecycleListeners.add(listener);
    return listener;
  }

  bool removeLifecycleListener(LifecycleListener<D> listener) =>
      _lifecycleListeners.remove(listener);

  /// Returns MutableSelectionModel for the given type. Lazy creates one upon first
  /// request.
  MutableSelectionModel<D> getSelectionModel(SelectionModelType type) {
    return _selectionModels.putIfAbsent(type, () => MutableSelectionModel<D>());
  }

  /// Returns a list of datum details from selection model of [type].
  List<DatumDetails<D>> getDatumDetails(SelectionModelType type);

  //
  // Renderer methods
  //

  set defaultRenderer(SeriesRenderer<D> renderer) {
    renderer.rendererId = SeriesRenderer.defaultRendererId;
    addSeriesRenderer(renderer);
  }

  SeriesRenderer<D> get defaultRenderer =>
      getSeriesRenderer(SeriesRenderer.defaultRendererId);

  void addSeriesRenderer(SeriesRenderer<D> renderer) {
    final rendererId = renderer.rendererId;

    final previousRenderer = _seriesRenderers[rendererId];
    if (previousRenderer != null) {
      removeView(previousRenderer);
      previousRenderer.onDetach(this);
    }

    addView(renderer);
    renderer.onAttach(this);
    _seriesRenderers[rendererId] = renderer;
  }

  SeriesRenderer<D> getSeriesRenderer(String? rendererId) {
    var renderer = _seriesRenderers[rendererId];

    // Special case, if we are asking for the default and we haven't made it
    // yet, then make it now.
    if (renderer == null) {
      // TODO: Throw an error if
      // `rendererId != SeriesRenderer.defaultRendererId`?
      renderer = makeDefaultRenderer();
      defaultRenderer = renderer;
    }

    return renderer;
  }

  SeriesRenderer<D> makeDefaultRenderer();

  bool pointWithinRenderer(Point<double> chartPosition) {
    return _usingRenderers.any((String rendererId) =>
        getSeriesRenderer(rendererId)
            .componentBounds!
            .containsPoint(chartPosition));
  }

  /// Retrieves the datum details that are nearest to the given [drawAreaPoint].
  ///
  /// [drawAreaPoint] represents a point in the chart, such as a point that was
  /// clicked/tapped on by a user.
  ///
  /// [selectAcrossAllDrawAreaComponents] specifies whether nearest data
  /// selection should be done across the combined draw area of all components
  /// with series draw areas, or just the chart's primary draw area bounds.
  List<DatumDetails<D>> getNearestDatumDetailPerSeries(
      Point<double> drawAreaPoint, bool selectAcrossAllDrawAreaComponents) {
    // Optionally grab the combined draw area bounds of all components. If this
    // is disabled, then we expect each series renderer to filter out the event
    // if [chartPoint] is located outside of its own component bounds.
    final boundsOverride =
        selectAcrossAllDrawAreaComponents ? drawableLayoutAreaBounds : null;

    final details = <DatumDetails<D>>[];
    _usingRenderers.forEach((String rendererId) {
      details
          .addAll(getSeriesRenderer(rendererId).getNearestDatumDetailPerSeries(
        drawAreaPoint,
        selectNearestByDomain,
        boundsOverride,
        selectOverlappingPoints: selectOverlappingPoints,
        selectExactEventLocation: selectExactEventLocation,
      ));
    });

    details.sort((DatumDetails<D> a, DatumDetails<D> b) {
      // Sort so that the nearest one is first.
      // Special sort, sort by domain distance first, then by measure distance.
      if (selectNearestByDomain) {
        final domainDiff = a.domainDistance!.compareTo(b.domainDistance!);
        if (domainDiff == 0) {
          return a.measureDistance!.compareTo(b.measureDistance!);
        }
        return domainDiff;
      } else {
        return a.relativeDistance!.compareTo(b.relativeDistance!);
      }
    });

    return details;
  }

  /// Retrieves the datum details for the current chart selection.
  ///
  /// [selectionModelType] specifies the type of the selection model to use.
  List<DatumDetails<D>> getSelectedDatumDetails(
      SelectionModelType selectionModelType) {
    final details = <DatumDetails<D>>[];

    if (_currentSeriesList == null) {
      return details;
    }

    final selectionModel = getSelectionModel(selectionModelType);
    if (!selectionModel.hasDatumSelection) {
      return details;
    }

    // Pass each selected datum to the appropriate series renderer to get full
    // details appropriate to its series type.
    for (final seriesDatum in selectionModel.selectedDatum) {
      final rendererId = seriesDatum.series.getAttr(rendererIdKey);
      details.add(
          getSeriesRenderer(rendererId).getDetailsForSeriesDatum(seriesDatum));
    }

    return details;
  }

  /// Retrieves the datum details for all data on the chart.
  List<DatumDetails<D>> getAllDatumDetails(
      {bool includeOverlaySeries = false}) {
    final details = <DatumDetails<D>>[];

    if (_currentSeriesList == null) {
      return details;
    }

    for (final series in _currentSeriesList!) {
      final rendererId = series.getAttr(rendererIdKey);

      if (!includeOverlaySeries && series.overlaySeries) {
        continue;
      }

      for (dynamic datum in series.data) {
        details.add(getSeriesRenderer(rendererId)
            .getDetailsForSeriesDatum(SeriesDatum<D>(series, datum)));
      }
    }

    return details;
  }

  //
  // Behavior methods
  //

  /// Helper method to create a behavior with congruent types.
  ///
  /// This invokes the provides helper with type parameters that match this
  /// chart.
  ChartBehavior<D> createBehavior(BehaviorCreator creator) => creator<D>();

  /// Attaches a behavior to the chart.
  ///
  /// Setting a behavior with the same role as a behavior already attached
  /// to the chart will replace the old behavior. The old behavior's removeFrom
  /// method will be called before we attach the behavior.
  void addBehavior(ChartBehavior<D> behavior) {
    final role = behavior.role;

    if (role != null && _behaviorRoleMap[role] != behavior) {
      // Remove any old behavior with the same role.
      removeBehavior(_behaviorRoleMap[role]);
      // Add the behavior.
      _behaviorRoleMap[role] = behavior;
    }

    // Add the behavior if it wasn't already added.
    if (!_behaviorStack.contains(behavior)) {
      _behaviorStack.add(behavior);
      behavior.attachTo(this);
    }
  }

  /// Removes a behavior from the chart.
  ///
  /// Returns true if a behavior was removed, otherwise returns false.
  bool removeBehavior(ChartBehavior<D>? behavior) {
    if (behavior == null) {
      return false;
    }

    final role = behavior.role;
    if (role != null && _behaviorRoleMap[role] == behavior) {
      _behaviorRoleMap.remove(role);
    }

    // Make sure the removed behavior is no longer registered for tap events.
    unregisterTappable(behavior);

    final wasAttached = _behaviorStack.remove(behavior);
    behavior.removeFrom(this);

    return wasAttached;
  }

  /// Tells the chart that this behavior responds to tap events.
  ///
  /// This should only be called after [behavior] has been attached to the chart
  /// via [addBehavior].
  void registerTappable(ChartBehavior<D> behavior) {
    final role = behavior.role;

    if (role != null &&
        _behaviorRoleMap[role] == behavior &&
        _behaviorTappableMap[role] != behavior) {
      _behaviorTappableMap[role] = behavior;
    }
  }

  /// Tells the chart that this behavior no longer responds to tap events.
  void unregisterTappable(ChartBehavior<D> behavior) {
    final role = behavior.role;
    if (role != null && _behaviorTappableMap[role] == behavior) {
      _behaviorTappableMap.remove(role);
    }
  }

  /// Returns a list of behaviors that have been added.
  List<ChartBehavior<D>> get behaviors => List.unmodifiable(_behaviorStack);

  //
  // Layout methods
  //
  void measure(int width, int height) {
    if (_rendererToSeriesList != null) {
      _layoutManager.measure(width, height);
    }
  }

  void layout(int width, int height) {
    if (_rendererToSeriesList != null) {
      layoutInternal(width, height);

      onPostLayout(_rendererToSeriesList!);
    }
  }

  void layoutInternal(int width, int height) {
    _chartWidth = width;
    _chartHeight = height;
    _layoutManager.layout(width, height);
  }

  void addView(LayoutView view) {
    if (!_layoutManager.isAttached(view)) {
      view.graphicsFactory = graphicsFactory;
      _layoutManager.addView(view);
    }
  }

  void removeView(LayoutView view) {
    _layoutManager.removeView(view);
  }

  /// Returns whether or not [point] is within the draw area bounds.
  bool withinDrawArea(Point<num> point) {
    return _layoutManager.withinDrawArea(point);
  }

  /// Returns the bounds of the chart draw area.
  Rectangle<int> get drawAreaBounds => _layoutManager.drawAreaBounds;

  int get marginBottom => _layoutManager.marginBottom;

  int get marginLeft => _layoutManager.marginLeft;

  int get marginRight => _layoutManager.marginRight;

  int get marginTop => _layoutManager.marginTop;

  /// Returns the combined bounds of the chart draw area and all layout
  /// components that draw series data.
  Rectangle<int> get drawableLayoutAreaBounds =>
      _layoutManager.drawableLayoutAreaBounds;

  //
  // Draw methods
  //
  void draw(List<Series<dynamic, D>> seriesList) {
    // Clear the selection model when [seriesList] changes.
    for (final selectionModel in _selectionModels.values) {
      selectionModel.clearSelection(notifyListeners: false);
    }

    var processedSeriesList =
        List.of(seriesList.map<MutableSeries<D>>(makeSeries));

    // Allow listeners to manipulate the seriesList.
    fireOnDraw(processedSeriesList);

    // Set an index on the series list.
    // This can be used by listeners of selection to determine the order of
    // series, because the selection details are not returned in this order.
    var seriesIndex = 0;
    processedSeriesList.forEach((series) => series.seriesIndex = seriesIndex++);

    // Initially save a reference to processedSeriesList. After drawInternal
    // finishes, we expect _currentSeriesList to contain a new, possibly
    // modified list.
    _currentSeriesList = processedSeriesList;

    // Store off processedSeriesList for use later during redraw calls. This
    // list will not reflect any modifications that were made to
    // _currentSeriesList by behaviors during the draw cycle.
    _originalSeriesList = processedSeriesList;

    drawInternal(processedSeriesList, skipAnimation: false, skipLayout: false);
  }

  /// Redraws and re-lays-out the chart using the previously rendered layout
  /// dimensions.
  void redraw({bool skipAnimation = false, bool skipLayout = false}) {
    drawInternal(_originalSeriesList,
        skipAnimation: skipAnimation, skipLayout: skipLayout);

    // Trigger layout and actually redraw the chart.
    if (!skipLayout) {
      measure(_chartWidth!, _chartHeight!);
      layout(_chartWidth!, _chartHeight!);
    } else {
      onSkipLayout();
    }
  }

  void drawInternal(List<MutableSeries<D>> seriesList,
      {bool? skipAnimation, bool? skipLayout}) {
    seriesList = seriesList
        .map((MutableSeries<D> series) => MutableSeries<D>.clone(series))
        .toList();

    // TODO: Handle exiting renderers.
    if (skipAnimation != null) {
      _animationsTemporarilyDisabled = skipAnimation;
    }

    configureSeries(seriesList);

    // Allow listeners to manipulate the processed seriesList.
    fireOnPreprocess(seriesList);

    _rendererToSeriesList = preprocessSeries(seriesList);

    // Allow listeners to manipulate the processed seriesList.
    fireOnPostprocess(seriesList);

    _currentSeriesList = seriesList;
  }

  List<MutableSeries<D>> get currentSeriesList => _currentSeriesList!;

  MutableSeries<D> makeSeries(Series<dynamic, D> series) {
    final s = MutableSeries<D>(series);

    // Setup the Renderer
    final rendererId =
        series.getAttribute(rendererIdKey) ?? SeriesRenderer.defaultRendererId;
    s.setAttr(rendererIdKey, rendererId);
    s.setAttr(rendererKey, getSeriesRenderer(rendererId));

    return s;
  }

  /// Preprocess series to assign missing color functions.
  void configureSeries(List<MutableSeries<D>> seriesList) {
    final rendererToSeriesList = <String?, List<MutableSeries<D>>>{};

    // Build map of rendererIds to SeriesLists. This map can't be re-used later
    // in the preprocessSeries call because some behaviors might alter the
    // seriesList.
    seriesList.forEach((MutableSeries<D> series) {
      final rendererId = series.getAttr(rendererIdKey);
      rendererToSeriesList.putIfAbsent(rendererId, () => []).add(series);
    });

    // Have each renderer add missing color functions to their seriesLists.
    rendererToSeriesList
        .forEach((String? rendererId, List<MutableSeries<D>> seriesList) {
      getSeriesRenderer(rendererId).configureSeries(seriesList);
    });
  }

  /// Preprocess series to allow stacking and other mutations.
  ///
  /// Build a map of rendererId to series.
  Map<String, List<MutableSeries<D>>> preprocessSeries(
      List<MutableSeries<D>> seriesList) {
    final rendererToSeriesList = <String, List<MutableSeries<D>>>{};

    var unusedRenderers = _usingRenderers;
    _usingRenderers = <String>{};

    // Build map of rendererIds to SeriesLists.
    seriesList.forEach((MutableSeries<D> series) {
      final rendererId = series.getAttr(rendererIdKey)!;
      rendererToSeriesList.putIfAbsent(rendererId, () => []).add(series);

      _usingRenderers.add(rendererId);
      unusedRenderers.remove(rendererId);
    });

    // Allow unused renderers to render out content.
    unusedRenderers
        .forEach((rendererId) => rendererToSeriesList[rendererId] = []);

    // Have each renderer preprocess their seriesLists.
    rendererToSeriesList.forEach((rendererId, seriesList) {
      getSeriesRenderer(rendererId).preprocessSeries(seriesList);
    });

    return rendererToSeriesList;
  }

  void onSkipLayout() {
    onPostLayout(_rendererToSeriesList!);
  }

  void onPostLayout(Map<String, List<MutableSeries<D>>> rendererToSeriesList) {
    // Update each renderer with
    rendererToSeriesList
        .forEach((String rendererId, List<MutableSeries<D>> seriesList) {
      getSeriesRenderer(rendererId).update(seriesList, animatingThisDraw);
    });

    // Request animation
    if (animatingThisDraw) {
      animationPercent = 0.0;
      context.requestAnimation(transition);
    } else {
      animationPercent = 1.0;
      context.requestPaint();
    }

    _animationsTemporarilyDisabled = false;
  }

  void paint(ChartCanvas canvas) {
    canvas.drawingView = 'BaseView';
    _layoutManager.paintOrderedViews.forEach((LayoutView view) {
      canvas.drawingView = view.runtimeType.toString();
      view.paint(canvas, animatingThisDraw ? animationPercent : 1.0);
    });

    canvas.drawingView = 'PostRender';
    fireOnPostrender(canvas);
    canvas.drawingView = null;

    if (animationPercent == 1.0) {
      fireOnAnimationComplete();
    }
  }

  bool get animatingThisDraw =>
      transition != null &&
      transition.inMilliseconds > 0 &&
      !_animationsTemporarilyDisabled;

  @protected
  void fireOnDraw(List<MutableSeries<D>> seriesList) {
    _lifecycleListeners.forEach((LifecycleListener<D> listener) {
      listener.onData?.call(seriesList);
    });
  }

  @protected
  void fireOnPreprocess(List<MutableSeries<D>> seriesList) {
    _lifecycleListeners.forEach((LifecycleListener<D> listener) {
      listener.onPreprocess?.call(seriesList);
    });
  }

  @protected
  void fireOnPostprocess(List<MutableSeries<D>> seriesList) {
    _lifecycleListeners.forEach((LifecycleListener<D> listener) {
      listener.onPostprocess?.call(seriesList);
    });
  }

  @protected
  void fireOnAxisConfigured() {
    _lifecycleListeners.forEach((LifecycleListener<D> listener) {
      listener.onAxisConfigured?.call();
    });
  }

  @protected
  void fireOnPostrender(ChartCanvas canvas) {
    _lifecycleListeners.forEach((LifecycleListener<D> listener) {
      listener.onPostrender?.call(canvas);
    });
  }

  @protected
  void fireOnAnimationComplete() {
    _lifecycleListeners.forEach((LifecycleListener<D> listener) {
      listener.onAnimationComplete?.call();
    });
  }

  /// Called to free up any resources due to chart going away.
  void destroy() {
    // Walk them in add order to support behaviors that remove other behaviors.
    for (var i = 0; i < _behaviorStack.length; i++) {
      _behaviorStack[i].removeFrom(this);
    }
    _behaviorStack.clear();
    _behaviorRoleMap.clear();
    _selectionModels.values
        .forEach((selectionModel) => selectionModel.clearAllListeners());
  }
}

class LifecycleListener<D> {
  /// Called when data is drawn to the chart (not a redraw).
  ///
  /// This step is good for processing the data (running averages, percentage of
  /// first, etc). It can also be used to add Series of data (trend line) or
  /// remove a line as mentioned above, removing Series.
  final LifecycleSeriesListCallback<D>? onData;

  /// Called for every redraw given the original SeriesList resulting from the
  /// previous onData.
  ///
  /// This step is good for injecting default attributes on the Series before
  /// the renderers process the data (ex: before stacking measures).
  final LifecycleSeriesListCallback<D>? onPreprocess;

  /// Called after the chart and renderers get a chance to process the data but
  /// before the axes process them.
  ///
  /// This step is good if you need to alter the Series measure values after the
  /// renderers have processed them (ex: after stacking measures).
  final LifecycleSeriesListCallback<D>? onPostprocess;

  /// Called after the Axes have been configured.
  /// This step is good if you need to use the axes to get any cartesian
  /// location information. At this point Axes should be immutable and stable.
  final LifecycleEmptyCallback? onAxisConfigured;

  /// Called after the chart is done rendering passing along the canvas allowing
  /// a behavior or other listener to render on top of the chart.
  ///
  /// This is a convenience callback, however if there is any significant canvas
  /// interaction or stacking needs, it is preferred that a AplosView/ChartView
  /// is added to the chart instead to fully participate in the view stacking.
  final LifecycleCanvasCallback? onPostrender;

  /// Called after animation hits 100%. This allows a behavior or other listener
  /// to chain animations to create a multiple step animation transition.
  final LifecycleEmptyCallback? onAnimationComplete;

  LifecycleListener(
      {this.onData,
      this.onPreprocess,
      this.onPostprocess,
      this.onAxisConfigured,
      this.onPostrender,
      this.onAnimationComplete});
}

typedef LifecycleSeriesListCallback<D> = void Function(
    List<MutableSeries<D>> seriesList);
typedef LifecycleCanvasCallback = void Function(ChartCanvas canvas);
typedef LifecycleEmptyCallback = void Function();

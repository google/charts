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

import 'behavior/chart_behavior.dart' show ChartBehavior;
import 'chart_canvas.dart' show ChartCanvas;
import 'chart_context.dart' show ChartContext;
import 'datum_details.dart' show DatumDetails;
import 'series_renderer.dart' show SeriesRenderer, rendererIdKey, rendererKey;
import 'processed_series.dart' show MutableSeries;
import '../layout/layout_view.dart' show LayoutView;
import '../layout/layout_config.dart' show LayoutConfig;
import '../layout/layout_manager.dart' show LayoutManager;
import '../layout/layout_manager_impl.dart' show LayoutManagerImpl;
import '../../common/graphics_factory.dart' show GraphicsFactory;
import '../../data/series.dart' show Series;
import '../../common/gesture_listener.dart' show GestureListener;
import '../../common/proxy_gesture_listener.dart' show ProxyGestureListener;
import 'selection_model/selection_model.dart'
    show SelectionModel, SelectionModelType;

typedef BehaviorCreator = ChartBehavior<T, D> Function<T, D>();

abstract class BaseChart<T, D> {
  ChartContext context;

  @protected
  GraphicsFactory graphicsFactory;

  LayoutManager _layoutManager;

  int _chartWidth;
  int _chartHeight;

  Duration transition = const Duration(milliseconds: 300);
  double animationPercent;

  bool _animationsTemporarilyDisabled = false;

  List<MutableSeries<T, D>> _currentSeriesList;
  Set<String> _usingRenderers = new Set<String>();
  Map<String, List<MutableSeries<T, D>>> _rendererToSeriesList;

  var _seriesRenderers = <String, SeriesRenderer<T, D>>{};

  /// Map of named chart behaviors attached to this chart.
  final _behaviorRoleMap = <String, ChartBehavior<T, D>>{};
  final _behaviorStack = <ChartBehavior<T, D>>[];

  final _gestureProxy = new ProxyGestureListener();

  final _selectionModels = <SelectionModelType, SelectionModel<T, D>>{};

  final _lifecycleListeners = <LifecycleListener<T, D>>[];

  BaseChart({LayoutConfig layoutConfig}) {
    _layoutManager = new LayoutManagerImpl(config: layoutConfig);
  }

  void init(ChartContext context, GraphicsFactory graphicsFactory) {
    this.context = context;

    // When graphics factory is updated, update all the views.
    if (this.graphicsFactory != graphicsFactory) {
      this.graphicsFactory = graphicsFactory;

      _layoutManager.applyToViews(
          (LayoutView view) => view.graphicsFactory = graphicsFactory);
    }
  }

  int get chartWidth => _chartWidth;

  int get chartHeight => _chartHeight;

  //
  // Gesture proxy methods
  //
  ProxyGestureListener get gestureProxy => _gestureProxy;

  /// Add a [GestureListener] to this chart.
  GestureListener addGestureListener(GestureListener listener) {
    _gestureProxy.listeners.add(listener);
    return listener;
  }

  /// Remove a [GestureListener] from this chart.
  void removeGestureListener(GestureListener listener) {
    _gestureProxy.listeners.remove(listener);
  }

  LifecycleListener addLifecycleListener(LifecycleListener listener) {
    _lifecycleListeners.add(listener);
    return listener;
  }

  bool removeLifecycleListener(LifecycleListener listener) =>
      _lifecycleListeners.remove(listener);

  /// Returns a SelectionModel for the given type. Lazy creates one upon first
  /// request.
  SelectionModel<T, D> getSelectionModel(SelectionModelType type) {
    return _selectionModels.putIfAbsent(type, () => new SelectionModel<T, D>());
  }

  /// Returns a list of datum details from selection model of [type].
  List<DatumDetails<T, D>> getDatumDetails(SelectionModelType type);

  //
  // Renderer methods
  //

  set defaultRenderer(SeriesRenderer<T, D> renderer) {
    renderer.rendererId = SeriesRenderer.defaultRendererId;
    addSeriesRenderer(renderer);
  }

  SeriesRenderer<T, D> get defaultRenderer =>
      getSeriesRenderer(SeriesRenderer.defaultRendererId);

  void addSeriesRenderer(SeriesRenderer renderer) {
    String rendererId = renderer.rendererId;

    SeriesRenderer<T, D> previousRenderer = _seriesRenderers[rendererId];
    if (previousRenderer != null) {
      removeView(previousRenderer);
      previousRenderer.onDetach(this);
    }

    addView(renderer);
    renderer.onAttach(this);
    _seriesRenderers[rendererId] = renderer;
  }

  SeriesRenderer<T, D> getSeriesRenderer(String rendererId) {
    SeriesRenderer<T, D> renderer = _seriesRenderers[rendererId];

    // Special case, if we are asking for the default and we haven't made it
    // yet, then make it now.
    if (renderer == null) {
      if (rendererId == SeriesRenderer.defaultRendererId) {
        renderer = makeDefaultRenderer();
        defaultRenderer = renderer;
      }
    }
    // TODO: throw error if couldn't find renderer by id?

    return renderer;
  }

  SeriesRenderer<T, D> makeDefaultRenderer();

  bool pointWithinRenderer(Point<double> chartPosition) {
    return _usingRenderers.any((String rendererId) =>
        getSeriesRenderer(rendererId)
            .componentBounds
            .containsPoint(chartPosition));
  }

  List<DatumDetails<T, D>> getNearestDatumDetailPerSeries(
      Point<double> drawAreaPoint) {
    final details = <DatumDetails<T, D>>[];
    _usingRenderers.forEach((String rendererId) {
      details.addAll(getSeriesRenderer(rendererId)
          .getNearestDatumDetailPerSeries(drawAreaPoint));
    });

    // Sort so that the nearest one is first.
    // Special sort, sort by domain distance first, then by measure distance.
    details.sort((DatumDetails<T, D> a, DatumDetails<T, D> b) {
      int domainDiff = a.domainDistance.compareTo(b.domainDistance);
      if (domainDiff == 0) {
        return a.measureDistance.compareTo(b.measureDistance);
      }
      return domainDiff;
    });

    return details;
  }

  //
  // Behavior methods
  //

  /// Helper method to create a behavior with congruent types.
  ///
  /// This invokes the provides helper with type parameters that match this
  /// chart.
  ChartBehavior<T, D> createBehavior(BehaviorCreator creator) =>
      creator<T, D>();

  /// Attaches a behavior to the chart.
  ///
  /// Setting a new behavior with the same role as a behavior already attached
  /// to the chart will replace the old behavior. The old behavior's removeFrom
  /// method will be called before we attach the new behavior.
  void addBehavior(ChartBehavior<T, D> behavior) {
    final role = behavior.role;

    if (role != null && _behaviorRoleMap[role] != behavior) {
      // Remove any old behavior with the same role.
      removeBehavior(_behaviorRoleMap[role]);
      // Add the new behavior.
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
  bool removeBehavior(ChartBehavior<T, D> behavior) {
    if (behavior == null) {
      return false;
    }

    final role = behavior?.role;
    if (role != null && _behaviorRoleMap[role] == behavior) {
      _behaviorRoleMap.remove(role);
    }

    final wasAttached = _behaviorStack.remove(behavior);
    behavior.removeFrom(this);

    return wasAttached;
  }

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

      onPostLayout(_rendererToSeriesList);
    }
  }

  void layoutInternal(int width, int height) {
    _chartWidth = width;
    _chartHeight = height;
    _layoutManager.layout(width, height);
  }

  void addView(LayoutView view) {
    if (_layoutManager.isAttached(view) == false) {
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

  //
  // Draw methods
  //
  void draw(List<Series<T, D>> seriesList) {
    var processedSeriesList = new List<MutableSeries<T, D>>.from(
        seriesList.map((Series<T, D> series) => makeSeries(series)));

    // Allow listeners to manipulate the seriesList.
    fireOnDraw(processedSeriesList);

    // Set an index on the series list.
    // This can be used by listeners of selection to determine the order of
    // series, because the selection details are not returned in this order.
    int seriesIndex = 0;
    processedSeriesList.forEach((series) => series.seriesIndex = seriesIndex++);

    _currentSeriesList = processedSeriesList;

    drawInternal(processedSeriesList, skipAnimation: false, skipLayout: false);
  }

  /// Redraws and re-lays-out the chart using the previously rendered layout
  /// dimensions.
  void redraw({bool skipAnimation = false, bool skipLayout = false}) {
    drawInternal(_currentSeriesList,
        skipAnimation: skipAnimation, skipLayout: skipLayout);

    // Trigger layout and actually redraw the chart.
    if (!skipLayout) {
      measure(_chartWidth, _chartHeight);
      layout(_chartWidth, _chartHeight);
    } else {
      onSkipLayout();
    }
  }

  void drawInternal(List<MutableSeries<T, D>> seriesList,
      {bool skipAnimation, bool skipLayout}) {
    seriesList = seriesList
        .map((MutableSeries<T, D> series) =>
            new MutableSeries<T, D>.clone(series))
        .toList();

    // TODO: Handle exiting renderers.
    _animationsTemporarilyDisabled = skipAnimation;

    // Allow listeners to manipulate the processed seriesList.
    fireOnPreprocess(seriesList);

    _rendererToSeriesList = preprocessSeries(seriesList);

    // Allow listeners to manipulate the processed seriesList.
    fireOnPostprocess(seriesList);
  }

  MutableSeries<T, D> makeSeries(Series<T, D> series) {
    final s = new MutableSeries<T, D>(series);

    // Setup the Renderer
    final rendererId =
        series.getAttribute(rendererIdKey) ?? SeriesRenderer.defaultRendererId;
    s.setAttr(rendererIdKey, rendererId);
    s.setAttr(rendererKey, getSeriesRenderer(rendererId));

    return s;
  }

  /// Preprocess series to allow stacking and other mutations.
  /// Build a map rendererId to series.
  Map<String, List<MutableSeries<T, D>>> preprocessSeries(
      List<MutableSeries<T, D>> seriesList) {
    Map<String, List<MutableSeries<T, D>>> rendererToSeriesList = {};

    var unusedRenderers = _usingRenderers;
    _usingRenderers = new Set<String>();

    // Build map of rendererIds to SeriesLists.
    seriesList.forEach((MutableSeries<T, D> series) {
      String rendererId = series.getAttr(rendererIdKey);
      rendererToSeriesList.putIfAbsent(rendererId, () => []).add(series);

      _usingRenderers.add(rendererId);
      unusedRenderers.remove(rendererId);
    });

    // Allow unused renderers to render out content.
    unusedRenderers
        .forEach((String rendererId) => rendererToSeriesList[rendererId] = []);

    // Have each renderer preprocess their seriesLists.
    rendererToSeriesList
        .forEach((String rendererId, List<MutableSeries<T, D>> seriesList) {
      getSeriesRenderer(rendererId).preprocessSeries(seriesList);
    });

    return rendererToSeriesList;
  }

  void onSkipLayout() {
    onPostLayout(_rendererToSeriesList);
  }

  void onPostLayout(
      Map<String, List<MutableSeries<T, D>>> rendererToSeriesList) {
    // Update each renderer with
    rendererToSeriesList
        .forEach((String rendererId, List<MutableSeries<T, D>> seriesList) {
      getSeriesRenderer(rendererId).update(seriesList, animatingThisDraw);
    });

    // Request animation
    if (animatingThisDraw) {
      animationPercent = 0.0;
      context.requestAnimation(this.transition);
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

  bool get animatingThisDraw => (transition != null &&
      transition.inMilliseconds > 0 &&
      !_animationsTemporarilyDisabled);

  @protected
  fireOnDraw(List<MutableSeries<T, D>> seriesList) {
    _lifecycleListeners.forEach((LifecycleListener<T, D> listener) {
      if (listener.onData != null) {
        listener.onData(seriesList);
      }
    });
  }

  @protected
  fireOnPreprocess(List<MutableSeries<T, D>> seriesList) {
    _lifecycleListeners.forEach((LifecycleListener<T, D> listener) {
      if (listener.onPreprocess != null) {
        listener.onPreprocess(seriesList);
      }
    });
  }

  @protected
  fireOnPostprocess(List<MutableSeries<T, D>> seriesList) {
    _lifecycleListeners.forEach((LifecycleListener<T, D> listener) {
      if (listener.onPostprocess != null) {
        listener.onPostprocess(seriesList);
      }
    });
  }

  @protected
  fireOnAxisConfigured() {
    _lifecycleListeners.forEach((LifecycleListener<T, D> listener) {
      if (listener.onAxisConfigured != null) {
        listener.onAxisConfigured();
      }
    });
  }

  @protected
  fireOnPostrender(ChartCanvas canvas) {
    _lifecycleListeners.forEach((LifecycleListener<T, D> listener) {
      if (listener.onPostrender != null) {
        listener.onPostrender(canvas);
      }
    });
  }

  @protected
  fireOnAnimationComplete() {
    _lifecycleListeners.forEach((LifecycleListener<T, D> listener) {
      if (listener.onAnimationComplete != null) {
        listener.onAnimationComplete();
      }
    });
  }

  /// Called to free up any resources due to chart going away.
  destroy() {
    // Walk them in add order to support behaviors that remove other behaviors.
    for (var i = 0; i < _behaviorStack.length; i++) {
      _behaviorStack[i].removeFrom(this);
    }
    _behaviorStack.clear();
    _behaviorRoleMap.clear();
    _selectionModels.values.forEach(
        (SelectionModel selectionModel) => selectionModel.clearListeners());
  }
}

class LifecycleListener<T, D> {
  /// Called when new data is drawn to the chart (not a redraw).
  ///
  /// This step is good for processing the data (running averages, percentage of
  /// first, etc). It can also be used to add Series of data (trend line) or
  /// remove a line as mentioned above, removing Series.
  final LifecycleSeriesListCallback onData;

  /// Called for every redraw given the original SeriesList resulting from the
  /// previous onData.
  ///
  /// This step is good for injecting default attributes on the Series before
  /// the renderers process the data (ex: before stacking measures).
  final LifecycleSeriesListCallback onPreprocess;

  /// Called after the chart and renderers get a chance to process the data but
  /// before the axes process them.
  ///
  /// This step is good if you need to alter the Series measure values after the
  /// renderers have processed them (ex: after stacking measures).
  final LifecycleSeriesListCallback onPostprocess;

  /// Called after the Axes have been configured.
  /// This step is good if you need to use the axes to get any cartesian
  /// location information. At this point Axes should be immutable and stable.
  final LifecycleEmptyCallback onAxisConfigured;

  /// Called after the chart is done rendering passing along the canvas allowing
  /// a behavior or other listener to render on top of the chart.
  ///
  /// This is a convenience callback, however if there is any significant canvas
  /// interaction or stacking needs, it is preferred that a AplosView/ChartView
  /// is added to the chart instead to fully participate in the view stacking.
  final LifecycleCanvasCallback onPostrender;

  /// Called after animation hits 100%. This allows a behavior or other listener
  /// to chain animations to create a multiple step animation transition.
  final LifecycleEmptyCallback onAnimationComplete;

  LifecycleListener(
      {this.onData,
      this.onPreprocess,
      this.onPostprocess,
      this.onAxisConfigured,
      this.onPostrender,
      this.onAnimationComplete});
}

typedef LifecycleSeriesListCallback<T, D>(List<MutableSeries<T, D>> seriesList);
typedef LifecycleCanvasCallback(ChartCanvas canvas);
typedef LifecycleEmptyCallback();

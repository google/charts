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

import '../../../common/graphics_factory.dart' show GraphicsFactory;
import '../../common/chart_context.dart' show ChartContext;
import 'axis.dart' show AxisOrientation;
import 'draw_strategy/tick_draw_strategy.dart' show TickDrawStrategy;
import 'numeric_scale.dart' show NumericScale;
import 'ordinal_scale.dart' show OrdinalScale;
import 'scale.dart' show MutableScale;
import 'tick.dart' show Tick;
import 'tick_formatter.dart' show TickFormatter;
import 'tick_provider.dart' show BaseTickProvider, TickHint;
import 'time/date_time_scale.dart' show DateTimeScale;

/// Tick provider that provides ticks at the two end points of the axis range.
class EndPointsTickProvider<D> extends BaseTickProvider<D> {
  @override
  List<Tick<D>> getTicks({
    required ChartContext? context,
    required GraphicsFactory graphicsFactory,
    required MutableScale<D> scale,
    required TickFormatter<D> formatter,
    required Map<D, String> formatterValueCache,
    required TickDrawStrategy<D> tickDrawStrategy,
    required AxisOrientation? orientation,
    bool viewportExtensionEnabled = false,
    TickHint<D>? tickHint,
  }) {
    final ticks = <Tick<D>>[];

    // Check to see if the axis has been configured with some domain values.
    //
    // An un-configured axis has no domain step size, and its scale defaults to
    // infinity.
    if (scale.domainStepSize.abs() != double.infinity) {
      final start = _getStartValue(tickHint, scale);
      final end = _getEndValue(tickHint, scale);

      final labels = formatter.format([start, end], formatterValueCache,
          stepSize: scale.domainStepSize);

      if (start != null) {
        ticks.add(Tick(
            value: start,
            textElement: graphicsFactory.createTextElement(labels[0]),
            locationPx: scale[start]?.toDouble()));
      }

      if (end != null) {
        ticks.add(Tick(
            value: end,
            textElement: graphicsFactory.createTextElement(labels[1]),
            locationPx: scale[end]?.toDouble()));
      }

      // Allow draw strategy to decorate the ticks.
      tickDrawStrategy.decorateTicks(ticks);
    }

    return ticks;
  }

  /// Get the start value from the scale.
  D _getStartValue(TickHint<D>? tickHint, MutableScale<D> scale) {
    Object? start;

    if (tickHint != null) {
      start = tickHint.start;
    } else {
      // Upcast to allow type promotion.
      // See https://github.com/dart-lang/sdk/issues/34018.
      Object _scale = scale;
      if (_scale is NumericScale) {
        start = _scale.viewportDomain.min;
      } else if (_scale is DateTimeScale) {
        start = _scale.viewportDomain.start;
      } else if (_scale is OrdinalScale) {
        start = _scale.domain.first;
      } else {
        throw UnsupportedError('Unrecognized scale: {scale.runtimeType}');
      }
    }

    return start as D;
  }

  /// Get the end value from the scale.
  D _getEndValue(TickHint<D>? tickHint, MutableScale<D> scale) {
    Object? end;

    if (tickHint != null) {
      end = tickHint.end;
    } else {
      // Upcast to allow type promotion.
      // See https://github.com/dart-lang/sdk/issues/34018.
      Object _scale = scale;
      if (_scale is NumericScale) {
        end = _scale.viewportDomain.max;
      } else if (_scale is DateTimeScale) {
        end = _scale.viewportDomain.end;
      } else if (_scale is OrdinalScale) {
        end = _scale.domain.last;
      } else {
        throw UnsupportedError('Unrecognized scale: {scale.runtimeType}');
      }
    }

    return end as D;
  }
}

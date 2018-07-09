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

import 'package:meta/meta.dart' show required;
import '../../common/chart_context.dart' show ChartContext;
import '../../../common/graphics_factory.dart' show GraphicsFactory;
import 'axis.dart' show AxisOrientation;
import 'scale.dart' show MutableScale;
import 'tick.dart' show Tick;
import 'spec/tick_spec.dart' show TickSpec;
import 'tick_formatter.dart' show TickFormatter;
import 'draw_strategy/tick_draw_strategy.dart' show TickDrawStrategy;
import 'tick_provider.dart' show TickProvider, TickHint;

/// A strategy that uses the ticks provided and only assigns positioning.
///
/// The [TextStyle] is not overridden during tick draw strategy decorateTicks.
/// If it is null, then the default is used.
class StaticTickProvider<D> extends TickProvider<D> {
  final List<TickSpec<D>> tickSpec;

  StaticTickProvider(this.tickSpec);

  @override
  List<Tick<D>> getTicks({
    @required ChartContext context,
    @required GraphicsFactory graphicsFactory,
    @required MutableScale<D> scale,
    @required TickFormatter<D> formatter,
    @required Map<D, String> formatterValueCache,
    @required TickDrawStrategy tickDrawStrategy,
    @required AxisOrientation orientation,
    bool viewportExtensionEnabled: false,
    TickHint<D> tickHint,
  }) {
    final ticks = <Tick<D>>[];

    for (TickSpec<D> spec in tickSpec) {
      if (scale.compareDomainValueToViewport(spec.value) == 0) {
        final tick = new Tick<D>(
            value: spec.value,
            textElement: graphicsFactory.createTextElement(spec.label),
            locationPx: scale[spec.value]);
        if (spec.style != null) {
          tick.textElement.textStyle = graphicsFactory.createTextPaint()
            ..fontFamily = spec.style.fontFamily
            ..fontSize = spec.style.fontSize
            ..color = spec.style.color;
        }
        ticks.add(tick);
      }
    }

    // Allow draw strategy to decorate the ticks.
    tickDrawStrategy.decorateTicks(ticks);

    return ticks;
  }

  @override
  bool operator ==(o) => o is StaticTickProvider && tickSpec == o.tickSpec;

  @override
  int get hashCode => tickSpec.hashCode;
}

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

import 'package:meta/meta.dart' show immutable;

import '../../../common/chart_context.dart' show ChartContext;
import '../ordinal_tick_provider.dart' show OrdinalTickProvider;
import '../static_tick_provider.dart' show StaticTickProvider;
import '../tick_formatter.dart' show OrdinalTickFormatter;
import '../ordinal_extents.dart' show OrdinalExtents;
import '../ordinal_scale.dart' show OrdinalScale;
import 'axis_spec.dart'
    show AxisSpec, TickProviderSpec, TickFormatterSpec, RenderSpec;
import 'tick_spec.dart' show TickSpec;

/// [AxisSpec] specialized for ordinal/non-continuous axes typically for bars.
@immutable
class OrdinalAxisSpec extends AxisSpec<String, OrdinalExtents, OrdinalScale> {
  /// Creates a [AxisSpec] that specialized for ordinal domain charts.
  ///
  /// [renderSpec] spec used to configure how the ticks and labels
  ///     actually render. Possible values are [GridlineRendererSpec],
  ///     [SmallTickRendererSpec] & [NoneRenderSpec]. Make sure that the <D>
  ///     given to the RenderSpec is of type [String] when using this spec.
  /// [tickProviderSpec] spec used to configure what ticks are generated.
  /// [tickFormatterSpec] spec used to configure how the tick labels are
  ///     formatted.
  /// [showAxisLine] override to force the axis to draw the axis line.
  OrdinalAxisSpec({
    RenderSpec<String> renderSpec,
    OrdinalTickProviderSpec tickProviderSpec,
    OrdinalTickFormatterSpec tickFormatterSpec,
    bool showAxisLine,
  })
      : super(
            renderSpec: renderSpec,
            tickProviderSpec: tickProviderSpec,
            tickFormatterSpec: tickFormatterSpec,
            showAxisLine: showAxisLine);

  @override
  bool operator ==(Object other) =>
      other is OrdinalAxisSpec && super == (other);
}

abstract class OrdinalTickProviderSpec
    extends TickProviderSpec<String, OrdinalExtents, OrdinalScale> {}

abstract class OrdinalTickFormatterSpec extends TickFormatterSpec<String> {}

@immutable
class BasicOrdinalTickProviderSpec implements OrdinalTickProviderSpec {
  BasicOrdinalTickProviderSpec();

  @override
  OrdinalTickProvider createTickProvider(ChartContext context) =>
      new OrdinalTickProvider();

  @override
  bool operator ==(Object other) => other is BasicOrdinalTickProviderSpec;

  @override
  int get hashCode => 37;
}

/// [TickProviderSpec] that allows you to specific the ticks to be used.
@immutable
class StaticOrdinalTickProviderSpec implements OrdinalTickProviderSpec {
  final List<TickSpec<String>> tickSpecs;

  StaticOrdinalTickProviderSpec(this.tickSpecs);

  @override
  StaticTickProvider<String, OrdinalExtents, OrdinalScale> createTickProvider(
          ChartContext context) =>
      new StaticTickProvider<String, OrdinalExtents, OrdinalScale>(tickSpecs);

  @override
  bool operator ==(Object other) =>
      other is StaticOrdinalTickProviderSpec && tickSpecs == other.tickSpecs;

  @override
  int get hashCode => tickSpecs.hashCode;
}

@immutable
class BasicOrdinalTickFormatterSpec implements OrdinalTickFormatterSpec {
  BasicOrdinalTickFormatterSpec();

  @override
  OrdinalTickFormatter createTickFormatter(ChartContext context) =>
      new OrdinalTickFormatter();

  @override
  bool operator ==(Object other) => other is BasicOrdinalTickFormatterSpec;

  @override
  int get hashCode => 37;
}

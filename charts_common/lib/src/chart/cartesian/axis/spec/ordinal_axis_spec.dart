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

import 'package:charts_common/src/chart/cartesian/axis/scale.dart'
    show RangeBandConfig;
import 'package:meta/meta.dart' show immutable;

import '../../../../common/graphics_factory.dart' show GraphicsFactory;
import '../../../common/chart_context.dart' show ChartContext;
import '../auto_adjusting_static_tick_provider.dart'
    show AutoAdjustingStaticTickProvider;
import '../axis.dart' show Axis, OrdinalAxis, OrdinalViewport;
import '../ordinal_scale.dart' show OrdinalScale;
import '../ordinal_tick_provider.dart' show OrdinalTickProvider;
import '../range_tick_provider.dart' show RangeTickProvider;
import '../simple_ordinal_scale.dart' show SimpleOrdinalScale;
import '../static_tick_provider.dart' show StaticTickProvider;
import '../tick_formatter.dart' show OrdinalTickFormatter;
import 'axis_spec.dart'
    show AxisSpec, TickProviderSpec, TickFormatterSpec, ScaleSpec, RenderSpec;
import 'tick_spec.dart' show TickSpec;

/// [AxisSpec] specialized for ordinal/non-continuous axes typically for bars.
@immutable
class OrdinalAxisSpec extends AxisSpec<String> {
  /// Sets viewport for this Axis.
  ///
  /// If pan / zoom behaviors are set, this is the initial viewport.
  final OrdinalViewport? viewport;

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
  const OrdinalAxisSpec({
    RenderSpec<String>? renderSpec,
    OrdinalTickProviderSpec? tickProviderSpec,
    OrdinalTickFormatterSpec? tickFormatterSpec,
    bool? showAxisLine,
    OrdinalScaleSpec? scaleSpec,
    this.viewport,
  }) : super(
          renderSpec: renderSpec,
          tickProviderSpec: tickProviderSpec,
          tickFormatterSpec: tickFormatterSpec,
          showAxisLine: showAxisLine,
          scaleSpec: scaleSpec,
        );

  @override
  void configure(Axis<String> axis, ChartContext context,
      GraphicsFactory graphicsFactory) {
    super.configure(axis, context, graphicsFactory);

    if (axis is OrdinalAxis && viewport != null) {
      axis.setScaleViewport(viewport!);
    }
  }

  @override
  OrdinalAxis createAxis() => OrdinalAxis();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is OrdinalAxisSpec &&
            viewport == other.viewport &&
            super == other);
  }

  @override
  int get hashCode {
    var hashcode = super.hashCode;
    hashcode = (hashcode * 37) + viewport.hashCode;
    return hashcode;
  }
}

abstract class OrdinalTickProviderSpec extends TickProviderSpec<String> {}

abstract class OrdinalTickFormatterSpec extends TickFormatterSpec<String> {}

abstract class OrdinalScaleSpec extends ScaleSpec<String> {}

@immutable
class BasicOrdinalTickProviderSpec implements OrdinalTickProviderSpec {
  const BasicOrdinalTickProviderSpec();

  @override
  OrdinalTickProvider createTickProvider(ChartContext context) =>
      OrdinalTickProvider();

  @override
  bool operator ==(Object other) => other is BasicOrdinalTickProviderSpec;

  @override
  int get hashCode => 37;
}

/// [TickProviderSpec] that allows you to specify the ticks to be used.
@immutable
class StaticOrdinalTickProviderSpec implements OrdinalTickProviderSpec {
  final List<TickSpec<String>> tickSpecs;

  const StaticOrdinalTickProviderSpec(this.tickSpecs);

  @override
  StaticTickProvider<String> createTickProvider(ChartContext context) =>
      StaticTickProvider<String>(tickSpecs);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StaticOrdinalTickProviderSpec && tickSpecs == other.tickSpecs);

  @override
  int get hashCode => tickSpecs.hashCode;
}

/// [TickProviderSpec] that tries different tick increments to avoid tick
/// collisions.
@immutable
class AutoAdjustingStaticOrdinalTickProviderSpec
    implements OrdinalTickProviderSpec {
  final List<TickSpec<String>> tickSpecs;
  final List<int> allowedTickIncrements;

  const AutoAdjustingStaticOrdinalTickProviderSpec(
      this.tickSpecs, this.allowedTickIncrements);

  @override
  AutoAdjustingStaticTickProvider<String> createTickProvider(
          ChartContext context) =>
      AutoAdjustingStaticTickProvider<String>(tickSpecs, allowedTickIncrements);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AutoAdjustingStaticOrdinalTickProviderSpec &&
          tickSpecs == other.tickSpecs);

  @override
  int get hashCode => tickSpecs.hashCode;
}

/// [TickProviderSpec] that allows you to provide range ticks and normal ticks.
@immutable
class RangeOrdinalTickProviderSpec implements OrdinalTickProviderSpec {
  final List<TickSpec<String>> tickSpecs;
  const RangeOrdinalTickProviderSpec(this.tickSpecs);

  @override
  RangeTickProvider<String> createTickProvider(ChartContext context) =>
      RangeTickProvider<String>(tickSpecs);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RangeOrdinalTickProviderSpec && tickSpecs == other.tickSpecs);

  @override
  int get hashCode => tickSpecs.hashCode;
}

@immutable
class BasicOrdinalTickFormatterSpec implements OrdinalTickFormatterSpec {
  const BasicOrdinalTickFormatterSpec();

  @override
  OrdinalTickFormatter createTickFormatter(ChartContext context) =>
      OrdinalTickFormatter();

  @override
  bool operator ==(Object other) => other is BasicOrdinalTickFormatterSpec;

  @override
  int get hashCode => 37;
}

@immutable
class SimpleOrdinalScaleSpec implements OrdinalScaleSpec {
  const SimpleOrdinalScaleSpec();

  @override
  OrdinalScale createScale() => SimpleOrdinalScale();

  @override
  bool operator ==(Object other) => other is SimpleOrdinalScaleSpec;

  @override
  int get hashCode => 37;
}

/// [OrdinalScaleSpec] which allows setting space between bars to be a fixed
/// pixel size.
@immutable
class FixedPixelSpaceOrdinalScaleSpec implements OrdinalScaleSpec {
  final double pixelSpaceBetweenBars;

  const FixedPixelSpaceOrdinalScaleSpec(this.pixelSpaceBetweenBars);

  @override
  OrdinalScale createScale() => SimpleOrdinalScale()
    ..rangeBandConfig =
        RangeBandConfig.fixedPixelSpaceBetweenStep(pixelSpaceBetweenBars);

  @override
  bool operator ==(Object other) => other is SimpleOrdinalScaleSpec;

  @override
  int get hashCode => 37;
}

/// [OrdinalScaleSpec] which allows setting bar width to be a fixed pixel size.
@immutable
class FixedPixelOrdinalScaleSpec implements OrdinalScaleSpec {
  final double pixels;

  const FixedPixelOrdinalScaleSpec(this.pixels);

  @override
  OrdinalScale createScale() => SimpleOrdinalScale()
    ..rangeBandConfig = RangeBandConfig.fixedPixel(pixels);

  @override
  bool operator ==(Object other) => other is SimpleOrdinalScaleSpec;

  @override
  int get hashCode => 37;
}

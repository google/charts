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

import '../../../../common/color.dart' show Color;
import '../../../../common/graphics_factory.dart' show GraphicsFactory;
import '../../../common/chart_context.dart' show ChartContext;
import '../axis.dart' show Axis;
import '../draw_strategy/tick_draw_strategy.dart' show TickDrawStrategy;
import '../scale.dart' show Scale, MutableScale;
import '../tick_formatter.dart' show TickFormatter;
import '../tick_provider.dart' show TickProvider;

@immutable
class AxisSpec<D> {
  final bool? showAxisLine;
  final RenderSpec<D>? renderSpec;
  final TickProviderSpec<D>? tickProviderSpec;
  final TickFormatterSpec<D>? tickFormatterSpec;
  final ScaleSpec<D>? scaleSpec;

  const AxisSpec({
    this.renderSpec,
    this.tickProviderSpec,
    this.tickFormatterSpec,
    this.showAxisLine,
    this.scaleSpec,
  });

  factory AxisSpec.from(
    AxisSpec<D> other, {
    RenderSpec<D>? renderSpec,
    TickProviderSpec<D>? tickProviderSpec,
    TickFormatterSpec<D>? tickFormatterSpec,
    bool? showAxisLine,
    ScaleSpec<D>? scaleSpec,
  }) {
    return AxisSpec(
      renderSpec: renderSpec ?? other.renderSpec,
      tickProviderSpec: tickProviderSpec ?? other.tickProviderSpec,
      tickFormatterSpec: tickFormatterSpec ?? other.tickFormatterSpec,
      showAxisLine: showAxisLine ?? other.showAxisLine,
      scaleSpec: scaleSpec ?? other.scaleSpec,
    );
  }

  void configure(
      Axis<D> axis, ChartContext context, GraphicsFactory graphicsFactory) {
    axis.resetDefaultConfiguration();

    if (showAxisLine != null) {
      axis.forceDrawAxisLine = showAxisLine;
    }

    if (renderSpec != null) {
      axis.tickDrawStrategy =
          renderSpec!.createDrawStrategy(context, graphicsFactory);
    }

    if (tickProviderSpec != null) {
      axis.tickProvider = tickProviderSpec!.createTickProvider(context);
    }

    if (tickFormatterSpec != null) {
      axis.tickFormatter = tickFormatterSpec!.createTickFormatter(context);
    }

    if (scaleSpec != null) {
      axis.scale = scaleSpec!.createScale() as MutableScale<D>;
    }
  }

  /// Creates an appropriately typed [Axis].
  Axis<D>? createAxis() => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AxisSpec &&
          renderSpec == other.renderSpec &&
          tickProviderSpec == other.tickProviderSpec &&
          tickFormatterSpec == other.tickFormatterSpec &&
          showAxisLine == other.showAxisLine &&
          scaleSpec == other.scaleSpec);

  @override
  int get hashCode {
    var hashcode = renderSpec.hashCode;
    hashcode = (hashcode * 37) + tickProviderSpec.hashCode;
    hashcode = (hashcode * 37) + tickFormatterSpec.hashCode;
    hashcode = (hashcode * 37) + showAxisLine.hashCode;
    hashcode = (hashcode * 37) + scaleSpec.hashCode;
    return hashcode;
  }
}

@immutable
abstract class TickProviderSpec<D> {
  TickProvider<D> createTickProvider(ChartContext context);
}

@immutable
abstract class TickFormatterSpec<D> {
  TickFormatter<D> createTickFormatter(ChartContext context);
}

@immutable
abstract class ScaleSpec<D> {
  Scale<D> createScale();
}

@immutable
abstract class RenderSpec<D> {
  const RenderSpec();

  TickDrawStrategy<D> createDrawStrategy(
      ChartContext context, GraphicsFactory graphicFactory);
}

@immutable
class TextStyleSpec {
  final String? fontFamily;
  final int? fontSize;
  final double? lineHeight;
  final Color? color;
  final String? fontWeight;

  const TextStyleSpec(
      {this.fontFamily,
      this.fontSize,
      this.lineHeight,
      this.color,
      this.fontWeight});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TextStyleSpec &&
            fontFamily == other.fontFamily &&
            fontSize == other.fontSize &&
            lineHeight == other.lineHeight &&
            color == other.color &&
            fontWeight == other.fontWeight);
  }

  @override
  int get hashCode {
    var hashcode = fontFamily.hashCode;
    hashcode = (hashcode * 37) + fontSize.hashCode;
    hashcode = (hashcode * 37) + lineHeight.hashCode;
    hashcode = (hashcode * 37) + color.hashCode;
    hashcode = (hashcode * 37) + fontWeight.hashCode;
    return hashcode;
  }
}

@immutable
class LineStyleSpec {
  final Color? color;
  final List<int>? dashPattern;
  final int? thickness;

  const LineStyleSpec({this.color, this.dashPattern, this.thickness});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LineStyleSpec &&
            color == other.color &&
            dashPattern == other.dashPattern &&
            thickness == other.thickness);
  }

  @override
  int get hashCode {
    var hashcode = color.hashCode;
    hashcode = (hashcode * 37) + dashPattern.hashCode;
    hashcode = (hashcode * 37) + thickness.hashCode;
    return hashcode;
  }
}

enum TickLabelAnchor {
  before,
  centered,
  after,

  /// The top most tick draws all text under the location.
  /// The bottom most tick draws all text above the location.
  /// The rest of the ticks are centered.
  inside,
}

enum TickLabelJustification {
  inside,
  outside,
}

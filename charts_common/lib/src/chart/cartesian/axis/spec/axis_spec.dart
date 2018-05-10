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
import '../../../../common/color.dart' show Color;
import '../../../../common/graphics_factory.dart' show GraphicsFactory;
import '../draw_strategy/tick_draw_strategy.dart' show TickDrawStrategy;
import '../axis.dart' show Axis;
import '../tick_provider.dart' show TickProvider;
import '../tick_formatter.dart' show TickFormatter;

@immutable
class AxisSpec<D> {
  final bool showAxisLine;
  final RenderSpec<D> renderSpec;
  final TickProviderSpec<D> tickProviderSpec;
  final TickFormatterSpec<D> tickFormatterSpec;

  AxisSpec({
    this.renderSpec,
    this.tickProviderSpec,
    this.tickFormatterSpec,
    this.showAxisLine,
  });

  configure(
      Axis<D> axis, ChartContext context, GraphicsFactory graphicsFactory) {
    if (showAxisLine != null) {
      axis.forceDrawAxisLine = showAxisLine;
    }

    if (renderSpec != null) {
      axis.tickDrawStrategy =
          renderSpec.createDrawStrategy(context, graphicsFactory);
    }

    if (tickProviderSpec != null) {
      axis.tickProvider = tickProviderSpec.createTickProvider(context);
    }

    if (tickFormatterSpec != null) {
      axis.tickFormatter = tickFormatterSpec.createTickFormatter(context);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is AxisSpec &&
      renderSpec == other.renderSpec &&
      tickProviderSpec == other.tickProviderSpec &&
      tickFormatterSpec == other.tickFormatterSpec &&
      showAxisLine == other.showAxisLine;

  @override
  int get hashCode {
    int hashcode = renderSpec?.hashCode ?? 0;
    hashcode = (hashcode * 37) + tickProviderSpec.hashCode;
    hashcode = (hashcode * 37) + tickFormatterSpec.hashCode;
    hashcode = (hashcode * 37) + showAxisLine.hashCode;
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
abstract class RenderSpec<D> {
  TickDrawStrategy<D> createDrawStrategy(
      ChartContext context, GraphicsFactory graphicFactory);
}

@immutable
class TextStyleSpec {
  final String fontFamily;
  final int fontSize;
  final Color color;

  TextStyleSpec({this.fontFamily, this.fontSize, this.color});

  @override
  bool operator ==(Object other) {
    return other is TextStyleSpec &&
        fontFamily == other.fontFamily &&
        fontSize == other.fontSize &&
        color == other.color;
  }

  @override
  int get hashCode {
    int hashcode = fontFamily?.hashCode ?? 0;
    hashcode = (hashcode * 37) + fontSize?.hashCode ?? 0;
    hashcode = (hashcode * 37) + color?.hashCode ?? 0;
    return hashcode;
  }
}

@immutable
class LineStyleSpec {
  final Color color;
  final int thickness;

  LineStyleSpec({this.color, this.thickness});

  @override
  bool operator ==(Object other) {
    return other is LineStyleSpec &&
        color == other.color &&
        thickness == other.thickness &&
        color == other.color;
  }

  @override
  int get hashCode {
    int hashcode = color?.hashCode ?? 0;
    hashcode = (hashcode * 37) + thickness?.hashCode ?? 0;
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

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

import 'package:charts_common/common.dart' as common;
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart'
    show GestureDetector, GestureTapUpCallback, TapUpDetails, Theme;

import '../../symbol_renderer.dart';
import 'legend.dart' show TappableLegend;

/// Strategy for building one widget from one [common.LegendEntry].
abstract class LegendEntryLayout {
  Widget build(BuildContext context, common.LegendEntry legendEntry,
      TappableLegend legend, bool isHidden);
}

/// Builds one legend entry as a row with symbol and label from the series.
///
/// If directionality from the chart context indicates RTL, the symbol is placed
/// to the right of the text instead of the left of the text.
class SimpleLegendEntryLayout implements LegendEntryLayout {
  const SimpleLegendEntryLayout();

  Widget createSymbol(BuildContext context, common.LegendEntry legendEntry,
      TappableLegend legend, bool isHidden) {
    // TODO: Consider allowing scaling the size for the symbol.
    // A custom symbol renderer can ignore this size and use their own.
    final materialSymbolSize = new Size(12.0, 12.0);

    final entryColor = legendEntry.color;
    var color = new Color.fromARGB(
        entryColor.a, entryColor.r, entryColor.g, entryColor.b);

    // Get the SymbolRendererBuilder wrapping a common.SymbolRenderer if needed.
    final SymbolRendererBuilder symbolRendererBuilder =
        legendEntry.symbolRenderer is SymbolRendererBuilder
            ? legendEntry.symbolRenderer
            : new SymbolRendererCanvas(legendEntry.symbolRenderer);

    return new GestureDetector(
        child: symbolRendererBuilder.build(
          context,
          size: materialSymbolSize,
          color: color,
          enabled: !isHidden,
        ),
        onTapUp: makeTapUpCallback(context, legendEntry, legend));
  }

  Widget createLabel(BuildContext context, common.LegendEntry legendEntry,
      TappableLegend legend, bool isHidden) {
    TextStyle style;

    // Make the entry text 26% opaque if the entry is hidden.
    if (isHidden) {
      // Use the color from the body 1 theme, but create a new style that only
      // specifies a color. This should keep anything else that this [Text] is
      // inheriting intact.
      final body1 = Theme.of(context).textTheme.body1;
      final color = body1.color.withOpacity(0.26);
      style = new TextStyle(inherit: true, color: color);
    }

    return new GestureDetector(
        child: new Text(legendEntry.label, style: style),
        onTapUp: makeTapUpCallback(context, legendEntry, legend));
  }

  @override
  Widget build(BuildContext context, common.LegendEntry legendEntry,
      TappableLegend legend, bool isHidden) {
    // TODO: Allow setting to configure the padding.
    final padding = new EdgeInsets.only(right: 8.0); // Material default.
    final symbol = createSymbol(context, legendEntry, legend, isHidden);
    final label = createLabel(context, legendEntry, legend, isHidden);

    // Row automatically reverses the content if Directionality is rtl.
    return new Row(children: [symbol, new Container(padding: padding), label]);
  }

  GestureTapUpCallback makeTapUpCallback(BuildContext context,
      common.LegendEntry legendEntry, TappableLegend legend) {
    return (TapUpDetails d) {
      legend.onLegendEntryTapUp(legendEntry);
    };
  }

  bool operator ==(Object other) => other is SimpleLegendEntryLayout;

  int get hashCode {
    return this.runtimeType.hashCode;
  }
}

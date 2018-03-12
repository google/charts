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
import '../../symbol_renderer.dart';

/// Strategy for building one widget from one [common.LegendEntry].
abstract class LegendEntryLayout {
  Widget build(BuildContext context, common.LegendEntry legendEntry);
}

/// Builds one legend entry as a row with symbol and label from the series.
///
/// If directionality from the chart context indicates RTL, the symbol is placed
/// to the right of the text instead of the left of the text.
class SimpleLegendEntryLayout implements LegendEntryLayout {
  const SimpleLegendEntryLayout();

  Widget createSymbol(BuildContext context, common.LegendEntry legendEntry) {
    // TODO: Consider allowing scaling the size for the symbol.
    // A custom symbol renderer can ignore this size and use their own.
    final materialSymbolSize = new Size(12.0, 12.0);

    final SymbolRenderer symbolRenderer =
        legendEntry.symbolRenderer ?? new RoundedRectSymbolRenderer();
    final color = legendEntry.color;

    return symbolRenderer.build(
      context,
      size: materialSymbolSize,
      color: new Color.fromARGB(color.a, color.r, color.g, color.b),
    );
  }

  Widget createLabel(BuildContext context, common.LegendEntry legendEntry) =>
      new Text(legendEntry.label);

  @override
  Widget build(BuildContext context, common.LegendEntry legendEntry) {
    // TODO: Allow setting to configure the padding.
    final padding = new EdgeInsets.only(right: 8.0); // Material default.
    final symbol = createSymbol(context, legendEntry);
    final label = createLabel(context, legendEntry);

    // Row automatically reverses the content if Directionality is rtl.
    return new Row(children: [symbol, new Container(padding: padding), label]);
  }
}

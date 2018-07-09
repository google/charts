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

import '../../../../common/color.dart';
import '../../../../common/symbol_renderer.dart';
import '../../series_renderer.dart' show rendererKey;
import '../../processed_series.dart' show ImmutableSeries;

/// Holder for the information used for a legend row.
///
/// [T] the datum class type for the series passed in.
/// [D] the domain class type for the datum.
class LegendEntry<D> {
  final String label;
  final ImmutableSeries<D> series;
  final dynamic datum;
  final int datumIndex;
  final D domain;
  final double value;
  final Color color;
  bool isSelected;

  /// Indicates whether this is in the first row of a tabular layout.
  bool inFirstRow;

  /// Indicates whether this is in the first column of a tabular layout.
  bool inFirstColumn;

  /// Indicates whether this is in the last row of a tabular layout.
  bool inLastRow;

  /// Indicates whether this is in the last column of a tabular layout.
  bool inLastColumn;

  // TODO: Forward the default formatters from series and allow for
  // native legends to provide separate formatters.

  LegendEntry(this.series, this.label,
      {this.datum,
      this.datumIndex,
      this.domain,
      this.value,
      this.color,
      this.isSelected: false,
      this.inFirstRow,
      this.inFirstColumn,
      this.inLastRow,
      this.inLastColumn});

  /// Get the native symbol renderer stored in the series.
  SymbolRenderer get symbolRenderer =>
      series.getAttr(rendererKey).symbolRenderer;
}

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
import '../../../cartesian/axis/spec/axis_spec.dart' show TextStyleSpec;
import '../../processed_series.dart' show ImmutableSeries;
import '../../series_renderer.dart' show rendererKey;

/// The most basic possible legend entry - just a display name and positioning.
class LegendEntryBase {
  final String label;
  final TextStyleSpec? textStyle;

  /// Zero based index for the row where this legend appears in the legend.
  int? rowNumber;

  /// Zero based index for the column where this legend appears in the legend.
  int? columnNumber;

  /// Total number of rows in the legend.
  int? rowCount;

  /// Total number of columns in the legend.
  int? columnCount;

  /// Indicates whether this is in the first row of a tabular layout.
  bool? inFirstRow;

  /// Indicates whether this is in the first column of a tabular layout.
  bool? inFirstColumn;

  /// Indicates whether this is in the last row of a tabular layout.
  bool? inLastRow;

  /// Indicates whether this is in the last column of a tabular layout.
  bool? inLastColumn;

  LegendEntryBase(this.label,
      {this.textStyle,
      this.rowNumber,
      this.columnNumber,
      this.rowCount,
      this.columnCount,
      this.inFirstRow,
      this.inFirstColumn,
      this.inLastRow,
      this.inLastColumn});
}

/// When the legend groups by category it will create additional legend entries
/// that track styling and grouping on a per category basis.
class LegendCategory<D> extends LegendEntryBase {
  /// The list of entries that should be displayed within this category.
  final List<LegendEntry<D>>? entries;

  LegendCategory(
    String label,
    this.entries, {
    TextStyleSpec? textStyle,
    int? rowNumber,
    int? columnNumber,
    int? rowCount,
    int? columnCount,
    bool? inFirstRow,
    bool? inFirstColumn,
    bool? inLastRow,
    bool? inLastColumn,
  }) : super(label,
            textStyle: textStyle,
            rowNumber: rowNumber,
            columnNumber: columnNumber,
            rowCount: rowCount,
            columnCount: columnCount,
            inFirstRow: inFirstRow,
            inFirstColumn: inFirstColumn,
            inLastRow: inLastRow,
            inLastColumn: inLastColumn);
}

/// Holder for the information used for a legend row.
///
/// [T] the datum class type for the series passed in.
/// [D] the domain class type for the datum.
class LegendEntry<D> extends LegendEntryBase {
  final ImmutableSeries<D> series;
  final dynamic datum;
  final int? datumIndex;
  final D? domain;
  final Color? color;
  double? value;
  List<int?>? selectedDataIndexes;
  String? formattedValue;
  bool isSelected;

  // TODO: Forward the default formatters from series and allow for
  // native legends to provide separate formatters.

  LegendEntry(
    this.series,
    String label, {
    this.datum,
    this.datumIndex,
    this.domain,
    this.value,
    this.selectedDataIndexes,
    this.color,
    this.isSelected = false,
    TextStyleSpec? textStyle,
    int? rowNumber,
    int? columnNumber,
    int? rowCount,
    int? columnCount,
    bool? inFirstRow,
    bool? inFirstColumn,
    bool? inLastRow,
    bool? inLastColumn,
  }) : super(label,
            textStyle: textStyle,
            rowNumber: rowNumber,
            columnNumber: columnNumber,
            rowCount: rowCount,
            columnCount: columnCount,
            inFirstRow: inFirstRow,
            inFirstColumn: inFirstColumn,
            inLastRow: inLastRow,
            inLastColumn: inLastColumn);

  /// Get the native symbol renderer stored in the series.
  SymbolRenderer? get symbolRenderer =>
      series.getAttr(rendererKey)!.symbolRenderer;

  /// Gets the dash pattern for the symbol from the given datum and series.
  ///
  /// Use the dash pattern from the datum if available, otherwise fall back to
  /// generic series dash pattern.
  List<int>? get dashPattern => series.dashPatternFn?.call(datumIndex ?? 0);
}

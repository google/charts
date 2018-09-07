# Line Annotation Line Chart Example

![](line_annotation_full.png)

Example:

```
/// Line chart with line annotations example.
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class LineLineAnnotationChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  LineLineAnnotationChart(this.seriesList, {this.animate});

  /// Creates a [LineChart] with sample data and line annotations.
  ///
  /// The second annotation extends beyond the range of the series data,
  /// demonstrating the effect of the [Charts.RangeAnnotation.extendAxis] flag.
  /// This can be set to false to disable range extension.
  factory LineLineAnnotationChart.withSampleData() {
    return new LineLineAnnotationChart(
      _createSampleData(),
      // Disable animations for image tests.
      animate: false,
    );
  }


  @override
  Widget build(BuildContext context) {
    return new charts.LineChart(seriesList, animate: animate, behaviors: [
      new charts.RangeAnnotation([
        new charts.LineAnnotationSegment(
            1.0, charts.RangeAnnotationAxisType.domain,
            startLabel: 'Domain 1'),
        new charts.LineAnnotationSegment(
            4, charts.RangeAnnotationAxisType.domain,
            endLabel: 'Domain 2', color: charts.MaterialPalette.gray.shade200),
        new charts.LineAnnotationSegment(
            20, charts.RangeAnnotationAxisType.measure,
            startLabel: 'Measure 1 Start',
            endLabel: 'Measure 1 End',
            color: charts.MaterialPalette.gray.shade300),
        new charts.LineAnnotationSegment(
            65, charts.RangeAnnotationAxisType.measure,
            startLabel: 'Measure 2 Start',
            endLabel: 'Measure 2 End',
            color: charts.MaterialPalette.gray.shade400),
      ]),
    ]);
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> _createSampleData() {
    final data = [
      new LinearSales(0, 5),
      new LinearSales(1, 25),
      new LinearSales(2, 100),
      new LinearSales(3, 75),
    ];

    return [
      new charts.Series<LinearSales, int>(
        id: 'Sales',
        domainFn: (LinearSales sales, _) => sales.year,
        measureFn: (LinearSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }
}

/// Sample linear data type.
class LinearSales {
  final int year;
  final int sales;

  LinearSales(this.year, this.sales);
}
```

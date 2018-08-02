# Stacked Area Nulls Line Chart Example

![](stacked_area_nulls_full.png)

Example:

```
/// Example of a stacked area chart with null measure values.
///
/// Null values will be visible as gaps in lines and area skirts. Any data
/// points that exist between two nulls in a line will be rendered as an
/// isolated point, as seen in the green series.
///
/// In a stacked area chart, no data above a null value in the stack will be
/// rendered. In this example, the null measure value at domain 2 in the Desktop
/// series will prevent any data from being rendered at domain 2 for every
/// series because it is at the bottom of the stack.
///
/// This will also result in an isolated point being rendered for the domain
/// value 3 in the Mobile series, because that series also contains a null at
/// domain 4.
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class StackedAreaNullsLineChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  StackedAreaNullsLineChart(this.seriesList, {this.animate});

  /// Creates a [LineChart] with sample data and no transition.
  factory StackedAreaNullsLineChart.withSampleData() {
    return new StackedAreaNullsLineChart(
      _createSampleData(),
      // Disable animations for image tests.
      animate: false,
    );
  }


  @override
  Widget build(BuildContext context) {
    return new charts.LineChart(seriesList,
        defaultRenderer:
            new charts.LineRendererConfig(includeArea: true, stacked: true),
        animate: animate);
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<LinearSales, int>> _createSampleData() {
    final myFakeDesktopData = [
      new LinearSales(0, 5),
      new LinearSales(1, 15),
      new LinearSales(2, null),
      new LinearSales(3, 75),
      new LinearSales(4, 100),
      new LinearSales(5, 90),
      new LinearSales(6, 75),
    ];

    final myFakeTabletData = [
      new LinearSales(0, 5),
      new LinearSales(1, 15),
      new LinearSales(2, 25),
      new LinearSales(3, 75),
      new LinearSales(4, 100),
      new LinearSales(5, 90),
      new LinearSales(6, 75),
    ];

    final myFakeMobileData = [
      new LinearSales(0, 5),
      new LinearSales(1, 15),
      new LinearSales(2, 25),
      new LinearSales(3, 75),
      new LinearSales(4, null),
      new LinearSales(5, 90),
      new LinearSales(6, 75),
    ];

    return [
      new charts.Series<LinearSales, int>(
        id: 'Desktop',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (LinearSales sales, _) => sales.year,
        measureFn: (LinearSales sales, _) => sales.sales,
        data: myFakeDesktopData,
      ),
      new charts.Series<LinearSales, int>(
        id: 'Tablet',
        colorFn: (_, __) => charts.MaterialPalette.red.shadeDefault,
        domainFn: (LinearSales sales, _) => sales.year,
        measureFn: (LinearSales sales, _) => sales.sales,
        data: myFakeTabletData,
      ),
      new charts.Series<LinearSales, int>(
        id: 'Mobile',
        colorFn: (_, __) => charts.MaterialPalette.green.shadeDefault,
        domainFn: (LinearSales sales, _) => sales.year,
        measureFn: (LinearSales sales, _) => sales.sales,
        data: myFakeMobileData,
      ),
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

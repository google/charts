# Grouped Target Line Bar Chart Example

![](grouped_target_line_full.png)

Example:

```
/// Bar chart example
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

class GroupedBarTargetLineChart extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  GroupedBarTargetLineChart(this.seriesList, {this.animate});

  factory GroupedBarTargetLineChart.withSampleData() {
    return new GroupedBarTargetLineChart(
      _createSampleData(),
      // Disable animations for image tests.
      animate: false,
    );
  }


  @override
  Widget build(BuildContext context) {
    return new charts.BarChart(seriesList,
        animate: animate,
        barGroupingType: charts.BarGroupingType.grouped,
        customSeriesRenderers: [
          new charts.BarTargetLineRendererConfig(
              // ID used to link series to this renderer.
              customRendererId: 'customTargetLine',
              groupingType: charts.BarGroupingType.grouped)
        ]);
  }

  /// Create series list with multiple series
  static List<charts.Series<OrdinalSales, String>> _createSampleData() {
    final desktopSalesData = [
      new OrdinalSales('2014', 5),
      new OrdinalSales('2015', 25),
      new OrdinalSales('2016', 100),
      new OrdinalSales('2017', 75),
    ];

    final tableSalesData = [
      new OrdinalSales('2014', 25),
      new OrdinalSales('2015', 50),
      new OrdinalSales('2016', 10),
      new OrdinalSales('2017', 20),
    ];

    final mobileSalesData = [
      new OrdinalSales('2014', 10),
      new OrdinalSales('2015', 15),
      new OrdinalSales('2016', 50),
      new OrdinalSales('2017', 45),
    ];

    final desktopTargetLineData = [
      new OrdinalSales('2014', 4),
      new OrdinalSales('2015', 20),
      new OrdinalSales('2016', 80),
      new OrdinalSales('2017', 65),
    ];

    final tableTargetLineData = [
      new OrdinalSales('2014', 30),
      new OrdinalSales('2015', 55),
      new OrdinalSales('2016', 15),
      new OrdinalSales('2017', 25),
    ];

    final mobileTargetLineData = [
      new OrdinalSales('2014', 10),
      new OrdinalSales('2015', 5),
      new OrdinalSales('2016', 45),
      new OrdinalSales('2017', 35),
    ];

    return [
      new charts.Series<OrdinalSales, String>(
        id: 'Desktop',
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: desktopSalesData,
      ),
      new charts.Series<OrdinalSales, String>(
        id: 'Tablet',
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: tableSalesData,
      ),
      new charts.Series<OrdinalSales, String>(
        id: 'Mobile',
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: mobileSalesData,
      ),
      new charts.Series<OrdinalSales, String>(
        id: 'Desktop Target Line',
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: desktopTargetLineData,
      )
        // Configure our custom bar target renderer for this series.
        ..setAttribute(charts.rendererIdKey, 'customTargetLine'),
      new charts.Series<OrdinalSales, String>(
        id: 'Tablet Target Line',
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: tableTargetLineData,
      )
        // Configure our custom bar target renderer for this series.
        ..setAttribute(charts.rendererIdKey, 'customTargetLine'),
      new charts.Series<OrdinalSales, String>(
        id: 'Mobile Target Line',
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: mobileTargetLineData,
      )
        // Configure our custom bar target renderer for this series.
        ..setAttribute(charts.rendererIdKey, 'customTargetLine'),
    ];
  }
}

/// Sample ordinal data type.
class OrdinalSales {
  final String year;
  final int sales;

  OrdinalSales(this.year, this.sales);
}
```

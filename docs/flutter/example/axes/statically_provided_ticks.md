# Statically Provided Ticks Axes Example

![](statically_provided_ticks_full.png)

Example:

```
/// Example of axis using statically provided ticks.
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;

/// Example of specifying a custom set of ticks to be used on the domain axis.
///
/// Specifying custom set of ticks allows specifying exactly what ticks are
/// used in the axis. Each tick is also allowed to have a different style set.
///
/// For an ordinal axis, the [StaticOrdinalTickProviderSpec] is shown in this
/// example defining ticks to be used with [TickSpec] of String.
///
/// For numeric axis, the [StaticNumericTickProviderSpec] can be used by passing
/// in a list of ticks defined with [TickSpec] of num.
///
/// For datetime axis, the [StaticDateTimeTickProviderSpec] can be used by
/// passing in a list of ticks defined with [TickSpec] of datetime.
class StaticallyProvidedTicks extends StatelessWidget {
  final List<charts.Series> seriesList;
  final bool animate;

  StaticallyProvidedTicks(this.seriesList, {this.animate});

  factory StaticallyProvidedTicks.withSampleData() {
    return new StaticallyProvidedTicks(
      _createSampleData(),
      // Disable animations for image tests.
      animate: false,
    );
  }


  @override
  Widget build(BuildContext context) {
    // Create the ticks to be used the domain axis.
    final staticTicks = <charts.TickSpec<String>>[
      new charts.TickSpec(
          // Value must match the domain value.
          '2014',
          // Optional label for this tick, defaults to domain value if not set.
          label: 'Year 2014',
          // The styling for this tick.
          style: new charts.TextStyleSpec(
              color: new charts.Color(r: 0x4C, g: 0xAF, b: 0x50))),
      // If no text style is specified - the style from renderSpec will be used
      // if one is specified.
      new charts.TickSpec('2015'),
      new charts.TickSpec('2016'),
      new charts.TickSpec('2017'),
    ];

    return new charts.BarChart(
      seriesList,
      animate: animate,
      domainAxis: new charts.OrdinalAxisSpec(
          tickProviderSpec:
              new charts.StaticOrdinalTickProviderSpec(staticTicks)),
    );
  }

  /// Create series list with single series
  static List<charts.Series<OrdinalSales, String>> _createSampleData() {
    final globalSalesData = [
      new OrdinalSales('2014', 5000),
      new OrdinalSales('2015', 25000),
      new OrdinalSales('2016', 100000),
      new OrdinalSales('2017', 750000),
    ];

    return [
      new charts.Series<OrdinalSales, String>(
        id: 'Global Revenue',
        domainFn: (OrdinalSales sales, _) => sales.year,
        measureFn: (OrdinalSales sales, _) => sales.sales,
        data: globalSalesData,
      ),
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

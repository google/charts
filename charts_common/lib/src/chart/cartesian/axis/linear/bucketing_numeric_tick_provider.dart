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

import '../../../../common/graphics_factory.dart' show GraphicsFactory;
import '../../../common/chart_context.dart' show ChartContext;
import '../axis.dart' show AxisOrientation;
import '../draw_strategy/tick_draw_strategy.dart' show TickDrawStrategy;
import '../numeric_scale.dart' show NumericScale;
import '../numeric_tick_provider.dart' show NumericTickProvider;
import '../tick.dart' show Tick;
import '../tick_formatter.dart' show SimpleTickFormatterBase, TickFormatter;
import '../tick_provider.dart' show TickHint;

/// Tick provider that generates ticks for a [BucketingNumericAxis].
///
/// An example illustration of a bucketing measure axis on a point chart
/// follows. In this case, values such as "6%" and "3%" are drawn in the bucket
/// of the axis, since they are less than the [threshold] value of 10%.
///
///  100% ┠─────────────────────────
///       ┃                  *
///       ┃         *
///   50% ┠──────*──────────────────
///       ┃
///       ┠─────────────────────────
/// < 10% ┃   *          *
///       ┗┯━━━━━━━━━━┯━━━━━━━━━━━┯━
///       0         50          100
///
/// This tick provider will generate ticks using the same strategy as
/// [NumericTickProvider], except that any ticks that are smaller than
/// [threshold] will be hidden with an empty label. A special tick will be added
/// at the [threshold] position, with a label offset that moves its label down
/// to the middle of the bucket.
class BucketingNumericTickProvider extends NumericTickProvider {
  /// All values smaller than the threshold will be bucketed into the same
  /// position in the reserved space on the axis.
  num? _threshold;

  set threshold(num threshold) {
    _threshold = threshold;
  }

  /// Whether or not measure values bucketed below the [threshold] should be
  /// visible on the chart, or collapsed.
  bool? _showBucket;

  set showBucket(bool showBucket) {
    _showBucket = showBucket;
  }

  @override
  List<Tick<num>> getTicks({
    required ChartContext? context,
    required GraphicsFactory graphicsFactory,
    required NumericScale scale,
    required TickFormatter<num> formatter,
    required Map<num, String> formatterValueCache,
    required TickDrawStrategy<num> tickDrawStrategy,
    required AxisOrientation? orientation,
    bool viewportExtensionEnabled = false,
    TickHint<num>? tickHint,
  }) {
    final _threshold = this._threshold;
    final _showBucket = this._showBucket;

    if (_threshold == null) {
      throw ArgumentError(
          'Bucketing threshold must be set before getting ticks.');
    }

    if (_showBucket == null) {
      throw ArgumentError(
          'The showBucket flag must be set before getting ticks.');
    }

    final localFormatter = _BucketingFormatter(
        threshold: _threshold,
        originalFormatter: formatter as SimpleTickFormatterBase<num>);

    final ticks = super.getTicks(
        context: context,
        graphicsFactory: graphicsFactory,
        scale: scale,
        formatter: localFormatter,
        formatterValueCache: formatterValueCache,
        tickDrawStrategy: tickDrawStrategy,
        orientation: orientation,
        viewportExtensionEnabled: viewportExtensionEnabled);

    // Create a tick for the threshold.
    final thresholdTick = Tick<num>(
        value: _threshold,
        textElement: graphicsFactory
            .createTextElement(localFormatter.formatValue(_threshold)),
        locationPx: (_showBucket ? scale[_threshold] : scale[0])!.toDouble(),
        labelOffsetPx:
            _showBucket ? -0.5 * (scale[_threshold]! - scale[0]!) : 0.0);
    tickDrawStrategy.decorateTicks(<Tick<num>>[thresholdTick]);

    // Filter out ticks that sit below the threshold.
    ticks.removeWhere((Tick<num> tick) =>
        tick.value <= thresholdTick.value && tick.value != 0.0);

    // Finally, add our threshold tick to the list.
    ticks.add(thresholdTick);

    // Make sure they are sorted by increasing value.
    ticks.sort((a, b) => a.value.compareTo(b.value));
    return ticks;
  }
}

class _BucketingFormatter extends SimpleTickFormatterBase<num> {
  _BucketingFormatter(
      {required this.threshold, required this.originalFormatter});

  /// All values smaller than the threshold will be formatted into an empty
  /// string.
  final num threshold;

  final SimpleTickFormatterBase<num> originalFormatter;

  /// Formats a single tick value.
  @override
  String formatValue(num value) {
    if (value < threshold) {
      return '';
    } else if (value == threshold) {
      return '< ' + originalFormatter.formatValue(value);
    } else {
      return originalFormatter.formatValue(value);
    }
  }
}

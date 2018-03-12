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

import '../../chart/cartesian/axis/spec/axis_spec.dart' show LineStyleSpec;
import '../color.dart' show Color;
import '../graphics_factory.dart' show GraphicsFactory;
import '../line_style.dart' show LineStyle;
import '../quantum_palette.dart' show QuantumPalette;
import '../palette.dart' show Palette;
import 'style.dart' show Style;

class QuantumStyle implements Style {
  const QuantumStyle();

  @override
  Color get black => QuantumPalette.black;

  @override
  Color get gray => QuantumPalette.gray.shadeDefault;

  @override
  Color get white => QuantumPalette.white;

  @override
  List<Palette> getOrderedPalettes(int count) =>
      QuantumPalette.getOrderedPalettes(count);

  @override
  LineStyle createAxisLineStyle(
      GraphicsFactory graphicsFactory, LineStyleSpec spec) {
    return graphicsFactory.createLinePaint()
      ..color = spec?.color ?? QuantumPalette.gray.shadeDefault
      ..strokeWidth = spec?.thickness ?? 1;
  }

  @override
  LineStyle createTickLineStyle(
      GraphicsFactory graphicsFactory, LineStyleSpec spec) {
    return graphicsFactory.createLinePaint()
      ..color = spec?.color ?? QuantumPalette.gray.shadeDefault
      ..strokeWidth = spec?.thickness ?? 1;
  }

  @override
  int get tickLength => 3;

  @override
  LineStyle createGridlineStyle(
      GraphicsFactory graphicsFactory, LineStyleSpec spec) {
    return graphicsFactory.createLinePaint()
      ..color = spec?.color ?? QuantumPalette.gray.shade300
      ..strokeWidth = spec?.thickness ?? 1;
  }

  @override
  Color get rangeAnnotationColor => QuantumPalette.gray.shade100;

  @override
  Color get linePointHighlighterColor => QuantumPalette.gray.shade600;
}

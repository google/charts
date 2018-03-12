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

import 'color.dart' show Color;
import 'palette.dart' show Palette;

/// A canonical palette of charting colors from quantum specs.
///
/// @link go/charting
class QuantumPalette {
  static const black = const Color(r: 0, g: 0, b: 0);
  static const white = const Color(r: 255, g: 255, b: 255);

  static Palette get googleBlue => const GoogleBluePalette();
  static Palette get googleRed => const GoogleRedPalette();
  static Palette get googleYellow => const GoogleYellowPalette();
  static Palette get googleGreen => const GoogleGreenPalette();
  static Palette get purple => const PurplePalette();
  static Palette get cyan => const CyanPalette();
  static Palette get deepOrange => const DeepOrangePalette();
  static Palette get lime => const LimePalette();
  static Palette get indigo => const IndigoPalette();
  static Palette get pink => const PinkPalette();
  static Palette get teal => const TealPalette();
  static GrayPalette get gray => const GrayPalette();

  static List<Palette> getOrderedPalettes(int count) {
    final orderedPalettes = <Palette>[];
    if (orderedPalettes.length < count) {
      orderedPalettes.add(googleBlue);
    }
    if (orderedPalettes.length < count) {
      orderedPalettes.add(googleRed);
    }
    if (orderedPalettes.length < count) {
      orderedPalettes.add(googleYellow);
    }
    if (orderedPalettes.length < count) {
      orderedPalettes.add(googleGreen);
    }
    if (orderedPalettes.length < count) {
      orderedPalettes.add(purple);
    }
    if (orderedPalettes.length < count) {
      orderedPalettes.add(cyan);
    }
    if (orderedPalettes.length < count) {
      orderedPalettes.add(deepOrange);
    }
    if (orderedPalettes.length < count) {
      orderedPalettes.add(lime);
    }
    if (orderedPalettes.length < count) {
      orderedPalettes.add(indigo);
    }
    if (orderedPalettes.length < count) {
      orderedPalettes.add(pink);
    }
    if (orderedPalettes.length < count) {
      orderedPalettes.add(teal);
    }
    return orderedPalettes;
  }
}

class GoogleBluePalette extends Palette {
  static const _shade100 = const Color(r: 0xC6, g: 0xDA, b: 0xFC); // #C6DAFC
  static const _shade800 = const Color(r: 0x2A, g: 0x56, b: 0xC6); // #2A56C6
  static const _shade500 = const Color(
      r: 0x42, g: 0x85, b: 0xF4, darker: _shade800, lighter: _shade100);

  const GoogleBluePalette();

  @override
  Color get shadeDefault => _shade500;
}

class GoogleRedPalette extends Palette {
  static const _shade100 = const Color(r: 0xF4, g: 0xC7, b: 0xC3); // #F4C7C3
  static const _shade900 = const Color(r: 0xA5, g: 0x27, b: 0x14); // #A52714
  static const _shade500 = const Color(
      r: 0xDB, g: 0x44, b: 0x37, darker: _shade900, lighter: _shade100);

  const GoogleRedPalette();

  @override
  Color get shadeDefault => _shade500;
}

class GoogleYellowPalette extends Palette {
  static const _shade100 = const Color(r: 0xFC, g: 0xE8, b: 0xB2); // #FCE8B2
  static const _shade800 = const Color(r: 0xEE, g: 0x81, b: 0x00); // #EE8100
  static const _shade500 = const Color(
      r: 0xF4, g: 0xB4, b: 0x00, darker: _shade800, lighter: _shade100);

  const GoogleYellowPalette();

  @override
  Color get shadeDefault => _shade500;
}

class GoogleGreenPalette extends Palette {
  static const _shade100 = const Color(r: 0xB7, g: 0xE1, b: 0xCD); // #B7E1CD
  static const _shade700 = const Color(r: 0x0B, g: 0x80, b: 0x43); // #0B8043
  static const _shade500 = const Color(
      r: 0x0F, g: 0x9D, b: 0x58, darker: _shade700, lighter: _shade100);

  const GoogleGreenPalette();

  @override
  Color get shadeDefault => _shade500;
}

class PurplePalette extends Palette {
  static const _shade100 = const Color(r: 0xE1, g: 0xBE, b: 0xE7); // #E1BEE7
  static const _shade800 = const Color(r: 0x6A, g: 0x1B, b: 0x9A); // #6A1B9A
  static const _shade400 = const Color(
      r: 0xAB, g: 0xB4, b: 0xBC, darker: _shade800, lighter: _shade100);

  const PurplePalette();

  @override
  Color get shadeDefault => _shade400;
}

class CyanPalette extends Palette {
  static const _shade100 = const Color(r: 0xB2, g: 0xEB, b: 0xF2); // #B2EBF2
  static const _shade800 = const Color(r: 0x00, g: 0x83, b: 0x8F); // #00838F
  static const _shade600 = const Color(
      r: 0x00, g: 0xAC, b: 0xC1, darker: _shade800, lighter: _shade100);

  const CyanPalette();

  @override
  Color get shadeDefault => _shade600;
}

class DeepOrangePalette extends Palette {
  static const _shade100 = const Color(r: 0xFF, g: 0xCC, b: 0xBC); // #FFCCBC
  static const _shade700 = const Color(r: 0xE6, g: 0x4A, b: 0x19); // #E64A19
  static const _shade400 = const Color(
      r: 0xFF, g: 0x70, b: 0x43, darker: _shade700, lighter: _shade100);

  const DeepOrangePalette();

  @override
  Color get shadeDefault => _shade400;
}

class LimePalette extends Palette {
  static const _shade100 = const Color(r: 0xF0, g: 0xF4, b: 0xC3); // #F0F4C3
  static const _shade900 = const Color(r: 0x82, g: 0x77, b: 0x17); // #827717
  static const _shade800 = const Color(
      r: 0x9E, g: 0x9D, b: 0x24, darker: _shade900, lighter: _shade100);

  const LimePalette();

  @override
  Color get shadeDefault => _shade800;
}

class IndigoPalette extends Palette {
  static const _shade100 = const Color(r: 0xC5, g: 0xCA, b: 0xE9); // #C5CAE9
  static const _shade600 = const Color(r: 0x39, g: 0x49, b: 0xAB); // #3949AB
  static const _shade400 = const Color(
      r: 0x5C, g: 0x6B, b: 0xC0, darker: _shade600, lighter: _shade100);

  const IndigoPalette();

  @override
  Color get shadeDefault => _shade400;
}

class PinkPalette extends Palette {
  static const _shade100 = const Color(r: 0xF8, g: 0xBB, b: 0xD0); // #F8BBD0
  static const _shade500 = const Color(r: 0xE9, g: 0x1E, b: 0x63); // #E91E63
  static const _shade300 = const Color(
      r: 0xF0, g: 0x62, b: 0x92, darker: _shade500, lighter: _shade100);

  const PinkPalette();

  @override
  Color get shadeDefault => _shade300;
}

class TealPalette extends Palette {
  static const _shade100 = const Color(r: 0xB2, g: 0xDF, b: 0xDB); // #B2DFDB
  static const _shade900 = const Color(r: 0x00, g: 0x4B, b: 0x40); // #004D40
  static const _shade700 = const Color(
      r: 0x00, g: 0x79, b: 0x6B, darker: _shade100, lighter: _shade900);

  const TealPalette();

  @override
  Color get shadeDefault => _shade700;
}

class GrayPalette extends Palette {
  static const _shade100 = const Color(r: 0xF5, g: 0xF5, b: 0xF5);
  static const _shade800 = const Color(r: 0x42, g: 0x42, b: 0x42);
  static const _shade500 = const Color(
      r: 0x9E, g: 0x9E, b: 0x9E, darker: _shade800, lighter: _shade100);

  const GrayPalette();

  @override
  Color get shadeDefault => _shade500;

  Color get shade50 => const Color(r: 0xFA, g: 0xFA, b: 0xFA);
  Color get shade100 => _shade100;
  Color get shade200 => const Color(r: 0xEE, g: 0xEE, b: 0xEE);
  Color get shade300 => const Color(r: 0xE0, g: 0xE0, b: 0xE0);
  Color get shade400 => const Color(r: 0xBD, g: 0xBD, b: 0xBD);
  Color get shade500 => _shade500;
  Color get shade600 => const Color(r: 0x75, g: 0x75, b: 0x75);
  Color get shade700 => const Color(r: 0x61, g: 0x61, b: 0x61);
  Color get shade800 => _shade800;
  Color get shade900 => const Color(r: 0x21, g: 0x21, b: 0x21);
}

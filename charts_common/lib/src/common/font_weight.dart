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

import 'package:meta/meta.dart' show immutable;

@immutable
class FontWeight {
  const FontWeight._(this.index);

  /// The encoded integer value of this font weight.
  final int index;

  /// corresponds to position of `Text.FontWeight.normal` in flutter
  static const normal = FontWeight._(4);

  /// corresponds to position of `Text.FontWeight.bold` in flutter
  static const bold = FontWeight._(6);

  @override
  bool operator ==(Object other) => other is FontWeight && index == other.index;

  @override
  int get hashCode => index;

  int asFlutterFontWeightIndex() => this.index;
}

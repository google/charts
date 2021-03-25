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

import 'package:charts_common/common.dart' as common show FontWeight;
import 'package:flutter/material.dart' as flutter;
import 'package:meta/meta.dart' show immutable;

@immutable
class MaterialFontWeight implements common.FontWeight {
  final int _index;

  const MaterialFontWeight._(this._index);

  @override
  int get index => _index;

  // values below match material Flutter.Text.FontWeight
  // normal and bold are exposed using abstract class,
  // but more are available from material theme so they are exposed here

  /// Thin, the least thick
  static const MaterialFontWeight w100 = MaterialFontWeight._(0);

  /// Extra-light
  static const MaterialFontWeight w200 = MaterialFontWeight._(1);

  /// Light
  static const MaterialFontWeight w300 = MaterialFontWeight._(2);

  /// Normal / regular / plain
  static const MaterialFontWeight w400 = MaterialFontWeight._(3);

  /// Medium
  static const MaterialFontWeight w500 = MaterialFontWeight._(4);

  /// Semi-bold
  static const MaterialFontWeight w600 = MaterialFontWeight._(5);

  /// Bold
  static const MaterialFontWeight w700 = MaterialFontWeight._(6);

  /// Extra-bold
  static const MaterialFontWeight w800 = MaterialFontWeight._(7);

  /// Black, the most thick
  static const MaterialFontWeight w900 = MaterialFontWeight._(8);

  /// The default font weight.
  static const MaterialFontWeight normal = w400;

  /// A commonly used font weight that is heavier than normal.
  static const MaterialFontWeight bold = w700;

  @override
  int asFlutterFontWeightIndex() {
    return _index;
  }

  flutter.FontWeight asFlutterFontWeight() {
    return flutter.FontWeight.values[index];
  }

  @override
  bool operator ==(Object other) =>
      other is MaterialFontWeight && index == other.index;

  @override
  int get hashCode => index;
}

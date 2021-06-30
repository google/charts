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

import 'package:flutter/material.dart' show BuildContext;
import 'package:mockito/mockito.dart';
import 'package:flutter/widgets.dart' show InheritedWidget;
import 'package:test/test.dart';
import 'package:charts_flutter/src/graphics_factory.dart';
import 'package:charts_flutter/src/text_element.dart';

// Can't use Mockito annotations with BuildContext yet? Fake it.
class FakeBuildContext extends Fake implements BuildContext {
  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>(
      {Object? aspect}) {
    return null;
  }
}

// Gave up trying to figure out how to use mockito for now.
class FakeGraphicsFactoryHelper extends Fake implements GraphicsFactoryHelper {
  double textScaleFactor;

  FakeGraphicsFactoryHelper(this.textScaleFactor) {}

  @override
  double getTextScaleFactorOf(BuildContext context) => textScaleFactor;
}

void main() {
  test('Text element gets assigned scale factor', () {
    final context = FakeBuildContext();
    final helper = FakeGraphicsFactoryHelper(3.0);
    final graphicsFactory = new GraphicsFactory(context, helper: helper);

    final textElement =
        graphicsFactory.createTextElement('test') as TextElement;

    expect(textElement.text, equals('test'));
    expect(textElement.textScaleFactor, equals(3.0));
  });
}

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

import 'package:charts_common/src/chart/layout/layout_config.dart';
import 'package:charts_common/src/chart/layout/layout_manager_impl.dart';

import 'package:test/test.dart';

void main() {
  test('default layout', () {
    var layout = LayoutManagerImpl();
    layout.measure(400, 300);

    expect(layout.marginTop, equals(0));
    expect(layout.marginRight, equals(0));
    expect(layout.marginBottom, equals(0));
    expect(layout.marginLeft, equals(0));
  });

  test('all fixed margin', () {
    var layout = LayoutManagerImpl(
      config: LayoutConfig(
        topSpec: MarginSpec.fixedPixel(12),
        rightSpec: MarginSpec.fixedPixel(11),
        bottomSpec: MarginSpec.fixedPixel(10),
        leftSpec: MarginSpec.fixedPixel(9),
      ),
    );
    layout.measure(400, 300);

    expect(layout.marginTop, equals(12));
    expect(layout.marginRight, equals(11));
    expect(layout.marginBottom, equals(10));
    expect(layout.marginLeft, equals(9));
  });

  test('marginSpec.fromPixel default', () {
    var ms = MarginSpec.fromPixel();

    expect(ms.getMinPixels(null), equals(0));
    expect(ms.getMinPixels(-1), equals(0));
    expect(ms.getMinPixels(0), equals(0));
    expect(ms.getMinPixels(1), equals(0));
    expect(ms.getMinPixels(1000000), equals(0));

    expect(ms.getMaxPixels(null), equals(0));
    expect(ms.getMaxPixels(-1), equals(0));
    expect(ms.getMaxPixels(0), equals(0));
    expect(ms.getMaxPixels(1), equals(1));
    expect(ms.getMaxPixels(1000000), equals(1000000));
  });

  test('marginSpec.fromPixel(minPixel: -1)', () {
    // This didn't work :(
    //expect(MarginSpec.fromPixel(minPixel: -1), throwsA(isA<AssertionError>()));

    try {
        MarginSpec.fromPixel(minPixel: -1);
        expect(false, equals(true), reason: 'Expected assert error, run with: `pub run test xxx` or `dart --enable-asserts xxx`');
    } catch (e) {
      //print('minPixel: caught error');
      expect(e.runtimeType.toString(), equals('_AssertionError'));
    }
  });

  test('marginSpec.fromPixel(maxPixel: -1)', () {
    // This didn't work :(
    //expect(MarginSpec.fromPixel(maxPixel: -1), throwsA(isA<AssertionError>()));

    try {
        MarginSpec.fromPixel(maxPixel: -1);
        expect(false, equals(true), reason: 'Expected assert error, run with: `pub run test xxx` or `dart --enable-asserts xxx`');
    } catch (e) {
      //print('minPixel: caught error');
      expect(e.runtimeType.toString(), equals('_AssertionError'));
    }
  });

  test('marginSpec.fromPixel(minPixel: 0, maxPixel: -1)', () {
    // This didn't work :(
    //expect(MarginSpec.fromPixel(minPixel: 0, maxPixel: -1), throwsA(isA<AssertionError>()));

    try {
        MarginSpec.fromPixel(minPixel: 0, maxPixel: -1);
        expect(false, equals(true), reason: 'Expected assert error, run with: `pub run test xxx` or `dart --enable-asserts xxx`');
    } catch (e) {
      //print('minPixel: caught error');
      expect(e.runtimeType.toString(), equals('_AssertionError'));
    }
  });

  test('marginSpec.fromPixel(minPixel: -1, maxPixel: 0)', () {
    // This didn't work :(
    //expect(MarginSpec.fromPixel(minPixel: -1, maxPixel: 0), throwsA(isA<AssertionError>()));

    try {
        MarginSpec.fromPixel(minPixel: -1, maxPixel: 0);
        expect(false, equals(true), reason: 'Expected assert error, run with: `pub run test xxx` or `dart --enable-asserts xxx`');
    } catch (e) {
      //print('minPixel: caught error');
      expect(e.runtimeType.toString(), equals('_AssertionError'));
    }
  });

  test('marginSpec.fromPixel(minPixel: -1, maxPixel: -1)', () {
    // This didn't work :(
    //expect(MarginSpec.fromPixel(minPixel: -1, maxPixel: -1), throwsA(isA<AssertionError>()));

    try {
        MarginSpec.fromPixel(minPixel: -1, maxPixel: -1);
        expect(false, equals(true), reason: 'Expected assert error, run with: `pub run test xxx` or `dart --enable-asserts xxx`');
    } catch (e) {
      //print('minPixel: caught error');
      expect(e.runtimeType.toString(), equals('_AssertionError'));
    }
  });

  test('marginSpec.fromPixel(minPixel: 0)', () {
    var ms = MarginSpec.fromPixel(minPixel: 0);

    expect(ms.getMinPixels(null), equals(0));
    expect(ms.getMinPixels(-1), equals(0));
    expect(ms.getMinPixels(0), equals(0));
    expect(ms.getMinPixels(1), equals(0));
    expect(ms.getMinPixels(1000000), equals(0));

    expect(ms.getMaxPixels(null), equals(0));
    expect(ms.getMaxPixels(-1), equals(0));
    expect(ms.getMaxPixels(0), equals(0));
    expect(ms.getMaxPixels(1), equals(1));
    expect(ms.getMaxPixels(1000000), equals(1000000));
  });

  test('marginSpec.fromPixel(minPixel: 1)', () {
    var ms = MarginSpec.fromPixel(minPixel: 1);

    expect(ms.getMinPixels(null), equals(0));
    expect(ms.getMinPixels(-1), equals(0));
    expect(ms.getMinPixels(0), equals(0));
    expect(ms.getMinPixels(1), equals(1));
    expect(ms.getMinPixels(1000000), equals(1));

    expect(ms.getMaxPixels(null), equals(0));
    expect(ms.getMaxPixels(-1), equals(0));
    expect(ms.getMaxPixels(0), equals(0));
    expect(ms.getMaxPixels(1), equals(1));
    expect(ms.getMaxPixels(1000000), equals(1000000));
  });

  test('marginSpec.fromPixel(minPixel: 100)', () {
    var ms = MarginSpec.fromPixel(minPixel: 100);

    expect(ms.getMinPixels(null), equals(0));
    expect(ms.getMinPixels(-1), equals(0));
    expect(ms.getMinPixels(0), equals(0));
    expect(ms.getMinPixels(1), equals(1));
    expect(ms.getMinPixels(1000000), equals(100));

    expect(ms.getMaxPixels(null), equals(0));
    expect(ms.getMaxPixels(-1), equals(0));
    expect(ms.getMaxPixels(0), equals(0));
    expect(ms.getMaxPixels(1), equals(1));
    expect(ms.getMaxPixels(1000000), equals(1000000));
  });

  test('marginSpec.fromPixel(maxPixel: 100)', () {
    var ms = MarginSpec.fromPixel(maxPixel: 100);

    expect(ms.getMinPixels(null), equals(0));
    expect(ms.getMinPixels(-1), equals(0));
    expect(ms.getMinPixels(0), equals(0));
    expect(ms.getMinPixels(1), equals(0));
    expect(ms.getMinPixels(1000000), equals(0));

    expect(ms.getMaxPixels(null), equals(0));
    expect(ms.getMaxPixels(-1), equals(0));
    expect(ms.getMaxPixels(0), equals(0));
    expect(ms.getMaxPixels(1), equals(1));
    expect(ms.getMaxPixels(1000000), equals(100));
  });

  test('marginSpec.fromPixel(minPixel: 50, maxPixel: 100)', () {
    var ms = MarginSpec.fromPixel(minPixel: 50, maxPixel: 100);

    expect(ms.getMinPixels(null), equals(0));
    expect(ms.getMinPixels(-1), equals(0));
    expect(ms.getMinPixels(0), equals(0));
    expect(ms.getMinPixels(1), equals(1));
    expect(ms.getMinPixels(1000000), equals(50));

    expect(ms.getMaxPixels(null), equals(0));
    expect(ms.getMaxPixels(-1), equals(0));
    expect(ms.getMaxPixels(0), equals(0));
    expect(ms.getMaxPixels(1), equals(1));
    expect(ms.getMaxPixels(1000000), equals(100));
  });

  test('marginSpec.fromPercent default', () {
    var ms = MarginSpec.fromPercent();

    expect(ms.getMinPixels(null), equals(0));
    expect(ms.getMinPixels(-1), equals(0));
    expect(ms.getMinPixels(0), equals(0));
    expect(ms.getMinPixels(1), equals(0));
    expect(ms.getMinPixels(1000000), equals(0));

    expect(ms.getMaxPixels(null), equals(0));
    expect(ms.getMaxPixels(-1), equals(0));
    expect(ms.getMaxPixels(0), equals(0));
    expect(ms.getMaxPixels(1), equals(1));
    expect(ms.getMaxPixels(1000000), equals(1000000));
  });

  test('marginSpec.fromPercent(minPercent: -1)', () {
    // This didn't work :(
    //expect(MarginSpec.fromPercent(minPercent: -1), throwsA(isA<AssertionError>()));

    try {
        MarginSpec.fromPercent(minPercent: -1);
        expect(false, equals(true), reason: 'Expected assert error, run with: `pub run test xxx` or `dart --enable-asserts xxx`');
    } catch (e) {
      //print('minPercent: caught error');
      expect(e.runtimeType.toString(), equals('_AssertionError'));
    }
  });

  test('marginSpec.fromPercent(maxPercent: -1)', () {
    // This didn't work :(
    //expect(MarginSpec.fromPercent(maxPercent: -1), throwsA(isA<AssertionError>()));

    try {
        MarginSpec.fromPercent(maxPercent: -1);
        expect(false, equals(true), reason: 'Expected assert error, run with: `pub run test xxx` or `dart --enable-asserts xxx`');
    } catch (e) {
      //print('minPercent: caught error');
      expect(e.runtimeType.toString(), equals('_AssertionError'));
    }
  });

  test('marginSpec.fromPercent(minPercent: 0, maxPercent: -1)', () {
    // This didn't work :(
    //expect(MarginSpec.fromPercent(minPercent: 0, maxPercent: -1), throwsA(isA<AssertionError>()));

    try {
        MarginSpec.fromPercent(minPercent: 0, maxPercent: -1);
        expect(false, equals(true), reason: 'Expected assert error, run with: `pub run test xxx` or `dart --enable-asserts xxx`');
    } catch (e) {
      //print('minPercent: caught error');
      expect(e.runtimeType.toString(), equals('_AssertionError'));
    }
  });

  test('marginSpec.fromPercent(minPercent: -1, maxPercent: 0)', () {
    // This didn't work :(
    //expect(MarginSpec.fromPercent(minPercent: -1, maxPercent: 0), throwsA(isA<AssertionError>()));

    try {
        MarginSpec.fromPercent(minPercent: -1, maxPercent: 0);
        expect(false, equals(true), reason: 'Expected assert error, run with: `pub run test xxx` or `dart --enable-asserts xxx`');
    } catch (e) {
      //print('minPercent: caught error');
      expect(e.runtimeType.toString(), equals('_AssertionError'));
    }
  });

  test('marginSpec.fromPercent(minPercent: -1, maxPercent: -1)', () {
    // This didn't work :(
    //expect(MarginSpec.fromPercent(minPercent: -1, maxPercent: -1), throwsA(isA<AssertionError>()));

    try {
        MarginSpec.fromPercent(minPercent: -1, maxPercent: -1);
        expect(false, equals(true), reason: 'Expected assert error, run with: `pub run test xxx` or `dart --enable-asserts xxx`');
    } catch (e) {
      //print('minPercent: caught error');
      expect(e.runtimeType.toString(), equals('_AssertionError'));
    }
  });

  test('marginSpec.fromPercent(minPercent: 0)', () {
    var ms = MarginSpec.fromPercent(minPercent: 0);

    expect(ms.getMinPixels(null), equals(0));
    expect(ms.getMinPixels(-1), equals(0));
    expect(ms.getMinPixels(0), equals(0));
    expect(ms.getMinPixels(1), equals(0));
    expect(ms.getMinPixels(1000000), equals(0));

    expect(ms.getMaxPixels(null), equals(0));
    expect(ms.getMaxPixels(-1), equals(0));
    expect(ms.getMaxPixels(0), equals(0));
    expect(ms.getMaxPixels(1), equals(1));
    expect(ms.getMaxPixels(1000000), equals(1000000));
  });

  test('marginSpec.fromPercent(minPercent: 1)', () {
    var ms = MarginSpec.fromPercent(minPercent: 1);

    expect(ms.getMinPixels(null), equals(0));
    expect(ms.getMinPixels(-1), equals(0));
    expect(ms.getMinPixels(0), equals(0));
    expect(ms.getMinPixels(1), equals(0));
    expect(ms.getMinPixels(1000000), equals(10000));

    expect(ms.getMaxPixels(null), equals(0));
    expect(ms.getMaxPixels(-1), equals(0));
    expect(ms.getMaxPixels(0), equals(0));
    expect(ms.getMaxPixels(1), equals(1));
    expect(ms.getMaxPixels(1000000), equals(1000000));
  });

  test('marginSpec.fromPercent(minPercent: 100)', () {
    var ms = MarginSpec.fromPercent(minPercent: 100);

    expect(ms.getMinPixels(null), equals(0));
    expect(ms.getMinPixels(-1), equals(0));
    expect(ms.getMinPixels(0), equals(0));
    expect(ms.getMinPixels(1), equals(1));
    expect(ms.getMinPixels(1000000), equals(1000000));

    expect(ms.getMaxPixels(null), equals(0));
    expect(ms.getMaxPixels(-1), equals(0));
    expect(ms.getMaxPixels(0), equals(0));
    expect(ms.getMaxPixels(1), equals(1));
    expect(ms.getMaxPixels(1000000), equals(1000000));
  });

  test('marginSpec.fromPercent(minPercent: 50, maxPercent: 100)', () {
    var ms = MarginSpec.fromPercent(minPercent: 50, maxPercent: 100);

    expect(ms.getMinPixels(null), equals(0));
    expect(ms.getMinPixels(-1), equals(0));
    expect(ms.getMinPixels(0), equals(0));
    expect(ms.getMinPixels(1), equals(1));
    expect(ms.getMinPixels(1000000), equals(500000));

    expect(ms.getMaxPixels(null), equals(0));
    expect(ms.getMaxPixels(-1), equals(0));
    expect(ms.getMaxPixels(0), equals(0));
    expect(ms.getMaxPixels(1), equals(1));
    expect(ms.getMaxPixels(1000000), equals(1000000));
  });

  test('marginSpec.fixedPixel(null) ', () {
    var ms = MarginSpec.fixedPixel(null);

    expect(ms.getMinPixels(null), equals(0));
    expect(ms.getMinPixels(-1), equals(0));
    expect(ms.getMinPixels(0), equals(0));
    expect(ms.getMinPixels(1), equals(0));
    expect(ms.getMinPixels(1000000), equals(0));

    expect(ms.getMaxPixels(null), equals(0));
    expect(ms.getMaxPixels(-1), equals(0));
    expect(ms.getMaxPixels(0), equals(0));
    expect(ms.getMaxPixels(1), equals(1));
    expect(ms.getMaxPixels(1000000), equals(1000000));
  });

  test('marginSpec.fixedPixel(-1) ', () {
    // This didn't work :(
    //expect(MarginSpec.fixedPixel(-1), throwsA(isA<AssertionError>()));

    try {
        MarginSpec.fixedPixel(-1);
        expect(false, equals(true), reason: 'Expected assert error, run with: `pub run test xxx` or `dart --enable-asserts xxx`');
    } catch (e) {
      expect(e.runtimeType.toString(), equals('_AssertionError'));
    }
  });

  test('marginSpec.fixedPixel(0) ', () {
    var ms = MarginSpec.fixedPixel(0);

    expect(ms.getMinPixels(null), equals(0));
    expect(ms.getMinPixels(-1), equals(0));
    expect(ms.getMinPixels(0), equals(0));
    expect(ms.getMinPixels(1), equals(0));
    expect(ms.getMinPixels(1000000), equals(0));

    expect(ms.getMaxPixels(null), equals(0));
    expect(ms.getMaxPixels(-1), equals(0));
    expect(ms.getMaxPixels(0), equals(0));
    expect(ms.getMaxPixels(1), equals(0));
    expect(ms.getMaxPixels(1000000), equals(0));
  });

  test('marginSpec.fixedPixel(100) ', () {
    var ms = MarginSpec.fixedPixel(100);

    expect(ms.getMinPixels(null), equals(0));
    expect(ms.getMinPixels(-1), equals(0));
    expect(ms.getMinPixels(0), equals(0));
    expect(ms.getMinPixels(1), equals(1));
    expect(ms.getMinPixels(1000000), equals(100));

    expect(ms.getMaxPixels(null), equals(0));
    expect(ms.getMaxPixels(-1), equals(0));
    expect(ms.getMaxPixels(0), equals(0));
    expect(ms.getMaxPixels(1), equals(1));
    expect(ms.getMaxPixels(1000000), equals(100));
  });
}

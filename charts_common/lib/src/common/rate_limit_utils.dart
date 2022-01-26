// Copyright 2019 the Charts project authors. Please see the AUTHORS file
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

import 'dart:async';

/// Function that accepts only one argument of type [T] with return type [R].
typedef UnaryFunction<T, R> = R Function(T argument);

/// A wrapper function that enforces the maximum number of times [callback] can
/// be called over a period of time.
///
/// [delay] specifies the amount of time to wait until [callback] can be called
/// again.
/// [defaultReturn] is used as the return value when throttle event occurs.
UnaryFunction<T, R> throttle<T, R>(UnaryFunction<T, R> callback,
    {Duration delay = Duration.zero, required R defaultReturn}) {
  Timer? timer;
  Stopwatch? stopwatch;

  return (T argument) {
    stopwatch ??= Stopwatch()..start();

    // This event happened too soon. Do not call the [callback] function yet,
    // unless it turns out to be the very last event. [delay]s for a period of
    // time before calling the [callback] function again.
    if (stopwatch!.elapsedMilliseconds < delay.inMilliseconds) {
      timer?.cancel();
      timer = Timer(delay, () {
        callback(argument);
        timer = null;
        stopwatch = null;
      });
      return defaultReturn;
    }

    stopwatch = null;

    // This is a non-throttled event, go ahead and clear away the last throttled
    // event callback so that we do not move the hover point back in time.
    timer?.cancel();
    return callback(argument);
  };
}

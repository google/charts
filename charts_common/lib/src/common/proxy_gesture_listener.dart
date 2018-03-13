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

import 'dart:math' show Point;

import 'gesture_listener.dart' show GestureListener;

/// Listens to all gestures and proxies to child listeners.
class ProxyGestureListener {
  final listeners = <GestureListener>[];
  var activeListeners = <GestureListener>[];

  bool onTapTest(Point<double> localPosition) {
    var localListeners = new List<GestureListener>.from(listeners);

    activeListeners.clear();

    var previouslyClaimed = false;
    localListeners.forEach((GestureListener listener) {
      var claimed = listener.onTapTest(localPosition);
      if (claimed && !previouslyClaimed) {
        // Cancel any already added non-claiming listeners now that someone is
        // claiming it.
        activeListeners = _cancel(all: activeListeners, keep: [listener]);
        previouslyClaimed = true;
      } else if (claimed || !previouslyClaimed) {
        activeListeners.add(listener);
      }
    });

    return previouslyClaimed;
  }

  bool onLongPress(Point<double> localPosition) {
    // Walk through listeners stopping at the first handled listener.
    final claimingListener = activeListeners.firstWhere(
        (GestureListener listener) =>
            listener.onLongPress != null && listener.onLongPress(localPosition),
        orElse: () => null);

    // If someone claims the long press, then cancel everyone else.
    if (claimingListener != null) {
      activeListeners = _cancel(all: activeListeners, keep: [claimingListener]);
      return true;
    }
    return false;
  }

  bool onTap(Point<double> localPosition) {
    // Walk through listeners stopping at the first handled listener.
    final claimingListener = activeListeners.firstWhere(
        (GestureListener listener) =>
            listener.onTap != null && listener.onTap(localPosition),
        orElse: () => null);

    // If someone claims the tap, then cancel everyone else.
    // This should hopefully be rare, like for drilling.
    if (claimingListener != null) {
      activeListeners = _cancel(all: activeListeners, keep: [claimingListener]);
      return true;
    }
    return false;
  }

  bool onHover(Point<double> localPosition) {
    // Cancel any previously active long lived gestures.
    activeListeners = <GestureListener>[];

    // Walk through listeners stopping at the first handled listener.
    return listeners.any((GestureListener listener) =>
        listener.onHover != null && listener.onHover(localPosition));
  }

  bool onDragStart(Point<double> localPosition) {
    // Walk through listeners stopping at the first handled listener.
    final claimingListener = activeListeners.firstWhere(
        (GestureListener listener) =>
            listener.onDragStart != null && listener.onDragStart(localPosition),
        orElse: () => null);

    if (claimingListener != null) {
      activeListeners = _cancel(all: activeListeners, keep: [claimingListener]);
      return true;
    }
    return false;
  }

  bool onDragUpdate(Point<double> localPosition, double scale) {
    return activeListeners.any((GestureListener listener) =>
        listener.onDragUpdate(localPosition, scale));
  }

  bool onDragEnd(
      Point<double> localPosition, double scale, double pixelsPerSecond) {
    return activeListeners.any((GestureListener listener) =>
        listener.onDragEnd(localPosition, scale, pixelsPerSecond));
  }

  List<GestureListener> _cancel(
      {List<GestureListener> all, List<GestureListener> keep}) {
    all.forEach((GestureListener listener) {
      if (!keep.contains(listener)) {
        listener.onTapCancel();
      }
    });
    return keep;
  }
}

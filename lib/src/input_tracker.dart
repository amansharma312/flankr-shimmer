import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'constants.dart';

/// Notes when someone last scrolled, dragged or typed, so a reveal landing
/// mid-gesture can swap at once instead of animating under their finger.
class FlankrInputTracker {
  FlankrInputTracker._();

  static final FlankrInputTracker instance = FlankrInputTracker._();

  final Stopwatch _since = Stopwatch();
  bool _installed = false;

  void ensureInstalled() {
    if (_installed) return;
    _installed = true;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onPointer);
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  /// Someone scrolled, dragged or typed within [kInputWindow].
  bool get recent => _since.isRunning && _since.elapsed < kInputWindow;

  void _mark() => _since
    ..reset()
    ..start();

  void _onPointer(PointerEvent event) {
    if (event is PointerMoveEvent || event is PointerScrollEvent) _mark();
  }

  bool _onKey(KeyEvent event) {
    _mark();
    return false;
  }
}

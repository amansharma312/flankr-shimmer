import 'package:flutter/scheduler.dart';

/// One clock for every skeleton, so they all shimmer in a single stream —
/// however late each one mounts. Ticks only while something listens.
class FlankrClock {
  FlankrClock._();

  static final FlankrClock instance = FlankrClock._();

  final Set<VoidCallback> _listeners = {};
  Ticker? _ticker;
  Duration _before = Duration.zero;
  Duration _current = Duration.zero;

  /// Animation time the clock has run for; every skeleton's phase is read
  /// from this. Frame time, not wall time, so tests and goldens are exact.
  Duration get elapsed => _before + _current;

  bool get isTicking => _ticker?.isActive ?? false;

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
    final ticker = _ticker ??= Ticker(_tick, debugLabel: 'FlankrClock');
    if (!ticker.isActive) ticker.start();
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
    final ticker = _ticker;
    if (_listeners.isNotEmpty || ticker == null || !ticker.isActive) return;
    ticker.stop();
    _before += _current;
    _current = Duration.zero;
  }

  void _tick(Duration elapsed) {
    _current = elapsed;
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }
}

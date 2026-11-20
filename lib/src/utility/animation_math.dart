import 'dart:math' as math;

/// Cosine ease, 0 → 1.
double easeCosine(double t) => (1 - math.cos(math.pi * t)) / 2;

/// How far through its current loop an animation [loop] long is after
/// [elapsed], from 0 (start) up to 1 (end).
double loopPhase(Duration elapsed, Duration loop) {
  final length = loop.inMicroseconds;
  if (length <= 0) return 0;
  return (elapsed.inMicroseconds % length) / length;
}

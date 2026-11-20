import 'package:flankr_shimmer/src/utility/animation_math.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('easeCosine', () {
    test('runs from 0 to 1 through the middle', () {
      expect(easeCosine(0), 0);
      expect(easeCosine(0.5), closeTo(0.5, 1e-12));
      expect(easeCosine(1), 1);
    });
  });

  group('loopPhase', () {
    const loop = Duration(seconds: 2);

    test('is how far through the current loop', () {
      expect(loopPhase(Duration.zero, loop), 0);
      expect(loopPhase(const Duration(milliseconds: 500), loop), 0.25);
      expect(loopPhase(const Duration(milliseconds: 2500), loop), 0.25);
    });

    test('is 0 for a loop with no length', () {
      expect(loopPhase(const Duration(seconds: 1), Duration.zero), 0);
    });
  });
}

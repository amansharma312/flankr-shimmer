import 'package:flankr_shimmer/flankr_shimmer.dart';
import 'package:flankr_shimmer/src/resources/flankr_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlankrReveal.smart', () {
    FlankrReveal pick({
      Duration waited = const Duration(seconds: 1),
      bool input = false,
      bool refetch = false,
      double height = 450,
      int pieces = 20,
    }) =>
        FlankrReveal.smart.resolve(FlankrRevealContext(
          waited: waited,
          input: input,
          refetch: refetch,
          height: height,
          screenHeight: 800,
          pieces: pieces,
        ));

    test('is instant mid-gesture or for a fast load', () {
      expect(pick(input: true).duration, Duration.zero);
      expect(pick(waited: const Duration(milliseconds: 50)).duration,
          Duration.zero);
    });

    test('crossfades quickly on a refetch and whole when small', () {
      expect(pick(refetch: true).duration, kRefetchFade);
      expect(pick(height: 60).wipe, FlankrWipe.none);
      expect(pick(pieces: 3).wipe, FlankrWipe.none);
    });

    test('runs in sequence for something big, unhurried', () {
      final reveal = pick();
      expect(reveal.wipe, FlankrWipe.down);
      // A screen of cards (~450px drawn) takes about 1.1s.
      expect(reveal.duration.inMilliseconds, inInclusiveRange(1050, 1150));
      expect(pick(height: 10000).duration, kWipeMax);
      expect(pick(height: 80).duration, kWipeMin);
    });

    test('sweep falls back to a crossfade over 1.5 screens', () {
      const ctx = FlankrRevealContext(
        waited: Duration(seconds: 1),
        input: false,
        refetch: false,
        height: 2000,
        screenHeight: 800,
      );
      expect(FlankrReveal.sweep.resolve(ctx).wipe, FlankrWipe.none);
    });
  });
}

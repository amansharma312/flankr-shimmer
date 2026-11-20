import 'package:flankr_shimmer/flankr_shimmer.dart';
import 'package:flankr_shimmer/src/resources/flankr_constants.dart';
import 'package:flankr_shimmer/src/utility/shimmer_math.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shimmer', () {
    test('the band never shrinks below its minimum', () {
      expect(shimmerBand(200), kShimmerMinBand);
      expect(shimmerBand(5000), kShimmerReferenceWidth * kShimmerBandFraction);
    });

    test('keeps one pace on any width', () {
      final style = FlankrTheme.defaults.resolve(Brightness.light);
      final wide = shimmerBand(1280);
      final narrow = shimmerBand(500);
      final paceWide = wide * kShimmerPeriodFactor / shimmerLoopMs(style, wide);
      final paceNarrow =
          narrow * kShimmerPeriodFactor / shimmerLoopMs(style, narrow);
      expect(paceNarrow, closeTo(paceWide, 1e-9));
    });

    test('pulse goes 1 → 0.45 → 1', () {
      final style = const FlankrTheme(animation: FlankrAnimation.pulse)
          .resolve(Brightness.light);
      expect(pulseOpacity(style, Duration.zero), 1);
      expect(pulseOpacity(style, const Duration(milliseconds: 1200)),
          closeTo(kPulseMinOpacity, 1e-9));
    });
  });
}

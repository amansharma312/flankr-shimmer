import 'dart:convert';

import 'package:flankr_shimmer/flankr_shimmer.dart';
import 'package:flankr_shimmer/src/constants.dart';
import 'package:flankr_shimmer/src/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlankrTheme', () {
    test('defaults match Skullet colours and timings', () {
      final light = FlankrTheme.defaults.resolve(Brightness.light);
      expect(light.base, const Color(0x12000000));
      expect(light.highlight, const Color(0x99FFFFFF));
      expect(light.animation, FlankrAnimation.shimmer);
      expect(light.duration, const Duration(seconds: 4));
      final dark = FlankrTheme.defaults.resolve(Brightness.dark);
      expect(dark.base, const Color(0x14FFFFFF));
    });

    test('unset fields fall through to the fallback', () {
      const inner = FlankrTheme(animation: FlankrAnimation.pulse, speed: FlankrSpeed.fast);
      final style = inner.resolve(Brightness.light);
      expect(style.animation, FlankrAnimation.pulse);
      expect(style.duration, const Duration(milliseconds: 1200));
      expect(style.radius, kDefaultRadius);
    });

    test('disabled animations hold still', () {
      final style = FlankrTheme.defaults.resolve(Brightness.light, disableAnimations: true);
      expect(style.animation, FlankrAnimation.none);
      expect(style.isAnimated, isFalse);
    });
  });

  group('BoneShape', () {
    const shape = BoneShape(
      size: Size(200, 40),
      bones: [Bone(Rect.fromLTWH(10, 5, 100, 12), 4), Bone(Rect.fromLTWH(0, 20, 200, 20), 10)],
    );

    test('round-trips through JSON', () {
      final json = jsonDecode(jsonEncode(shape.toJson())) as Map<String, dynamic>;
      expect(BoneShape.fromJson(json), shape);
    });

    test('scales across a new width and keeps its height', () {
      final scaled = shape.scaledTo(400);
      expect(scaled.size, const Size(400, 40));
      expect(scaled.bones.first.rect, const Rect.fromLTWH(20, 5, 200, 12));
    });

    test('caps a radius at a pill', () {
      expect(const Bone(Rect.fromLTWH(0, 0, 100, 10), 99).clampedRadius, 5);
    });

    test('generic lines are sized from the font', () {
      final lines = BoneShape.lines(fontSize: 20);
      expect(lines.bones, hasLength(3));
      expect(lines.size.height, 90);
    });
  });

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
      final paceNarrow = narrow * kShimmerPeriodFactor / shimmerLoopMs(style, narrow);
      expect(paceNarrow, closeTo(paceWide, 1e-9));
    });

    test('pulse goes 1 → 0.45 → 1', () {
      final style = const FlankrTheme(animation: FlankrAnimation.pulse).resolve(Brightness.light);
      expect(pulseOpacity(style, Duration.zero), 1);
      expect(pulseOpacity(style, const Duration(milliseconds: 1200)), closeTo(kPulseMinOpacity, 1e-9));
    });
  });

  group('FlankrReveal.smart', () {
    FlankrReveal pick({Duration waited = const Duration(seconds: 1), bool input = false, bool refetch = false, double height = 500}) =>
        FlankrReveal.smart.resolve(FlankrRevealContext(
          waited: waited,
          input: input,
          refetch: refetch,
          height: height,
          screenHeight: 800,
        ));

    test('is instant mid-gesture or for a fast load', () {
      expect(pick(input: true).duration, Duration.zero);
      expect(pick(waited: const Duration(milliseconds: 50)).duration, Duration.zero);
    });

    test('crossfades quickly on a refetch and whole when small', () {
      expect(pick(refetch: true).duration, kRefetchFade);
      expect(pick(height: 100).wipe, FlankrWipe.none);
    });

    test('runs in sequence for something big', () {
      expect(pick().wipe, FlankrWipe.down);
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

  group('FlankrMemory', () {
    tearDown(() => forgetShapes());

    test('remembers shapes, persists them, and forgets on sign-out', () {
      Map<String, dynamic>? saved;
      FlankrMemory.instance.onShapesChanged = (json) => saved = json;
      const shape = BoneShape(size: Size(10, 10), bones: [Bone(Rect.fromLTWH(0, 0, 10, 10), 2)]);
      FlankrMemory.instance.rememberShape('card', shape);
      expect(saved!.keys, ['card']);

      forgetShapes();
      expect(FlankrMemory.instance.shapeFor('card'), isNull);

      FlankrMemory.instance.restoreShapes(jsonDecode(jsonEncode({'card': shape.toJson(), 'bad': 1})) as Map<String, dynamic>);
      expect(FlankrMemory.instance.shapeFor('card'), shape);
      expect(FlankrMemory.instance.shapeFor('bad'), isNull);
      FlankrMemory.instance.onShapesChanged = null;
    });

    test('keeps only the newest shapes', () {
      const shape = BoneShape(size: Size(10, 10), bones: [Bone(Rect.fromLTWH(0, 0, 10, 10), 2)]);
      for (var i = 0; i < kMaxRememberedShapes + 5; i++) {
        FlankrMemory.instance.rememberShape('s$i', shape);
      }
      expect(FlankrMemory.instance.shapeFor('s0'), isNull);
      expect(FlankrMemory.instance.shapeFor('s${kMaxRememberedShapes + 4}'), isNotNull);
    });
  });
}

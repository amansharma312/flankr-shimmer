import 'package:flankr_shimmer/flankr_shimmer.dart';
import 'package:flankr_shimmer/src/resources/flankr_constants.dart';
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
      const inner = FlankrTheme(
          animation: FlankrAnimation.pulse, speed: FlankrSpeed.fast);
      final style = inner.resolve(Brightness.light);
      expect(style.animation, FlankrAnimation.pulse);
      expect(style.duration, const Duration(milliseconds: 1200));
      expect(style.radius, kDefaultRadius);
    });

    test('disabled animations hold still', () {
      final style = FlankrTheme.defaults
          .resolve(Brightness.light, disableAnimations: true);
      expect(style.animation, FlankrAnimation.none);
      expect(style.isAnimated, isFalse);
    });
  });
}

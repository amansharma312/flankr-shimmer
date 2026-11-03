import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import 'constants.dart';
import 'theme.dart';

/// The width of the shimmer's band for a screen this wide.
double shimmerBand(double width) =>
    math.max(kShimmerMinBand, math.min(width, kShimmerReferenceWidth) * kShimmerBandFraction);

/// How long one loop takes, so the band keeps the pace it has on a
/// [kShimmerReferenceWidth] screen on any width.
double shimmerLoopMs(FlankrStyle style, double band) {
  final referencePeriod = shimmerBand(kShimmerReferenceWidth) * kShimmerPeriodFactor;
  return style.duration.inMilliseconds * (band * kShimmerPeriodFactor) / referencePeriod;
}

/// The highlight sweeping over a skeleton, as a shader in its own paint space.
///
/// [origin] is the skeleton's top-left in screen space; the band is laid out
/// in screen space (or, for [FlankrAnimation.groupShimmer], the skeleton's own
/// space), so every skeleton on screen shares one sweep.
ui.Shader shimmerShader({
  required FlankrStyle style,
  required Offset origin,
  required Size size,
  required double screenWidth,
  required Duration elapsed,
}) {
  final group = style.animation == FlankrAnimation.groupShimmer;
  final band = shimmerBand(group ? size.width : screenWidth);
  final period = band * kShimmerPeriodFactor;
  final loop = shimmerLoopMs(style, band);
  final phase = (elapsed.inMicroseconds / 1000 % loop) / loop;

  // Distance along the slant, in screen space, at which this loop's period starts.
  final start = phase * period - band;
  final direction = Offset(kSlantCos, kSlantSin);
  final shift = group ? Offset.zero : origin;
  final from = direction * start - shift;
  final to = direction * (start + period) - shift;

  final (colors, stops) = _bandStops(style.highlight, band / period);
  return ui.Gradient.linear(from, to, colors, stops, TileMode.repeated);
}

(List<Color>, List<double>)? _cachedBand;
Color? _cachedHighlight;
double? _cachedFraction;

/// The band's eased colour stops; the same for every skeleton of one theme,
/// so they are built once rather than per frame.
(List<Color>, List<double>) _bandStops(Color highlight, double fraction) {
  if (highlight == _cachedHighlight && fraction == _cachedFraction) return _cachedBand!;
  final colors = <Color>[];
  final stops = <double>[];
  void stop(double at, double strength) {
    stops.add(at * fraction);
    colors.add(highlight.withValues(alpha: highlight.a * strength));
  }

  for (var i = 0; i <= kShimmerSteps; i++) {
    stop(i / kShimmerSteps * kShimmerPeak, easeCosine(i / kShimmerSteps));
  }
  for (var i = 1; i <= kShimmerSteps; i++) {
    stop(kShimmerPeak + i / kShimmerSteps * (1 - kShimmerPeak), easeCosine(1 - i / kShimmerSteps));
  }
  stops.add(1);
  colors.add(highlight.withValues(alpha: 0));
  _cachedHighlight = highlight;
  _cachedFraction = fraction;
  return _cachedBand = (List.unmodifiable(colors), List.unmodifiable(stops));
}

/// The pulse's opacity at [elapsed]: 1 → 0.45 → 1, eased, in step everywhere.
double pulseOpacity(FlankrStyle style, Duration elapsed) {
  final loop = style.duration.inMicroseconds;
  final phase = (elapsed.inMicroseconds % loop) / loop;
  final half = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
  return 1 - (1 - kPulseMinOpacity) * Curves.easeInOut.transform(half);
}

/// Timings and shapes, mirroring the Skullet web library this package ports.
library;

import 'dart:math' as math;

/// How long a skeleton is held back, so data that beats it never flashes one.
const Duration kSkeletonDelay = Duration(milliseconds: 150);

/// A plain crossfade between skeleton and content.
const Duration kFadeDuration = Duration(milliseconds: 200);

/// The quick crossfade used when data is refetched over what is on screen.
const Duration kRefetchFade = Duration(milliseconds: 120);

/// Someone scrolled or typed within this window: reveal at once, don't animate.
const Duration kInputWindow = Duration(milliseconds: 400);

/// Content shorter than this (logical px) is revealed whole, not in sequence.
const double kSmallReveal = 72;

/// Content of this many pieces or fewer is revealed whole, not in sequence.
const int kSmallRevealPieces = 3;

/// A sweep taller than this many screens gives way to a crossfade.
const double kSweepMaxScreens = 1.5;

/// Shimmer loop lengths per speed, measured on a [kShimmerReferenceWidth] screen.
const Duration kShimmerSlow = Duration(milliseconds: 4000);
const Duration kShimmerFast = Duration(milliseconds: 2000);

/// Pulse loop lengths per speed.
const Duration kPulseSlow = Duration(milliseconds: 2400);
const Duration kPulseFast = Duration(milliseconds: 1200);

/// A shimmer keeps the pace it has across a screen this wide, on any width.
const double kShimmerReferenceWidth = 1280;

/// The band takes this fraction of the screen width…
const double kShimmerBandFraction = 0.7;

/// …but never less than this many logical px.
const double kShimmerMinBand = 320;

/// One loop of the shimmer travels this many band widths.
const double kShimmerPeriodFactor = 2.5;

/// Where in the band the highlight peaks, 0 to 1.
const double kShimmerPeak = 0.85;

/// Steps used to approximate the band's cosine ease.
const int kShimmerSteps = 12;

/// The slant of the shimmer (and of a sweep), in degrees past vertical.
const double kShimmerSlantDegrees = 20;

/// The lowest opacity a pulse fades to.
const double kPulseMinOpacity = 0.45;

/// The softest a reveal's wipe front gets, in logical px; it widens to
/// [kWipeSoftnessFraction] of the revealed height, so each row fades in
/// rather than snapping.
const double kWipeSoftness = 96;
const double kWipeSoftnessFraction = 0.4;

/// A sequence reveal: a base, plus time per logical px of revealed height.
const Duration kSequenceBase = Duration(milliseconds: 600);
const double kSequenceMsPerPx = 1.1;
const Duration kWipeMin = Duration(milliseconds: 700);
const Duration kWipeMax = Duration(milliseconds: 1500);

/// Default radius of a bar of text or a plain block.
const double kDefaultRadius = 4;

/// Shapes with more bones than this are not remembered.
const int kMaxRememberedBones = 400;

/// At most this many shapes are remembered; the oldest go first.
const int kMaxRememberedShapes = 64;

/// The shimmer's travel direction, a unit vector (y points down).
final double kSlantCos = math.cos(kShimmerSlantDegrees * math.pi / 180);
final double kSlantSin = math.sin(kShimmerSlantDegrees * math.pi / 180);

/// Cosine ease, 0 → 1.
double easeCosine(double t) => (1 - math.cos(math.pi * t)) / 2;

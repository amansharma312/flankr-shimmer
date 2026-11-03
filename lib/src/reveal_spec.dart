import 'package:flutter/foundation.dart';

import 'constants.dart';

/// How a reveal's content crosses in over its skeleton.
enum FlankrWipe {
  /// Skeleton and content crossfade whole.
  none,

  /// A soft front moves top to bottom, bringing content in where its skeleton was.
  down,

  /// A diagonal front at the shimmer's slant.
  diagonal,
}

/// What a reveal knows as its content lands, for [FlankrReveal.choose].
@immutable
class FlankrRevealContext {
  const FlankrRevealContext({
    required this.waited,
    required this.input,
    required this.refetch,
    required this.height,
    required this.screenHeight,
    this.pieces = 0,
  });

  /// How long the skeleton was up (including the hold).
  final Duration waited;

  /// Someone scrolled, dragged or typed in the last 400ms.
  final bool input;

  /// The skeleton was drawn from the data already on screen.
  final bool refetch;

  /// How tall the skeleton's drawn part is, in logical px (where its bones
  /// are, not empty space below them), capped at the screen's height.
  final double height;

  final double screenHeight;

  /// How many bones (bars and blocks) the skeleton has.
  final int pieces;
}

/// How content replaces its skeleton.
///
/// Use a built-in — [together], [sequence], [sweep], [smart], [instant] — or
/// build your own. When [choose] is set it decides per reveal and wins over
/// the other fields.
@immutable
class FlankrReveal {
  const FlankrReveal({
    this.duration = kFadeDuration,
    this.wipe = FlankrWipe.none,
    this.hold = kSkeletonDelay,
    this.choose,
  });

  /// 0 is instant. For wipes, the time the front takes to cross.
  final Duration duration;
  final FlankrWipe wipe;

  /// How long a skeleton waits before it shows, so a fast load never flashes one.
  final Duration hold;
  final FlankrReveal Function(FlankrRevealContext context)? choose;

  /// Swaps at once.
  static const FlankrReveal instant = FlankrReveal(duration: Duration.zero);

  /// Crossfades skeleton and content whole.
  static const FlankrReveal together = FlankrReveal();

  /// Brings content in top to bottom, where its skeleton was.
  static const FlankrReveal sequence = FlankrReveal(choose: _sequence);

  /// Carries content in behind one diagonal front at the shimmer's slant;
  /// a crossfade for anything over about a screen and a half.
  static const FlankrReveal sweep = FlankrReveal(choose: _sweep);

  /// Decides per reveal: at once mid-gesture or for a load under the hold; a
  /// quick crossfade for a refetch; whole for something small; otherwise in sequence.
  static const FlankrReveal smart = FlankrReveal(choose: _smart);

  /// Resolves [choose], if any, into a concrete reveal.
  FlankrReveal resolve(FlankrRevealContext context) {
    final picked = choose?.call(context);
    if (picked == null) return this;
    return picked.choose == null ? picked : picked.resolve(context);
  }

  static FlankrReveal _sequence(FlankrRevealContext c) => FlankrReveal(
        wipe: FlankrWipe.down,
        duration: _wipeDuration(c.height),
      );

  static FlankrReveal _sweep(FlankrRevealContext c) {
    if (c.height > c.screenHeight * kSweepMaxScreens) return together;
    return FlankrReveal(
      wipe: FlankrWipe.diagonal,
      duration: _wipeDuration(c.height),
    );
  }

  static FlankrReveal _smart(FlankrRevealContext c) {
    if (c.input || c.waited < kSkeletonDelay) return instant;
    if (c.refetch) return const FlankrReveal(duration: kRefetchFade);
    if (c.height < kSmallReveal || (c.pieces > 0 && c.pieces <= kSmallRevealPieces)) return together;
    return _sequence(c);
  }

  /// About 1.1s for a screen of cards; longer for more, never rushed.
  static Duration _wipeDuration(double height) {
    final ms = kSequenceBase.inMilliseconds + height * kSequenceMsPerPx;
    final clamped = ms.clamp(kWipeMin.inMilliseconds.toDouble(), kWipeMax.inMilliseconds.toDouble());
    return Duration(milliseconds: clamped.round());
  }
}

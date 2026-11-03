import 'package:flutter/widgets.dart';

import 'constants.dart';

/// How skeletons move. All of them hold still when animations are disabled.
enum FlankrAnimation {
  /// One highlight sweeps across the whole screen, in step for every skeleton.
  shimmer,

  /// Each skeleton gets a sweep of its own.
  groupShimmer,

  /// Every skeleton fades softly in and out, in step.
  pulse,

  /// No motion.
  none,
}

/// How quickly the animation loops: a shimmer in 4s or 2s, a pulse in 2.4s or 1.2s.
enum FlankrSpeed { slow, fast }

/// The font line each bar of text is drawn from.
enum TextTop { ascender, capHeight, xHeight }

/// The font line each bar of text is drawn down to.
enum TextBottom { baseline, descender }

/// `system` follows the ambient [Theme]'s brightness; the others pin one set of colours.
enum FlankrMode { light, dark, system }

/// The fill of a skeleton and the highlight that sweeps across it.
@immutable
class FlankrColors {
  const FlankrColors({required this.base, required this.highlight});

  final Color base;
  final Color highlight;

  @override
  bool operator ==(Object other) =>
      other is FlankrColors && other.base == base && other.highlight == highlight;

  @override
  int get hashCode => Object.hash(base, highlight);
}

/// Where each line of text's bar sits, between two of the font's own lines.
@immutable
class FlankrText {
  const FlankrText({this.top = TextTop.ascender, this.bottom = TextBottom.descender});

  final TextTop top;
  final TextBottom bottom;

  @override
  bool operator ==(Object other) => other is FlankrText && other.top == top && other.bottom == bottom;

  @override
  int get hashCode => Object.hash(top, bottom);
}

/// Colours for light and dark, plus how skeletons look and move.
///
/// Every field is optional; unset fields fall through to an outer
/// [FlankrProvider], then to [FlankrTheme.defaults].
@immutable
class FlankrTheme {
  const FlankrTheme({
    this.light,
    this.dark,
    this.radius,
    this.animation,
    this.speed,
    this.text,
  });

  /// `rgb(0 0 0 / 0.07)` with a `rgb(255 255 255 / 0.6)` highlight.
  static const FlankrColors defaultLight = FlankrColors(
    base: Color(0x12000000),
    highlight: Color(0x99FFFFFF),
  );

  /// `rgb(255 255 255 / 0.08)` with a `rgb(255 255 255 / 0.1)` highlight.
  static const FlankrColors defaultDark = FlankrColors(
    base: Color(0x14FFFFFF),
    highlight: Color(0x1AFFFFFF),
  );

  static const FlankrTheme defaults = FlankrTheme(
    light: defaultLight,
    dark: defaultDark,
    radius: kDefaultRadius,
    animation: FlankrAnimation.shimmer,
    speed: FlankrSpeed.slow,
    text: FlankrText(),
  );

  final FlankrColors? light;
  final FlankrColors? dark;

  /// How round each bar of text and plain block is drawn. Images, avatars and
  /// chips keep their own shape.
  final double? radius;
  final FlankrAnimation? animation;
  final FlankrSpeed? speed;
  final FlankrText? text;

  /// This theme, with anything it leaves unset taken from [fallback].
  FlankrTheme over(FlankrTheme fallback) => FlankrTheme(
        light: light ?? fallback.light,
        dark: dark ?? fallback.dark,
        radius: radius ?? fallback.radius,
        animation: animation ?? fallback.animation,
        speed: speed ?? fallback.speed,
        text: text ?? fallback.text,
      );

  /// Everything a skeleton needs to paint, for one brightness.
  FlankrStyle resolve(Brightness brightness, {bool disableAnimations = false}) {
    final full = over(defaults);
    final colors = brightness == Brightness.dark ? full.dark! : full.light!;
    final animation = disableAnimations ? FlankrAnimation.none : full.animation!;
    return FlankrStyle(
      base: colors.base,
      highlight: colors.highlight,
      radius: full.radius!,
      animation: animation,
      duration: _durationOf(animation, full.speed!),
      text: full.text!,
    );
  }

  static Duration _durationOf(FlankrAnimation animation, FlankrSpeed speed) {
    final fast = speed == FlankrSpeed.fast;
    if (animation == FlankrAnimation.pulse) return fast ? kPulseFast : kPulseSlow;
    return fast ? kShimmerFast : kShimmerSlow;
  }

  @override
  bool operator ==(Object other) =>
      other is FlankrTheme &&
      other.light == light &&
      other.dark == dark &&
      other.radius == radius &&
      other.animation == animation &&
      other.speed == speed &&
      other.text == text;

  @override
  int get hashCode => Object.hash(light, dark, radius, animation, speed, text);
}

/// A fully resolved theme: what the painter reads.
@immutable
class FlankrStyle {
  const FlankrStyle({
    required this.base,
    required this.highlight,
    required this.radius,
    required this.animation,
    required this.duration,
    required this.text,
  });

  final Color base;
  final Color highlight;
  final double radius;
  final FlankrAnimation animation;
  final Duration duration;
  final FlankrText text;

  bool get isAnimated => animation != FlankrAnimation.none;

  @override
  bool operator ==(Object other) =>
      other is FlankrStyle &&
      other.base == base &&
      other.highlight == highlight &&
      other.radius == radius &&
      other.animation == animation &&
      other.duration == duration &&
      other.text == text;

  @override
  int get hashCode => Object.hash(base, highlight, radius, animation, duration, text);
}

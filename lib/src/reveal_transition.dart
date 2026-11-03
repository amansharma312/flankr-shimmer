import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'constants.dart';
import 'reveal_spec.dart';

/// Brings [content] in over [bones] as [animation] runs 0 → 1.
///
/// The content sizes the reveal; the skeleton sits over its top, so a
/// skeleton that measured differently from its content never stretches.
class FlankrRevealTransition extends StatefulWidget {
  const FlankrRevealTransition({
    super.key,
    required this.animation,
    required this.wipe,
    required this.content,
    required this.bones,
    this.extent,
  });

  final Animation<double> animation;
  final FlankrWipe wipe;
  final Widget content;
  final Widget bones;

  /// How far down the skeleton actually has bones, in logical px. The front
  /// crosses this, not empty space below it, so the visible part of the
  /// reveal takes its whole duration. The full height when null.
  final double? extent;

  @override
  State<FlankrRevealTransition> createState() => _FlankrRevealTransitionState();
}

class _FlankrRevealTransitionState extends State<FlankrRevealTransition> {
  /// The taller of content and skeleton, so both fronts cross the same distance.
  Size _extent = Size.zero;

  /// Wipes ease gently in and out (sine, not cubic, so the front never
  /// rushes through the middle); a crossfade keeps the linear fade.
  late CurvedAnimation _eased = _curve();

  CurvedAnimation _curve() => CurvedAnimation(parent: widget.animation, curve: Curves.easeInOutSine);

  @override
  void didUpdateWidget(FlankrRevealTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      _eased.dispose();
      _eased = _curve();
    }
  }

  @override
  void dispose() {
    _eased.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = widget.animation;
    // Passthrough: the content gets exactly the constraints it gets when shown.
    Widget stack(Widget content, Widget bones) => Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.none,
          children: [content, Positioned(top: 0, left: 0, right: 0, child: bones)],
        );
    final content = RepaintBoundary(child: widget.content);
    final bones = RepaintBoundary(child: widget.bones);
    if (widget.wipe == FlankrWipe.none) {
      return stack(
        FadeTransition(opacity: animation, child: content),
        FadeTransition(opacity: ReverseAnimation(animation), child: bones),
      );
    }
    // Only the masks change per frame; both children keep their own layers.
    return AnimatedBuilder(
      animation: _eased,
      builder: (context, _) => stack(
        ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => _front(bounds, grow: true),
          child: content,
        ),
        ShaderMask(
          blendMode: BlendMode.dstOut,
          shaderCallback: (bounds) => _front(bounds, grow: false),
          child: bones,
        ),
      ),
    );
  }

  /// Opaque behind the front, clear ahead of it.
  ui.Shader _front(Rect bounds, {required bool grow}) {
    if (grow) _extent = bounds.size;
    final width = math.max(_extent.width, bounds.width);
    final full = math.max(_extent.height, bounds.height);
    final height = math.min(widget.extent ?? full, full);
    final soft = math.max(kWipeSoftness, height * kWipeSoftnessFraction);
    final direction = widget.wipe == FlankrWipe.down ? const Offset(0, 1) : Offset(kSlantCos, kSlantSin);
    final distance = width * direction.dx + height * direction.dy + soft;
    // At 1 everything is shown, including anything below the drawn extent.
    final at = _eased.value >= 1 ? double.infinity : _eased.value * distance;
    if (at.isInfinite) {
      return ui.Gradient.linear(Offset.zero, const Offset(0, 1), const [Color(0xFFFFFFFF), Color(0xFFFFFFFF)]);
    }
    return ui.Gradient.linear(
      direction * (at - soft),
      direction * at,
      const [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
    );
  }
}

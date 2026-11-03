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
  });

  final Animation<double> animation;
  final FlankrWipe wipe;
  final Widget content;
  final Widget bones;

  @override
  State<FlankrRevealTransition> createState() => _FlankrRevealTransitionState();
}

class _FlankrRevealTransitionState extends State<FlankrRevealTransition> {
  /// The taller of content and skeleton, so both fronts cross the same distance.
  Size _extent = Size.zero;

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
      animation: animation,
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
    final height = math.max(_extent.height, bounds.height);
    final direction = widget.wipe == FlankrWipe.down ? const Offset(0, 1) : Offset(kSlantCos, kSlantSin);
    final distance = width * direction.dx + height * direction.dy + kWipeSoftness;
    final at = widget.animation.value * distance;
    return ui.Gradient.linear(
      direction * (at - kWipeSoftness),
      direction * at,
      const [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
    );
  }
}

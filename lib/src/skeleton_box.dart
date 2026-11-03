import 'package:flutter/widgets.dart';

import 'hints.dart';
import 'render_bones.dart';

/// A single placeholder bar, shimmering in step with every skeleton on screen.
///
/// Inside a loading [Skeleton] it becomes part of that skeleton; on its own
/// it draws itself.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height, this.radius})
      : widthFactor = null;

  /// A bar spanning [widthFactor] of the available width — `0.6` for 60%.
  const SkeletonBox.fraction({super.key, required double this.widthFactor, this.height, this.radius})
      : width = null;

  /// Fills the available width when null.
  final double? width;
  final double? widthFactor;

  /// One line of the ambient text size when null.
  final double? height;

  /// The theme's radius when null; `height / 2` for a pill or circle.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final h = height ?? DefaultTextStyle.of(context).style.fontSize ?? 14;
    final factor = widthFactor;
    // The block wraps only the bar itself, so a fraction stays a fraction.
    final bar = FlankrBlock(
      radius: radius,
      child: SizedBox(width: factor == null ? (width ?? double.infinity) : null, height: h),
    );
    final block = factor == null
        ? bar
        : FractionallySizedBox(widthFactor: factor, alignment: AlignmentDirectional.centerStart, child: bar);
    return FlankrLoading.of(context) ? block : FlankrBones(child: block);
  }
}

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
    final Widget box = factor == null
        ? SizedBox(width: width ?? double.infinity, height: h)
        : FractionallySizedBox(
            widthFactor: factor,
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(height: h),
          );
    final block = FlankrBlock(radius: radius, child: box);
    return FlankrLoading.of(context) ? block : FlankrBones(child: block);
  }
}

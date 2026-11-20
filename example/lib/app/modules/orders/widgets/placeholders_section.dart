import 'package:flankr_shimmer/flankr_shimmer.dart';
import 'package:flutter/material.dart';

/// SkeletonBox on its own, outside any Skeleton.
class PlaceholdersSection extends StatelessWidget {
  const PlaceholdersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 24),
        Text('Standalone placeholders'),
        SizedBox(height: 8),
        SkeletonBox.fraction(widthFactor: 0.6),
        SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: SkeletonBox(width: 48, height: 48, radius: 24),
        ),
      ],
    );
  }
}

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

/// One bar or block of a skeleton, relative to the skeleton's top-left.
@immutable
class Bone {
  const Bone(this.rect, this.radius);

  factory Bone.fromJson(List<dynamic> json) => Bone(
        Rect.fromLTWH(
          (json[0] as num).toDouble(),
          (json[1] as num).toDouble(),
          (json[2] as num).toDouble(),
          (json[3] as num).toDouble(),
        ),
        (json[4] as num).toDouble(),
      );

  final Rect rect;
  final double radius;

  /// [radius], capped so a bar is never rounder than a pill.
  double get clampedRadius => math.min(radius, rect.shortestSide / 2);

  RRect get rrect => RRect.fromRectAndRadius(rect, Radius.circular(clampedRadius));

  List<double> toJson() => [
        _round(rect.left),
        _round(rect.top),
        _round(rect.width),
        _round(rect.height),
        _round(radius),
      ];

  static double _round(double v) => (v * 10).roundToDouble() / 10;

  @override
  bool operator ==(Object other) => other is Bone && other.rect == rect && other.radius == radius;

  @override
  int get hashCode => Object.hash(rect, radius);

  @override
  String toString() => 'Bone($rect, r=$radius)';
}

/// A whole skeleton's layout: never its content, only where things sit.
@immutable
class BoneShape {
  const BoneShape({required this.size, required this.bones});

  factory BoneShape.fromJson(Map<String, dynamic> json) {
    final size = json['size'] as List<dynamic>;
    return BoneShape(
      size: Size((size[0] as num).toDouble(), (size[1] as num).toDouble()),
      bones: [
        for (final bone in json['bones'] as List<dynamic>) Bone.fromJson(bone as List<dynamic>),
      ],
    );
  }

  /// A few generic lines, for when there is nothing better to draw from.
  factory BoneShape.lines({double fontSize = 14, int count = 3}) {
    const widths = [1.0, 0.92, 0.6, 0.84, 0.72];
    final lineHeight = fontSize * 1.5;
    final barHeight = fontSize * 0.95;
    final top = (lineHeight - barHeight) / 2;
    return BoneShape(
      size: Size(100, lineHeight * count),
      bones: [
        for (var i = 0; i < count; i++)
          Bone(
            Rect.fromLTWH(0, i * lineHeight + top, 100 * widths[i % widths.length], barHeight),
            barHeight / 4,
          ),
      ],
    );
  }

  final Size size;
  final List<Bone> bones;

  bool get isEmpty => bones.isEmpty;

  /// This shape stretched across [width], keeping its height.
  BoneShape scaledTo(double width) {
    if (size.width <= 0 || width == size.width || !width.isFinite) return this;
    final k = width / size.width;
    return BoneShape(
      size: Size(width, size.height),
      bones: [
        for (final b in bones)
          Bone(Rect.fromLTWH(b.rect.left * k, b.rect.top, b.rect.width * k, b.rect.height), b.radius),
      ],
    );
  }

  /// Every bone as one path, so overlapping bones never double their fill.
  Path toPath([Offset offset = Offset.zero]) {
    final path = Path();
    for (final bone in bones) {
      path.addRRect(bone.rrect.shift(offset));
    }
    return path;
  }

  Map<String, dynamic> toJson() => {
        'size': [size.width, size.height],
        'bones': [for (final b in bones) b.toJson()],
      };

  @override
  bool operator ==(Object other) =>
      other is BoneShape && other.size == size && listEquals(other.bones, bones);

  @override
  int get hashCode => Object.hash(size, Object.hashAll(bones));
}

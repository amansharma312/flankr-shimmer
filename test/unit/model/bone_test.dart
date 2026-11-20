import 'dart:convert';

import 'package:flankr_shimmer/flankr_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoneShape', () {
    const shape = BoneShape(
      size: Size(200, 40),
      bones: [
        Bone(Rect.fromLTWH(10, 5, 100, 12), 4),
        Bone(Rect.fromLTWH(0, 20, 200, 20), 10)
      ],
    );

    test('round-trips through JSON', () {
      final json =
          jsonDecode(jsonEncode(shape.toJson())) as Map<String, dynamic>;
      expect(BoneShape.fromJson(json), shape);
    });

    test('scales across a new width and keeps its height', () {
      final scaled = shape.scaledTo(400);
      expect(scaled.size, const Size(400, 40));
      expect(scaled.bones.first.rect, const Rect.fromLTWH(20, 5, 200, 12));
    });

    test('caps a radius at a pill', () {
      expect(const Bone(Rect.fromLTWH(0, 0, 100, 10), 99).clampedRadius, 5);
    });

    test('generic lines are sized from the font', () {
      final lines = BoneShape.lines(fontSize: 20);
      expect(lines.bones, hasLength(3));
      expect(lines.size.height, 90);
    });
  });
}

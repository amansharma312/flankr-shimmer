import 'dart:convert';

import 'package:flankr_shimmer/flankr_shimmer.dart';
import 'package:flankr_shimmer/src/resources/flankr_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlankrMemory', () {
    tearDown(() => forgetShapes());

    test('remembers shapes, persists them, and forgets on sign-out', () {
      Map<String, dynamic>? saved;
      FlankrMemory.instance.onShapesChanged = (json) => saved = json;
      const shape = BoneShape(
          size: Size(10, 10), bones: [Bone(Rect.fromLTWH(0, 0, 10, 10), 2)]);
      FlankrMemory.instance.rememberShape('card', shape);
      expect(saved!.keys, ['card']);

      forgetShapes();
      expect(FlankrMemory.instance.shapeFor('card'), isNull);

      FlankrMemory.instance.restoreShapes(
          jsonDecode(jsonEncode({'card': shape.toJson(), 'bad': 1}))
              as Map<String, dynamic>);
      expect(FlankrMemory.instance.shapeFor('card'), shape);
      expect(FlankrMemory.instance.shapeFor('bad'), isNull);
      FlankrMemory.instance.onShapesChanged = null;
    });

    test('keeps only the newest shapes', () {
      const shape = BoneShape(
          size: Size(10, 10), bones: [Bone(Rect.fromLTWH(0, 0, 10, 10), 2)]);
      for (var i = 0; i < kMaxRememberedShapes + 5; i++) {
        FlankrMemory.instance.rememberShape('s$i', shape);
      }
      expect(FlankrMemory.instance.shapeFor('s0'), isNull);
      expect(FlankrMemory.instance.shapeFor('s${kMaxRememberedShapes + 4}'),
          isNotNull);
    });
  });
}

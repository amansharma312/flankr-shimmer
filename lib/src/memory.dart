import 'dart:collection';

import 'bone.dart';
import 'constants.dart';

/// Remembers, under each skeleton's `id`, the data it last showed and the
/// shape it last had — so a reload is drawn exactly.
///
/// Shapes keep layout, never content. Data stays in memory only; shapes can
/// be persisted across launches with [onShapesChanged] and [restoreShapes].
class FlankrMemory {
  FlankrMemory._();

  static final FlankrMemory instance = FlankrMemory._();

  final LinkedHashMap<String, Object> _data = LinkedHashMap();
  final LinkedHashMap<String, BoneShape> _shapes = LinkedHashMap();

  /// Called with every remembered shape whenever one is added or forgotten —
  /// write it to `shared_preferences` or similar to keep shapes across launches.
  void Function(Map<String, dynamic> json)? onShapesChanged;

  Object? dataFor(String id) => _data[id];

  BoneShape? shapeFor(String id) => _shapes[id];

  /// Keeps at most [kMaxRememberedShapes] entries; the oldest go first.
  void rememberData(String id, Object data) {
    _data
      ..remove(id)
      ..[id] = data;
    while (_data.length > kMaxRememberedShapes) {
      _data.remove(_data.keys.first);
    }
  }

  void rememberShape(String id, BoneShape shape) {
    if (shape.isEmpty || shape.bones.length > kMaxRememberedBones) return;
    if (_shapes[id] == shape) return;
    _shapes
      ..remove(id)
      ..[id] = shape;
    while (_shapes.length > kMaxRememberedShapes) {
      _shapes.remove(_shapes.keys.first);
    }
    _notify();
  }

  /// Loads shapes saved from [onShapesChanged]. Malformed entries are skipped.
  void restoreShapes(Map<String, dynamic> json) {
    for (final entry in json.entries) {
      try {
        _shapes[entry.key] = BoneShape.fromJson(entry.value as Map<String, dynamic>);
      } on Object {
        continue;
      }
    }
  }

  Map<String, dynamic> shapesToJson() => {
        for (final entry in _shapes.entries) entry.key: entry.value.toJson(),
      };

  /// Forgets remembered data and shapes — call it on sign-out.
  void forget({bool shapes = true}) {
    _data.clear();
    if (!shapes) return;
    _shapes.clear();
    _notify();
  }

  void _notify() => onShapesChanged?.call(shapesToJson());
}

/// Forgets remembered data and shapes — call it on sign-out.
void forgetShapes({bool persisted = true}) => FlankrMemory.instance.forget(shapes: persisted);

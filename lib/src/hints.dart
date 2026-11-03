import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Draws [child] as one block while it is part of a skeleton, whatever it holds.
class FlankrBlock extends SingleChildRenderObjectWidget {
  const FlankrBlock({super.key, this.radius, super.child});

  /// The block's corner radius; the theme's radius when null.
  final double? radius;

  @override
  RenderFlankrBlock createRenderObject(BuildContext context) => RenderFlankrBlock(radius: radius);

  @override
  void updateRenderObject(BuildContext context, RenderFlankrBlock renderObject) {
    renderObject.radius = radius;
  }
}

class RenderFlankrBlock extends RenderProxyBox {
  RenderFlankrBlock({double? radius}) : _radius = radius;

  double? _radius;
  double? get radius => _radius;
  set radius(double? value) {
    if (value == _radius) return;
    _radius = value;
    markNeedsPaint();
  }
}

/// Draws nothing for [child] while it is part of a skeleton.
class FlankrIgnore extends SingleChildRenderObjectWidget {
  const FlankrIgnore({super.key, super.child});

  @override
  RenderFlankrIgnore createRenderObject(BuildContext context) => RenderFlankrIgnore();
}

class RenderFlankrIgnore extends RenderProxyBox {}

/// Builds [skeleton] in place of [child] while inside a loading skeleton —
/// for a widget whose loading shape is better described by hand.
///
/// ```dart
/// FlankrStandIn(
///   skeleton: const SkeletonBox(width: 40, height: 40, radius: 20),
///   child: Avatar(user),
/// )
/// ```
class FlankrStandIn extends StatelessWidget {
  const FlankrStandIn({super.key, required this.skeleton, required this.child});

  final Widget skeleton;
  final Widget child;

  @override
  Widget build(BuildContext context) => FlankrLoading.of(context) ? skeleton : child;
}

/// Tells widgets below whether they are being drawn as a skeleton.
class FlankrLoading extends InheritedWidget {
  const FlankrLoading({super.key, required this.loading, required super.child});

  final bool loading;

  /// True while [context] sits inside a loading skeleton.
  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FlankrLoading>()?.loading ?? false;

  @override
  bool updateShouldNotify(FlankrLoading oldWidget) => oldWidget.loading != loading;
}

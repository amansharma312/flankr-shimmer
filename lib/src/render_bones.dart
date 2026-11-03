import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'bone.dart';
import 'clock.dart';
import 'hints.dart';
import 'measure.dart';
import 'provider.dart';
import 'shimmer.dart';
import 'theme.dart';

/// How often a visible, animating skeleton checks whether its content's
/// layout has changed underneath it (a font loading, say).
const Duration kRemeasureInterval = Duration(milliseconds: 300);

/// Lays [child] out unseen and draws a skeleton of it in its place: a bar for
/// every line of text, a block for every image, icon and control. The
/// skeleton takes exactly the space the content will.
///
/// With no [child], draws [replay] — a shape measured before — along with
/// [replaySurfaces] when they were measured at the same width.
class FlankrBones extends StatelessWidget {
  const FlankrBones({
    super.key,
    this.child,
    this.replay,
    this.replaySurfaces = const [],
    this.visible = true,
    this.onMeasured,
  }) : assert(child != null || replay != null, 'Give a child to measure or a shape to replay.');

  /// Replays a whole measurement: bones and surfaces.
  FlankrBones.measured(FlankrMeasurement measurement, {Key? key, bool visible = true})
      : this(key: key, replay: measurement.shape, replaySurfaces: measurement.surfaces, visible: visible);

  final Widget? child;
  final BoneShape? replay;
  final List<FlankrSurface> replaySurfaces;

  /// While false the skeleton takes its space but paints nothing — the hold.
  final bool visible;

  /// Called after a frame with what was measured, for remembering it.
  final ValueChanged<FlankrMeasurement>? onMeasured;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: ExcludeFocus(
        child: FlankrLoading(
          loading: true,
          child: _BonesRender(
            style: FlankrConfig.styleOf(context),
            visible: visible,
            replay: replay,
            replaySurfaces: replaySurfaces,
            // `valuesOf` replaces this from Flutter 3.35; kept for 3.27+ support.
            // ignore: deprecated_member_use
            tickerEnabled: TickerMode.of(context),
            screenWidth: MediaQuery.maybeSizeOf(context)?.width ?? 400,
            onMeasured: onMeasured,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _BonesRender extends SingleChildRenderObjectWidget {
  const _BonesRender({
    required this.style,
    required this.visible,
    required this.replay,
    required this.replaySurfaces,
    required this.tickerEnabled,
    required this.screenWidth,
    required this.onMeasured,
    super.child,
  });

  final FlankrStyle style;
  final bool visible;
  final BoneShape? replay;
  final List<FlankrSurface> replaySurfaces;
  final bool tickerEnabled;
  final double screenWidth;
  final ValueChanged<FlankrMeasurement>? onMeasured;

  @override
  RenderFlankrBones createRenderObject(BuildContext context) => RenderFlankrBones(
        style: style,
        visible: visible,
        replay: replay,
        replaySurfaces: replaySurfaces,
        tickerEnabled: tickerEnabled,
        screenWidth: screenWidth,
        onMeasured: onMeasured,
      );

  @override
  void updateRenderObject(BuildContext context, RenderFlankrBones renderObject) {
    renderObject
      ..style = style
      ..visible = visible
      ..replay = replay
      ..replaySurfaces = replaySurfaces
      ..tickerEnabled = tickerEnabled
      ..screenWidth = screenWidth
      ..onMeasured = onMeasured;
  }
}

/// Lays its child out but never paints it; paints the child's bones instead.
class RenderFlankrBones extends RenderProxyBox {
  RenderFlankrBones({
    required FlankrStyle style,
    required bool visible,
    required BoneShape? replay,
    List<FlankrSurface> replaySurfaces = const [],
    required bool tickerEnabled,
    required double screenWidth,
    this.onMeasured,
  })  : _style = style,
        _visible = visible,
        _replay = replay,
        _replaySurfaces = replaySurfaces,
        _tickerEnabled = tickerEnabled,
        _screenWidth = screenWidth;

  ValueChanged<FlankrMeasurement>? onMeasured;
  FlankrMeasurement? _measurement;
  Duration _measuredAt = Duration.zero;
  Path? _path;
  ui.Picture? _surfaces;
  bool _listening = false;

  FlankrStyle _style;
  FlankrStyle get style => _style;
  set style(FlankrStyle value) {
    if (value == _style) return;
    final remeasure = value.radius != _style.radius || value.text != _style.text;
    _style = value;
    if (remeasure) _invalidate();
    _syncClock();
    markNeedsPaint();
  }

  bool _visible;
  set visible(bool value) {
    if (value == _visible) return;
    _visible = value;
    _syncClock();
    markNeedsPaint();
  }

  BoneShape? _replay;
  set replay(BoneShape? value) {
    if (value == _replay) return;
    _replay = value;
    markNeedsLayout();
  }

  List<FlankrSurface> _replaySurfaces;
  set replaySurfaces(List<FlankrSurface> value) {
    if (identical(value, _replaySurfaces)) return;
    _replaySurfaces = value;
    _invalidate();
    markNeedsPaint();
  }

  bool _tickerEnabled;
  set tickerEnabled(bool value) {
    if (value == _tickerEnabled) return;
    _tickerEnabled = value;
    _syncClock();
  }

  double _screenWidth;
  set screenWidth(double value) {
    if (value == _screenWidth) return;
    _screenWidth = value;
    markNeedsPaint();
  }

  /// The skeleton's shape, once it has been painted.
  FlankrMeasurement? get measurement => _measurement;

  @override
  bool get isRepaintBoundary => true;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) => false;

  void _invalidate() {
    _measurement = null;
    _path = null;
    _surfaces?.dispose();
    _surfaces = null;
  }

  Size _replaySize(BoxConstraints constraints) {
    final shape = _replay!;
    final width = constraints.hasBoundedWidth ? constraints.maxWidth : shape.size.width;
    return constraints.constrain(Size(width, shape.size.height));
  }

  @override
  void performLayout() {
    _invalidate();
    if (child != null) return super.performLayout();
    size = _replaySize(constraints);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      child != null ? super.computeDryLayout(constraints) : _replaySize(constraints);

  @override
  double computeMinIntrinsicWidth(double height) =>
      child != null ? super.computeMinIntrinsicWidth(height) : _replay!.size.width;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      child != null ? super.computeMaxIntrinsicWidth(height) : _replay!.size.width;

  @override
  double computeMinIntrinsicHeight(double width) =>
      child != null ? super.computeMinIntrinsicHeight(width) : _replay!.size.height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      child != null ? super.computeMaxIntrinsicHeight(width) : _replay!.size.height;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _syncClock();
  }

  @override
  void detach() {
    _stopListening();
    super.detach();
  }

  @override
  void dispose() {
    _stopListening();
    _invalidate();
    super.dispose();
  }

  void _syncClock() {
    final want = attached && _visible && _tickerEnabled && _style.isAnimated;
    if (want && !_listening) {
      FlankrClock.instance.addListener(markNeedsPaint);
      _listening = true;
    } else if (!want) {
      _stopListening();
    }
  }

  void _stopListening() {
    if (!_listening) return;
    FlankrClock.instance.removeListener(markNeedsPaint);
    _listening = false;
  }

  /// Measures again when the last measurement is stale; keeps the cached
  /// path and surfaces when nothing actually moved.
  void _ensureMeasured() {
    final now = FlankrClock.instance.elapsed;
    final current = _measurement;
    if (current != null && (child == null || now - _measuredAt < kRemeasureInterval)) return;
    _measuredAt = now;
    final measured = _measure();
    if (current != null && current.shape == measured.shape) return;
    _invalidate();
    _apply(measured);
  }

  FlankrMeasurement _measure() {
    final box = child;
    if (box != null) return measureBones(box, _style);
    final shape = _replay!;
    final sameWidth = (shape.size.width - size.width).abs() < 0.5;
    return FlankrMeasurement(shape.scaledTo(size.width), sameWidth ? _replaySurfaces : const []);
  }

  void _apply(FlankrMeasurement measured) {
    _measurement = measured;
    _path = measured.shape.toPath();
    if (measured.surfaces.isNotEmpty) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      for (final surface in measured.surfaces) {
        canvas
          ..save()
          ..clipRect(surface.clip)
          ..transform(surface.transform.storage);
        surface.paint(canvas, surface.size);
        canvas.restore();
      }
      _surfaces = recorder.endRecording();
    }
    final callback = onMeasured;
    if (callback != null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (attached) callback(measured);
      });
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_visible) return;
    _ensureMeasured();
    final canvas = context.canvas
      ..save()
      ..translate(offset.dx, offset.dy);
    final surfaces = _surfaces;
    if (surfaces != null) canvas.drawPicture(surfaces);

    final path = _path!;
    final elapsed = FlankrClock.instance.elapsed;
    final opacity = _style.animation == FlankrAnimation.pulse ? pulseOpacity(_style, elapsed) : 1.0;
    canvas.drawPath(path, Paint()..color = _style.base.withValues(alpha: _style.base.a * opacity));

    if (_style.animation == FlankrAnimation.shimmer || _style.animation == FlankrAnimation.groupShimmer) {
      final shader = shimmerShader(
        style: _style,
        origin: localToGlobal(Offset.zero),
        size: size,
        screenWidth: _screenWidth,
        elapsed: elapsed,
      );
      canvas.drawPath(path, Paint()..shader = shader);
    }
    canvas.restore();
  }
}

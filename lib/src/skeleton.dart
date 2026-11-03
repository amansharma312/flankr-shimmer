import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'bone.dart';
import 'debug_outline.dart';
import 'input_tracker.dart';
import 'measure.dart';
import 'memory.dart';
import 'provider.dart';
import 'render_bones.dart';
import 'reveal_spec.dart';
import 'reveal_transition.dart';
import 'theme.dart';

/// Where a skeleton's shape came from, best first.
enum FlankrSource {
  /// The data on screen, when `loading` is forced over it.
  data,

  /// The data last shown under the same `id`.
  last,

  /// The shape remembered under the same `id`.
  remembered,

  /// The `sample`.
  sample,

  /// Plain children, rendered without their data.
  children,

  /// A hand-made `skeleton` widget.
  custom,

  /// A few generic lines — give a `sample` instead.
  generic,
}

/// Shows a skeleton of what it will render while its data loads, then
/// reveals the content in its place. The skeleton takes exactly the space
/// the content will, so nothing moves when it arrives.
///
/// ```dart
/// Skeleton<User>(
///   data: user,                 // loading while null
///   sample: User.sample,        // draws the very first skeleton
///   builder: (context, user) => UserCard(user),
/// )
/// ```
class Skeleton<T extends Object> extends StatefulWidget {
  const Skeleton({
    super.key,
    required this.data,
    required Widget Function(BuildContext context, T data) this.builder,
    this.sample,
    this.loading,
    this.id,
    this.label,
    this.skeleton,
    this.error,
    this.empty = false,
    this.emptyMessage,
    this.onReveal,
    this.reveal,
  }) : child = null;

  /// Toggled by hand, with plain children rendered as they are.
  const Skeleton.child({
    super.key,
    required bool this.loading,
    required Widget this.child,
    this.id,
    this.label,
    this.skeleton,
    this.error,
    this.empty = false,
    this.emptyMessage,
    this.onReveal,
    this.reveal,
  })  : data = null,
        sample = null,
        builder = null;

  /// Loading while null; passed to [builder] once it isn't.
  final T? data;

  /// Stands in for [data] to draw the very first skeleton.
  final T? sample;
  final Widget Function(BuildContext context, T data)? builder;
  final Widget? child;

  /// Shows the skeleton, even over [data] — say, while refetching.
  final bool? loading;

  /// Remembers the skeleton's shape (and last data) under this key.
  final String? id;

  /// Read to screen readers while loading.
  final String? label;

  /// Shown while loading instead of the measured skeleton.
  final Widget? skeleton;

  /// Shown instead of the content when set.
  final Widget? error;

  /// Shows [emptyMessage], or the content if there's none.
  final bool empty;
  final Widget? emptyMessage;

  /// Called once content has come in over a skeleton.
  final VoidCallback? onReveal;

  /// How content replaces its skeleton; the provider's, else `smart`.
  final FlankrReveal? reveal;

  bool get isLoading => loading ?? data == null;

  @override
  State<Skeleton<T>> createState() => _SkeletonState<T>();
}

enum _Phase { hold, skeleton, revealing, shown }

class _SkeletonState<T extends Object> extends State<Skeleton<T>> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final GlobalKey _bonesKey = GlobalKey(debugLabel: 'flankr bones');
  final GlobalKey _contentKey = GlobalKey(debugLabel: 'flankr content');
  final Stopwatch _waited = Stopwatch();

  _Phase _phase = _Phase.shown;
  Timer? _hold;
  bool _refetch = false;
  FlankrReveal? _active;
  Widget? _loadingBones;
  FlankrMeasurement? _lastMeasurement;
  bool _dependenciesReady = false;
  FlankrSource? _source;
  FlankrStyle? _style;
  double? _skeletonHeight;
  String? _moved;
  bool _warned = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    FlankrInputTracker.instance.ensureInstalled();
    if (widget.isLoading) {
      _startLoading(refetch: false);
    } else {
      _afterShown(revealed: false);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dependenciesReady) return;
    _dependenciesReady = true;
    if (_phase == _Phase.hold) _scheduleHold();
  }

  @override
  void didUpdateWidget(Skeleton<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final was = oldWidget.isLoading;
    final now = widget.isLoading;
    if (!was && now) _startLoading(refetch: _phase == _Phase.shown && oldWidget.data != null);
    if (was && !now) _finishLoading();
    if (!was && !now && widget.data != oldWidget.data) _afterShown(revealed: false);
  }

  @override
  void dispose() {
    _hold?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startLoading({required bool refetch}) {
    _refetch = refetch;
    _waited
      ..reset()
      ..start();
    _controller.stop();
    _hold?.cancel();
    _phase = _Phase.hold;
    // The provider's hold needs inherited widgets, which initState can't read yet.
    if (_dependenciesReady) _scheduleHold();
  }

  void _scheduleHold() {
    final hold = (widget.reveal ?? FlankrConfig.of(context).reveal).hold;
    if (hold == Duration.zero) {
      _phase = _Phase.skeleton;
      return;
    }
    _hold = Timer(hold, () {
      if (mounted && _phase == _Phase.hold) setState(() => _phase = _Phase.skeleton);
    });
  }

  void _finishLoading() {
    _hold?.cancel();
    _waited.stop();
    switch (_phase) {
      case _Phase.hold:
        _phase = _Phase.shown;
        _afterShown(revealed: false);
      case _Phase.skeleton:
        final skeleton = _bonesKey.currentContext?.findRenderObject();
        _skeletonHeight = skeleton is RenderBox && skeleton.hasSize ? skeleton.size.height : null;
        final spec = _resolveReveal();
        if (spec.duration == Duration.zero) {
          _phase = _Phase.shown;
          _afterShown(revealed: true);
          return;
        }
        _active = spec;
        _phase = _Phase.revealing;
        _controller.duration = spec.duration;
        _controller.forward(from: 0).whenComplete(() {
          if (!mounted || _phase != _Phase.revealing) return;
          setState(() => _phase = _Phase.shown);
          _afterShown(revealed: true);
        });
      case _Phase.revealing || _Phase.shown:
        break;
    }
  }

  FlankrReveal _resolveReveal() {
    final spec = widget.reveal ?? FlankrConfig.of(context).reveal;
    final screenHeight = MediaQuery.maybeSizeOf(context)?.height ?? 800;
    final drawn = _drawnExtent() ?? _skeletonHeight ?? 0;
    return spec.resolve(FlankrRevealContext(
      waited: _waited.elapsed,
      input: FlankrInputTracker.instance.recent,
      refetch: _refetch,
      height: drawn.clamp(0, screenHeight).toDouble(),
      screenHeight: screenHeight,
      pieces: _lastMeasurement?.shape.bones.length ?? 0,
    ));
  }

  /// How far down the skeleton actually draws: the bottom of its lowest bone.
  double? _drawnExtent() {
    final bones = _lastMeasurement?.shape.bones;
    if (bones == null || bones.isEmpty) return null;
    return bones.fold<double>(0, (bottom, bone) => bone.rect.bottom > bottom ? bone.rect.bottom : bottom);
  }

  /// After a frame: report the reveal, remember data and shape, check for movement.
  void _afterShown({required bool revealed}) {
    final skeletonHeight = revealed ? _skeletonHeight : null;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _phase != _Phase.shown) return;
      if (revealed) widget.onReveal?.call();
      final id = widget.id;
      final data = widget.data;
      if (id != null && data != null) FlankrMemory.instance.rememberData(id, data);
      final box = _contentKey.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return;
      final style = _style;
      if (id != null && style != null) {
        // Measure after a reveal, or when the content's size has changed since.
        final stored = FlankrMemory.instance.shapeFor(id);
        if (revealed || stored == null || stored.size != box.size) {
          FlankrMemory.instance.rememberShape(id, measureBones(box, style).shape);
        }
      }
      if (skeletonHeight != null) _checkMoved(skeletonHeight, box.size.height);
    });
  }

  void _checkMoved(double skeleton, double content) {
    final moved = (content - skeleton).abs();
    if (moved <= 1) return;
    final message = 'content moved ${moved.toStringAsFixed(0)}px';
    if (kDebugMode) {
      debugPrint('[flankr_shimmer] ${widget.id ?? T}: skeleton was ${skeleton.toStringAsFixed(0)}px '
          'tall, content ${content.toStringAsFixed(0)}px — $message. Make the sample match real data.');
    }
    if (FlankrConfig.of(context).debug) setState(() => _moved = message);
  }

  @override
  Widget build(BuildContext context) {
    _style = FlankrConfig.styleOf(context);
    if (widget.error != null) return widget.error!;
    final loading = _phase == _Phase.hold || _phase == _Phase.skeleton;
    Widget body = switch (_phase) {
      _Phase.hold => _bones(visible: false),
      _Phase.skeleton => _bones(visible: true),
      _Phase.revealing => FlankrRevealTransition(
          animation: _controller,
          wipe: _active!.wipe,
          extent: _drawnExtent(),
          content: _content(),
          bones: _revealBones(),
        ),
      _Phase.shown => widget.empty ? (widget.emptyMessage ?? _content()) : _content(),
    };
    if (loading) body = Semantics(container: true, label: widget.label, child: body);
    if (FlankrConfig.of(context).debug) {
      body = FlankrDebugOutline(
        label: loading || _phase == _Phase.revealing ? _source?.name : (_moved ?? 'shown'),
        warn: _moved != null || _source == FlankrSource.generic,
        child: body,
      );
    }
    return body;
  }

  Widget _content() {
    final builder = widget.builder;
    final data = widget.data;
    final child = builder == null ? widget.child! : (data == null ? const SizedBox.shrink() : builder(context, data));
    return KeyedSubtree(key: _contentKey, child: child);
  }

  /// The skeleton leaving during a reveal: replayed from its last measurement,
  /// so the content is never mounted twice (GlobalKeys, focus, side effects).
  Widget _revealBones() {
    if (_source == FlankrSource.custom) return _loadingBones ?? const SizedBox.shrink();
    final measured = _lastMeasurement;
    return measured == null ? const SizedBox.shrink() : FlankrBones.measured(measured);
  }

  void _onMeasured(FlankrMeasurement measurement) => _lastMeasurement = measurement;

  Widget _bones({required bool visible}) {
    final (source, bones) = _pickSource(visible);
    _source = source;
    if (source == FlankrSource.generic) _warnGeneric();
    return _loadingBones = KeyedSubtree(key: _bonesKey, child: bones);
  }

  (FlankrSource, Widget) _pickSource(bool visible) {
    final custom = widget.skeleton;
    if (custom != null) {
      return (FlankrSource.custom, Visibility.maintain(visible: visible, child: custom));
    }
    Widget measured(Widget child) => FlankrBones(visible: visible, onMeasured: _onMeasured, child: child);
    Widget replayed(BoneShape shape) => FlankrBones(visible: visible, onMeasured: _onMeasured, replay: shape);
    final builder = widget.builder;
    final id = widget.id;
    final data = widget.data;
    if (builder != null && data != null) return (FlankrSource.data, measured(builder(context, data)));
    final last = id == null ? null : FlankrMemory.instance.dataFor(id);
    if (builder != null && last is T) return (FlankrSource.last, measured(builder(context, last)));
    final shape = id == null ? null : FlankrMemory.instance.shapeFor(id);
    if (shape != null) return (FlankrSource.remembered, replayed(shape));
    final sample = widget.sample;
    if (builder != null && sample != null) return (FlankrSource.sample, measured(builder(context, sample)));
    if (widget.child != null) return (FlankrSource.children, measured(widget.child!));
    final fontSize = DefaultTextStyle.of(context).style.fontSize ?? 14;
    return (FlankrSource.generic, replayed(BoneShape.lines(fontSize: fontSize)));
  }

  void _warnGeneric() {
    if (_warned || !kDebugMode) return;
    _warned = true;
    debugPrint('[flankr_shimmer] Skeleton<$T>${widget.id == null ? '' : ' "${widget.id}"'} has no sample, '
        'so it is drawn as generic lines. Pass `sample:` with data shaped like the real thing.');
  }
}

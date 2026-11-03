import 'package:flutter/widgets.dart';

import 'reveal_spec.dart';
import 'skeleton.dart';

/// A [Skeleton] fed by a [Future]: loads until it settles, then shows its
/// value — or [errorBuilder]'s widget for its error.
class SkeletonFuture<T extends Object> extends StatefulWidget {
  const SkeletonFuture({
    super.key,
    required this.future,
    required this.builder,
    this.sample,
    this.errorBuilder,
    this.id,
    this.label,
    this.onReveal,
    this.reveal,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final T? sample;
  final Widget Function(BuildContext context, Object error)? errorBuilder;
  final String? id;
  final String? label;
  final VoidCallback? onReveal;
  final FlankrReveal? reveal;

  @override
  State<SkeletonFuture<T>> createState() => _SkeletonFutureState<T>();
}

class _SkeletonFutureState<T extends Object> extends State<SkeletonFuture<T>> {
  T? _value;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  @override
  void didUpdateWidget(SkeletonFuture<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.future != widget.future) _subscribe();
  }

  void _subscribe() {
    final future = widget.future;
    _value = null;
    _error = null;
    future.then(
      (value) {
        if (mounted && widget.future == future) setState(() => _value = value);
      },
      onError: (Object error, StackTrace stack) {
        if (!mounted || widget.future != future) return;
        if (widget.errorBuilder == null) {
          FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack, library: 'flankr_shimmer'));
        }
        setState(() => _error = error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return Skeleton<T>(
      data: _value,
      sample: widget.sample,
      builder: widget.builder,
      id: widget.id,
      label: widget.label,
      onReveal: widget.onReveal,
      reveal: widget.reveal,
      error: error == null ? null : (widget.errorBuilder?.call(context, error) ?? const SizedBox.shrink()),
    );
  }
}

import 'package:flutter/widgets.dart';

/// Outlines a skeleton with where its shape came from, or whether its
/// content moved anything on arrival. Shown when a provider sets `debug`.
class FlankrDebugOutline extends StatelessWidget {
  const FlankrDebugOutline({super.key, required this.child, this.label, this.warn = false});

  final Widget child;
  final String? label;
  final bool warn;

  static const Color _ok = Color(0xFF16A34A);
  static const Color _warn = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final color = warn ? _warn : _ok;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(decoration: BoxDecoration(border: Border.all(color: color))),
          ),
        ),
        if (label != null)
          Positioned(
            top: 0,
            left: 0,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: ColoredBox(
                  color: color,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    child: Text(
                      label!,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(fontSize: 10, color: Color(0xFFFFFFFF), height: 1.2),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import 'reveal_spec.dart';
import 'theme.dart';

/// Sets skeletons up for everything inside it: theme, light/dark mode, how
/// content is revealed, and the debug overlay. Providers nest; an inner one
/// overrides only what it sets.
class FlankrProvider extends StatelessWidget {
  const FlankrProvider({
    super.key,
    this.theme,
    this.mode,
    this.reveal,
    this.debug,
    required this.child,
  });

  final FlankrTheme? theme;
  final FlankrMode? mode;
  final FlankrReveal? reveal;

  /// Outlines every skeleton with where its shape came from, and whether the
  /// content moved anything when it arrived.
  final bool? debug;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final parent = FlankrConfig.of(context);
    return FlankrScope(
      config: FlankrConfig(
        theme: theme == null ? parent.theme : theme!.over(parent.theme),
        mode: mode ?? parent.mode,
        reveal: reveal ?? parent.reveal,
        debug: debug ?? parent.debug,
      ),
      child: child,
    );
  }
}

/// The configuration a [FlankrProvider] hands down.
@immutable
class FlankrConfig {
  const FlankrConfig({
    this.theme = FlankrTheme.defaults,
    this.mode = FlankrMode.system,
    this.reveal = FlankrReveal.smart,
    this.debug = false,
  });

  final FlankrTheme theme;
  final FlankrMode mode;
  final FlankrReveal reveal;
  final bool debug;

  static const FlankrConfig fallback = FlankrConfig();

  static FlankrConfig of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FlankrScope>()?.config ?? fallback;

  /// The style to paint with here: colours for the current brightness, and no
  /// motion when the platform asks for reduced motion.
  static FlankrStyle styleOf(BuildContext context) {
    final config = of(context);
    final brightness = switch (config.mode) {
      FlankrMode.light => Brightness.light,
      FlankrMode.dark => Brightness.dark,
      FlankrMode.system => Theme.of(context).brightness,
    };
    final disable = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return config.theme.resolve(brightness, disableAnimations: disable);
  }

  @override
  bool operator ==(Object other) =>
      other is FlankrConfig &&
      other.theme == theme &&
      other.mode == mode &&
      other.reveal == reveal &&
      other.debug == debug;

  @override
  int get hashCode => Object.hash(theme, mode, reveal, debug);
}

/// Carries a [FlankrConfig] down the tree. Use [FlankrProvider] to create one.
class FlankrScope extends InheritedWidget {
  const FlankrScope({super.key, required this.config, required super.child});

  final FlankrConfig config;

  @override
  bool updateShouldNotify(FlankrScope oldWidget) => oldWidget.config != config;
}

import 'package:flankr_shimmer_example/app/resources/color_manager.dart';
import 'package:flutter/material.dart';

abstract final class StylesManager {
  static final ThemeData light = ThemeData(colorSchemeSeed: ColorManager.seed);

  static final ThemeData dark = ThemeData(
    colorSchemeSeed: ColorManager.seed,
    brightness: Brightness.dark,
  );

  static const EdgeInsets screenPadding = EdgeInsets.all(16);
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const double cardGap = 12;
}

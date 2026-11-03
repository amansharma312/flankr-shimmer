/// Smart skeleton loading for Flutter: wrap what you'd render once your data
/// arrives, and while it loads a shimmering skeleton is drawn from it — a bar
/// for every line of text, a block for every image, icon and control.
///
/// A Flutter port of the ideas in Skullet (https://skullet.lochie.me).
library;

export 'src/bone.dart' show Bone, BoneShape;
export 'src/clock.dart' show FlankrClock;
export 'src/hints.dart' show FlankrBlock, FlankrIgnore, FlankrLoading, FlankrStandIn;
export 'src/measure.dart' show FlankrMeasurement, FlankrSurface, measureBones;
export 'src/memory.dart' show FlankrMemory, forgetShapes;
export 'src/provider.dart' show FlankrConfig, FlankrProvider, FlankrScope;
export 'src/render_bones.dart' show FlankrBones;
export 'src/reveal_spec.dart' show FlankrReveal, FlankrRevealContext, FlankrWipe;
export 'src/skeleton.dart' show FlankrSource, Skeleton;
export 'src/skeleton_box.dart' show SkeletonBox;
export 'src/skeleton_future.dart' show SkeletonFuture;
export 'src/theme.dart'
    show FlankrAnimation, FlankrColors, FlankrMode, FlankrSpeed, FlankrStyle, FlankrText, FlankrTheme, TextBottom, TextTop;

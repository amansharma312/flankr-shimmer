/// Smart skeleton loading for Flutter: wrap what you'd render once your data
/// arrives, and while it loads a shimmering skeleton is drawn from it — a bar
/// for every line of text, a block for every image, icon and control.
///
/// A Flutter port of the ideas in Skullet (https://skullet.lochie.me).
library;

export 'src/model/bone.dart' show Bone, BoneShape;
export 'src/services/flankr_clock.dart' show FlankrClock;
export 'src/widgets/hints.dart'
    show FlankrBlock, FlankrIgnore, FlankrLoading, FlankrStandIn;
export 'src/services/bone_measurer.dart'
    show FlankrMeasurement, FlankrSurface, measureBones;
export 'src/services/flankr_memory.dart' show FlankrMemory, forgetShapes;
export 'src/controller/flankr_provider.dart'
    show FlankrConfig, FlankrProvider, FlankrScope;
export 'src/widgets/render_bones.dart' show FlankrBones;
export 'src/model/reveal_spec.dart'
    show FlankrReveal, FlankrRevealContext, FlankrWipe;
export 'src/widgets/skeleton.dart' show FlankrSource, Skeleton;
export 'src/widgets/skeleton_box.dart' show SkeletonBox;
export 'src/widgets/skeleton_future.dart' show SkeletonFuture;
export 'src/model/flankr_theme.dart'
    show
        FlankrAnimation,
        FlankrColors,
        FlankrMode,
        FlankrSpeed,
        FlankrStyle,
        FlankrText,
        FlankrTheme,
        TextBottom,
        TextTop;

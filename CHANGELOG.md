## 0.1.2

- `SkeletonFuture` no longer throws when its value is itself a `Future`.
- Internal: sources reorganised into `model/`, `controller/`, `services/`, `widgets/`, `utility/` and `resources/`, with shared easing and loop-timing helpers. The public API is unchanged.

## 0.1.1

- No longer imports `package:flutter/material.dart`; the package now depends only on `widgets`, so it works the same in Material, Cupertino and custom-design apps.
- `FlankrMode.system` now follows the device light/dark setting (`MediaQuery.platformBrightnessOf`) instead of `Theme.of(context).brightness`. If your app forces a theme mode regardless of the device, set `FlankrMode.light` or `FlankrMode.dark` on `FlankrProvider`.

## 0.1.0

- First release: `Skeleton`, `Skeleton.child`, `SkeletonFuture`, `SkeletonBox`.
- Skeletons measured from your real widgets: a bar per line of text, a block per image, icon and control; cards and sheets keep their surface.
- One shimmer stream across every skeleton on screen; `shimmer`, `groupShimmer`, `pulse`, `none`.
- Reveals: `smart`, `together`, `sequence`, `sweep`, `instant`, or your own.
- Remembered shapes by `id`, persistable as JSON; `forgetShapes()` for sign-out.
- `FlankrProvider` for theme, light/dark mode, reveal and a debug overlay.

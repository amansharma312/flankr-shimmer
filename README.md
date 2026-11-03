# flankr_shimmer

Smart skeleton loading for Flutter.

Wrap what you'd render once your data arrives. While it loads, flankr_shimmer
lays that content out unseen and draws a skeleton in its place: a bar for
every line of text, a block for every image, icon and control. Cards and
sheets keep their own surface. The skeleton takes exactly the space the
content will, so nothing moves when it arrives.

You don't hand-build a second "shimmer layout" that drifts out of sync with
the real one: the skeleton is measured from your real widgets.

## Install

```shell
flutter pub add flankr_shimmer
```

## Usage

Pass your data and build from it. It's loading while `data` is `null`:

```dart
import 'package:flankr_shimmer/flankr_shimmer.dart';

Skeleton<User>(
  data: user,                 // null while loading
  sample: User.sample,        // stands in to draw the very first skeleton
  builder: (context, user) => UserCard(user),
)
```

Or toggle it yourself, with plain children:

```dart
Skeleton.child(
  loading: user == null,
  child: const ProfileHeader(),
)
```

Or hand it a `Future`:

```dart
SkeletonFuture<List<Order>>(
  future: api.orders(),
  sample: List.filled(3, Order.sample),
  builder: (context, orders) => OrderList(orders),
  errorBuilder: (context, error) => const Text('Could not load orders'),
)
```

| Parameter      | Description                                                    |
| -------------- | -------------------------------------------------------------- |
| `data`         | Loading while null; passed to `builder` once it isn't.         |
| `sample`       | Stands in for `data` to draw the very first skeleton.          |
| `loading`      | Shows the skeleton, even over `data` (say, while refetching).  |
| `id`           | Remembers the skeleton's shape (and last data) under this key. |
| `label`        | Read to screen readers while loading.                          |
| `skeleton`     | Shown while loading instead of the measured skeleton.          |
| `error`        | Shown instead of the content when set.                         |
| `empty`        | Shows `emptyMessage`, or the content if there's none.          |
| `emptyMessage` |                                                                |
| `onReveal`     | Called once content has come in over a skeleton.               |
| `reveal`       | How content replaces its skeleton (below).                     |

## Provider

`FlankrProvider` sets skeletons up for everything inside it. Providers nest,
and an inner one overrides only what it sets.

```dart
FlankrProvider(
  mode: FlankrMode.system,           // or light / dark; system follows Theme.of(context)
  theme: const FlankrTheme(radius: 6),
  reveal: FlankrReveal.smart,        // or together / sequence / sweep / instant
  debug: kDebugMode,                 // outlines each skeleton with its source
  child: MyApp(),
)
```

### Theming

```dart
const theme = FlankrTheme(
  light: FlankrColors(base: Color(0x12000000), highlight: Color(0x99FFFFFF)),
  dark: FlankrColors(base: Color(0x14FFFFFF), highlight: Color(0x1AFFFFFF)),
  animation: FlankrAnimation.shimmer, // groupShimmer, pulse or none
  speed: FlankrSpeed.slow,            // shimmer 4s / 2s, pulse 2.4s / 1.2s
  radius: 6,                          // text bars and plain blocks
  text: FlankrText(top: TextTop.ascender, bottom: TextBottom.descender),
);
```

- `shimmer` sweeps one highlight across the whole screen, so every skeleton
  shimmers in a single stream however late it mounts. `groupShimmer` gives
  each skeleton its own sweep. `pulse` fades every skeleton in and out, in step.
- The shimmer keeps the pace it has on a 1280px-wide screen at any width, so
  a tablet doesn't make it race.
- Everything holds still when the platform asks for reduced motion
  (`MediaQuery.disableAnimations`).

### Lines of text

Each line gets a bar between two of the font's own lines: a top of
`ascender`, `capHeight` or `xHeight`, and a bottom of `baseline` or
`descender`. The default, ascender to descender, includes hanging letters
like g, p and y. Lines follow your real wrapping, alignment, `maxLines` and
text scaling.

### Reveals

- `together` crossfades skeleton and content whole.
- `sequence` brings content in top to bottom, where its skeleton was.
- `sweep` carries content in behind one diagonal front at the shimmer's
  slant. It falls back to a crossfade for anything over about a screen and a half.
- `smart` (the default) decides per reveal. It swaps at once mid-scroll or for
  a load under 150ms (the skeleton is held back that long, so a fast load
  never flashes one). It uses a quick crossfade for a refetch, crossfades
  something small whole, and runs anything else in sequence.
- Or write your own: `FlankrReveal(duration: ..., wipe: FlankrWipe.down, choose: (context) => ...)`.

## Where the skeleton's shape comes from

The best available source wins, in this order:

1. The data on screen, when you force `loading` over it.
2. The data it last showed under the same `id`, so a reload is exact.
3. The shape remembered under the same `id`.
4. Your `sample`.
5. Plain children (`Skeleton.child`).
6. A few generic lines, with a warning in debug mode.

In debug mode, flankr_shimmer warns when a skeleton and its content differ in
height, and when a skeleton has no `sample`.

### Keeping shapes across launches

Remembered shapes keep layout, never content. Persist them with any storage,
for example `shared_preferences`:

```dart
final prefs = await SharedPreferences.getInstance();
final saved = prefs.getString('flankr_shapes');
if (saved != null) FlankrMemory.instance.restoreShapes(jsonDecode(saved));
FlankrMemory.instance.onShapesChanged =
    (json) => prefs.setString('flankr_shapes', jsonEncode(json));
```

Clear them on sign-out:

```dart
forgetShapes();
```

## Hints

- `FlankrBlock` draws its child as one block (give it a `radius`).
- `FlankrIgnore` draws nothing for its child.
- `FlankrStandIn(skeleton: ..., child: ...)` builds `skeleton` in place of
  `child` while loading, for when you'd rather describe the shape by hand.

## Placeholder boxes

```dart
const SkeletonBox(width: 120, height: 14);
const SkeletonBox.fraction(widthFactor: 0.6);
const SkeletonBox(width: 40, height: 40, radius: 20); // a circle
```

A `SkeletonBox` shimmers in step with every other skeleton. Inside a loading
`Skeleton` it becomes part of that skeleton.

## What gets drawn

| In your tree                                                  | In the skeleton                          |
| ------------------------------------------------------------- | ---------------------------------------- |
| `Text`, `RichText`                                            | one bar per line                         |
| `Icon`                                                        | a block                                  |
| `Image`, `DecoratedBox` with an image, `CustomPaint` leaves   | a block, taking a rounded clip's radius  |
| `TextField`                                                   | a block                                  |
| Buttons                                                       | one block in the button's shape          |
| `Card`, `Material`, `Container` with colour, border or shadow | keeps its surface; contents become bones |
| A coloured box holding nothing to draw                        | a block in its shape                     |
| Offstage, invisible or off-screen widgets                     | nothing                                  |

## Accessibility

While loading, the skeleton is hidden from screen readers and doesn't respond
to touch. Pass `label` to have something read in its place.

## Testing

Skeletons animate on a shared ticker while visible, so `pumpAndSettle` won't
settle until they're gone. Pump explicit durations instead, or pass
`reveal: FlankrReveal.instant`. While loading, the sample's text is in the
widget tree but hidden from semantics: query by semantics, not by text.

## Credits

flankr_shimmer is a Flutter port of the ideas in
[Skullet](https://skullet.lochie.me) by Lochie Axon (MIT). It reuses Skullet's
behaviour, colours and timings, re-implemented for Flutter's render tree.
It is not affiliated with or endorsed by the Skullet project.

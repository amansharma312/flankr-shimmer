import 'package:flankr_shimmer/flankr_shimmer.dart';
import 'package:flankr_shimmer/src/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class User {
  const User(this.name, this.bio);
  final String name;
  final String bio;
}

const sampleUser = User('Sample Name', 'A short line of sample bio text');

Widget card(User user) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(width: 40, height: 40, child: FlankrBlock(radius: 20, child: SizedBox.expand())),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name, style: const TextStyle(fontSize: 18)),
                  Text(user.bio),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );

Widget app(Widget child, {bool disableAnimations = false}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations, size: const Size(400, 800)),
        child: Scaffold(body: SafeArea(child: child)),
      ),
    );

Skeleton<User> profile({User? data, VoidCallback? onReveal, String? id, String? label}) => Skeleton<User>(
      data: data,
      sample: sampleUser,
      id: id,
      label: label,
      onReveal: onReveal,
      builder: (context, user) => card(user),
    );

void main() {
  tearDown(() => forgetShapes());

  testWidgets('measures text lines, icons, blocks and keeps the card surface', (tester) async {
    await tester.pumpWidget(app(Center(child: SizedBox(width: 360, child: card(sampleUser)))));
    final cardBox = tester.renderObject<RenderBox>(find.byType(Card));
    final style = FlankrTheme.defaults.resolve(Brightness.light);
    final m = measureBones(cardBox, style);

    // avatar block, name line, bio line, chevron icon
    expect(m.shape.bones, hasLength(4));
    expect(m.shape.bones.first.radius, 20);
    expect(m.surfaces, isNotEmpty, reason: 'the card keeps its surface');

    final nameBox = tester.renderObject<RenderBox>(find.text('Sample Name'));
    final nameTop = nameBox.localToGlobal(Offset.zero, ancestor: cardBox).dy;
    final bar = m.shape.bones[1].rect;
    expect(bar.top, greaterThan(nameTop), reason: 'bars sit inside the line, not over its leading');
    expect(bar.bottom, lessThan(nameTop + nameBox.size.height));
    expect(bar.height, closeTo(18 * 0.95, 0.5));
  });

  testWidgets('FlankrIgnore draws nothing, FlankrBlock draws one block', (tester) async {
    await tester.pumpWidget(app(const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlankrIgnore(child: Text('hidden')),
        FlankrBlock(child: Column(children: [Text('one'), Text('two')])),
      ],
    )));
    final root = tester.renderObject<RenderBox>(find.byType(Column).first);
    final m = measureBones(root, FlankrTheme.defaults.resolve(Brightness.light));
    expect(m.shape.bones, hasLength(1));
  });

  testWidgets('holds the skeleton back so a fast load never flashes one', (tester) async {
    var revealed = 0;
    await tester.pumpWidget(app(profile(onReveal: () => revealed++)));
    final bones = tester.renderObject<RenderBox>(find.byType(FlankrBones).first);
    expect(bones.size.height, greaterThan(0), reason: 'space is reserved during the hold');
    expect(find.byType(FlankrBones), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpWidget(app(profile(data: const User('Ada', 'Real bio'), onReveal: () => revealed++)));
    await tester.pump();
    expect(find.text('Ada'), findsOneWidget);
    expect(find.byType(FlankrBones), findsNothing);
    expect(revealed, 0, reason: 'no skeleton was shown, so nothing was revealed over one');
  });

  testWidgets('shows a skeleton, then reveals content and calls onReveal once', (tester) async {
    var revealed = 0;
    await tester.pumpWidget(app(profile(label: 'Loading profile', onReveal: () => revealed++)));
    await tester.pump(kSkeletonDelay + const Duration(milliseconds: 10));
    expect(find.bySemanticsLabel('Loading profile'), findsOneWidget);
    expect(find.bySemanticsLabel('Sample Name'), findsNothing, reason: 'sample text is hidden from semantics');

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(app(profile(data: const User('Ada', 'Real bio'), onReveal: () => revealed++)));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('Ada'), findsOneWidget);
    expect(find.byType(FlankrBones), findsNothing);
    expect(revealed, 1);
  });

  testWidgets('remembers the shape under an id and replays it next visit', (tester) async {
    await tester.pumpWidget(app(profile(id: 'profile', data: const User('Ada', 'Real bio'))));
    await tester.pump();
    expect(FlankrMemory.instance.shapeFor('profile'), isNotNull);
    expect(FlankrMemory.instance.dataFor('profile'), isA<User>());

    FlankrMemory.instance.forget(shapes: false); // drop data, keep the shape
    await tester.pumpWidget(app(const SizedBox()));
    await tester.pumpWidget(app(Skeleton<User>(
      data: null,
      id: 'profile',
      builder: (context, user) => card(user),
    )));
    final bones = tester.widget<FlankrBones>(find.byType(FlankrBones));
    expect(bones.replay, FlankrMemory.instance.shapeFor('profile'));
  });

  testWidgets('falls back to generic lines without a sample', (tester) async {
    await tester.pumpWidget(app(Skeleton<User>(data: null, builder: (context, user) => card(user))));
    final bones = tester.widget<FlankrBones>(find.byType(FlankrBones));
    expect(bones.replay?.bones, hasLength(3));
  });

  testWidgets('error and empty states', (tester) async {
    await tester.pumpWidget(app(Skeleton<User>(
      data: const User('a', 'b'),
      error: const Text('Failed'),
      builder: (context, user) => card(user),
    )));
    expect(find.text('Failed'), findsOneWidget);

    await tester.pumpWidget(app(Skeleton<User>(
      data: const User('a', 'b'),
      empty: true,
      emptyMessage: const Text('Nothing here'),
      builder: (context, user) => card(user),
    )));
    expect(find.text('Nothing here'), findsOneWidget);
  });

  testWidgets('Skeleton.child toggles plain children', (tester) async {
    await tester.pumpWidget(app(const Skeleton.child(loading: true, child: Text('Hello'))));
    expect(find.byType(FlankrBones), findsOneWidget);
    await tester.pumpWidget(app(const Skeleton.child(loading: false, child: Text('Hello'))));
    await tester.pump();
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('every skeleton shares one clock, which stops when they go', (tester) async {
    await tester.pumpWidget(app(const Column(children: [SkeletonBox(width: 100), SkeletonBox(width: 50)])));
    expect(FlankrClock.instance.isTicking, isTrue);
    await tester.pumpWidget(app(const SizedBox()));
    expect(FlankrClock.instance.isTicking, isFalse);
  });

  testWidgets('holds still when animations are disabled', (tester) async {
    await tester.pumpWidget(app(const SkeletonBox(width: 100), disableAnimations: true));
    expect(FlankrClock.instance.isTicking, isFalse);
    expect(tester.getSize(find.byType(SkeletonBox)), const Size(100, 14));
  });

  testWidgets('SkeletonFuture loads until the future settles', (tester) async {
    final future = Future<User>.delayed(const Duration(milliseconds: 500), () => const User('Ada', 'bio'));
    await tester.pumpWidget(app(SkeletonFuture<User>(
      future: future,
      sample: sampleUser,
      reveal: FlankrReveal.instant,
      builder: (context, user) => card(user),
    )));
    expect(find.byType(FlankrBones), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(find.text('Ada'), findsOneWidget);
  });

  testWidgets('FlankrStandIn swaps in its skeleton only while loading', (tester) async {
    const standIn = FlankrStandIn(skeleton: SkeletonBox(width: 40, height: 40), child: Text('real'));
    await tester.pumpWidget(app(const Skeleton.child(loading: true, child: standIn)));
    expect(find.text('real'), findsNothing);
    await tester.pumpWidget(app(const Skeleton.child(loading: false, child: standIn)));
    await tester.pump();
    expect(find.text('real'), findsOneWidget);
  });

  testWidgets('a tall sequence wipe runs frame by frame to the end', (tester) async {
    Widget list(List<User>? users) => Skeleton<List<User>>(
          data: users,
          sample: List.filled(8, sampleUser),
          reveal: FlankrReveal.sequence,
          builder: (context, users) => SingleChildScrollView(
            child: Column(children: [for (final u in users) card(u)]),
          ),
        );
    await tester.pumpWidget(app(list(null)));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(app(list(List.filled(8, const User('Ada', 'Real bio')))));
    var frames = 0;
    while (find.byType(FlankrBones).evaluate().isNotEmpty && frames < 120) {
      await tester.pump(const Duration(milliseconds: 16));
      frames++;
    }
    expect(find.byType(FlankrBones), findsNothing, reason: 'reveal finished after $frames frames');
    expect(find.byType(ShaderMask), findsNothing);
    expect(frames, greaterThan(10), reason: 'a tall reveal animates rather than swapping');
  });
}

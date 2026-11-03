import 'package:flankr_shimmer/flankr_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget app(Widget child) => MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(size: Size(400, 800)),
        child: Scaffold(body: child),
      ),
    );

FlankrStyle get style => FlankrTheme.defaults.resolve(Brightness.light);

void main() {
  tearDown(() => forgetShapes());

  testWidgets('a bare Text root is measured, not skipped', (tester) async {
    await tester.pumpWidget(app(const Center(child: Text('hello world'))));
    final m = measureBones(tester.renderObject<RenderBox>(find.text('hello world')), style);
    expect(m.shape.bones, hasLength(1));
  });

  testWidgets('softWrap: false keeps one line', (tester) async {
    await tester.pumpWidget(app(const Center(
      child: SizedBox(width: 60, child: Text('a long line that would wrap many times', softWrap: false, overflow: TextOverflow.clip)),
    )));
    final m = measureBones(tester.renderObject<RenderBox>(find.byType(Text)), style);
    expect(m.shape.bones, hasLength(1));
    expect(m.shape.bones.single.rect.width, lessThanOrEqualTo(60.5), reason: 'clipped to the paragraph');
  });

  testWidgets('text with inline widgets is drawn line by line', (tester) async {
    await tester.pumpWidget(app(const Center(
      child: SizedBox(
        width: 300,
        child: Text.rich(TextSpan(style: TextStyle(fontSize: 8), children: [
          TextSpan(text: 'Rated '),
          WidgetSpan(child: SizedBox(width: 16, height: 16)),
          TextSpan(text: ' by 1,204 people'),
        ])),
      ),
    )));
    final m = measureBones(tester.renderObject<RenderBox>(find.byType(RichText)), style);
    expect(m.shape.bones, hasLength(1));
  });

  testWidgets('directional border radii do not crash the measurer', (tester) async {
    await tester.pumpWidget(app(const Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadiusDirectional.only(topStart: Radius.circular(12))),
      child: Padding(padding: EdgeInsets.all(16), child: Text('card')),
    )));
    final m = measureBones(tester.renderObject<RenderBox>(find.byType(Card)), style);
    expect(m.shape.bones, hasLength(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a reveal never mounts the content twice (GlobalKeys survive)', (tester) async {
    final key = GlobalKey();
    Widget build(bool loading) => app(Skeleton.child(
          loading: loading,
          reveal: FlankrReveal.together,
          child: SizedBox(key: key, height: 40, child: const Text('keyed')),
        ));
    await tester.pumpWidget(build(true));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(build(false));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.takeException(), isNull);
    expect(find.text('keyed'), findsOneWidget);
  });

  testWidgets('content keeps its constraints during a reveal', (tester) async {
    Widget build(String? data) => app(Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Skeleton<String>(
              data: data,
              sample: 'sample',
              reveal: FlankrReveal.together,
              builder: (context, s) => ColoredBox(key: const ValueKey('content'), color: Colors.red, child: Text(s)),
            ),
          ],
        ));
    await tester.pumpWidget(build(null));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(build('real'));
    await tester.pump(const Duration(milliseconds: 50));
    final full = tester.getSize(find.byType(Column)).width;
    expect(tester.getSize(find.byKey(const ValueKey('content'))).width, full, reason: 'mid-reveal');
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getSize(find.byKey(const ValueKey('content'))).width, full, reason: 'shown');
  });

  testWidgets('bones follow content that changes behind a relayout boundary', (tester) async {
    late StateSetter setText;
    var text = 'short';
    FlankrMeasurement? last;
    await tester.pumpWidget(app(Center(
      child: FlankrBones(
        onMeasured: (m) => last = m,
        child: SizedBox(
          width: 100,
          height: 100,
          child: StatefulBuilder(builder: (context, setState) {
            setText = setState;
            return Text(text);
          }),
        ),
      ),
    )));
    await tester.pump();
    expect(last!.shape.bones, hasLength(1));
    setText(() => text = 'now a much longer text that wraps');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump();
    expect(last!.shape.bones.length, greaterThan(1));
  });

  testWidgets("the provider's hold is honoured", (tester) async {
    await tester.pumpWidget(app(FlankrProvider(
      reveal: const FlankrReveal(hold: Duration.zero),
      child: Skeleton<String>(data: null, sample: 's', builder: (context, s) => Text(s)),
    )));
    expect(FlankrClock.instance.isTicking, isTrue, reason: 'visible on the first frame, no hold');
  });

  testWidgets('replayed shapes report intrinsic sizes', (tester) async {
    const shape = BoneShape(size: Size(120, 48), bones: [Bone(Rect.fromLTWH(0, 0, 120, 48), 4)]);
    await tester.pumpWidget(app(const Center(child: IntrinsicHeight(child: FlankrBones(replay: shape)))));
    expect(tester.getSize(find.byType(FlankrBones)).height, 48);
  });

  testWidgets('SkeletonBox.fraction draws only its fraction', (tester) async {
    await tester.pumpWidget(app(const Column(children: [SkeletonBox.fraction(widthFactor: 0.6)])));
    final parent = tester.getSize(find.byType(Scaffold)).width;
    final m = measureBones(tester.renderObject<RenderBox>(find.byType(FractionallySizedBox)), style);
    expect(m.shape.bones.single.rect.width, closeTo(parent * 0.6, 0.5));
  });
}

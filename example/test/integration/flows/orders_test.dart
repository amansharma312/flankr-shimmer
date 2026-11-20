import 'package:flankr_shimmer/flankr_shimmer.dart';
import 'package:flankr_shimmer_example/app/modules/orders/controller/orders_repository.dart';
import 'package:flankr_shimmer_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lets the orders load and the reveal finish. The standalone SkeletonBox
/// placeholders shimmer for ever, so the screen never settles; pump a fixed
/// time instead of pumpAndSettle.
Future<void> loadOrders(WidgetTester tester) async {
  await tester.pump(OrdersRepository.delay);
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  tearDown(forgetShapes);

  testWidgets('orders show a skeleton, then load and reload', (tester) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Easy Spin Laundry'), findsNothing);
    expect(find.bySemanticsLabel('Loading orders'), findsOneWidget);

    await loadOrders(tester);
    expect(find.text('Easy Spin Laundry'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Reload'));
    await loadOrders(tester);
    expect(find.text('Fresh Press'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the orders screen has no layout errors on a phone', (
    tester,
  ) async {
    tester.view.physicalSize =
        const Size(375, 812) * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ExampleApp());
    await loadOrders(tester);
    expect(find.byType(Card), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });
}

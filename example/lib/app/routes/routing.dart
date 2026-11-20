import 'package:flankr_shimmer/flankr_shimmer.dart';
import 'package:flankr_shimmer_example/app/modules/orders/screens/orders_screen.dart';
import 'package:flutter/widgets.dart';

abstract final class Routing {
  static const String home = '/';

  static final Map<String, WidgetBuilder> routes = {
    home: (context) => const FlankrProvider(
      theme: FlankrTheme(radius: 6),
      reveal: FlankrReveal.smart,
      child: OrdersScreen(),
    ),
  };
}

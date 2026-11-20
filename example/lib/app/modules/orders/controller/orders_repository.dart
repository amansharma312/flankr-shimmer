import 'package:flankr_shimmer_example/app/modules/orders/model/order_model.dart';

/// A fake orders API.
abstract final class OrdersRepository {
  /// How long a fetch takes; `--dart-define=DEMO_DELAY_MS=6000` to linger.
  static const Duration delay = Duration(
    milliseconds: int.fromEnvironment('DEMO_DELAY_MS', defaultValue: 2000),
  );

  static Future<List<Order>> fetch() => Future.delayed(
    delay,
    () => const [
      Order(
        'Easy Spin Laundry',
        'Wash & fold · 4 kg',
        '₹349',
        'Out for delivery',
      ),
      Order('Fresh Press', 'Dry clean · 2 shirts', '₹180', 'Delivered'),
      Order('Spin City', 'Ironing · 8 items', '₹120', 'Delivered'),
    ],
  );
}

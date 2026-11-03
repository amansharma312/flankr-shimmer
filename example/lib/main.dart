import 'package:flankr_shimmer/flankr_shimmer.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

class Order {
  const Order(this.store, this.items, this.total, this.status);

  final String store;
  final String items;
  final String total;
  final String status;

  static const sample = Order('Sample store name', '3 items · Sample summary', '₹000', 'Delivered');
}

/// How long the fake fetch takes; `--dart-define=DEMO_DELAY_MS=6000` to linger.
const int demoDelayMs = int.fromEnvironment('DEMO_DELAY_MS', defaultValue: 2000);

Future<List<Order>> fetchOrders() => Future.delayed(
      const Duration(milliseconds: demoDelayMs),
      () => const [
        Order('Easy Spin Laundry', 'Wash & fold · 4 kg', '₹349', 'Out for delivery'),
        Order('Fresh Press', 'Dry clean · 2 shirts', '₹180', 'Delivered'),
        Order('Spin City', 'Ironing · 8 items', '₹120', 'Delivered'),
      ],
    );

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flankr_shimmer',
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1E3A8A)),
      darkTheme: ThemeData(colorSchemeSeed: const Color(0xFF1E3A8A), brightness: Brightness.dark),
      home: const FlankrProvider(
        theme: FlankrTheme(radius: 6),
        reveal: FlankrReveal.smart,
        child: OrdersPage(),
      ),
    );
  }
}

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late Future<List<Order>> _orders = fetchOrders();

  void _reload() => setState(() => _orders = fetchOrders());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      body: SkeletonFuture<List<Order>>(
        id: 'orders',
        future: _orders,
        sample: const [Order.sample, Order.sample, Order.sample],
        label: 'Loading orders',
        builder: (context, orders) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final order in orders) OrderCard(order: order),
            const SizedBox(height: 24),
            const Text('Standalone placeholders'),
            const SizedBox(height: 8),
            const SkeletonBox.fraction(widthFactor: 0.6),
            const SizedBox(height: 8),
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: SkeletonBox(width: 48, height: 48, radius: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(radius: 22, child: Icon(Icons.local_laundry_service)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.store, style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(order.items, style: text.bodyMedium),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(order.total, style: text.titleMedium),
                const SizedBox(height: 4),
                Chip(label: Text(order.status), visualDensity: VisualDensity.compact),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

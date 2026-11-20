import 'package:flankr_shimmer/flankr_shimmer.dart';
import 'package:flankr_shimmer_example/app/modules/orders/controller/orders_repository.dart';
import 'package:flankr_shimmer_example/app/modules/orders/model/order_model.dart';
import 'package:flankr_shimmer_example/app/modules/orders/widgets/order_card.dart';
import 'package:flankr_shimmer_example/app/modules/orders/widgets/placeholders_section.dart';
import 'package:flankr_shimmer_example/app/resources/styles_manager.dart';
import 'package:flutter/material.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<Order>> _orders = OrdersRepository.fetch();

  void _reload() {
    // A block body: an arrow would hand setState the Future, which it rejects.
    setState(() {
      _orders = OrdersRepository.fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            onPressed: _reload,
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SkeletonFuture<List<Order>>(
        id: 'orders',
        future: _orders,
        sample: const [Order.sample, Order.sample, Order.sample],
        label: 'Loading orders',
        builder: (context, orders) => ListView(
          padding: StylesManager.screenPadding,
          children: [
            for (final order in orders) OrderCard(order: order),
            const PlaceholdersSection(),
          ],
        ),
      ),
    );
  }
}

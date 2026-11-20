import 'package:flankr_shimmer_example/app/modules/orders/model/order_model.dart';
import 'package:flankr_shimmer_example/app/resources/styles_manager.dart';
import 'package:flutter/material.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: StylesManager.cardGap),
      child: Padding(
        padding: StylesManager.cardPadding,
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              child: Icon(Icons.local_laundry_service),
            ),
            const SizedBox(width: StylesManager.cardGap),
            Expanded(
              flex: 3,
              child: _Lines(
                first: Text(order.store, style: text.titleMedium),
                second: Text(order.items, style: text.bodyMedium),
              ),
            ),
            const SizedBox(width: StylesManager.cardGap),
            // Flexible, so a long status wraps instead of pushing the row
            // past the edge of a narrow screen.
            Flexible(
              flex: 2,
              child: _Lines(
                alignment: CrossAxisAlignment.end,
                first: Text(order.total, style: text.titleMedium),
                second: Chip(
                  label: Text(order.status, textAlign: TextAlign.end),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two lines, one over the other.
class _Lines extends StatelessWidget {
  const _Lines({
    required this.first,
    required this.second,
    this.alignment = CrossAxisAlignment.start,
  });

  final Widget first;
  final Widget second;
  final CrossAxisAlignment alignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignment,
      children: [first, const SizedBox(height: 4), second],
    );
  }
}

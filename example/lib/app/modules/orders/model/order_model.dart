import 'package:flutter/foundation.dart';

@immutable
class Order {
  const Order(this.store, this.items, this.total, this.status);

  final String store;
  final String items;
  final String total;
  final String status;

  /// Stands in while the real orders load, to draw the first skeleton.
  static const sample = Order(
    'Sample store name',
    '3 items · Sample summary',
    '₹000',
    'Delivered',
  );
}

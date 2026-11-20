import 'package:flankr_shimmer/flankr_shimmer.dart';
import 'package:flutter/material.dart';

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
            const SizedBox(
                width: 40,
                height: 40,
                child: FlankrBlock(radius: 20, child: SizedBox.expand())),
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
        data: MediaQueryData(
            disableAnimations: disableAnimations, size: const Size(400, 800)),
        child: Scaffold(body: child),
      ),
    );

Skeleton<User> profile(
        {User? data, VoidCallback? onReveal, String? id, String? label}) =>
    Skeleton<User>(
      data: data,
      sample: sampleUser,
      id: id,
      label: label,
      onReveal: onReveal,
      builder: (context, user) => card(user),
    );

/// The default theme's style in light mode.
FlankrStyle get style => FlankrTheme.defaults.resolve(Brightness.light);

import 'package:flankr_shimmer_example/app/resources/styles_manager.dart';
import 'package:flankr_shimmer_example/app/routes/routing.dart';
import 'package:flutter/material.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'flankr_shimmer',
      theme: StylesManager.light,
      darkTheme: StylesManager.dark,
      initialRoute: Routing.home,
      routes: Routing.routes,
    );
  }
}

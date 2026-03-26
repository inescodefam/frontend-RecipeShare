import 'package:flutter/material.dart';

/// Entry point for the RecipeShare **mobile** app (iOS & Android).
/// Screens, routing, and providers will live under `lib/` as we build out the app.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RecipeShareMobileApp());
}

class RecipeShareMobileApp extends StatelessWidget {
  const RecipeShareMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecipeShare',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE8652A)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('RecipeShare Mobile — project scaffold'),
        ),
      ),
    );
  }
}

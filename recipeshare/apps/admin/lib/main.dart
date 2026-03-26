import 'package:flutter/material.dart';

/// Entry point for the RecipeShare **admin** web app (Flutter Web).
/// Dashboard layout and admin routes will be added in later steps.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RecipeShareAdminApp());
}

class RecipeShareAdminApp extends StatelessWidget {
  const RecipeShareAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecipeShare Admin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6A4F)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('RecipeShare Admin — project scaffold'),
        ),
      ),
    );
  }
}

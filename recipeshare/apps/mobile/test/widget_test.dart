import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/main.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/router/app_router.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

void main() {
  testWidgets('RecipeShare boots with router and providers', (tester) async {
    final services = RecipeShareServices.mock();
    final auth = AuthProvider(services.auth);
    final router = AppRouter.create(auth);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<RecipeShareServices>.value(value: services),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: RecipeShareMobileApp(router: router),
      ),
    );

    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

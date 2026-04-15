import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared/shared.dart';

class _AuthServiceForSettings implements AuthService {
  _AuthServiceForSettings(this.currentUser);

  User? currentUser;
  bool updateProfileResult = true;
  bool changeEmailResult = true;
  bool changePasswordResult = true;
  bool removeImageResult = true;
  String? nextError;

  int updateProfileCalls = 0;
  int changeEmailCalls = 0;
  int changePasswordCalls = 0;
  int removeImageCalls = 0;

  @override
  Future<User?> getCurrentUser() async => currentUser;

  @override
  Future<User> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<User> register({
    required String username,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<User> updateProfile({required String username, required String bio}) async {
    updateProfileCalls++;
    if (!updateProfileResult) {
      throw StateError(nextError ?? 'Could not update profile');
    }
    currentUser = (currentUser ?? _baseUser()).copyWith(
      username: username.trim(),
      bio: bio.trim(),
    );
    return currentUser!;
  }

  @override
  Future<User> changeEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    changeEmailCalls++;
    if (!changeEmailResult) {
      throw StateError(nextError ?? 'Could not update email');
    }
    currentUser = (currentUser ?? _baseUser()).copyWith(email: newEmail.trim());
    return currentUser!;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    changePasswordCalls++;
    if (!changePasswordResult) {
      throw StateError(nextError ?? 'Could not change password');
    }
  }

  @override
  Future<User> uploadProfileImage({
    required List<int> imageBytes,
    String? filename,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<User> removeProfileImage() async {
    removeImageCalls++;
    if (!removeImageResult) {
      throw StateError(nextError ?? 'Remove failed');
    }
    currentUser = (currentUser ?? _baseUser()).copyWith(profileImageUrl: '');
    return currentUser!;
  }
}

User _baseUser() => const User(
      id: 'u1',
      username: 'Alice',
      email: 'alice@example.com',
      passwordHash: 'hash',
      bio: 'Hello',
      profileImageUrl: '',
      isBlocked: false,
      isAdmin: false,
      followersCount: 0,
      followingCount: 0,
      recipesCount: 0,
    );

GoRouter _router(AuthProvider auth) {
  return GoRouter(
    initialLocation: '/home/profile/settings',
    routes: [
      GoRoute(
        path: '/home/profile/settings',
        builder: (_, __) => ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: const SettingsScreen(),
        ),
      ),
      GoRoute(
        path: '/home/profile',
        builder: (_, __) => const Scaffold(body: Text('profile-target')),
      ),
    ],
  );
}

void main() {
  testWidgets('shows loading state when user is null', (tester) async {
    final service = _AuthServiceForSettings(null);
    final auth = AuthProvider(service);
    await auth.init();

    await tester.pumpWidget(MaterialApp.router(routerConfig: _router(auth)));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('validates and submits profile form successfully', (tester) async {
    final service = _AuthServiceForSettings(_baseUser());
    final auth = AuthProvider(service);
    await auth.init();

    await tester.pumpWidget(MaterialApp.router(routerConfig: _router(auth)));
    await tester.pumpAndSettle();

    expect(find.text('Account settings'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'ab');
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(find.text('At least 3 characters'), findsOneWidget);
    expect(service.updateProfileCalls, 0);

    await tester.enterText(find.byType(TextFormField).at(0), 'Alice Updated');
    await tester.enterText(find.byType(TextFormField).at(1), 'New bio');
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(service.updateProfileCalls, 1);
    expect(find.text('Profile updated'), findsOneWidget);
  });

  testWidgets('submits email and password forms with validation', (tester) async {
    final service = _AuthServiceForSettings(_baseUser());
    final auth = AuthProvider(service);
    await auth.init();

    await tester.pumpWidget(MaterialApp.router(routerConfig: _router(auth)));
    await tester.pumpAndSettle();

    final updateEmailButton = find.widgetWithText(OutlinedButton, 'Update email');
    final changePasswordButton = find.widgetWithText(OutlinedButton, 'Change password');
    final emailField = find.bySemanticsLabel('Email');
    final emailPasswordField =
        find.bySemanticsLabel('Current password (to confirm email change)');
    final currentPasswordField = find.bySemanticsLabel('Current password');
    final newPasswordField = find.bySemanticsLabel('New password');
    final confirmPasswordField = find.bySemanticsLabel('Confirm new password');

    await tester.ensureVisible(updateEmailButton);
    await tester.enterText(emailField, 'bad_email');
    await tester.tap(updateEmailButton);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Required'), findsAtLeastNWidgets(1));
    expect(service.changeEmailCalls, 0);

    await tester.enterText(emailField, 'new@example.com');
    await tester.enterText(emailPasswordField, 'pw');
    await tester.ensureVisible(updateEmailButton);
    await tester.tap(updateEmailButton);
    await tester.pumpAndSettle();
    expect(service.changeEmailCalls, 1);
    expect(find.text('Email updated'), findsOneWidget);

    await tester.dragUntilVisible(
      changePasswordButton,
      find.byType(ListView),
      const Offset(0, -200),
    );
    await tester.enterText(currentPasswordField, 'pw');
    await tester.enterText(newPasswordField, '123456');
    await tester.enterText(confirmPasswordField, '123456');
    final buttonWidget = tester.widget<OutlinedButton>(changePasswordButton);
    expect(buttonWidget.onPressed, isNotNull);
    buttonWidget.onPressed!.call();
    await tester.pumpAndSettle();
    expect(service.changePasswordCalls, 1);
  });
}

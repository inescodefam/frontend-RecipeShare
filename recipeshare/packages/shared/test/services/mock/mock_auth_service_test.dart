import 'package:flutter_test/flutter_test.dart';
import 'package:shared/services/mock/mock_auth_service.dart';
import 'package:shared/services/mock/mock_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MockAuthService', () {
    test('login/register/getCurrentUser/logout flow', () async {
      final data = MockDataService();
      final service = MockAuthService(data);

      final user = await service.login(
        email: 'admin@recipeshare.local',
        password: 'not-empty',
      );
      expect(user.email, 'admin@recipeshare.local');
      expect((await service.getCurrentUser())?.id, user.id);

      final registered = await service.register(
        username: 'new user',
        email: 'new.user@example.com',
        password: 'secret123',
      );
      expect(registered.username, 'new user');
      expect(registered.email, 'new.user@example.com');
      expect((await service.getCurrentUser())?.id, registered.id);

      await service.logout();
      expect(await service.getCurrentUser(), isNull);
    });

    test('throws validation errors for bad login/register input', () async {
      final data = MockDataService();
      final service = MockAuthService(data);

      await expectLater(
        () => service.login(email: 'unknown@example.com', password: 'pw'),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        () => service.register(
          username: 'x',
          email: 'any@example.com',
          password: '123',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('profile and email updates mutate current session user', () async {
      final data = MockDataService();
      final service = MockAuthService(data);

      await service.login(email: 'admin@recipeshare.local', password: 'pw');

      final updatedProfile = await service.updateProfile(
        username: 'ChefUpdated',
        bio: 'Updated bio',
      );
      expect(updatedProfile.username, 'ChefUpdated');
      expect(updatedProfile.bio, 'Updated bio');

      final updatedEmail = await service.changeEmail(
        newEmail: 'chef.updated@example.com',
        currentPassword: 'pw',
      );
      expect(updatedEmail.email, 'chef.updated@example.com');
    });

    test('password/image actions validate and update fields', () async {
      final data = MockDataService();
      final service = MockAuthService(data);

      await service.login(email: 'admin@recipeshare.local', password: 'pw');

      await expectLater(
        () => service.changePassword(
          currentPassword: '',
          newPassword: '123456',
        ),
        throwsA(isA<StateError>()),
      );

      await service.changePassword(
        currentPassword: 'pw',
        newPassword: '123456',
      );

      final withImage = await service.uploadProfileImage(
        imageBytes: const [1, 2, 3, 4],
        filename: 'avatar.png',
      );
      expect(withImage.profileImageUrl, contains('picsum.photos/seed'));

      final noImage = await service.removeProfileImage();
      expect(noImage.profileImageUrl, '');
    });
  });
}

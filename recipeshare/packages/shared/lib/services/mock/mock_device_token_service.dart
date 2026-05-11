import '../device_token_service.dart';

class MockDeviceTokenService implements DeviceTokenService {
  @override
  Future<void> registerDeviceToken(String token) async {}

  @override
  Future<void> unregisterDeviceToken(String token) async {}
}

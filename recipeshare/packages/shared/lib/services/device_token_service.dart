abstract class DeviceTokenService {
  Future<void> registerDeviceToken(String token);

  Future<void> unregisterDeviceToken(String token);
}

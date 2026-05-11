import 'package:dio/dio.dart';

import '../device_token_service.dart';
import 'dio_error_message.dart';

class HttpDeviceTokenService implements DeviceTokenService {
  HttpDeviceTokenService(this._dio);

  final Dio _dio;

  @override
  Future<void> registerDeviceToken(String token) async {
    try {
      await _dio.post<void>(
        '/api/device-tokens',
        data: <String, dynamic>{'token': token},
      );
    } on DioException catch (e) {
      throw StateError(messageFromDio(e));
    }
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    try {
      final encoded = Uri.encodeComponent(token);
      await _dio.delete<void>('/api/device-tokens/$encoded');
    } on DioException catch (e) {
      throw StateError(messageFromDio(e));
    }
  }
}

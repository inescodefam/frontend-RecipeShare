import 'package:dio/dio.dart';

String messageFromDio(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    if (error.response?.statusCode == 403) {
      return 'You do not have permission (Admin role required).';
    }
    return error.message ?? 'Request failed';
  }
  return error.toString();
}

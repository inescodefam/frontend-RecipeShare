import 'package:dio/dio.dart';

import '../../models/admin_catalog_row.dart';
import 'admin_catalog_http.dart';
import 'dio_error_message.dart';

class HttpAdminTagsService implements AdminCatalogHttp {
  HttpAdminTagsService(this._dio);

  final Dio _dio;

  Future<List<AdminCatalogRow>> fetchAll() async {
    final res = await _dio.get<dynamic>('/api/admin/tags');
    final data = res.data;
    if (data is! List) return const [];
    return data
        .map((e) => AdminCatalogRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> create(String name) async {
    final res = await _dio.post<dynamic>(
      '/api/admin/tags',
      data: {'name': name.trim()},
    );
    final raw = res.data;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    throw StateError('Unexpected create response');
  }

  Future<void> update(int id, String name) async {
    await _dio.put<void>(
      '/api/admin/tags/$id',
      data: {'name': name.trim()},
    );
  }

  Future<void> delete(int id) async {
    await _dio.delete<void>('/api/admin/tags/$id');
  }

  Future<void> toggleActive(int id) async {
    await _dio.patch<void>('/api/admin/tags/$id/toggle-IsActive');
  }

  String messageFromError(Object e) => messageFromDio(e);
}

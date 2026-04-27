import 'package:dio/dio.dart';

import '../../models/models.dart';
import '../collection_service.dart';
import 'dio_error_message.dart';

class HttpCollectionService implements CollectionService {
  HttpCollectionService(this._dio);

  final Dio _dio;

  @override
  Future<List<Collection>> getMyCollections() async {
    try {
      final res = await _dio.get<List<dynamic>>('/api/collections');
      final list = res.data ?? const [];
      return list
          .map((e) => Collection.fromApiJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw StateError(messageFromDio(e));
    }
  }

  @override
  Future<Collection> createCollection(String name) async {
    try {
      final res = await _dio.post<dynamic>(
        '/api/collections',
        data: <String, dynamic>{'name': name.trim()},
      );
      final id = int.tryParse('${res.data}');
      if (id == null) {
        throw StateError('Create collection succeeded but id is missing');
      }
      return Collection(
        id: '$id',
        userId: '',
        name: name.trim(),
        recipeIds: const [],
      );
    } on DioException catch (e) {
      throw StateError(messageFromDio(e));
    }
  }

  @override
  Future<void> addRecipeToCollection(String collectionId, String recipeId) async {
    try {
      await _dio.post<void>('/api/collections/$collectionId/recipes/$recipeId');
    } on DioException catch (e) {
      throw StateError(messageFromDio(e));
    }
  }

  @override
  Future<void> removeRecipeFromCollection(String collectionId, String recipeId) async {
    try {
      await _dio.delete<void>('/api/collections/$collectionId/recipes/$recipeId');
    } on DioException catch (e) {
      throw StateError(messageFromDio(e));
    }
  }

  @override
  Future<List<Recipe>> getCollectionRecipes(String collectionId) async {
    try {
      final res = await _dio.get<List<dynamic>>('/api/collections/$collectionId/recipes');
      final list = res.data ?? const [];
      return list
          .map((e) => Recipe.fromApiSummary(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw StateError(messageFromDio(e));
    }
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    try {
      await _dio.delete<void>('/api/collections/$collectionId');
    } on DioException catch (e) {
      throw StateError(messageFromDio(e));
    }
  }
}

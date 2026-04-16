import 'package:dio/dio.dart';

import '../../models/models.dart';
import '../../models/recipe_write_payload.dart';
import '../recipe_service.dart';

class HttpRecipeService implements RecipeService {
  HttpRecipeService(this._dio);

  final Dio _dio;

  String _messageFromDio(DioException e) {
    final data = e.response?.data;
    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }
    if (data is Map) {
      final err = data['error'];
      if (err != null) return err.toString();
      final title = data['title'];
      if (title != null) return title.toString();
    }
    return e.message ?? 'Request failed';
  }

  RecipePage _mapPage(Map<String, dynamic> data) {
    final raw = data['items'] as List<dynamic>? ?? const [];
    final items = raw
        .map((e) => Recipe.fromApiSummary(e as Map<String, dynamic>))
        .toList();
    final next = data['nextCursor'];
    final nextCursor = next is int ? next : int.tryParse('$next');
    final hasMore = data['hasMore'] as bool? ?? false;
    return RecipePage(
      items: items,
      hasMore: hasMore,
      nextCursor: nextCursor,
    );
  }

  @override
  Future<RecipePage> getFeedPage(
    String userId, {
    int? cursor,
    int pageSize = 10,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/recipes',
        queryParameters: <String, dynamic>{
          'followingOnly': true,
          'pageSize': pageSize,
          if (cursor != null) 'cursor': cursor,
        },
      );
      final data = res.data;
      if (data == null) {
        return const RecipePage(items: [], hasMore: false);
      }
      return _mapPage(data);
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<RecipePage> getExplorePage({
    int? cursor,
    int pageSize = 10,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/recipes',
        queryParameters: <String, dynamic>{
          'pageSize': pageSize,
          if (cursor != null) 'cursor': cursor,
        },
      );
      final data = res.data;
      if (data == null) {
        return const RecipePage(items: [], hasMore: false);
      }
      return _mapPage(data);
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<List<Recipe>> getFeatured() async {
    final page = await getExplorePage(pageSize: 50);
    return page.items.where((r) => r.isFeature).toList();
  }

  @override
  Future<Recipe> getRecipeById(String id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/api/recipes/$id');
      final data = res.data;
      if (data == null) throw StateError('Empty recipe response');
      return Recipe.fromApiDetail(data);
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  int? _parseCreatedId(Response<dynamic> response) {
    final loc = response.headers.value('location') ??
        response.headers.value('Location');
    if (loc == null || loc.isEmpty) return null;
    final uri = Uri.parse(loc);
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segs.isEmpty) return null;
    return int.tryParse(segs.last);
  }

  @override
  Future<String> createRecipeWithPayload(
    RecipeWritePayload payload, {
    String? ownerUserId,
  }) async {
    try {
      final res = await _dio.post<dynamic>(
        '/api/recipes',
        data: payload.toCreateJson(),
      );
      final fromHeader = _parseCreatedId(res);
      if (fromHeader != null) return '$fromHeader';
      throw StateError('Create recipe succeeded but id could not be determined');
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<void> updateRecipeWithPayload(String id, RecipeWritePayload payload) async {
    try {
      await _dio.put<void>(
        '/api/recipes/$id',
        data: payload.toUpdateJson(),
      );
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<void> deleteRecipe(String id) async {
    try {
      await _dio.delete<void>('/api/recipes/$id');
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<String> uploadRecipeImage(
    String recipeId,
    List<int> bytes, {
    String? filename,
  }) async {
    try {
      final form = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: filename ?? 'recipe.jpg',
        ),
      });
      final res = await _dio.put<Map<String, dynamic>>(
        '/api/recipes/$recipeId/image',
        data: form,
      );
      final url = res.data?['url'] as String?;
      if (url != null && url.isNotEmpty) return url;
      throw StateError('Upload succeeded but URL was missing');
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<void> deleteRecipeImage(String recipeId) async {
    try {
      await _dio.delete<void>('/api/recipes/$recipeId/image');
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<List<CategoryTag>> listRecipeCategories() async {
    try {
      final res = await _dio.get<List<dynamic>>('/api/categories');
      final list = res.data ?? const [];
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return CategoryTag(
          id: '${m['id']}',
          name: m['name'] as String? ?? '',
          type: CategoryTagType.category,
          recipeCount: m['recipeCount'] as int? ?? 0,
        );
      }).toList();
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<List<CategoryTag>> listRecipeTags() async {
    try {
      final res = await _dio.get<List<dynamic>>('/api/tags');
      final list = res.data ?? const [];
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return CategoryTag(
          id: '${m['id']}',
          name: m['name'] as String? ?? '',
          type: CategoryTagType.tag,
          recipeCount: m['recipeCount'] as int? ?? 0,
        );
      }).toList();
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<void> likeRecipe(String recipeId, String userId) async {
    throw UnimplementedError('Likes API not wired yet');
  }

  @override
  Future<void> unlikeRecipe(String recipeId, String userId) async {
    throw UnimplementedError('Likes API not wired yet');
  }

  @override
  Future<void> rateRecipe(String recipeId, String userId, int stars) async {
    throw UnimplementedError('Ratings API not wired yet');
  }
}

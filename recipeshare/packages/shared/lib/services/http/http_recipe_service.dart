import 'package:dio/dio.dart';

import '../../models/models.dart';
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
        '/api/feed',
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
  Future<RecipePage> getExplorePage({
    String? search,
    String? categoryId,
    List<String> tagIds = const [],
    int? cursor,
    int pageSize = 10,
  }) async {
    final parsedCategoryId = int.tryParse(categoryId ?? '');
    final parsedTagIds = tagIds
        .map((id) => int.tryParse(id))
        .whereType<int>()
        .toList();
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/feed/explore',
        queryParameters: <String, dynamic>{
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (parsedCategoryId != null) 'categoryId': parsedCategoryId,
          if (parsedTagIds.isNotEmpty) 'tagIds': parsedTagIds,
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
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/feed/featured',
        queryParameters: const <String, dynamic>{'pageSize': 10},
      );
      final data = res.data;
      if (data == null) return const [];
      return _mapPage(data).items;
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
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
  Future<ToggleLikeResult> toggleLikeRecipe(String recipeId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/api/recipes/$recipeId/like');
      final data = res.data ?? const <String, dynamic>{};
      return ToggleLikeResult(
        isLiked: data['isLiked'] as bool? ?? false,
        likeCount: data['likeCount'] as int? ?? 0,
      );
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }

  @override
  Future<RatingSummary> rateRecipe(String recipeId, int stars) async {
    final clamped = stars.clamp(1, 5);
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/api/recipes/$recipeId/rating',
        data: <String, dynamic>{'value': clamped},
      );
      final data = res.data ?? const <String, dynamic>{};
      return RatingSummary(
        myRating: data['myRating'] as int?,
        averageRating: (data['averageRating'] as num?)?.toDouble() ?? 0,
        ratingCount: data['ratingCount'] as int? ?? 0,
      );
    } on DioException catch (e) {
      throw StateError(_messageFromDio(e));
    }
  }
}

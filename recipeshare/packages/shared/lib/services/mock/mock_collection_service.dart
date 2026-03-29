import '../collection_service.dart';
import '../../models/models.dart';
import 'mock_data_service.dart';

class MockCollectionService implements CollectionService {
  MockCollectionService(this._data);

  final MockDataService _data;

  @override
  Future<List<Collection>> getCollectionsForUser(String userId) async {
    return _data.getCollectionsByUserId(userId);
  }

  @override
  Future<Collection> createCollection(String userId, String name) async {
    final c = Collection(
      id: 'col_${_data.newId()}',
      userId: userId,
      name: name.trim(),
      recipeIds: const [],
    );
    await _data.upsertCollection(c);
    return c;
  }

  @override
  Future<void> addRecipeToCollection(String collectionId, String recipeId) async {
    final existing = await _data.getCollectionById(collectionId);
    if (existing == null) {
      throw StateError('Collection not found: $collectionId');
    }
    if (existing.recipeIds.contains(recipeId)) return;
    await _data.upsertCollection(
      Collection(
        id: existing.id,
        userId: existing.userId,
        name: existing.name,
        recipeIds: [...existing.recipeIds, recipeId],
      ),
    );
  }

  @override
  Future<void> removeRecipeFromCollection(
    String collectionId,
    String recipeId,
  ) async {
    final existing = await _data.getCollectionById(collectionId);
    if (existing == null) {
      throw StateError('Collection not found: $collectionId');
    }
    await _data.upsertCollection(
      Collection(
        id: existing.id,
        userId: existing.userId,
        name: existing.name,
        recipeIds: existing.recipeIds.where((id) => id != recipeId).toList(),
      ),
    );
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    await _data.deleteCollectionById(collectionId);
  }
}

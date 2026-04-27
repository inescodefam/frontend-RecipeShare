import '../collection_service.dart';
import '../../models/models.dart';
import 'mock_data_service.dart';

class MockCollectionService implements CollectionService {
  MockCollectionService(this._data);

  final MockDataService _data;

  @override
  Future<List<Collection>> getMyCollections() async {
    return _data.getAllCollections();
  }

  @override
  Future<Collection> createCollection(String name) async {
    final c = Collection(
      id: 'col_${_data.newId()}',
      userId: 'mock-user',
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
  Future<List<Recipe>> getCollectionRecipes(String collectionId) async {
    final collection = await _data.getCollectionById(collectionId);
    if (collection == null) return const [];
    final all = await _data.getRecipes();
    final recipeIds = collection.recipeIds.toSet();
    return all.where((recipe) => recipeIds.contains(recipe.id)).toList();
  }

  @override
  Future<void> deleteCollection(String collectionId) async {
    await _data.deleteCollectionById(collectionId);
  }
}

import '../models/models.dart';

abstract class CollectionService {
  Future<List<Collection>> getCollectionsForUser(String userId);

  Future<Collection> createCollection(String userId, String name);

  Future<void> addRecipeToCollection(String collectionId, String recipeId);

  Future<void> removeRecipeFromCollection(String collectionId, String recipeId);

  Future<void> deleteCollection(String collectionId);
}

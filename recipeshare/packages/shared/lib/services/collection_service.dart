import '../models/models.dart';

abstract class CollectionService {
  Future<List<Collection>> getMyCollections();

  Future<Collection> createCollection(String name);

  Future<void> addRecipeToCollection(String collectionId, String recipeId);

  Future<void> removeRecipeFromCollection(String collectionId, String recipeId);

  Future<List<Recipe>> getCollectionRecipes(String collectionId);

  Future<void> deleteCollection(String collectionId);
}

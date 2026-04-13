import '../../models/admin_catalog_row.dart';

abstract class AdminCatalogHttp {
  Future<List<AdminCatalogRow>> fetchAll();

  Future<int> create(String name);

  Future<void> update(int id, String name);

  Future<void> delete(int id);

  Future<void> toggleActive(int id);

  String messageFromError(Object e);
}

import 'package:dio/dio.dart';

import 'admin_service.dart';
import 'http/auth_session_storage.dart';
import 'auth_service.dart';
import 'collection_service.dart';
import 'comment_service.dart';
import 'recipe_service.dart';
import 'report_service.dart';
import 'user_service.dart';
import 'http/http_auth_service.dart';
import 'http/http_recipe_service.dart';
import 'http/http_user_service.dart';
import 'mock/mock_admin_service.dart';
import 'mock/mock_auth_service.dart';
import 'mock/mock_collection_service.dart';
import 'mock/mock_comment_service.dart';
import 'mock/mock_data_service.dart';
import 'mock/mock_recipe_service.dart';
import 'mock/mock_report_service.dart';
import 'mock/mock_user_service.dart';

class RecipeShareServices {
  RecipeShareServices({
    required this.data,
    required this.auth,
    required this.recipes,
    required this.users,
    required this.comments,
    required this.collections,
    required this.reports,
    required this.admin,
  });

  final MockDataService data;

  final AuthService auth;
  final RecipeService recipes;
  final UserService users;
  final CommentService comments;
  final CollectionService collections;
  final ReportService reports;
  final AdminService admin;

  factory RecipeShareServices.mock() {
    final data = MockDataService();
    return RecipeShareServices(
      data: data,
      auth: MockAuthService(data),
      recipes: MockRecipeService(data),
      users: MockUserService(data),
      comments: MockCommentService(data),
      collections: MockCollectionService(data),
      reports: MockReportService(data),
      admin: MockAdminService(data),
    );
  }


  factory RecipeShareServices.api(Dio dio, AuthSessionStorage session) {
    final data = MockDataService();
    return RecipeShareServices(
      data: data,
      auth: HttpAuthService(dio, session: session),
      recipes: HttpRecipeService(dio),
      users: HttpUserService(dio),
      comments: MockCommentService(data),
      collections: MockCollectionService(data),
      reports: MockReportService(data),
      admin: MockAdminService(data),
    );
  }
}

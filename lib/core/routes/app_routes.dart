import 'package:get/get.dart';
import 'package:seizure_app/core/middlewares/auth_middleware.dart';
import 'package:seizure_app/features/login/view_models/login_view_model.dart';
import 'package:seizure_app/features/login/views/login_view.dart';
import 'package:seizure_app/features/root/root_view.dart';

abstract class AppRoutes {
  static const String root = '/';
  static const String login = '/login';
  static const String profile = '/profile';
}

final String initialRoute = AppRoutes.root;

final List<GetPage> routes = [
  GetPage(name: AppRoutes.root, page: () => RootView(), middlewares: [AuthMiddleware()]),
  GetPage(name: AppRoutes.login, page: () => LoginView(), binding: LoginBinding()),
];

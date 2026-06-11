import 'package:get/get.dart';
import 'package:seizure_app/core/middlewares/auth_middleware.dart';
import 'package:seizure_app/features/alert_history/alert_history_view.dart';
import 'package:seizure_app/features/alert_history/view_models/alert_history_view_model.dart';
import 'package:seizure_app/features/login/view_models/login_view_model.dart';
import 'package:seizure_app/features/login/views/login_view.dart';
import 'package:seizure_app/features/onboarding/onboarding_view.dart';
import 'package:seizure_app/features/root/root_view.dart';
import 'package:seizure_app/features/signup/view_models/signup_view_model.dart';
import 'package:seizure_app/features/signup/views/signup_view.dart';

abstract class AppRoutes {
  static const String root = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';
  static const String profile = '/profile';
  static const String alertHistory = '/alert-history';
}

final String initialRoute = AppRoutes.root;

final List<GetPage> routes = [
  GetPage(name: AppRoutes.root, page: () => RootView(), middlewares: [AuthMiddleware()]),
  GetPage(name: AppRoutes.login, page: () => LoginView(), binding: LoginBinding()),
  GetPage(name: AppRoutes.signup, page: () => SignupView(), binding: SignupBinding()),
  GetPage(name: AppRoutes.onboarding, page: () => OnboardingView(), middlewares: [AuthMiddleware()]),
  GetPage(
    name: AppRoutes.alertHistory,
    page: () => const AlertHistoryView(),
    binding: AlertHistoryBinding(),
  ),
];

import 'package:get/get.dart';
import 'package:seizure_app/core/middlewares/auth_middleware.dart';
import 'package:seizure_app/features/alert_history/alert_history_view.dart';
import 'package:seizure_app/features/alert_history/view_models/alert_history_view_model.dart';
import 'package:seizure_app/features/caregiver/caregiver_view.dart';
import 'package:seizure_app/features/caregiver/incoming_alert_view.dart';
import 'package:seizure_app/features/caregiver/view_models/caregiver_view_model.dart';
import 'package:seizure_app/features/caregiver/view_models/incoming_alert_view_model.dart';
import 'package:seizure_app/features/circle_invite/circle_invite_view.dart';
import 'package:seizure_app/features/circle_invite/view_models/circle_invite_view_model.dart';
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
  static const String caregiverMode = '/caregiver-mode';
  static const String incomingAlert = '/incoming-alert';
  static const String circleInvite = '/circle-invite';
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
  GetPage(
    name: AppRoutes.caregiverMode,
    page: () => const CaregiverView(),
    binding: CaregiverBinding(),
  ),
  GetPage(
    name: AppRoutes.incomingAlert,
    page: () => const IncomingAlertView(),
    binding: IncomingAlertBinding(),
  ),
  GetPage(
    name: AppRoutes.circleInvite,
    page: () => const CircleInviteView(),
    binding: CircleInviteBinding(),
  ),
];

import 'package:get/get.dart';
import 'package:seizure_app/features/analytics/analytics_view.dart';
import 'package:seizure_app/features/analytics/view_models/analytics_view_model.dart';
import 'package:seizure_app/core/middlewares/auth_middleware.dart';
import 'package:seizure_app/features/alert_history/alert_history_view.dart';
import 'package:seizure_app/features/alert_history/view_models/alert_history_view_model.dart';
import 'package:seizure_app/features/caregiver/incoming_alert_view.dart';
import 'package:seizure_app/features/caregiver/responding_view.dart';
import 'package:seizure_app/features/caregiver/view_models/incoming_alert_view_model.dart';
import 'package:seizure_app/features/caregiver/view_models/responding_view_model.dart';
import 'package:seizure_app/features/circle_invite/circle_invite_view.dart';
import 'package:seizure_app/features/circle_invite/view_models/circle_invite_view_model.dart';
import 'package:seizure_app/features/login/view_models/login_view_model.dart';
import 'package:seizure_app/features/login/views/login_view.dart';
import 'package:seizure_app/features/onboarding/onboarding_view.dart';
import 'package:seizure_app/features/onboarding/view_models/onboarding_view_model.dart';
import 'package:seizure_app/features/root/root_view.dart';
import 'package:seizure_app/features/signup/view_models/signup_view_model.dart';
import 'package:seizure_app/features/mode/mode_view.dart';
import 'package:seizure_app/features/mode/view_models/mode_view_model.dart';
import 'package:seizure_app/features/signup/views/signup_view.dart';
import 'package:seizure_app/features/splash/splash_view.dart';
import 'package:seizure_app/features/support/support_view.dart';
import 'package:seizure_app/features/safety_plan/safety_plan_view.dart';
import 'package:seizure_app/features/safety_plan/view_models/safety_plan_view_model.dart';
import 'package:seizure_app/features/safety_readiness/safety_readiness_view.dart';
import 'package:seizure_app/features/safety_readiness/view_models/safety_readiness_view_model.dart';

abstract class AppRoutes {
  static const String analytics = '/insights';
  static const String splash = '/splash';
  static const String root = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';
  static const String profile = '/profile';
  static const String alertHistory = '/alert-history';
  static const String incomingAlert = '/incoming-alert';
  static const String circleInvite = '/circle-invite';
  static const String mode = '/mode';
  static const String responding = '/responding';
  static const String support = '/support';
  static const String safetyPlan = '/safety-plan';
  static const String safetyReadiness = '/safety-readiness';
  static const String redirectArgument = 'redirectRoute';
}

final String initialRoute = AppRoutes.splash;

final List<GetPage> routes = [
  GetPage(
    name: AppRoutes.analytics,
    page: () => const AnalyticsView(),
    binding: AnalyticsBinding(),
    middlewares: [AuthMiddleware()],
  ),
  GetPage(name: AppRoutes.splash, page: () => SplashView()),
  GetPage(
    name: AppRoutes.root,
    page: () => const RootView(),
    binding: RootBinding(),
    middlewares: [AuthMiddleware()],
  ),
  GetPage(
    name: AppRoutes.login,
    page: () => LoginView(),
    binding: LoginBinding(),
  ),
  GetPage(
    name: AppRoutes.signup,
    page: () => SignupView(),
    binding: SignupBinding(),
  ),
  GetPage(
    name: AppRoutes.onboarding,
    page: () => const OnboardingView(),
    binding: OnboardingBinding(),
  ),
  GetPage(
    name: AppRoutes.alertHistory,
    page: () => const AlertHistoryView(),
    binding: AlertHistoryBinding(),
    middlewares: [AuthMiddleware()],
  ),
  GetPage(
    name: AppRoutes.incomingAlert,
    page: () => const IncomingAlertView(),
    binding: IncomingAlertBinding(),
    middlewares: [AuthMiddleware()],
  ),
  GetPage(
    name: AppRoutes.circleInvite,
    page: () => const CircleInviteView(),
    binding: CircleInviteBinding(),
    middlewares: [AuthMiddleware()],
  ),
  GetPage(
    name: AppRoutes.mode,
    page: () => const ModeView(),
    binding: ModeBinding(),
    middlewares: [AuthMiddleware()],
  ),
  GetPage(
    name: AppRoutes.responding,
    page: () => const RespondingView(),
    binding: RespondingBinding(),
    middlewares: [AuthMiddleware()],
  ),
  GetPage(
    name: AppRoutes.support,
    page: () => const SupportView(),
    middlewares: [AuthMiddleware()],
  ),
  GetPage(
    name: AppRoutes.safetyPlan,
    page: () => const SafetyPlanView(),
    binding: SafetyPlanBinding(),
    middlewares: [AuthMiddleware()],
  ),
  GetPage(
    name: AppRoutes.safetyReadiness,
    page: () => const SafetyReadinessView(),
    binding: SafetyReadinessBinding(),
    middlewares: [AuthMiddleware()],
  ),
];

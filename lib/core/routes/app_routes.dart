import 'package:get/get.dart';
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

abstract class AppRoutes {
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
}

final String initialRoute = AppRoutes.splash;

final List<GetPage> routes = [
  GetPage(name: AppRoutes.splash, page: () => SplashView()),
  GetPage(
    name: AppRoutes.root,
    page: () => const RootView(),
    binding: RootBinding(),
    middlewares: [AuthMiddleware()],
  ),
  GetPage(name: AppRoutes.login, page: () => LoginView(), binding: LoginBinding()),
  GetPage(name: AppRoutes.signup, page: () => SignupView(), binding: SignupBinding()),
  GetPage(
    name: AppRoutes.onboarding,
    page: () => const OnboardingView(),
    binding: OnboardingBinding(),
  ),
  GetPage(name: AppRoutes.alertHistory, page: () => const AlertHistoryView(), binding: AlertHistoryBinding()),
  GetPage(name: AppRoutes.incomingAlert, page: () => const IncomingAlertView(), binding: IncomingAlertBinding()),
  GetPage(name: AppRoutes.circleInvite, page: () => const CircleInviteView(), binding: CircleInviteBinding()),
  GetPage(name: AppRoutes.mode, page: () => const ModeView(), binding: ModeBinding(), middlewares: [AuthMiddleware()]),
  GetPage(name: AppRoutes.responding, page: () => const RespondingView(), binding: RespondingBinding()),
];

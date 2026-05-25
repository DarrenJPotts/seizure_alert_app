import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/routes/route_middleware.dart';
import 'package:seizure_app/core/controllers/firebase_auth_controller/firebase_auth_controller.dart';
import 'package:seizure_app/core/routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final FirebaseAuthController authService = FirebaseAuthController.instance();
    return authService.isLoggedIn.value ? null : RouteSettings(name: AppRoutes.login);
  }
}
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get_navigation/src/routes/route_middleware.dart';
import 'package:seizure_app/core/routes/app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    if (FirebaseAuth.instance.currentUser != null) return null;

    return RouteSettings(
      name: AppRoutes.login,
      arguments: <String, String?>{AppRoutes.redirectArgument: route},
    );
  }
}

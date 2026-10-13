import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seizure_app/core/controllers/firebase_auth_controller/firebase_auth_controller.dart';

class CreatedUser extends Fake implements User {
  @override
  Future<void> sendEmailVerification([
    ActionCodeSettings? actionCodeSettings,
  ]) async => throw FirebaseAuthException(code: 'network-request-failed');
}

class CreatedCredential extends Fake implements UserCredential {
  @override
  User? get user => CreatedUser();
}

class RegistrationAuth extends Fake implements FirebaseAuth {
  int created = 0;
  @override
  User? get currentUser => null;
  @override
  Future<void> signOut() async {}
  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    created++;
    return CreatedCredential();
  }
}

void main() {
  tearDown(Get.reset);
  testWidgets('verification delivery failure does not fail account creation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const GetMaterialApp(home: Scaffold()));
    final auth = RegistrationAuth();
    await FirebaseAuthController(
      auth: auth,
    ).registerUser('test@example.com', 'password123');
    expect(auth.created, 1);
    await tester.pumpAndSettle();
    expect(find.text('Account created'), findsOneWidget);
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
  });
}

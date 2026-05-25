import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/shared_pref_keys.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseAuthController extends GetxController {
  FirebaseAuthController();

  static FirebaseAuthController instance() => Get.isRegistered<FirebaseAuthController>()
      ? Get.find<FirebaseAuthController>()
      : Get.put<FirebaseAuthController>(FirebaseAuthController(), permanent: true);

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final StreamSubscription _userDataSubscription;
  final Rxn<User> user = Rxn<User>();
  final RxBool isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();

    _userDataSubscription = FirebaseAuth.instance.userChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        user.value = firebaseUser;
        isLoggedIn.value = true;
      } else {
        user.value = null;
        isLoggedIn.value = false;
      }
    });
  }

  @override
  void onClose() {
    _userDataSubscription.cancel();
    super.onClose();
  }

  Future<ResultDto<User>> signIn(String email, String password) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

      user.value = credential.user;
      isLoggedIn.value = true;

      _storeUser();

      return ResultDto.success(credential.user!);
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Try again later';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Check your connection';
          break;
        default:
          errorMessage = 'Invalid email or password. Please try again.';
      }

      return ResultDto.failure(errorMessage);
    } catch (e) {
      return ResultDto.failure('An unexpected error occurred');
    }
  }

  Future<void> registerUser(String emailAddress, String password) async {
    await FirebaseAuth.instance.signOut();
    await FirebaseAuth.instance.createUserWithEmailAndPassword(email: emailAddress, password: password);
  }

  Future<void> signOut() async {
    FirebaseAuth.instance.signOut();
    await _clearData();
  }

  Future<void> _storeUser() async {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    final User? currentUser = user.value;
    if (currentUser == null) return;

    final userMap = {
      'uid': currentUser.uid,
      'email': currentUser.email,
      'displayName': currentUser.displayName,
      'photoURL': currentUser.photoURL,
    };

    sharedPreferences.setString(SharedPrefKeys.currentUser, jsonEncode(userMap));
  }

  Future<Map<String, dynamic>?> getStoredUser() async {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    final String? userJson = sharedPreferences.getString(SharedPrefKeys.currentUser);
    if (userJson == null) return null;
    return jsonDecode(userJson) as Map<String, dynamic>;
  }

  Future<void> _clearData() async {
    final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.clear();
    user.value = null;
    isLoggedIn.value = false;
  }
}

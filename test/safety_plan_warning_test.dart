import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/services/firebase_collections_service.dart';
import 'package:seizure_app/features/safety_plan/safety_plan_view.dart';
import 'package:seizure_app/features/safety_plan/view_models/safety_plan_view_model.dart';

class LoadedPlan extends SafetyPlanViewModel {
  LoadedPlan({this.loaded = true})
    : super(FirestoreService(FakeFirebaseFirestore()));
  final bool loaded;
  @override
  bool get hasLoadedPlan => loaded;
  @override
  Future<void> load() async {
    loading.value = false;
    actionPlanController.text = 'Keep this instruction';
    error.value =
        'Safety plan saved. Enable notifications to receive reminders.';
  }
}

void main() {
  tearDown(Get.reset);
  testWidgets('scheduling warnings preserve the form and edits', (
    tester,
  ) async {
    Get.put<SafetyPlanViewModel>(LoadedPlan());
    await tester.pumpWidget(const GetMaterialApp(home: SafetyPlanView()));
    expect(find.text('Keep this instruction'), findsOneWidget);
    expect(
      find.text(
        'Safety plan saved. Enable notifications to receive reminders.',
      ),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Save safety plan'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Save safety plan'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('initial load errors still offer retry', (tester) async {
    Get.put<SafetyPlanViewModel>(LoadedPlan(loaded: false));
    await tester.pumpWidget(const GetMaterialApp(home: SafetyPlanView()));
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}

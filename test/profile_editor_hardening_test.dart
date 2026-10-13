import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/features/profile/views/widgets/edit_profile_bottom_sheet.dart';

void main() {
  testWidgets(
    'dismissing profile editor during a save does not update disposed state',
    (tester) async {
      final pending = Completer<bool>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditProfileBottomSheet(
              user: UserDto(
                uid: 'user',
                email: 'test@example.com',
                displayName: 'Test User',
              ),
              onSave:
                  ({
                    required displayName,
                    phone,
                    bloodType,
                    seizureType,
                    medications,
                    emergencyNote,
                  }) => pending.future,
            ),
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Save'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      pending.complete(false);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('unexpected profile save failure leaves an actionable error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: EditProfileBottomSheet(
            user: UserDto(
              uid: 'user',
              email: 'test@example.com',
              displayName: 'Test User',
            ),
            onSave:
                ({
                  required displayName,
                  phone,
                  bloodType,
                  seizureType,
                  medications,
                  emergencyNote,
                }) async => throw StateError('offline'),
          ),
        ),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Save'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(
      find.text('Your profile could not be saved. Please try again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

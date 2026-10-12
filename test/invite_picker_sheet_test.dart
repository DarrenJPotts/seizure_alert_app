import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/dtos/result_dto.dart';
import 'package:seizure_app/features/contacts/widgets/invite_picker_sheet.dart';

void main() {
  testWidgets(
    'drawer shows immediately and centres loading inside code section',
    (tester) async {
      final pending = Completer<ResultDto<String>>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InvitePickerSheet(
              phone: '+27821234567',
              contactName: 'Test contact',
              loadCode: () => pending.future,
            ),
          ),
        ),
      );
      expect(find.text('Invite Test contact'), findsOneWidget);
      expect(find.text('Via SMS'), findsOneWidget);
      final loader = find.byType(CircularProgressIndicator);
      expect(loader, findsOneWidget);
      expect(
        tester.getCenter(loader).dx,
        closeTo(
          tester.view.physicalSize.width / tester.view.devicePixelRatio / 2,
          0.1,
        ),
      );
      final share = tester.widget<InkWell>(
        find
            .ancestor(of: find.text('Via SMS'), matching: find.byType(InkWell))
            .first,
      );
      expect(share.onTap, isNull);
      pending.complete(ResultDto.success('123456'));
      await tester.pump();
      expect(loader, findsNothing);
      expect(find.text('123456'), findsOneWidget);
    },
  );

  testWidgets('failed code load offers inline retry', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InvitePickerSheet(
            phone: '',
            contactName: 'Test',
            loadCode: () async => ++attempts == 1
                ? ResultDto.failure('Try again')
                : ResultDto.success('654321'),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Invite Test'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(find.text('654321'), findsOneWidget);
    expect(attempts, 2);
  });
}

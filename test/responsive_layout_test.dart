// Regression coverage for narrow screens, large text, and both appearances.
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/features/contacts/widgets/add_contact_bottom_sheet.dart';
import 'package:seizure_app/features/contacts/widgets/contact_card.dart';
import 'package:seizure_app/features/sos/widgets/contact_status_row.dart';
import 'package:seizure_app/features/sos/widgets/active_heads_up_card.dart';
import 'package:seizure_app/features/seizure_log/widgets/seizure_log_row.dart';
import 'package:seizure_app/features/alert_history/widgets/alert_history_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seizure_app/core/themes/app_theme.dart';
import 'package:seizure_app/core/dtos/seizure_log_dto.dart';
import 'package:seizure_app/core/dtos/user_dto.dart';
import 'package:seizure_app/core/widgets/app_dropdown_field.dart';
import 'package:seizure_app/features/seizure_log/widgets/add_seizure_log_bottom_sheet.dart';
import 'package:seizure_app/features/seizure_log/widgets/seizure_calendar_summary.dart';
import 'package:seizure_app/features/profile/views/widgets/edit_profile_bottom_sheet.dart';
import 'package:seizure_app/features/home/widgets/activity_grid.dart';
import 'package:seizure_app/features/sos/widgets/sos_heads_up_options_card.dart';
import 'package:seizure_app/features/heads_up/heads_up/heads_up_bottom_sheet_widget.dart';
import 'package:seizure_app/features/heads_up/view_models/heads_up_view_model.dart';

Future<bool> save({
  String? id,
  required DateTime occurredAt,
  int? durationSeconds,
  String? location,
  String? trigger,
  String? notes,
  String? seizureType,
  String? aura,
  String? severity,
  String? awareness,
  String? injuries,
  int? recoveryMinutes,
  bool rescueMedicationUsed = false,
  bool alertFired = false,
}) async => true;

void main() {
  for (final width in [280.0, 320.0, 390.0]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      for (final dark in [false, true]) {
        for (final name in [
          'seizure-add',
          'seizure-edit',
          'profile',
          'activity',
          'calendar',
          'heads-up-card',
          'heads-up-sheet',
          'shared-dropdown',
          'contact-form',
          'contact-pending',
          'contact-linked',
          'contact-status',
          'log-row',
          'alert-card',
          'active-heads-up',
        ]) {
          testWidgets('$name width=$width scale=$scale dark=$dark', (
            tester,
          ) async {
            tester.view.physicalSize = Size(width, 560);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await tester.runAsync(() async {
              await (FontLoader('RedHatDisplay')
                    ..addFont(
                      rootBundle.load('assets/fonts/RedHatDisplay-Regular.ttf'),
                    )
                    ..addFont(
                      rootBundle.load('assets/fonts/RedHatDisplay-Bold.ttf'),
                    ))
                  .load();
            });
            final clipping = <String>[];
            final vm = HeadsUpViewModel();
            final log = SeizureLogDto(
              id: 'test',
              userId: 'test',
              occurredAt: DateTime.now(),
              severity: 'Moderate',
              awareness: 'Unconscious',
              durationSeconds: 119,
            );
            Widget child = switch (name) {
              'seizure-add' => AddSeizureLogBottomSheet(
                onAdd: save,
                onUpdate: save,
              ),
              'seizure-edit' => AddSeizureLogBottomSheet(
                onAdd: save,
                onUpdate: save,
                existingLog: log,
              ),
              'profile' => EditProfileBottomSheet(
                user: UserDto(
                  uid: 'test',
                  email: 'test@example.com',
                  displayName: 'Long Name Test',
                  bloodType: 'AB+',
                ),
                onSave:
                    ({
                      required displayName,
                      phone,
                      bloodType,
                      seizureType,
                      medications,
                      emergencyNote,
                    }) async => true,
              ),
              'activity' => ActivityGrid(
                cells: List.generate(
                  28,
                  (i) => (
                    date: DateTime(2026, 10, i + 1),
                    hasSeizure: i == 2,
                    isFuture: false,
                    isToday: i == 12,
                  ),
                ),
              ),
              'calendar' => SeizureCalendarSummary(logs: [log]),
              'heads-up-card' => const SosHeadsUpOptionsCard(),
              'heads-up-sheet' => HeadsUpBottomSheet(
                customDuration: true,
                viewModel: vm,
              ),
              'contact-form' => AddContactBottomSheet(
                onAdd:
                    ({
                      required name,
                      required phone,
                      relation,
                      notifyViaPush = false,
                    }) async => null,
                onUpdate:
                    ({
                      required existing,
                      required name,
                      required phone,
                      relation,
                      notifyViaPush = false,
                    }) async => true,
                onSendInvite: ({required contactId}) async =>
                    throw StateError('Not called during layout probe'),
              ),
              'contact-pending' || 'contact-linked' => ContactCard(
                contact: ContactDto(
                  id: 'test',
                  userId: 'test',
                  name: 'A caregiver with a long display name',
                  phone: '+27821234567',
                  createdAt: DateTime.now(),
                  inviteStatus: 'pending',
                  linkedUid: name == 'contact-linked' ? 'linked' : null,
                ),
                onTap: () {},
                onDelete: () {},
                onInvite: () {},
              ),
              'contact-status' => const ContactStatusRow(
                name: 'A caregiver with a long display name',
                phone: '+27821234567',
                seen: true,
                responding: true,
                deliveryStatus: 'delivered',
              ),
              'log-row' => SeizureLogRow(log: log, onTap: () {}),
              'alert-card' => AlertHistoryCard(
                alert: AlertDto(
                  id: 'test',
                  userId: 'test',
                  type: AlertType.headsUpExpired,
                  status: AlertStatus.sent,
                  createdAt: DateTime.now(),
                  ownerName: 'A patient with a long display name',
                ),
                onTap: () {},
              ),
              'active-heads-up' => ActiveHeadsUpCard(vm: vm),
              _ => AppDropdownField<String>(
                items: const [
                  'A long example dropdown option',
                  'Another long option',
                ],
                value: 'A long example dropdown option',
                onChangeCallback: (_) {},
              ),
            };
            final sheet =
                name.startsWith('seizure') ||
                name == 'profile' ||
                name == 'heads-up-sheet' ||
                name == 'contact-form';
            await tester.pumpWidget(
              MaterialApp(
                key: UniqueKey(),
                theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(width, 560),
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: Scaffold(
                    body: sheet
                        ? child
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: child,
                          ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            if (name.startsWith('seizure') || name == 'profile') {
              final dropdown = find
                  .byType(DropdownButtonFormField<String>)
                  .first;
              await tester.scrollUntilVisible(
                dropdown,
                200,
                scrollable: find.byType(Scrollable).first,
              );
              await tester.tap(dropdown);
              await tester.pumpAndSettle();
              final nav = tester.state<NavigatorState>(
                find.byType(Navigator).first,
              );
              if (nav.canPop()) {
                nav.pop();
                await tester.pumpAndSettle();
              }
            }

            if (name == 'heads-up-card' || name == 'seizure-edit') {
              for (final label
                  in name == 'heads-up-card'
                      ? ['30 min', '1 hr', '2 hrs']
                      : ['Moderate', 'Unconscious']) {
                final finder = find.text(label);
                final paragraph = tester.renderObject<RenderParagraph>(finder);
                final requiredHeight = paragraph.getMaxIntrinsicHeight(
                  paragraph.size.width,
                );
                if (requiredHeight > paragraph.size.height + 1) {
                  clipping.add(
                    '$label: needs $requiredHeight high, available ${paragraph.size.height}',
                  );
                }
              }
            }
            expect(tester.takeException(), isNull);
            expect(
              clipping,
              isEmpty,
              reason:
                  'Selected choices and duration labels must fit without clipping',
            );
            await tester.pumpWidget(const MaterialApp(home: Scaffold()));
            await tester.pumpAndSettle();
            vm.onClose();
          });
        }
      }
    }
  }
}

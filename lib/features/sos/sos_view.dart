import 'package:seizure_app/core/themes/app_palette.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/dtos/alert_response_dto.dart';
import 'package:seizure_app/core/dtos/alert_delivery_dto.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/services/call_service.dart';
import 'package:seizure_app/core/widgets/alert_map_widget.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:seizure_app/features/contacts/view_models/contacts_view_model.dart';
import 'package:seizure_app/features/heads_up/view_models/heads_up_view_model.dart';
import 'package:seizure_app/features/heads_up/heads_up/heads_up_bottom_sheet_widget.dart';
import 'package:seizure_app/features/root/root_view.dart';
import 'package:seizure_app/features/sos/view_models/sos_view_model.dart';
import 'package:seizure_app/features/sos/widgets/active_heads_up_card.dart';
import 'package:seizure_app/features/sos/widgets/contact_status_row.dart';
import 'package:seizure_app/features/sos/widgets/sos_button_widget.dart';
import 'package:seizure_app/features/sos/widgets/sos_heads_up_options_card.dart';
import 'package:seizure_app/features/sos/widgets/sos_idle_sheet.dart';
import 'package:seizure_app/features/sos/widgets/sos_contacts_summary.dart';
import 'package:seizure_app/features/sos/widgets/sos_status_board_header.dart';
import 'package:seizure_app/features/sos/widgets/missed_check_in_card.dart';

class SosView extends StatelessWidget {
  const SosView({super.key, required this.viewModel});

  final RootViewModel viewModel;

  static const double _sheetMinSize = 0.10;
  static const double _sheetMaxSize = 0.55;

  void _handleSOS(
    BuildContext context,
    SosViewModel sosVm, {
    required bool hasRecipients,
    VoidCallback? onComplete,
  }) {
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => CountdownAlertDialog(
          hasRecipients: hasRecipients,
          onConfirm: () {
            Navigator.pop(context);
            sosVm.startSos();
          },
          onCancel: () => Navigator.pop(context),
        ),
      ).whenComplete(() => onComplete?.call()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SosViewModel sosVm = Get.find<SosViewModel>();

    return Obx(() {
      final bool widgetRequested = viewModel.widgetSosRequested.value;
      if (sosVm.activeSos.value != null) {
        if (widgetRequested) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            viewModel.discardWidgetSosRequest();
          });
        }
        return _buildActiveState(context, sosVm);
      }
      if (widgetRequested) {
        final contactsVm = Get.find<ContactsViewModel>();
        final contactsState = contactsVm.screenState.value;
        if (contactsState == GenericScreenStates.initial ||
            contactsState == GenericScreenStates.loading) {
          return _buildWidgetLoadingState(context, sosVm);
        }
        if (contactsState == GenericScreenStates.error) {
          // Contacts often fail to load because the phone is offline, which
          // is exactly when an SOS must not be dropped. Start the countdown
          // anyway: the alert queues, and the delivery states on the active
          // screen say whether anyone was actually told.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!viewModel.consumeWidgetSosRequest()) return;
            _handleSOS(
              context,
              sosVm,
              hasRecipients: true,
              onComplete: viewModel.completeWidgetSosRequest,
            );
          });
          return _buildIdleState(context, sosVm);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!viewModel.consumeWidgetSosRequest()) return;
          _handleSOS(
            context,
            sosVm,
            hasRecipients: contactsVm.contacts.any(
              (contact) => contact.isPushReady,
            ),
            onComplete: viewModel.completeWidgetSosRequest,
          );
        });
      }
      return _buildIdleState(context, sosVm);
    });
  }

  Widget _buildWidgetLoadingState(BuildContext context, SosViewModel sosVm) {
    return Stack(
      children: [
        _buildIdleState(context, sosVm),
        Positioned.fill(
          child: ColoredBox(
            color: context.paper.withValues(alpha: 0.92),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: context.ink),
                  const SizedBox(height: Dimensions.sixteen),
                  Text(
                    'Checking your circle…',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveState(BuildContext context, SosViewModel sosVm) {
    final ContactsViewModel contactsVm = Get.find<ContactsViewModel>();

    return Obx(() {
      final RxList<ContactDto> contacts = contactsVm.contacts;
      final RxList<AlertResponseDto> responses = sosVm.alertResponses;
      final RxList<AlertDeliveryDto> deliveries = sosVm.alertDeliveries;
      final List<ContactDto> recipients = contacts
          .where((ContactDto c) => c.isPushReady)
          .toList();
      final int totalCount = recipients.length;
      final int seenCount = recipients
          .where(
            (ContactDto c) => responses.any(
              (AlertResponseDto r) =>
                  r.contactId == c.id && (r.seen || r.responding),
            ),
          )
          .length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SosStatusBoardHeader(
            elapsedLabel: sosVm.formattedElapsed(),
            seenCount: seenCount,
            totalCount: totalCount,
            onCancel: sosVm.cancelSos,
            delivery: sosVm.delivery.value,
            onCallForHelp: () => _callForHelp(context, contacts),
            onRetry: sosVm.retrySend,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      Dimensions.twentyFour,
                      Dimensions.twentyFour,
                      Dimensions.twentyFour,
                      0,
                    ),
                    child: Text(
                      'YOUR CIRCLE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.secondaryInk,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  if (recipients.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Dimensions.twentyFour,
                        Dimensions.twelve,
                        Dimensions.twentyFour,
                        0,
                      ),
                      child: Text(
                        contacts.isEmpty
                            ? 'No contacts are set up to receive this SOS.'
                            : 'No alert method is enabled for your contacts.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.secondaryInk,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.twentyFour,
                      ),
                      child: Column(
                        children: recipients.map((ContactDto contact) {
                          AlertResponseDto? response;
                          AlertDeliveryDto? delivery;
                          for (final AlertResponseDto r in responses) {
                            if (r.contactId == contact.id) {
                              response = r;
                              break;
                            }
                          }
                          for (final AlertDeliveryDto value in deliveries) {
                            if (value.contactId == contact.id) {
                              delivery = value;
                              break;
                            }
                          }
                          return ContactStatusRow(
                            name: contact.name,
                            phone: contact.phone,
                            seen: response?.seen ?? false,
                            responding: response?.responding ?? false,
                            deliveryStatus: delivery?.status,
                            escalationStage: delivery?.escalationStage ?? 0,
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: Dimensions.twentyFour),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.twentyFour,
                    ),
                    child: SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: Builder(
                        builder: (BuildContext _) {
                          final AlertDto? alert = sosVm.activeSos.value;
                          final double? lat = alert?.latitude;
                          final double? lng = alert?.longitude;
                          if (lat == null || lng == null) {
                            return const AlertMapPlaceholder();
                          }
                          return AlertMapWidget(latitude: lat, longitude: lng);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimensions.twentyFour),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  /// Lets the person choose who to call. With one contact it dials
  /// straight away; it used to always dial the top contact without saying so.
  void _callForHelp(BuildContext context, List<ContactDto> contacts) {
    HapticFeedback.heavyImpact();
    final List<ContactDto> ordered =
        contacts.where((c) => c.phone.trim().isNotEmpty).toList()
          ..sort((a, b) => a.priority.compareTo(b.priority));
    if (ordered.length == 1) {
      CallService.call(ordered.first.phone);
      return;
    }
    AppBottomSheet.show<void>(
      context: context,
      builder: (BuildContext sheetContext) => AppBottomSheetContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Who do you want to call?',
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: Dimensions.twelve),
            for (final ContactDto contact in ordered)
              ListTile(
                contentPadding: EdgeInsets.zero,
                minTileHeight: 56,
                leading: const Icon(Icons.call),
                title: Text(contact.name),
                subtitle: Text(contact.phone),
                onTap: () {
                  HapticFeedback.heavyImpact();
                  Navigator.of(sheetContext).pop();
                  CallService.call(contact.phone);
                },
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              minTileHeight: 56,
              leading: const Icon(Icons.local_hospital_outlined),
              title: const Text(
                'Emergency services (${CallService.emergencyNumber})',
              ),
              onTap: () {
                HapticFeedback.heavyImpact();
                Navigator.of(sheetContext).pop();
                CallService.callEmergency();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleState(BuildContext context, SosViewModel sosVm) {
    final ContactsViewModel contactsVm = Get.find<ContactsViewModel>();

    return LayoutBuilder(
      builder: (context, constraints) {
        return _buildCompactIdleState(context, sosVm, contactsVm);
      },
    );
  }

  Widget _buildCompactIdleState(
    BuildContext context,
    SosViewModel sosVm,
    ContactsViewModel contactsVm,
  ) {
    return Obx(
      () => SosIdleSheet(
        sheetMinSize: _sheetMinSize,
        sheetMaxSize: _sheetMaxSize,
        sosHero: _buildSosHero(context, sosVm, contactsVm),
        content: _buildRosterAndHeadsUp(contactsVm, showDivider: false),
        onOpenHeadsUp: HeadsUpViewModel.instance().activeHeadsUp.value == null
            ? () => HeadsUpBottomSheet.show()
            : null,
      ),
    );
  }

  Widget _buildSosHero(
    BuildContext context,
    SosViewModel sosVm,
    ContactsViewModel contactsVm,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Obx(() {
          final HeadsUpViewModel headsUpVm = HeadsUpViewModel.instance();
          if (headsUpVm.missedCheckIns.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(bottom: Dimensions.twentyFour),
            child: MissedCheckInCard(
              vm: headsUpVm,
              alert: headsUpVm.missedCheckIns.first,
            ),
          );
        }),
        Text(
          'Tap to alert your circle',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Dimensions.eight),
        Obx(() {
          final bool hasRecipients = contactsVm.contacts.any(
            (c) => c.isPushReady,
          );
          if (hasRecipients) {
            return Text(
              '10 seconds to cancel before your circle is notified',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
              textAlign: TextAlign.center,
            );
          }
          // Nobody would be told. That is a warning, not a hint.
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Dimensions.sixteen),
            decoration: BoxDecoration(
              border: Border.all(color: context.ink, width: 1.5),
              borderRadius: BorderRadius.circular(context.design.cardRadius),
            ),
            child: Column(
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.warning_amber_rounded, color: context.ink),
                    const SizedBox(width: Dimensions.twelve),
                    Expanded(
                      child: Text(
                        'Nobody will be notified if you press SOS. Add a '
                        'contact and turn on their alerts.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Dimensions.eight),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => viewModel.changePage(3),
                    child: const Text('Add a contact'),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: Dimensions.twentyFour),
        Obx(() {
          final bool hasRecipients = contactsVm.contacts.any(
            (c) => c.isPushReady,
          );
          return SOSButton(
            hasRecipients: hasRecipients,
            onPressed: () =>
                _handleSOS(context, sosVm, hasRecipients: hasRecipients),
          );
        }),
        const SizedBox(height: Dimensions.thirtyTwo),

        Obx(
          () => SosContactsSummary(
            contacts: contactsVm.contacts.toList(),
            onAddContact: () => viewModel.changePage(3),
          ),
        ),
      ],
    );
  }

  Widget _buildRosterAndHeadsUp(
    ContactsViewModel contactsVm, {
    bool showDivider = true,
  }) {
    return Column(
      children: [
        Obx(() {
          final HeadsUpViewModel headsUpVm = HeadsUpViewModel.instance();
          final bool hasActiveHeadsUp = headsUpVm.activeHeadsUp.value != null;

          return hasActiveHeadsUp
              ? ActiveHeadsUpCard(vm: headsUpVm)
              : const SosHeadsUpOptionsCard();
        }),
      ],
    );
  }
}

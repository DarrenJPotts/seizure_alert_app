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
import 'package:seizure_app/features/contacts/view_models/contacts_view_model.dart';
import 'package:seizure_app/features/heads_up/view_models/heads_up_view_model.dart';
import 'package:seizure_app/features/root/root_view.dart';
import 'package:seizure_app/features/sos/view_models/sos_view_model.dart';
import 'package:seizure_app/features/sos/widgets/active_heads_up_card.dart';
import 'package:seizure_app/features/sos/widgets/contact_status_row.dart';
import 'package:seizure_app/features/sos/widgets/sos_button_widget.dart';
import 'package:seizure_app/features/sos/widgets/sos_heads_up_options_card.dart';
import 'package:seizure_app/features/sos/widgets/sos_idle_sheet.dart';
import 'package:seizure_app/features/sos/widgets/sos_contacts_summary.dart';
import 'package:seizure_app/features/sos/widgets/sos_status_board_header.dart';

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
    HapticFeedback.heavyImpact();
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
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!viewModel.widgetSosRequested.value) return;
            viewModel.discardWidgetSosRequest();
            Get.snackbar(
              'Contacts unavailable',
              'Check your connection and try SOS again.',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.black,
              colorText: Colors.white,
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
            color: Colors.white.withValues(alpha: 0.92),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Colors.black),
                  SizedBox(height: Dimensions.sixteen),
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
            onCallForHelp: () => _callFirstContact(contacts),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      Dimensions.twentyFour,
                      Dimensions.twentyFour,
                      Dimensions.twentyFour,
                      0,
                    ),
                    child: Text(
                      'YOUR CIRCLE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  if (recipients.isEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        Dimensions.twentyFour,
                        Dimensions.twelve,
                        Dimensions.twentyFour,
                        0,
                      ),
                      child: Text(
                        contacts.isEmpty
                            ? 'No contacts are set up to receive this SOS.'
                            : 'No alert method is enabled for your contacts.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.symmetric(
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
                  SizedBox(height: Dimensions.twentyFour),
                  Padding(
                    padding: EdgeInsets.symmetric(
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
                  SizedBox(height: Dimensions.twentyFour),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }

  void _callFirstContact(List<ContactDto> contacts) {
    HapticFeedback.heavyImpact();
    if (contacts.isEmpty) {
      CallService.call(null);
      return;
    }
    final List<ContactDto> ordered = contacts.toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    CallService.call(ordered.first.phone);
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
    return SosIdleSheet(
      sheetMinSize: _sheetMinSize,
      sheetMaxSize: _sheetMaxSize,
      sosHero: _buildSosHero(context, sosVm, contactsVm),
      content: _buildRosterAndHeadsUp(contactsVm, showDivider: false),
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
        Text(
          'Tap to alert your circle',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: Dimensions.eight),
        Obx(() {
          final bool hasRecipients = contactsVm.contacts.any(
            (c) => c.isPushReady,
          );
          return Text(
            hasRecipients
                ? '10 seconds to cancel before your circle is notified'
                : 'No linked contacts are ready for this SOS. Invite a contact or enable push alerts.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
            textAlign: TextAlign.center,
          );
        }),
        SizedBox(height: Dimensions.twentyFour),
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
        SizedBox(height: Dimensions.thirtyTwo),

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

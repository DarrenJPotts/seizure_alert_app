import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/alert_dto.dart';
import 'package:seizure_app/core/dtos/alert_response_dto.dart';
import 'package:seizure_app/core/dtos/contact_dto.dart';
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
import 'package:seizure_app/features/sos/widgets/sos_contacts_summary.dart';
import 'package:seizure_app/features/sos/widgets/sos_status_board_header.dart';

class SosView extends StatelessWidget {
  const SosView({super.key, required this.viewModel});

  final RootViewModel viewModel;

  static const double _sheetMinSize = 0.10;
  static const double _sheetMaxSize = 0.55;

  void _handleSOS(BuildContext context, SosViewModel sosVm) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CountdownAlertDialog(
        onConfirm: () {
          Navigator.pop(context);
          sosVm.startSos();
        },
        onCancel: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SosViewModel sosVm = Get.find<SosViewModel>();

    return Obx(() {
      if (sosVm.activeSos.value != null) {
        return _buildActiveState(context, sosVm);
      }
      return _buildIdleState(context, sosVm);
    });
  }

  Widget _buildActiveState(BuildContext context, SosViewModel sosVm) {
    final ContactsViewModel contactsVm = Get.find<ContactsViewModel>();

    return Obx(() {
      final RxList<ContactDto> contacts = contactsVm.contacts;
      final RxList<AlertResponseDto> responses = sosVm.alertResponses;
      final int totalCount = contacts.length;
      final int seenCount = contacts
          .where(
            (ContactDto c) => responses.any((AlertResponseDto r) => r.contactId == c.id && (r.seen || r.responding)),
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
                        color: Colors.black45,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  if (contacts.isEmpty)
                    Padding(
                      padding: EdgeInsets.fromLTRB(Dimensions.twentyFour, Dimensions.twelve, Dimensions.twentyFour, 0),
                      child: Text(
                        'You have no contacts to notify yet.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
                      ),
                    )
                  else
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: Dimensions.twentyFour),
                      child: Column(
                        children: contacts.map((ContactDto contact) {
                          AlertResponseDto? response;
                          for (final AlertResponseDto r in responses) {
                            if (r.contactId == contact.id) {
                              response = r;
                              break;
                            }
                          }
                          return ContactStatusRow(
                            name: contact.name,
                            phone: contact.phone,
                            seen: response?.seen ?? false,
                            responding: response?.responding ?? false,
                          );
                        }).toList(),
                      ),
                    ),
                  SizedBox(height: Dimensions.twentyFour),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: Dimensions.twentyFour),
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
    final List<ContactDto> ordered = contacts.toList()..sort((a, b) => a.priority.compareTo(b.priority));
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

  Widget _buildCompactIdleState(BuildContext context, SosViewModel sosVm, ContactsViewModel contactsVm) {
    return _CompactIdleSheet(
      sheetMinSize: _sheetMinSize,
      sheetMaxSize: _sheetMaxSize,
      sosHero: _buildSosHero(context, sosVm, contactsVm),
      content: _buildRosterAndHeadsUp(contactsVm, showDivider: false),
    );
  }

  Widget _buildSosHero(BuildContext context, SosViewModel sosVm, ContactsViewModel contactsVm) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Tap to alert your circle', style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
        SizedBox(height: Dimensions.eight),
        Text(
          '10 seconds to cancel before anyone is notified',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: Dimensions.twentyFour),
        SOSButton(onPressed: () => _handleSOS(context, sosVm)),
        SizedBox(height: Dimensions.thirtyTwo),

        Obx(() => SosContactsSummary(contacts: contactsVm.contacts.toList())),
      ],
    );
  }

  Widget _buildRosterAndHeadsUp(ContactsViewModel contactsVm, {bool showDivider = true}) {
    return Column(
      children: [

        Obx(() {
          final HeadsUpViewModel headsUpVm = HeadsUpViewModel.instance();
          final bool hasActiveHeadsUp = headsUpVm.activeHeadsUp.value != null;

          return hasActiveHeadsUp ? ActiveHeadsUpCard(vm: headsUpVm) : const SosHeadsUpOptionsCard();
        }),
      ],
    );
  }
}

class _CompactIdleSheet extends StatefulWidget {
  const _CompactIdleSheet({
    required this.sosHero,
    required this.content,
    required this.sheetMinSize,
    required this.sheetMaxSize,
  });

  final Widget sosHero;
  final Widget content;
  final double sheetMinSize;
  final double sheetMaxSize;

  @override
  State<_CompactIdleSheet> createState() => _CompactIdleSheetState();
}

class _CompactIdleSheetState extends State<_CompactIdleSheet> {
  late final DraggableScrollableController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DraggableScrollableController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isRevealed => _controller.isAttached && _controller.size > widget.sheetMinSize + 0.02;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sheetMinHeight = constraints.maxHeight * widget.sheetMinSize;

        return Stack(
          children: [
            Positioned.fill(
              bottom: sheetMinHeight,
              child: Padding(
                padding: EdgeInsets.all(Dimensions.twentyFour),
                child: Center(child: widget.sosHero),
              ),
            ),
            DraggableScrollableSheet(
              controller: _controller,
              initialChildSize: widget.sheetMinSize,
              minChildSize: widget.sheetMinSize,
              maxChildSize: widget.sheetMaxSize,
              builder: (context, scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: context.theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.fromLTRB(
                      Dimensions.twentyFour,
                      Dimensions.sixteen,
                      Dimensions.twentyFour,
                      Dimensions.twentyFour,
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: Container(
                            width: Dimensions.thirtySix,
                            height: 4,
                            margin: EdgeInsets.only(bottom: Dimensions.twelve),
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(Dimensions.circular),
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(bottom: Dimensions.twelve),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.keyboard_arrow_up,
                                size: 18,
                                color: Colors.black.withValues(alpha: 0.45),
                              ),
                              SizedBox(width: Dimensions.six),
                              Text(
                                'Heads Up & your circle',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: double.infinity, height: 1, color: Colors.black12),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) => _isRevealed ? child! : const SizedBox.shrink(),
                          child: Padding(
                            padding: EdgeInsets.only(top: Dimensions.twentyFour),
                            child: widget.content,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

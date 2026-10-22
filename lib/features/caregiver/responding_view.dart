import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/alert_detail_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:seizure_app/core/widgets/live_indicator.dart';
import 'package:seizure_app/features/caregiver/view_models/responding_view_model.dart';
import 'package:seizure_app/features/caregiver/widgets/caregiver_avatar.dart';

class RespondingView extends GetView<RespondingViewModel> {
  const RespondingView({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceDim,
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          final GenericScreenStates state = controller.screenState.value;

          if (state == GenericScreenStates.loading ||
              state == GenericScreenStates.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state == GenericScreenStates.error ||
              controller.detail.value == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(Dimensions.twentyFour),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: Dimensions.twelve,
                  children: <Widget>[
                    Icon(Icons.error_outline, size: 48, color: scheme.outline),
                    Text(
                      'This alert is no longer available',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    TextButton(
                      onPressed: Get.back<void>,
                      child: const Text('Go back'),
                    ),
                  ],
                ),
              ),
            );
          }

          return const _Loaded();
        }),
      ),
    );
  }
}

class _Loaded extends GetView<RespondingViewModel> {
  const _Loaded();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _Header(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: controller.reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.twenty,
                Dimensions.twenty,
                Dimensions.twenty,
                Dimensions.twelve,
              ),
              children: <Widget>[
                Text(
                  controller.ownerName,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: Dimensions.six),
                Obx(
                  () => Text(
                    controller.subtitle,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.twentyFour),
                const _RosterSection(),
                const SizedBox(height: Dimensions.twentyFour),
                const _CarePlanSection(),
              ],
            ),
          ),
        ),
        const _ActionBar(),
      ],
    );
  }
}

class _Header extends GetView<RespondingViewModel> {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.twenty,
        Dimensions.eight,
        Dimensions.twenty,
        0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          GestureDetector(
            onTap: Get.back,
            behavior: HitTestBehavior.opaque,
            child: Semantics(
              button: true,
              label: 'Back',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: Dimensions.six),
                  Text(
                    'Alerts',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.twelve,
              vertical: Dimensions.six,
            ),
            decoration: BoxDecoration(
              color: scheme.inverseSurface,
              borderRadius: BorderRadius.circular(Dimensions.circular),
            ),
            child: Obx(() {
              final TextStyle? style = Theme.of(context).textTheme.labelSmall
                  ?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: scheme.onInverseSurface,
                  );

              if (!controller.isAlertActive) {
                return Text(controller.alertStatusLabel, style: style);
              }

              return LiveStatusLabel(
                label: controller.alertStatusLabel,
                color: scheme.onInverseSurface,
                indicatorSize: 10,
                gap: Dimensions.six,
                textStyle: style,
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _RosterSection extends GetView<RespondingViewModel> {
  const _RosterSection();

  @override
  Widget build(BuildContext context) => Obx(() {
    final List<AlertResponderDto> roster = controller.roster;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionLabel('Who is responding'),
        const SizedBox(height: Dimensions.ten),
        _Card(
          children: roster.isEmpty
              ? <Widget>[const _MessageRow('Nobody has opened this alert yet')]
              : <Widget>[
                  for (final AlertResponderDto responder in roster)
                    _ResponderRow(responder: responder),
                ],
        ),
      ],
    );
  });
}

class _ResponderRow extends GetView<RespondingViewModel> {
  const _ResponderRow({required this.responder});

  final AlertResponderDto responder;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String name = responder.isCaller ? 'You' : responder.contactName;
    final TextStyle? statusStyle = Theme.of(context).textTheme.bodyLarge
        ?.copyWith(fontSize: 13, color: scheme.onSurfaceVariant);

    return SizedBox(
      height: 68,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.sixteen),
        child: Row(
          children: <Widget>[
            CaregiverAvatar(
              name: responder.isCaller ? null : responder.contactName,
              size: 34,
            ),
            const SizedBox(width: Dimensions.twelve),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: Dimensions.two),
                  responder.responding
                      ? LiveStatusLabel(
                          label: controller.statusFor(responder),
                          indicatorSize: 10,
                          gap: Dimensions.six,
                          textStyle: statusStyle,
                        )
                      : Text(
                          controller.statusFor(responder),
                          overflow: TextOverflow.ellipsis,
                          style: statusStyle,
                        ),
                ],
              ),
            ),
            if (controller.canNudge(responder)) ...<Widget>[
              const SizedBox(width: Dimensions.eight),
              Obx(() {
                final bool busy = controller.nudging.contains(
                  responder.responderId,
                );
                return OutlinedButton(
                  onPressed: busy ? null : () => controller.nudge(responder),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: scheme.onSurface),
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.fourteen,
                      vertical: Dimensions.six,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Dimensions.circular),
                    ),
                  ),
                  child: Text(
                    busy ? 'Sending…' : 'Nudge',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _CarePlanSection extends GetView<RespondingViewModel> {
  const _CarePlanSection();

  @override
  Widget build(BuildContext context) => Obx(() {
    final List<String> steps = controller.carePlanSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionLabel('Care plan'),
        const SizedBox(height: Dimensions.ten),
        _Card(
          children: <Widget>[
            if (controller.detail.value?.ownerProfile.emergencyNote
                    ?.trim()
                    .isNotEmpty ==
                true)
              _MessageRow(
                'Emergency note: ${controller.detail.value!.ownerProfile.emergencyNote!.trim()}',
              ),
            if (steps.isEmpty)
              const _MessageRow(
                'No caregiver instructions saved. Ask them to add a safety plan.',
              )
            else
              for (int i = 0; i < steps.length; i++)
                _CarePlanStep(number: i + 1, text: steps[i]),
            if (controller.detail.value?.ownerProfile.rescueMedication
                    ?.trim()
                    .isNotEmpty ==
                true)
              _MessageRow(
                'Rescue medication: ${controller.detail.value!.ownerProfile.rescueMedication!.trim()}',
              ),
            if (controller.detail.value != null)
              _MessageRow(
                'Call emergency services after ${controller.detail.value!.ownerProfile.callEmergencyAfterMinutes} minutes unless the plan says sooner.',
              ),
          ],
        ),
      ],
    );
  });
}

class _CarePlanStep extends StatelessWidget {
  const _CarePlanStep({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: Dimensions.eighteen,
      vertical: Dimensions.sixteen,
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: Dimensions.fourteen,
          child: Text(
            '$number',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: Dimensions.twelve),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.5),
          ),
        ),
      ],
    ),
  );
}

class _ActionBar extends GetView<RespondingViewModel> {
  const _ActionBar();

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimensions.twenty,
        Dimensions.twelve,
        Dimensions.twenty,
        Dimensions.twenty,
      ),
      child: Row(
        spacing: Dimensions.ten,
        children: <Widget>[
          Expanded(
            child: SizedBox(
              height: 64,
              child: ElevatedButton(
                onPressed: () => AppBottomSheet.show<void>(
                  context: context,
                  builder: (_) => _LogResponseSheet(controller: controller),
                ),

                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Log what happened',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 64,
            height: 64,
            child: OutlinedButton(
              onPressed: controller.callOwner,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: scheme.onSurface, width: 1.5),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Icon(Icons.call, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogResponseSheet extends StatefulWidget {
  const _LogResponseSheet({required this.controller});

  final RespondingViewModel controller;

  @override
  State<_LogResponseSheet> createState() => _LogResponseSheetState();
}

class _LogResponseSheetState extends State<_LogResponseSheet> {
  late final TextEditingController _field;

  @override
  void initState() {
    super.initState();
    _field = TextEditingController(
      text: widget.controller.detail.value?.callerResponse?.note ?? '',
    );
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppBottomSheetContent(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('What happened', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: Dimensions.eight),
        Text(
          'Recorded against your response so ${widget.controller.ownerName.split(' ').first} can read it later. '
          'It does not replace their own seizure log.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Dimensions.sixteen),
        TextField(
          controller: _field,
          autofocus: true,
          maxLines: 5,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Duration, what you saw, what you did…',
          ),
        ),
        const SizedBox(height: Dimensions.twentyFour),
        Obx(
          () => ElevatedButton(
            onPressed: widget.controller.isSavingNote.value
                ? null
                : () async {
                    final bool saved = await widget.controller.saveNote(
                      _field.text,
                    );
                    if (saved && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
            child: Text(
              widget.controller.isSavingNote.value ? 'Saving…' : 'Save',
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: Dimensions.two),
    child: Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceBright,
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          for (int i = 0; i < children.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 1, thickness: 1),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: Dimensions.eighteen,
      vertical: Dimensions.twenty,
    ),
    child: Text(
      message,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontSize: 14,
        height: 1.5,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

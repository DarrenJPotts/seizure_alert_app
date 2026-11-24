import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/alert_detail_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/extensions/typed_extensions.dart';
import 'package:seizure_app/core/widgets/alert_map_widget.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:seizure_app/core/services/call_service.dart';
import 'package:seizure_app/core/widgets/live_indicator.dart';
import 'package:seizure_app/features/caregiver/helpers/emergency_guidance.dart';
import 'package:seizure_app/features/caregiver/view_models/incoming_alert_view_model.dart';
import 'package:seizure_app/core/themes/app_palette.dart';

const Color _alertSurface = Colors.black;
const Color _alertInk = Colors.white;

String _clock(BuildContext context, DateTime time) => MaterialLocalizations.of(
  context,
).formatTimeOfDay(TimeOfDay.fromDateTime(time));

class IncomingAlertView extends GetView<IncomingAlertViewModel> {
  const IncomingAlertView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _alertSurface,
    body: SafeArea(
      child: Obx(() {
        final GenericScreenStates state = controller.screenState.value;

        if (state == GenericScreenStates.loading ||
            state == GenericScreenStates.initial) {
          return const Center(
            child: CircularProgressIndicator(color: _alertInk),
          );
        }

        if (state == GenericScreenStates.error ||
            controller.detail.value == null) {
          return controller.alertGone.value
              ? _UnavailableState()
              : const _LoadFailedState();
        }

        return _Loaded(detail: controller.detail.value!);
      }),
    ),
  );
}

class _Loaded extends GetView<IncomingAlertViewModel> {
  const _Loaded({required this.detail});

  final AlertDetailDto detail;

  @override
  Widget build(BuildContext context) {
    final OwnerProfileDto owner = detail.ownerProfile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimensions.twenty,
            Dimensions.twelve,
            Dimensions.twenty,
            0,
          ),
          child: Obx(() {
            final TextStyle? style = Theme.of(context).textTheme.labelSmall
                ?.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: _alertInk.withValues(alpha: 0.6),
                );

            if (!controller.isAlertActive) {
              return Text(controller.alertStatusLabel, style: style);
            }

            return LiveStatusLabel(
              label: controller.alertStatusLabel,
              semanticsLabel: controller.startedSemantics(
                (DateTime t) => _clock(context, t),
              ),
              color: _alertInk,
              indicatorSize: 12,
              gap: Dimensions.eight,
              textStyle: style,
            );
          }),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              Dimensions.twenty,
              Dimensions.twenty,
              Dimensions.twenty,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.twelve,
                    vertical: Dimensions.four,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: _alertInk),
                    borderRadius: BorderRadius.circular(Dimensions.circular),
                  ),
                  child: Text(
                    controller.typeLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _alertInk,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: Dimensions.ten),
                Text(
                  controller.heading,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: _alertInk,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: Dimensions.ten),
                Text(
                  controller.summaryLine,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                    color: _alertInk.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: Dimensions.twenty),
                const _LocationCard(),
                if (controller.isAlertActive) ...<Widget>[
                  const SizedBox(height: Dimensions.twelve),
                  const _EmergencyServicesCard(),
                ],
                // The care plan comes before the stat cards: it is what the
                // caregiver needs to act on.
                if (owner.carePlanSteps.isNotEmpty ||
                    owner.emergencyNote?.trim().isNotEmpty == true ||
                    owner.rescueMedication?.trim().isNotEmpty ==
                        true) ...<Widget>[
                  const SizedBox(height: Dimensions.twelve),
                  _EmergencyNote(
                    note: owner.carePlanSteps.join('\n'),
                    emergencyNote: owner.emergencyNote,
                    rescueMedication: owner.rescueMedication,
                  ),
                ],
                _StatCardRow(
                  owner: owner,
                  medication: controller.primaryMedication,
                ),
                const SizedBox(height: Dimensions.twenty),
              ],
            ),
          ),
        ),
        const _ActionBar(),
      ],
    );
  }
}

class _LocationCard extends GetView<IncomingAlertViewModel> {
  const _LocationCard();

  @override
  Widget build(BuildContext context) {
    final AlertDetailDto detail = controller.detail.value!;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _alertInk.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(context.design.cardRadius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 180,
            width: double.infinity,
            child: controller.hasLocation
                ? AlertMapWidget(
                    latitude: detail.alert.latitude!,
                    longitude: detail.alert.longitude!,
                  )
                : const _NoLocation(),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.sixteen,
              vertical: Dimensions.fourteen,
            ),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: _alertInk.withValues(alpha: 0.12)),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.location_on_outlined,
                  size: 20,
                  color: _alertInk.withValues(alpha: 0.7),
                ),
                const SizedBox(width: Dimensions.ten),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        detail.alert.locationLabel ??
                            (controller.hasLocation
                                ? 'Location shared'
                                : 'No location'),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: _alertInk,
                        ),
                      ),
                      Obx(() {
                        final String? distance = controller.distanceLabel();
                        if (distance == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: Dimensions.two),
                          child: Text(
                            distance,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: _alertInk.withValues(alpha: 0.5),
                                ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (controller.hasLocation)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.sixteen,
                0,
                Dimensions.sixteen,
                Dimensions.sixteen,
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    controller.openDirections();
                  },
                  icon: const Icon(Icons.directions_outlined),
                  label: const Text('Directions'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _alertInk,
                    minimumSize: const Size.fromHeight(52),
                    side: BorderSide(color: _alertInk.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.design.cardRadius,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NoLocation extends StatelessWidget {
  const _NoLocation();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _alertInk.withValues(alpha: 0.03),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Dimensions.eight,
        children: <Widget>[
          Icon(
            Icons.location_off_outlined,
            color: _alertInk.withValues(alpha: 0.38),
            size: 28,
          ),
          Text(
            'Location unavailable',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: _alertInk.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatCardRow extends StatelessWidget {
  const _StatCardRow({required this.owner, required this.medication});

  final OwnerProfileDto owner;
  final String? medication;

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = <Widget>[
      if (owner.daysSinceLastSeizure != null)
        _StatCard(
          label: 'Last event',
          value: '${owner.daysSinceLastSeizure} days ago',
        ),
      if (medication != null)
        _StatCard(label: 'Medication', value: medication!),
      if (owner.seizureType.isNotNullOrEmpty)
        _StatCard(label: 'Seizure type', value: owner.seizureType!),
      if (owner.bloodType.isNotNullOrEmpty)
        _StatCard(label: 'Blood type', value: owner.bloodType!),
    ];

    if (cards.isEmpty) return const SizedBox.shrink();

    // Every card is shown, two per row. Blood type and seizure type were
    // previously dropped once two other cards existed.
    return Padding(
      padding: const EdgeInsets.only(top: Dimensions.twenty),
      child: Column(
        spacing: Dimensions.eight,
        children: <Widget>[
          for (int i = 0; i < cards.length; i += 2)
            Row(
              spacing: Dimensions.eight,
              children: <Widget>[
                cards[i],
                if (i + 1 < cards.length)
                  cards[i + 1]
                else
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.fourteen,
        vertical: Dimensions.twelve,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: _alertInk.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(context.design.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _alertInk.withValues(alpha: 0.5),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: _alertInk,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmergencyNote extends StatelessWidget {
  const _EmergencyNote({
    required this.note,
    this.emergencyNote,
    required this.rescueMedication,
  });

  final String note;
  final String? emergencyNote;
  final String? rescueMedication;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(Dimensions.sixteen),
    decoration: BoxDecoration(
      border: Border.all(color: _alertInk.withValues(alpha: 0.15)),
      borderRadius: BorderRadius.circular(context.design.cardRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'SEIZURE ACTION PLAN',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: _alertInk.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: Dimensions.eight),
        if (emergencyNote?.trim().isNotEmpty == true) ...[
          // This screen is always black, whatever the app theme, so every
          // text colour is set explicitly. The theme's ink was near-black here
          // in light mode, which made the note invisible.
          Text(
            'Emergency note',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _alertInk,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Dimensions.four),
          Text(
            emergencyNote!.trim(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _alertInk),
          ),
          const SizedBox(height: Dimensions.twelve),
        ],
        if (note.isNotEmpty)
          Text(
            note,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5, color: _alertInk),
          ),
        if (rescueMedication.isNotNullOrEmpty) ...<Widget>[
          const SizedBox(height: Dimensions.twelve),
          Text(
            'Rescue medication: $rescueMedication',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _alertInk,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    ),
  );
}

/// When to call emergency services, with a clock time and a dial button.
class _EmergencyServicesCard extends GetView<IncomingAlertViewModel> {
  const _EmergencyServicesCard();

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(Dimensions.sixteen),
    decoration: BoxDecoration(
      border: Border.all(color: _alertInk.withValues(alpha: 0.15)),
      borderRadius: BorderRadius.circular(context.design.cardRadius),
    ),
    child: Obx(() {
      // Reading elapsed rebuilds this every second for the countdown.
      controller.elapsed.value;
      final DateTime? started = controller.startedAt;
      final DateTime now = DateTime.now();
      final bool overdue =
          started != null &&
          isPastEmergencyDeadline(
            startedAt: started,
            callAfterMinutes: controller.callEmergencyAfterMinutes,
            now: now,
          );
      final ButtonStyle style = overdue
          ? ElevatedButton.styleFrom(
              backgroundColor: _alertInk,
              foregroundColor: _alertSurface,
              minimumSize: const Size.fromHeight(52),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.design.cardRadius),
              ),
            )
          : OutlinedButton.styleFrom(
              foregroundColor: _alertInk,
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: _alertInk.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.design.cardRadius),
              ),
            );
      void onCall() {
        HapticFeedback.heavyImpact();
        controller.callEmergency();
      }

      const Widget icon = Icon(Icons.local_hospital_outlined);
      const Widget label = Text(
        'Call emergency services (${CallService.emergencyNumber})',
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (started != null)
            Text(
              emergencyCallGuidance(
                startedAt: started,
                callAfterMinutes: controller.callEmergencyAfterMinutes,
                now: now,
                formatTime: (DateTime t) => _clock(context, t),
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _alertInk,
                fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
                height: 1.5,
              ),
            ),
          const SizedBox(height: Dimensions.twelve),
          if (overdue)
            ElevatedButton.icon(
              onPressed: onCall,
              icon: icon,
              label: label,
              style: style,
            )
          else
            OutlinedButton.icon(
              onPressed: onCall,
              icon: icon,
              label: label,
              style: style,
            ),
        ],
      );
    }),
  );
}

class _ActionBar extends GetView<IncomingAlertViewModel> {
  const _ActionBar();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Dimensions.twenty,
      Dimensions.twenty,
      Dimensions.twenty,
      Dimensions.eight,
    ),
    child: Column(
      children: <Widget>[
        // Minimum heights, not fixed ones, so labels can grow at large text
        // sizes instead of being clipped.
        ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 72,
            minWidth: double.infinity,
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.heavyImpact();
              controller.callOwner();
            },
            icon: const Icon(Icons.call, size: 24),
            label: Text(
              'Call ${controller.detail.value?.ownerProfile.displayName.split(' ').first ?? ''}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: _alertSurface,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _alertInk,
              foregroundColor: _alertSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.design.cardRadius),
              ),
            ),
          ),
        ),
        const SizedBox(height: Dimensions.twelve),
        if (!controller.isAlertActive)
          ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: 60,
              minWidth: double.infinity,
            ),
            child: OutlinedButton(
              onPressed: Get.back<void>,
              style: OutlinedButton.styleFrom(
                foregroundColor: _alertInk,
                side: BorderSide(color: _alertInk.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    context.design.cardRadius,
                  ),
                ),
              ),
              child: const Text('Back to alerts'),
            ),
          )
        else
          Row(
            spacing: Dimensions.ten,
            children: <Widget>[
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 60),
                  child: Obx(
                    () => OutlinedButton(
                      onPressed: controller.isResponding.value
                          ? null
                          : () {
                              HapticFeedback.selectionClick();
                              controller.respond();
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _alertInk,
                        disabledForegroundColor: _alertInk.withValues(
                          alpha: 0.38,
                        ),
                        side: BorderSide(
                          color: _alertInk.withValues(alpha: 0.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            context.design.cardRadius,
                          ),
                        ),
                      ),
                      child: controller.isResponding.value
                          ? const SizedBox.square(
                              dimension: Dimensions.twenty,
                              child: CircularProgressIndicator(
                                color: _alertInk,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "I'm on my way",
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: _alertInk),
                            ),
                    ),
                  ),
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 60, minHeight: 60),
                child: OutlinedButton(
                  onPressed: () => _showMoreActions(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _alertInk,
                    side: BorderSide(color: _alertInk.withValues(alpha: 0.35)),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        context.design.cardRadius,
                      ),
                    ),
                  ),
                  child: const Icon(
                    Icons.more_horiz,
                    size: 22,
                    semanticLabel: 'More options',
                  ),
                ),
              ),
            ],
          ),
      ],
    ),
  );
  void _showMoreActions(BuildContext context) {
    final OwnerProfileDto? owner = controller.detail.value?.ownerProfile;

    AppBottomSheet.show(
      context: context,
      builder: (BuildContext _) => AppBottomSheetContent(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text('More', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Dimensions.sixteen),
            if (controller.hasLocation)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.directions_outlined),
                title: const Text('Open directions'),
                onTap: () {
                  Get.back<void>();
                  controller.openDirections();
                },
              ),
            if (owner?.bloodType.isNotNullOrEmpty ?? false)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bloodtype_outlined),
                title: const Text('Blood type'),
                trailing: Text(owner!.bloodType!),
              ),
            if (owner?.seizureType.isNotNullOrEmpty ?? false)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.medical_information_outlined),
                title: const Text('Seizure type'),
                trailing: Text(owner!.seizureType!),
              ),
            if ((owner?.medications.length ?? 0) > 1)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.medication_outlined),
                title: const Text('All medications'),
                subtitle: Text(owner!.medications.join(', ')),
              ),
            const SizedBox(height: Dimensions.eight),
            TextButton(onPressed: Get.back<void>, child: const Text('Close')),
          ],
        ),
      ),
    );
  }
}

/// The alert could not be loaded (offline, a timeout, the server busy). It
/// may still be live, so this never says the alert is gone.
class _LoadFailedState extends GetView<IncomingAlertViewModel> {
  const _LoadFailedState();

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(Dimensions.twentyFour),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: _alertInk.withValues(alpha: 0.7),
          ),
          const SizedBox(height: Dimensions.sixteen),
          Text(
            "Couldn't load this alert",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _alertInk,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: Dimensions.eight),
          Text(
            'The alert may still be active. Check your connection and try '
            'again, or call for help now.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _alertInk, height: 1.5),
          ),
          const SizedBox(height: Dimensions.twentyFour),
          ElevatedButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              controller.retry();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _alertInk,
              foregroundColor: _alertSurface,
              minimumSize: const Size.fromHeight(56),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.design.cardRadius),
              ),
            ),
            child: const Text('Try again'),
          ),
          const SizedBox(height: Dimensions.twelve),
          OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.heavyImpact();
              controller.callEmergency();
            },
            icon: const Icon(Icons.local_hospital_outlined),
            label: const Text(
              'Call emergency services (${CallService.emergencyNumber})',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _alertInk,
              minimumSize: const Size.fromHeight(52),
              side: BorderSide(color: _alertInk.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(context.design.cardRadius),
              ),
            ),
          ),
          const SizedBox(height: Dimensions.eight),
          TextButton(
            onPressed: Get.back<void>,
            style: TextButton.styleFrom(foregroundColor: _alertInk),
            child: const Text('Go back'),
          ),
        ],
      ),
    ),
  );
}

class _UnavailableState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Dimensions.twentyFour),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Dimensions.twelve,
        children: <Widget>[
          Icon(
            Icons.error_outline,
            size: 48,
            color: _alertInk.withValues(alpha: 0.38),
          ),
          Text(
            'This alert is no longer available',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _alertInk.withValues(alpha: 0.7),
            ),
          ),
          TextButton(
            onPressed: Get.back<void>,
            style: TextButton.styleFrom(foregroundColor: _alertInk),
            child: const Text('Go back'),
          ),
        ],
      ),
    ),
  );
}

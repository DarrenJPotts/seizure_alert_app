import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/alert_detail_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/extensions/typed_extensions.dart';
import 'package:seizure_app/core/widgets/alert_map_widget.dart';
import 'package:seizure_app/core/widgets/bottom_sheet/app_bottom_sheet.dart';
import 'package:seizure_app/core/widgets/live_indicator.dart';
import 'package:seizure_app/features/caregiver/view_models/incoming_alert_view_model.dart';

const Color _alertSurface = Colors.black;
const Color _alertInk = Colors.white;

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
          return _UnavailableState();
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
          padding: EdgeInsets.fromLTRB(
            Dimensions.twenty,
            Dimensions.twelve,
            Dimensions.twenty,
            0,
          ),
          child: Obx(() {
            final TextStyle? style = Theme.of(context).textTheme.labelSmall
                ?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                  color: _alertInk.withValues(alpha: 0.6),
                );

            if (!controller.isAlertActive) {
              return Text(controller.alertStatusLabel, style: style);
            }

            return LiveStatusLabel(
              label: controller.alertStatusLabel,
              color: _alertInk,
              indicatorSize: 12,
              gap: Dimensions.eight,
              textStyle: style,
            );
          }),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              Dimensions.twenty,
              Dimensions.twenty,
              Dimensions.twenty,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Dimensions.twelve,
                    vertical: Dimensions.four,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: _alertInk),
                    borderRadius: BorderRadius.circular(Dimensions.circular),
                  ),
                  child: Text(
                    'SOS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _alertInk,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: Dimensions.ten),
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
                SizedBox(height: Dimensions.ten),
                Text(
                  controller.summaryLine,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 15,
                    height: 1.5,
                    color: _alertInk.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: Dimensions.twenty),
                const _LocationCard(),
                SizedBox(height: Dimensions.twenty),
                _StatCardRow(
                  owner: owner,
                  medication: controller.primaryMedication,
                ),
                if (owner.carePlanSteps.isNotEmpty) ...<Widget>[
                  SizedBox(height: Dimensions.twelve),
                  _EmergencyNote(
                    note: owner.carePlanSteps.join('\n'),
                    rescueMedication: owner.rescueMedication,
                    callAfterMinutes: owner.callEmergencyAfterMinutes,
                  ),
                ],
                SizedBox(height: Dimensions.twenty),
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
        borderRadius: BorderRadius.circular(16),
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
            padding: EdgeInsets.symmetric(
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
                SizedBox(width: Dimensions.ten),
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
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: _alertInk,
                        ),
                      ),
                      Obx(() {
                        final String? distance = controller.distanceLabel();
                        if (distance == null) return const SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(top: Dimensions.two),
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
                if (controller.hasLocation)
                  GestureDetector(
                    onTap: controller.openDirections,
                    behavior: HitTestBehavior.opaque,
                    child: Semantics(
                      button: true,
                      label: 'Open directions',
                      child: Text(
                        'Directions',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: _alertInk,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: _alertInk,
                        ),
                      ),
                    ),
                  ),
              ],
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
              color: _alertInk.withValues(alpha: 0.38),
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

    return Row(spacing: Dimensions.eight, children: cards.take(2).toList());
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: EdgeInsets.symmetric(
        horizontal: Dimensions.fourteen,
        vertical: Dimensions.twelve,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: _alertInk.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: _alertInk.withValues(alpha: 0.5),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 17,
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
    required this.rescueMedication,
    required this.callAfterMinutes,
  });

  final String note;
  final String? rescueMedication;
  final int callAfterMinutes;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(Dimensions.sixteen),
    decoration: BoxDecoration(
      border: Border.all(color: _alertInk.withValues(alpha: 0.15)),
      borderRadius: BorderRadius.circular(16),
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
        SizedBox(height: Dimensions.eight),
        Text(
          note,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 15,
            height: 1.5,
            color: _alertInk,
          ),
        ),
        if (rescueMedication.isNotNullOrEmpty) ...<Widget>[
          SizedBox(height: Dimensions.twelve),
          Text(
            'Rescue medication: $rescueMedication',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _alertInk,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        SizedBox(height: Dimensions.twelve),
        Text(
          'Call emergency services after $callAfterMinutes minutes unless the plan says sooner.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _alertInk.withValues(alpha: 0.7),
          ),
        ),
      ],
    ),
  );
}

class _ActionBar extends GetView<IncomingAlertViewModel> {
  const _ActionBar();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      Dimensions.twenty,
      Dimensions.twenty,
      Dimensions.twenty,
      Dimensions.eight,
    ),
    child: Column(
      children: <Widget>[
        SizedBox(
          height: 72,
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: controller.callOwner,
            icon: const Icon(Icons.call, size: 24),
            label: Text(
              'Call ${controller.detail.value?.ownerProfile.displayName.split(' ').first ?? ''}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: _alertSurface,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _alertInk,
              foregroundColor: _alertSurface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        SizedBox(height: Dimensions.twelve),
        if (!controller.isAlertActive)
          SizedBox(
            height: 60,
            width: double.infinity,
            child: OutlinedButton(
              onPressed: Get.back<void>,
              style: OutlinedButton.styleFrom(
                foregroundColor: _alertInk,
                side: BorderSide(color: _alertInk.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                child: SizedBox(
                  height: 60,
                  child: Obx(
                    () => OutlinedButton(
                      onPressed: controller.isResponding.value
                          ? null
                          : controller.respond,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _alertInk,
                        disabledForegroundColor: _alertInk.withValues(
                          alpha: 0.38,
                        ),
                        side: BorderSide(
                          color: _alertInk.withValues(alpha: 0.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: controller.isResponding.value
                          ? SizedBox.square(
                              dimension: Dimensions.twenty,
                              child: const CircularProgressIndicator(
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
              SizedBox(
                width: 60,
                height: 60,
                child: OutlinedButton(
                  onPressed: () => _showMoreActions(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _alertInk,
                    side: BorderSide(color: _alertInk.withValues(alpha: 0.35)),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Icon(Icons.more_horiz, size: 22),
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
            SizedBox(height: Dimensions.sixteen),
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
            SizedBox(height: Dimensions.eight),
            TextButton(onPressed: Get.back<void>, child: const Text('Close')),
          ],
        ),
      ),
    );
  }
}

class _UnavailableState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(Dimensions.twentyFour),
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

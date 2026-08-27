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

class IncomingAlertView extends GetView<IncomingAlertViewModel> {
  const IncomingAlertView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: Obx(() {
        final GenericScreenStates state = controller.screenState.value;

        if (state == GenericScreenStates.loading || state == GenericScreenStates.initial) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }

        if (state == GenericScreenStates.error || controller.detail.value == null) {
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
          padding: EdgeInsets.fromLTRB(Dimensions.twenty, Dimensions.twelve, Dimensions.twenty, 0),
          child: Obx(
            () => LiveStatusLabel(
              label: 'LIVE · STARTED ${controller.elapsedClock} AGO',
              color: Colors.white,
              indicatorSize: 12,
              gap: Dimensions.eight,
              textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(Dimensions.twenty, Dimensions.twenty, Dimensions.twenty, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: Dimensions.twelve, vertical: Dimensions.four),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(Dimensions.circular),
                  ),
                  child: Text(
                    'SOS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: Dimensions.ten),
                Text(
                  '${owner.displayName.split(' ').first} needs help',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
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
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: Dimensions.twenty),
                const _LocationCard(),
                SizedBox(height: Dimensions.twenty),
                _StatCardRow(owner: owner, medication: controller.primaryMedication),
                if (owner.emergencyNote.isNotNullOrEmpty) ...<Widget>[
                  SizedBox(height: Dimensions.twelve),
                  _EmergencyNote(note: owner.emergencyNote!),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 180,
            width: double.infinity,
            child: controller.hasLocation
                ? AlertMapWidget(latitude: detail.alert.latitude!, longitude: detail.alert.longitude!)
                : const _NoLocation(),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: Dimensions.sixteen, vertical: Dimensions.fourteen),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.12))),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.location_on_outlined, size: 20, color: Colors.white.withValues(alpha: 0.7)),
                SizedBox(width: Dimensions.ten),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        detail.alert.locationLabel ?? (controller.hasLocation ? 'Location shared' : 'No location'),
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
                      ),
                      Obx(() {
                        final String? distance = controller.distanceLabel();
                        if (distance == null) return const SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(top: Dimensions.two),
                          child: Text(
                            distance,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.5)),
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
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white,
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
    color: Colors.white.withValues(alpha: 0.03),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Dimensions.eight,
        children: <Widget>[
          const Icon(Icons.location_off_outlined, color: Colors.white38, size: 28),
          Text('Location unavailable', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white38)),
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
        _StatCard(label: 'Last event', value: '${owner.daysSinceLastSeizure} days ago'),
      if (medication != null) _StatCard(label: 'Medication', value: medication!),
      if (owner.seizureType.isNotNullOrEmpty) _StatCard(label: 'Seizure type', value: owner.seizureType!),
      if (owner.bloodType.isNotNullOrEmpty) _StatCard(label: 'Blood type', value: owner.bloodType!),
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
      padding: EdgeInsets.symmetric(horizontal: Dimensions.fourteen, vertical: Dimensions.twelve),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmergencyNote extends StatelessWidget {
  const _EmergencyNote({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(Dimensions.sixteen),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'EMERGENCY NOTE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        SizedBox(height: Dimensions.eight),
        Text(
          note,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15, height: 1.5, color: Colors.white),
        ),
      ],
    ),
  );
}

class _ActionBar extends GetView<IncomingAlertViewModel> {
  const _ActionBar();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(Dimensions.twenty, Dimensions.twenty, Dimensions.twenty, Dimensions.eight),
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
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 19, fontWeight: FontWeight.w700, color: Colors.black),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        SizedBox(height: Dimensions.twelve),
        Row(
          spacing: Dimensions.ten,
          children: <Widget>[
            Expanded(
              child: SizedBox(
                height: 60,
                child: Obx(
                  () => OutlinedButton(
                    onPressed: controller.isResponding.value ? null : controller.respond,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      "I'm on my way",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white),
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
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                leading: const Icon(Icons.directions_outlined, color: Colors.black),
                title: const Text('Open directions'),
                onTap: () {
                  Get.back<void>();
                  controller.openDirections();
                },
              ),
            if (owner?.bloodType.isNotNullOrEmpty ?? false)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bloodtype_outlined, color: Colors.black),
                title: const Text('Blood type'),
                trailing: Text(owner!.bloodType!),
              ),
            if (owner?.seizureType.isNotNullOrEmpty ?? false)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.medical_information_outlined, color: Colors.black),
                title: const Text('Seizure type'),
                trailing: Text(owner!.seizureType!),
              ),
            if ((owner?.medications.length ?? 0) > 1)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.medication_outlined, color: Colors.black),
                title: const Text('All medications'),
                subtitle: Text(owner!.medications.join(', ')),
              ),
            SizedBox(height: Dimensions.eight),
            TextButton(
              onPressed: Get.back<void>,
              style: TextButton.styleFrom(foregroundColor: Colors.black),
              child: const Text('Close'),
            ),
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
          const Icon(Icons.error_outline, size: 48, color: Colors.white38),
          Text(
            'This alert is no longer available',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          TextButton(
            onPressed: Get.back<void>,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Go back'),
          ),
        ],
      ),
    ),
  );
}

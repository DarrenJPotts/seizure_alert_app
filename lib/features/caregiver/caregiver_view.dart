import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/watched_person_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/features/caregiver/view_models/caregiver_view_model.dart';
import 'package:seizure_app/core/services/call_service.dart';

class CaregiverView extends GetView<CaregiverViewModel> {
  const CaregiverView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(Dimensions.twentyFour, 0, Dimensions.twentyFour, Dimensions.twenty),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Dimensions.four,
              children: [
                Text('Caregiver mode', style: context.theme.textTheme.bodySmall?.copyWith(color: Colors.black45)),
                Text(
                  'People I watch',
                  style: context.theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              final GenericScreenStates state = controller.screenState.value;

              if (state == GenericScreenStates.loading || state == GenericScreenStates.initial) {
                return const Center(child: CircularProgressIndicator(color: Colors.black));
              }

              if (state == GenericScreenStates.error) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: Dimensions.twelve,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.black26),
                      Text(
                        'Could not load your watch list',
                        style: context.theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                );
              }

              if (state == GenericScreenStates.empty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: Dimensions.twelve,
                    children: [
                      const Icon(Icons.supervisor_account_outlined, size: 48, color: Colors.black26),
                      Text(
                        'You are not watching anyone yet',
                        style: context.theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: Colors.black,
                onRefresh: () => controller.loadPeopleIWatch(forceRefresh: true),
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(Dimensions.twentyFour, 0, Dimensions.twentyFour, Dimensions.twentyFour),
                  itemCount: controller.people.length,
                  separatorBuilder: (BuildContext _, int _) => SizedBox(height: Dimensions.twelve),
                  itemBuilder: (BuildContext context, int index) => _PersonRow(person: controller.people[index]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person});

  final WatchedPersonDto person;

  @override
  Widget build(BuildContext context) {
    if (person.status == WatchedPersonStatus.monitoring) {
      return Container(
        padding: EdgeInsets.all(Dimensions.sixteen),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _Avatar(
              name: person.ownerName,
              background: Colors.black.withValues(alpha: 0.06),
              foreground: Colors.black54,
            ),
            SizedBox(width: Dimensions.twelve),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.ownerName, style: context.theme.textTheme.bodyMedium),
                  Text('Monitoring', style: context.theme.textTheme.bodySmall?.copyWith(color: Colors.black45)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final bool isSos = person.status == WatchedPersonStatus.sos;
    final bool canViewDetails = isSos && person.activeAlertId != null;

    return Container(
      padding: EdgeInsets.all(Dimensions.twenty),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(
                name: person.ownerName,
                background: Colors.transparent,
                foreground: Colors.white,
                border: Colors.white.withValues(alpha: 0.4),
              ),
              SizedBox(width: Dimensions.twelve),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSos ? Colors.redAccent : Colors.orangeAccent,
                          ),
                        ),
                        SizedBox(width: Dimensions.eight),
                        Text(
                          isSos ? 'SOS ACTIVE' : 'HEADS UP',
                          style: context.theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      person.ownerName,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.sixteen),
          Row(
            spacing: Dimensions.eight,
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _handleCall(person),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: Dimensions.twelve),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(isSos ? 'Call' : 'Check on them'),
                  ),
                ),
              ),
              if (canViewDetails)
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _handleViewDetails(person),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                        padding: EdgeInsets.symmetric(vertical: Dimensions.twelve),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('View details'),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleViewDetails(WatchedPersonDto person) {
    Get.toNamed(AppRoutes.incomingAlert, arguments: {'alertId': person.activeAlertId});
  }

  Future<void> _handleCall(WatchedPersonDto person) =>
      CallService.call(person.ownerPhone);
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.background, required this.foreground, this.border});

  final String name;
  final Color background;
  final Color foreground;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: background,
        border: border != null ? Border.all(color: border!, width: 1.5) : null,
      ),
      child: Center(
        child: Text(
          _initials(name),
          style: context.theme.textTheme.bodySmall?.copyWith(color: foreground, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  String _initials(String value) {
    final List<String> parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }
}

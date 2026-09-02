import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:seizure_app/core/constants/dimensions.dart';
import 'package:seizure_app/core/dtos/watched_person_dto.dart';
import 'package:seizure_app/core/enums/generic_screen_states.dart';
import 'package:seizure_app/core/extensions/typed_extensions.dart';
import 'package:seizure_app/core/routes/app_routes.dart';
import 'package:seizure_app/core/services/call_service.dart';
import 'package:seizure_app/core/widgets/live_indicator.dart';
import 'package:seizure_app/features/caregiver/view_models/caregiver_view_model.dart';
import 'package:seizure_app/features/caregiver/widgets/caregiver_avatar.dart';

class CaregiverView extends GetView<CaregiverViewModel> {
  const CaregiverView({super.key, this.onOpenProfile});

  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Header(onOpenProfile: onOpenProfile),
      Expanded(
        child: Obx(() {
          final GenericScreenStates state = controller.screenState.value;

          if (state == GenericScreenStates.loading || state == GenericScreenStates.initial) {
            return const Center(child: CircularProgressIndicator(color: Colors.black));
          }

          if (state == GenericScreenStates.error) {
            return _EmptyState(
              icon: Icons.error_outline,
              message: 'Could not load your watch list',
              action: TextButton(
                onPressed: () => controller.loadPeopleIWatch(forceRefresh: true),
                style: TextButton.styleFrom(foregroundColor: Colors.black),
                child: const Text('Try again'),
              ),
            );
          }

          if (state == GenericScreenStates.empty) {
            return const _EmptyState(
              icon: Icons.shield_outlined,
              message: 'You are not watching anyone yet',
              detail: 'When someone adds you as an emergency contact and you accept, they appear here.',
            );
          }

          return RefreshIndicator(
            color: Colors.black,
            onRefresh: () => controller.loadPeopleIWatch(forceRefresh: true),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                Dimensions.twenty,
                Dimensions.twenty,
                Dimensions.twenty,
                Dimensions.twentyFour,
              ),
              children: <Widget>[
                for (final WatchedPersonDto person in controller.sortedPeople) ...<Widget>[
                  _PersonCard(person: person),
                  SizedBox(height: Dimensions.twentyTwo),
                ],
                if (controller.recentActivity.isNotEmpty) const _RecentActivitySection(),
              ],
            ),
          );
        }),
      ),
    ],
  );
}

class _Header extends StatelessWidget {
  const _Header({this.onOpenProfile});

  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(Dimensions.twenty, Dimensions.eight, Dimensions.twenty, 0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(horizontal: Dimensions.ten, vertical: Dimensions.four),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black.withValues(alpha: 0.2)),
                  borderRadius: BorderRadius.circular(Dimensions.circular),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.shield_outlined, size: 14, color: Colors.black),
                    SizedBox(width: Dimensions.six),
                    Text(
                      'CAREGIVER',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: Dimensions.six),
              Text(
                'Watching',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  height: 1.1,
                ),
              ),
              Obx(() {
                final DateTime? at = Get.find<CaregiverViewModel>().lastUpdatedAt.value;
                if (at == null) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.only(top: Dimensions.four),
                  child: Text(
                    'Updated ${_relativeLong(at)}  ·  pull to refresh',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black.withValues(alpha: 0.45)),
                  ),
                );
              }),
            ],
          ),
        ),
        if (onOpenProfile != null)
          GestureDetector(
            onTap: onOpenProfile,
            child: Semantics(button: true, label: 'Open profile', child: const CaregiverAvatar(name: null, size: 34)),
          ),
      ],
    ),
  );
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person});

  final WatchedPersonDto person;

  bool get _isSos => person.status == WatchedPersonStatus.sos;

  @override
  Widget build(BuildContext context) {
    final bool inverted = _isSos;
    final Color ink = inverted ? Colors.white : Colors.black;

    return Container(
      padding: EdgeInsets.all(Dimensions.eighteen),
      decoration: BoxDecoration(
        color: inverted ? Colors.black : Colors.white,
        border: inverted ? null : Border.all(color: Colors.black.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CaregiverAvatar(
                name: person.ownerName,
                size: 44,
                background: inverted ? Colors.white : Colors.black,
                foreground: inverted ? Colors.black : Colors.white,
              ),
              SizedBox(width: Dimensions.twelve),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      person.ownerName,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: ink, fontWeight: FontWeight.w600, letterSpacing: -0.2),
                    ),
                    SizedBox(height: Dimensions.three),
                    _StatusLine(person: person, ink: ink),
                  ],
                ),
              ),
              SizedBox(width: Dimensions.eight),
              _CallButton(person: person, ink: ink),
            ],
          ),
          if (_isSos) ...<Widget>[
            SizedBox(height: Dimensions.sixteen),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: person.activeAlertId == null
                    ? null
                    : () => Get.toNamed(
                        AppRoutes.incomingAlert,
                        arguments: <String, String?>{'alertId': person.activeAlertId},
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white24,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: Dimensions.fourteen),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Open alert'),
              ),
            ),
          ] else if (person.status == WatchedPersonStatus.headsUp && person.headsUpNote.isNotNullOrEmpty) ...<Widget>[
            SizedBox(height: Dimensions.fourteen),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: Dimensions.fourteen, vertical: Dimensions.twelve),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                border: const Border(left: BorderSide(color: Colors.black, width: 2)),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
              ),
              child: Text(
                '"${person.headsUpNote}"',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14, height: 1.5),
              ),
            ),
          ] else if (person.daysSinceLastSeizure != null || person.lastAlertAt != null) ...<Widget>[
            SizedBox(height: Dimensions.sixteen),
            Row(
              spacing: Dimensions.eight,
              children: <Widget>[
                if (person.daysSinceLastSeizure != null)
                  _StatChip(label: 'Seizure-free', value: '${person.daysSinceLastSeizure}d'),
                if (person.lastAlertAt != null)
                  _StatChip(label: 'Last alert', value: _relativeShort(person.lastAlertAt!)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.person, required this.ink});

  final WatchedPersonDto person;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(fontSize: 13, color: ink.withValues(alpha: 0.5));

    switch (person.status) {
      case WatchedPersonStatus.sos:
        return LiveStatusLabel(
          label: 'SOS sent${person.lastAlertAt == null ? '' : ' · ${_relativeLong(person.lastAlertAt!)}'}',
          color: ink,
          indicatorSize: 12,
          gap: Dimensions.six,
          textStyle: style?.copyWith(color: ink.withValues(alpha: 0.7), fontWeight: FontWeight.w600),
        );

      case WatchedPersonStatus.headsUp:
        return Row(
          children: <Widget>[
            Icon(Icons.warning_amber_rounded, size: 15, color: ink),
            SizedBox(width: Dimensions.six),
            Flexible(
              child: Text(
                'Heads Up sent${person.headsUpAt == null ? '' : ' · ${_relativeLong(person.headsUpAt!)}'}',
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
          ],
        );

      case WatchedPersonStatus.monitoring:
        return LiveStatusLabel(
          label: 'All clear',
          color: ink,
          indicatorSize: 12,
          gap: Dimensions.six,
          textStyle: style,
        );
    }
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.person, required this.ink});

  final WatchedPersonDto person;
  final Color ink;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Call ${person.ownerName}',
    child: GestureDetector(
      onTap: () => CallService.call(person.ownerPhone),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ink.withValues(alpha: person.ownerPhone == null ? 0.25 : 1), width: 1.5),
        ),
        child: Icon(Icons.call, size: 20, color: ink.withValues(alpha: person.ownerPhone == null ? 0.25 : 1)),
      ),
    ),
  );
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: EdgeInsets.all(Dimensions.twelve),
      decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(fontSize: 11, color: Colors.black.withValues(alpha: 0.45)),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3),
            ),
          ),
        ],
      ),
    ),
  );
}

class _RecentActivitySection extends GetView<CaregiverViewModel> {
  const _RecentActivitySection();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Padding(
        padding: EdgeInsets.only(left: Dimensions.two, bottom: Dimensions.ten),
        child: Text(
          'RECENT ACTIVITY',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: Colors.black.withValues(alpha: 0.4),
          ),
        ),
      ),
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: <Widget>[
            for (int i = 0; i < controller.recentActivity.length; i++) ...<Widget>[
              if (i > 0) Divider(height: 1, thickness: 1, color: Colors.black.withValues(alpha: 0.1)),
              _ActivityRow(event: controller.recentActivity[i]),
            ],
          ],
        ),
      ),
    ],
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.event});

  final WatchActivityDto event;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 58,
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: Dimensions.eighteen),
      child: Row(
        children: <Widget>[
          Icon(
            event.kind == 'sos' ? Icons.emergency_outlined : Icons.warning_amber_rounded,
            size: 20,
            color: Colors.black,
          ),
          SizedBox(width: Dimensions.fourteen),
          Expanded(
            child: Text(
              '${event.personName.split(' ').first} · ${event.label}',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            _clockOrDate(event.at),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: 13, color: Colors.black.withValues(alpha: 0.45)),
          ),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message, this.detail, this.action});

  final IconData icon;
  final String message;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(Dimensions.twentyFour),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: Dimensions.twelve,
        children: <Widget>[
          Icon(icon, size: 48, color: Colors.black26),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          if (detail != null)
            Text(
              detail!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black45),
            ),
          ?action,
        ],
      ),
    ),
  );
}

String _relativeLong(DateTime at) {
  final Duration since = DateTime.now().difference(at);
  if (since.inMinutes < 1) return 'just now';
  if (since.inMinutes < 60) return '${since.inMinutes} min ago';
  if (since.inHours < 24) return '${since.inHours} h ago';
  return '${since.inDays} d ago';
}

String _relativeShort(DateTime at) {
  final Duration since = DateTime.now().difference(at);
  if (since.inHours < 1) return '${since.inMinutes}m';
  if (since.inHours < 24) return '${since.inHours}h';
  return '${since.inDays}d';
}

String _clockOrDate(DateTime at) {
  final DateTime now = DateTime.now();
  final String hhmm = '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';
  if (at.year == now.year && at.month == now.month && at.day == now.day) return hhmm;
  return '${at.day}/${at.month}';
}

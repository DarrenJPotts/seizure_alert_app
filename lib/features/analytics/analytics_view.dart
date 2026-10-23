import 'widgets/insights_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/constants/dimensions.dart';
import '../../core/enums/generic_screen_states.dart';
import '../../core/themes/app_palette.dart';
import 'models/analytics_summary.dart';
import 'view_models/analytics_view_model.dart';

class AnalyticsView extends GetView<AnalyticsViewModel> {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Insights')),
    body: SafeArea(
      top: false,
      child: Obx(() {
        final state = controller.state;
        if (state == GenericScreenStates.initial ||
            state == GenericScreenStates.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state == GenericScreenStates.error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.twentyFour),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Your seizure history could not be loaded.'),
                  TextButton(
                    onPressed: controller.retry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        final summary = controller.summary;
        return ListView(
          padding: const EdgeInsets.all(Dimensions.twentyFour),
          children: [
            Text(
              'Your recorded patterns',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: Dimensions.eight),
            Text(
              'Your personal health diary',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
            ),
            const SizedBox(height: Dimensions.sixteen),
            Wrap(
              spacing: Dimensions.eight,
              runSpacing: Dimensions.eight,
              children: [
                for (final days in [30, 90])
                  ChoiceChip(
                    label: Text('$days days'),
                    selected: controller.selectedDays.value == days,
                    selectedColor: context.ink,
                    showCheckmark: false,
                    labelStyle: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(
                          color: controller.selectedDays.value == days
                              ? context.paper
                              : context.ink,
                        ),
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      controller.selectDays(days);
                    },
                  ),
              ],
            ),
            const SizedBox(height: Dimensions.sixteen),
            Text(
              '${AnalyticsSummary.shortDate(summary.start)} – ${AnalyticsSummary.shortDate(summary.end)} · local time',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: Dimensions.twentyFour),
            InsightsCalendar(logs: controller.home.seizureLogs.toList()),
            const SizedBox(height: Dimensions.twentyFour),
            _InsightsCard(
              title: 'Recorded seizures',
              children: [
                Text(
                  '${summary.count}',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                Text(
                  summary.comparison,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Previous period: ${summary.previousCount} recorded. Today is included in the current period.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (summary.count == 0)
                  const Text(
                    'No events recorded in this period. Add an entry from Daily log if one is missing.',
                  ),
              ],
            ),
            const SizedBox(height: Dimensions.twentyFour),
            _InsightsCard(
              title: 'Frequency over time',
              children: [
                Text(
                  'Recorded events per ${summary.days ~/ 6}-day interval',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                _CountBars(buckets: summary.frequency),
              ],
            ),
            const SizedBox(height: Dimensions.twentyFour),
            _InsightsCard(
              title: 'Duration',
              children: [
                _Metric(
                  label: 'Typical duration (median)',
                  value: AnalyticsSummary.durationText(
                    summary.medianDurationSeconds,
                  ),
                ),
                _Metric(
                  label: 'Longest recorded',
                  value: AnalyticsSummary.durationText(
                    summary.longestDurationSeconds,
                  ),
                ),
                Text(
                  'Based on ${summary.durationCount} of ${summary.count} entries with a recorded duration. Missing durations are excluded.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: Dimensions.twentyFour),
            _InsightsCard(
              title: 'Recovery',
              children: [
                _Metric(
                  label: 'Typical recovery (median)',
                  value: summary.medianRecoveryMinutes == null
                      ? 'Not recorded'
                      : '${summary.medianRecoveryMinutes! % 1 == 0 ? summary.medianRecoveryMinutes!.toInt() : summary.medianRecoveryMinutes!.toStringAsFixed(1)} min',
                ),
                Text(
                  'Based on ${summary.recoveryCount} of ${summary.count} entries with a recorded recovery time. Missing recovery times are excluded.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: Dimensions.twentyFour),
            _InsightsCard(
              title: 'Time of day',
              children: [
                _CountBars(buckets: summary.timeOfDay),
                Text(
                  'Based on ${summary.count} recorded events, grouped by local time.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: Dimensions.twentyFour),
            Text(
              'These summaries describe logged events, not seizure risk. Unlogged days are not confirmed seizure-free days. Older records may be incomplete.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: context.secondaryInk),
            ),
          ],
        );
      }),
    ),
  );
}

class _InsightsCard extends StatelessWidget {
  const _InsightsCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(Dimensions.twenty),
    decoration: BoxDecoration(
      color: context.cardSurface,
      border: context.designBorder,
      borderRadius: BorderRadius.circular(context.design.cardRadius),
      boxShadow: context.designShadows,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: Dimensions.twelve,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        ...children,
      ],
    ),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: Dimensions.four,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(value, style: Theme.of(context).textTheme.headlineSmall),
    ],
  );
}

class _CountBars extends StatelessWidget {
  const _CountBars({required this.buckets});
  final List<AnalyticsBucket> buckets;
  @override
  Widget build(BuildContext context) {
    final largest = buckets.fold<int>(
      0,
      (value, bucket) => bucket.count > value ? bucket.count : value,
    );
    return Column(
      spacing: Dimensions.twelve,
      children: [
        for (final bucket in buckets)
          Semantics(
            label: '${bucket.label}: ${bucket.count} recorded events',
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Dimensions.four,
                children: [
                  Wrap(
                    spacing: Dimensions.eight,
                    children: [
                      Text(
                        bucket.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${bucket.count}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: Dimensions.eight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: context.ink.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(Dimensions.four),
                    ),
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: largest == 0 ? 0 : bucket.count / largest,
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.ink,
                          borderRadius: BorderRadius.circular(Dimensions.four),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

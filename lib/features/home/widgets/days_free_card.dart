import 'package:seizure_app/core/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:seizure_app/core/constants/dimensions.dart';

class DaysFreeCard extends StatelessWidget {
  const DaysFreeCard({super.key, required this.days});

  final int? days;

  @override
  Widget build(BuildContext context) {
    final String headline;
    final String sub;

    if (days == null) {
      headline = '—';
      sub = 'No seizures logged yet';
    } else if (days == 0) {
      headline = 'Today';
      sub = 'Last seizure was today';
    } else if (days == 1) {
      headline = '1';
      sub = 'day since last seizure';
    } else {
      headline = '$days';
      sub = 'days since last seizure';
    }

    if (context.design.raisedSurfaces) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.heroSurface,
          borderRadius: BorderRadius.circular(context.design.featureRadius),
          boxShadow: context.designShadows,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.design.featureRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(Dimensions.twenty),
                child: Text(
                  'Last seizure',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: context.heroInk),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(Dimensions.twentyFour),
                decoration: BoxDecoration(
                  color: context.cardSurface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(context.design.featureRadius),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Dimensions.sixteen,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        headline,
                        style: Theme.of(
                          context,
                        ).textTheme.displayLarge?.copyWith(color: context.ink),
                      ),
                    ),
                    Text(
                      sub,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.secondaryInk,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.twentyFour),
      decoration: BoxDecoration(
        color: context.heroSurface,
        boxShadow: context.designShadows,
        borderRadius: BorderRadius.circular(context.design.featureRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: context.design.heroGap,
        children: [
          Text(
            'Last seizure',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.heroInk,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              headline,
              style: Theme.of(
                context,
              ).textTheme.displayLarge?.copyWith(color: context.heroInk),
            ),
          ),
          if (context.design.heroDivider)
            Divider(color: context.heroInk.withValues(alpha: 0.3)),
          Text(
            sub,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.heroInk),
          ),
        ],
      ),
    );
  }
}

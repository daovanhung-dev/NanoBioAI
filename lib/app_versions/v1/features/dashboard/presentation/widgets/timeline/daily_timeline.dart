import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

import 'timeline_event.dart';
import 'timeline_row.dart';

class DailyTimeline extends StatelessWidget {
  final List<TimelineEvent> events;

  const DailyTimeline({required this.events, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: context.semanticColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.sm,
        border: Border.all(color: context.semanticColors.borderLight),
      ),
      child: Column(
        children: List.generate(events.length, (i) {
          final event = events[i];
          final isLast = i == events.length - 1;
          return Padding(
            padding: EdgeInsets.only(
              bottom: i < events.length - 1 ? AppSpacing.md : 0,
            ),
            child: TimelineRow(event: event, isLast: isLast),
          );
        }),
      ),
    );
  }
}

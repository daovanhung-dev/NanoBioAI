import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

import '../../enums/insight_type.dart';
import 'insight_card.dart';
import 'insight_data.dart';

class AiInsightSection extends StatelessWidget {
  final List<InsightData> insights;
  final String concern;

  const AiInsightSection({
    required this.insights,
    required this.concern,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final allInsights = concern.isNotEmpty
        ? [
            InsightData(
              type: InsightType.warning,
              title: 'Mối quan tâm sức khoẻ',
              body: concern,
              icon: Icons.health_and_safety_rounded,
            ),
            ...insights,
          ]
        : insights;

    return Column(
      children: List.generate(
        allInsights.length,
        (i) => Padding(
          padding: EdgeInsets.only(
            bottom: i < allInsights.length - 1 ? AppSpacing.sm : 0,
          ),
          child: InsightCard(data: allInsights[i]),
        ),
      ),
    );
  }
}

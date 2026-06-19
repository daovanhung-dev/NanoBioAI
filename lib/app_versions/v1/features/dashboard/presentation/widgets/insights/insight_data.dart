import 'package:flutter/material.dart';

import '../../enums/insight_type.dart';

@immutable
class InsightData {
  final InsightType type;
  final String title;
  final String body;
  final IconData icon;

  const InsightData({
    required this.type,
    required this.title,
    required this.body,
    required this.icon,
  });
}

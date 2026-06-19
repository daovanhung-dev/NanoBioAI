import 'package:flutter/material.dart';

@immutable
class TimelineEvent {
  final String time;
  final String label;
  final String detail;
  final IconData icon;
  final Color color;

  const TimelineEvent({
    required this.time,
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
  });
}

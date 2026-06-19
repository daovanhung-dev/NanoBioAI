import 'package:flutter/material.dart';

@immutable
class StatItem {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color bgColor;
  final double progress;

  const StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.bgColor,
    required this.progress,
  });
}

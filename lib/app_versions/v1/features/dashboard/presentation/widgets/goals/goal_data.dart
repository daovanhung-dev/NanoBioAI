import 'package:flutter/material.dart';

@immutable
class GoalData {
  final String label;
  final double current;
  final double target;
  final String unit;
  final IconData icon;
  final Color color;

  const GoalData({
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.icon,
    required this.color,
  });

  double get progress => (current / target).clamp(0.0, 1.0);
}

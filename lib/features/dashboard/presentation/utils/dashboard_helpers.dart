import 'package:flutter/material.dart';
import 'package:nano_app/core/theme/theme.dart';

String formatSteps(int steps) {
  if (steps >= 1000) {
    return '${(steps / 1000).toStringAsFixed(1)}k';
  }

  return steps.toString();
}

String greetingMessage(DateTime now) {
  if (now.hour < 12) {
    return 'Chào buổi sáng ☀️';
  }

  if (now.hour < 17) {
    return 'Chào buổi chiều 🌤️';
  }

  return 'Chào buổi tối 🌙';
}

String bmiStatus(double bmi) {
  if (bmi < 18.5) return 'Thiếu cân';
  if (bmi < 25.0) return 'Bình thường';
  if (bmi < 30.0) return 'Thừa cân';
  return 'Béo phì';
}

Color bmiStatusColor(double bmi) {
  if (bmi < 18.5) return const Color(0xFFF59E0B);
  if (bmi < 25.0) return const Color(0xFF22C55E);
  if (bmi < 30.0) return const Color(0xFFF97316);
  return const Color(0xFFEF4444);
}

Color bmiMetricColor(double bmi) {
  if (bmi < 18.5) return const Color(0xFFFBBF24);
  if (bmi < 25.0) return const Color(0xFF4ADE80);
  if (bmi < 30.0) return const Color(0xFFFB923C);
  return const Color(0xFFF87171);
}

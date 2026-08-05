import 'package:flutter/material.dart';

import 'package:nano_app/core/theme/app_colors.dart';
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
  if (bmi < 18.5) return AppColors.warning;
  if (bmi < 25.0) return AppColors.success;
  if (bmi < 30.0) return AppColors.careCoral;
  return AppColors.error;
}

Color bmiMetricColor(double bmi) {
  if (bmi < 18.5) return AppColors.energyYellow;
  if (bmi < 25.0) return AppColors.primaryLight;
  if (bmi < 30.0) return AppColors.careCoral;
  return AppColors.careCoral;
}

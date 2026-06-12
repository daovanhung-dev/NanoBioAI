import 'package:flutter/material.dart';

import '../enums/insight_type.dart';
import '../widgets/goals/goal_data.dart';
import '../widgets/insights/insight_data.dart';
import '../widgets/timeline/timeline_event.dart';

class DashboardMockStats {
  const DashboardMockStats._();

  static const int steps = 8420;
  static const int stepsGoal = 10000;
  static const double calories = 1840;
  static const double caloriesGoal = 2200;
  static const int heartRate = 72;
  static const double stress = 28;
  static const double waterLiters = 1.8;
  static const double waterGoal = 2.5;
  static const double sleepHours = 7.2;
  static const double sleepGoal = 8.0;
  static const String sleepPhase = 'Deep Sleep';
  static const double oxygenSat = 98.4;

  static const List<GoalData> goals = [
    GoalData(
      label: 'Bước chân',
      current: 8420,
      target: 10000,
      unit: 'bước',
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF3B82F6),
    ),
    GoalData(
      label: 'Năng lượng',
      current: 1840,
      target: 2200,
      unit: 'kcal',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFF97316),
    ),
    GoalData(
      label: 'Nước uống',
      current: 1800,
      target: 2500,
      unit: 'ml',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF06B6D4),
    ),
    GoalData(
      label: 'Giấc ngủ',
      current: 7,
      target: 8,
      unit: 'giờ',
      icon: Icons.bedtime_rounded,
      color: Color(0xFF8B5CF6),
    ),
  ];

  static const List<TimelineEvent> timeline = [
    TimelineEvent(
      time: '06:30',
      label: 'Thức dậy',
      detail: '7.2 giờ ngủ · Chất lượng tốt',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFF59E0B),
    ),
    TimelineEvent(
      time: '07:15',
      label: 'Bữa sáng',
      detail: '420 kcal · Cân bằng dinh dưỡng',
      icon: Icons.restaurant_rounded,
      color: Color(0xFF22C55E),
    ),
    TimelineEvent(
      time: '09:00',
      label: 'Tập luyện',
      detail: '35 phút · 310 kcal đốt cháy',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFF3B82F6),
    ),
    TimelineEvent(
      time: '12:30',
      label: 'Bữa trưa',
      detail: '650 kcal · Đạm cao',
      icon: Icons.lunch_dining_rounded,
      color: Color(0xFF06B6D4),
    ),
    TimelineEvent(
      time: '15:00',
      label: 'Uống nước',
      detail: '500ml · Tổng 1.8L hôm nay',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF0EA5E9),
    ),
  ];

  static const List<InsightData> insights = [
    InsightData(
      type: InsightType.recommendation,
      title: 'Gợi ý cá nhân hoá',
      body:
          'Nhịp tim nghỉ ngơi của bạn đã cải thiện 8% trong 2 tuần qua. Tiếp tục duy trì lịch tập cardio hiện tại để tối ưu sức khoẻ tim mạch.',
      icon: Icons.auto_awesome_rounded,
    ),
    InsightData(
      type: InsightType.warning,
      title: 'Cần chú ý',
      body:
          'Mức độ hydration hôm nay đang thấp hơn mục tiêu 28%. Uống thêm 700ml nước trước 20:00 để đạt mục tiêu ngày hôm nay.',
      icon: Icons.warning_amber_rounded,
    ),
    InsightData(
      type: InsightType.tip,
      title: 'Mẹo thông minh',
      body:
          'Dữ liệu giấc ngủ cho thấy bạn ngủ sâu nhất lúc 01:00–03:00. Hãy lên giường trước 23:00 để tối đa hoá giai đoạn này.',
      icon: Icons.lightbulb_rounded,
    ),
  ];
}

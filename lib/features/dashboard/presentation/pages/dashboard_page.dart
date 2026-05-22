// lib/features/dashboard/presentation/pages/dashboard_page.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/theme/theme.dart';

import '../../providers/dashboard_provider.dart';

// ============================================================
// MOCK SUPPLEMENTAL DATA
// (Replace with real Riverpod providers / SQLite / Supabase)
// ============================================================

class _MockStats {
  static const int steps = 8_420;
  static const int stepsGoal = 10_000;
  static const double calories = 1_840;
  static const double caloriesGoal = 2_200;
  static const int heartRate = 72;
  static const double stress = 28;
  static const double waterLiters = 1.8;
  static const double waterGoal = 2.5;
  static const double sleepHours = 7.2;
  static const double sleepGoal = 8.0;
  static const String sleepPhase = 'Deep Sleep';
  static const double oxygenSat = 98.4;

  static const List<_GoalData> goals = [
    _GoalData(
      label: 'Bước chân',
      current: 8_420,
      target: 10_000,
      unit: 'bước',
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF3B82F6),
    ),
    _GoalData(
      label: 'Calories',
      current: 1_840,
      target: 2_200,
      unit: 'kcal',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFF97316),
    ),
    _GoalData(
      label: 'Nước uống',
      current: 1_800,
      target: 2_500,
      unit: 'ml',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF06B6D4),
    ),
    _GoalData(
      label: 'Giấc ngủ',
      current: 7,
      target: 8,
      unit: 'giờ',
      icon: Icons.bedtime_rounded,
      color: Color(0xFF8B5CF6),
    ),
  ];

  static const List<_TimelineEvent> timeline = [
    _TimelineEvent(
      time: '06:30',
      label: 'Thức dậy',
      detail: '7.2 giờ ngủ · Chất lượng tốt',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFF59E0B),
    ),
    _TimelineEvent(
      time: '07:15',
      label: 'Bữa sáng',
      detail: '420 kcal · Cân bằng dinh dưỡng',
      icon: Icons.restaurant_rounded,
      color: Color(0xFF22C55E),
    ),
    _TimelineEvent(
      time: '09:00',
      label: 'Tập luyện',
      detail: '35 phút · 310 kcal đốt cháy',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFF3B82F6),
    ),
    _TimelineEvent(
      time: '12:30',
      label: 'Bữa trưa',
      detail: '650 kcal · Đạm cao',
      icon: Icons.lunch_dining_rounded,
      color: Color(0xFF06B6D4),
    ),
    _TimelineEvent(
      time: '15:00',
      label: 'Uống nước',
      detail: '500ml · Tổng 1.8L hôm nay',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF0EA5E9),
    ),
  ];

  static const List<_InsightData> insights = [
    _InsightData(
      type: _InsightType.recommendation,
      title: 'Gợi ý cá nhân hoá',
      body:
          'Nhịp tim nghỉ ngơi của bạn đã cải thiện 8% trong 2 tuần qua. Tiếp tục duy trì lịch tập cardio hiện tại để tối ưu sức khoẻ tim mạch.',
      icon: Icons.auto_awesome_rounded,
    ),
    _InsightData(
      type: _InsightType.warning,
      title: 'Cần chú ý',
      body:
          'Mức độ hydration hôm nay đang thấp hơn mục tiêu 28%. Uống thêm 700ml nước trước 20:00 để đạt mục tiêu ngày hôm nay.',
      icon: Icons.warning_amber_rounded,
    ),
    _InsightData(
      type: _InsightType.tip,
      title: 'Mẹo thông minh',
      body:
          'Dữ liệu giấc ngủ cho thấy bạn ngủ sâu nhất lúc 01:00–03:00. Hãy lên giường trước 23:00 để tối đa hoá giai đoạn này.',
      icon: Icons.lightbulb_rounded,
    ),
  ];
}

enum _InsightType { recommendation, warning, tip }

@immutable
class _GoalData {
  final String label;
  final double current;
  final double target;
  final String unit;
  final IconData icon;
  final Color color;

  const _GoalData({
    required this.label,
    required this.current,
    required this.target,
    required this.unit,
    required this.icon,
    required this.color,
  });

  double get progress => (current / target).clamp(0.0, 1.0);
}

@immutable
class _TimelineEvent {
  final String time;
  final String label;
  final String detail;
  final IconData icon;
  final Color color;

  const _TimelineEvent({
    required this.time,
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
  });
}

@immutable
class _InsightData {
  final _InsightType type;
  final String title;
  final String body;
  final IconData icon;

  const _InsightData({
    required this.type,
    required this.title,
    required this.body,
    required this.icon,
  });
}

// ============================================================
// DASHBOARD PAGE
// ============================================================

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final AnimationController _pulseController;
  late final AnimationController _scoreController;

  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;
  late final Animation<double> _scoreProgress;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: AppDuration.slow,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scoreController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeIn = CurvedAnimation(parent: _entryController, curve: Curves.easeOut);

    _slideUp = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _entryController, curve: Curves.easeOutCubic),
        );

    _scoreProgress = Tween<double>(begin: 0, end: 0.86).animate(
      CurvedAnimation(parent: _scoreController, curve: Curves.easeOutExpo),
    );

    _entryController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _scoreController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _pulseController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: dashboardAsync.when(
        loading: () => const _DashboardLoading(),
        error: (e, _) => _DashboardError(error: e.toString()),
        data: (dashboard) => FadeTransition(
          opacity: _fadeIn,
          child: SlideTransition(
            position: _slideUp,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // ── Hero Header ───────────────────────────────
                SliverToBoxAdapter(
                  child: _HeroHeader(
                    name: dashboard.fullName,
                    bmi: dashboard.bmi,
                    pulseAnimation: _pulseController,
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: AppSpacing.lg),

                      // ── AI Health Score ─────────────────────
                      _HealthScoreCard(
                        bmi: dashboard.bmi,
                        sleepQuality: dashboard.sleepQuality,
                        activityLevel: dashboard.activityLevel,
                        scoreAnimation: _scoreProgress,
                        pulseAnimation: _pulseController,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Quick Stats Grid ────────────────────
                      _QuickStatsGrid(
                        weightKg: dashboard.weightKg,
                        heightCm: dashboard.heightCm,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── AI Insight Section ──────────────────
                      _SectionHeader(
                        title: 'AI Insights',
                        subtitle: 'Phân tích thời gian thực',
                        icon: Icons.auto_awesome_rounded,
                        iconColor: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _AiInsightSection(
                        insights: _MockStats.insights,
                        concern: dashboard.concernText,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Daily Timeline ──────────────────────
                      _SectionHeader(
                        title: 'Hành trình hôm nay',
                        subtitle: 'Theo dõi hoạt động',
                        icon: Icons.timeline_rounded,
                        iconColor: AppColors.secondary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DailyTimeline(events: _MockStats.timeline),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Goal Progress ───────────────────────
                      _SectionHeader(
                        title: 'Mục tiêu ngày',
                        subtitle: 'Tiến độ & thành tích',
                        icon: Icons.flag_rounded,
                        iconColor: const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _GoalProgressSection(goals: _MockStats.goals),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Smart Lifestyle ─────────────────────
                      _SectionHeader(
                        title: 'Smart Lifestyle',
                        subtitle: 'Chất lượng cuộc sống',
                        icon: Icons.spa_rounded,
                        iconColor: const Color(0xFF22C55E),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SmartLifestyleSection(
                        sleepQuality: dashboard.sleepQuality,
                        activityLevel: dashboard.activityLevel,
                        waterPerDay: dashboard.waterPerDay,
                        conditions: dashboard.conditions,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Health Goals Chips ──────────────────
                      _SectionHeader(
                        title: 'Mục tiêu sức khoẻ',
                        subtitle: 'Kế hoạch cá nhân',
                        icon: Icons.track_changes_rounded,
                        iconColor: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _GoalChipsGrid(goals: dashboard.goals),

                      // ── Bottom spacing for floating nav ─────
                      const SizedBox(height: 120),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HERO HEADER
// ============================================================

class _HeroHeader extends StatelessWidget {
  final String name;
  final double bmi;
  final AnimationController pulseAnimation;

  const _HeroHeader({
    required this.name,
    required this.bmi,
    required this.pulseAnimation,
  });

  String get _bmiStatus {
    if (bmi < 18.5) return 'Thiếu cân';
    if (bmi < 25.0) return 'Bình thường';
    if (bmi < 30.0) return 'Thừa cân';
    return 'Béo phì';
  }

  Color get _bmiColor {
    if (bmi < 18.5) return const Color(0xFFF59E0B);
    if (bmi < 25.0) return const Color(0xFF22C55E);
    if (bmi < 30.0) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Chào buổi sáng ☀️'
        : now.hour < 17
        ? 'Chào buổi chiều 🌤️'
        : 'Chào buổi tối 🌙';

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF0EA5E9)],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: [
          ...AppShadows.primary,
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Floating blur decorations
          Positioned(
            top: -30,
            right: -30,
            child: AnimatedBuilder(
              animation: pulseAnimation,
              builder: (_, __) => Opacity(
                opacity: 0.12 + pulseAnimation.value * 0.06,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -20,
            child: AnimatedBuilder(
              animation: pulseAnimation,
              builder: (_, __) => Opacity(
                opacity: 0.07 + pulseAnimation.value * 0.04,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: 120,
            child: AnimatedBuilder(
              animation: pulseAnimation,
              builder: (_, __) => Opacity(
                opacity: 0.05 + pulseAnimation.value * 0.03,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              72,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: avatar + notification
                Row(
                  children: [
                    // Avatar with glow ring
                    AnimatedBuilder(
                      animation: pulseAnimation,
                      builder: (_, child) => Container(
                        padding: const EdgeInsets.all(2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(
                              0.5 + pulseAnimation.value * 0.3,
                            ),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(
                                0.1 + pulseAnimation.value * 0.1,
                              ),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: child,
                      ),
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF93C5FD), Color(0xFF3B82F6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: AppShadows.sm,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Live indicator
                    AnimatedBuilder(
                      animation: pulseAnimation,
                      builder: (_, __) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(
                            AppRadius.circular,
                          ),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(
                                  0xFF4ADE80,
                                ).withOpacity(0.7 + pulseAnimation.value * 0.3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Live',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: AppTypography.semiBold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: AppSpacing.sm),

                    // Notification bell
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.notifications_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                // Greeting
                Text(
                  greeting,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white.withOpacity(0.75),
                    fontWeight: AppTypography.regular,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: AppTextStyles.displaySmall.copyWith(
                    color: Colors.white,
                    fontWeight: AppTypography.extraBold,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Bottom status row
                Row(
                  children: [
                    _HeaderStatPill(
                      icon: Icons.monitor_heart_rounded,
                      label: '${_MockStats.heartRate} bpm',
                      active: true,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _HeaderStatPill(
                      icon: Icons.bloodtype_rounded,
                      label: '${_MockStats.oxygenSat.toStringAsFixed(1)}% SpO₂',
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    // BMI badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _bmiColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(AppRadius.circular),
                        border: Border.all(color: _bmiColor.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.speed_rounded, color: _bmiColor, size: 13),
                          const SizedBox(width: 4),
                          Text(
                            'BMI ${bmi.toStringAsFixed(1)} · $_bmiStatus',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: _bmiColor,
                              fontWeight: AppTypography.semiBold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _HeaderStatPill({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(active ? 0.2 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.circular),
        border: Border.all(color: Colors.white.withOpacity(active ? 0.4 : 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// AI HEALTH SCORE CARD
// ============================================================

class _HealthScoreCard extends StatelessWidget {
  final double bmi;
  final String sleepQuality;
  final String activityLevel;
  final Animation<double> scoreAnimation;
  final AnimationController pulseAnimation;

  const _HealthScoreCard({
    required this.bmi,
    required this.sleepQuality,
    required this.activityLevel,
    required this.scoreAnimation,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF0F172A)],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primaryLight,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'AI Health Score',
                style: AppTextStyles.heading3.copyWith(color: Colors.white),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withOpacity(0.4),
                  ),
                ),
                child: Text(
                  'Excellent',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: const Color(0xFF4ADE80),
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Score + ring + metrics
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Animated circular score
              SizedBox(
                width: 120,
                height: 120,
                child: AnimatedBuilder(
                  animation: scoreAnimation,
                  builder: (_, __) => CustomPaint(
                    painter: _ScoreRingPainter(
                      progress: scoreAnimation.value,
                      pulseValue: pulseAnimation.value,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(scoreAnimation.value * 100).toInt()}',
                            style: AppTextStyles.displayMedium.copyWith(
                              color: Colors.white,
                              fontWeight: AppTypography.black,
                              fontSize: 36,
                            ),
                          ),
                          Text(
                            '/ 100',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.lg),

              // Metrics list
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ScoreMetricRow(
                      icon: Icons.speed_rounded,
                      label: 'BMI',
                      value: bmi.toStringAsFixed(1),
                      color: _bmiColor(bmi),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ScoreMetricRow(
                      icon: Icons.bedtime_rounded,
                      label: 'Giấc ngủ',
                      value: sleepQuality,
                      color: const Color(0xFF818CF8),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ScoreMetricRow(
                      icon: Icons.directions_run_rounded,
                      label: 'Vận động',
                      value: activityLevel,
                      color: const Color(0xFF34D399),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ScoreMetricRow(
                      icon: Icons.favorite_rounded,
                      label: 'Nhịp tim',
                      value: '${_MockStats.heartRate} bpm',
                      color: const Color(0xFFF87171),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ScoreMetricRow(
                      icon: Icons.water_drop_rounded,
                      label: 'Nước',
                      value: '${_MockStats.waterLiters}L',
                      color: const Color(0xFF38BDF8),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Weekly trend mini chart
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.trending_up_rounded,
                  color: Color(0xFF4ADE80),
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Tăng 12% so với tuần trước',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const Spacer(),
                Text(
                  '+12%',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: const Color(0xFF4ADE80),
                    fontWeight: AppTypography.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Color _bmiColor(double bmi) {
    if (bmi < 18.5) return const Color(0xFFFBBF24);
    if (bmi < 25.0) return const Color(0xFF4ADE80);
    if (bmi < 30.0) return const Color(0xFFFB923C);
    return const Color(0xFFF87171);
  }
}

class _ScoreMetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ScoreMetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white54),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(
            color: Colors.white,
            fontWeight: AppTypography.semiBold,
          ),
        ),
      ],
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double progress;
  final double pulseValue;

  const _ScoreRingPainter({required this.progress, required this.pulseValue});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    const strokeWidth = 8.0;
    const startAngle = -math.pi / 2;

    // Track ring
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress ring gradient simulation
    final progressPaint = Paint()
      ..shader = const SweepGradient(
        colors: [Color(0xFF60A5FA), Color(0xFF22D3EE), Color(0xFF4ADE80)],
        stops: [0.0, 0.5, 1.0],
        startAngle: 0,
        endAngle: math.pi * 2,
        transform: GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progress * math.pi * 2,
      false,
      progressPaint,
    );

    // Glow dot at end of progress
    if (progress > 0.02) {
      final angle = startAngle + progress * math.pi * 2;
      final dotCenter = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      final glowPaint = Paint()
        ..color = const Color(0xFF60A5FA).withOpacity(0.4 + pulseValue * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(dotCenter, 6, glowPaint);
      canvas.drawCircle(dotCenter, 4, Paint()..color = const Color(0xFF93C5FD));
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter old) =>
      old.progress != progress || old.pulseValue != pulseValue;
}

// ============================================================
// QUICK STATS GRID
// ============================================================

class _QuickStatsGrid extends StatelessWidget {
  final double weightKg;
  final double heightCm;

  const _QuickStatsGrid({required this.weightKg, required this.heightCm});

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatItem(
        icon: Icons.local_fire_department_rounded,
        label: 'Calories',
        value: '${_MockStats.calories.toInt()}',
        unit: 'kcal',
        color: const Color(0xFFF97316),
        bgColor: const Color(0xFFFFF7ED),
        progress: _MockStats.calories / _MockStats.caloriesGoal,
      ),
      _StatItem(
        icon: Icons.water_drop_rounded,
        label: 'Nước',
        value: _MockStats.waterLiters.toStringAsFixed(1),
        unit: 'lít',
        color: const Color(0xFF06B6D4),
        bgColor: const Color(0xFFECFEFF),
        progress: _MockStats.waterLiters / _MockStats.waterGoal,
      ),
      _StatItem(
        icon: Icons.bedtime_rounded,
        label: 'Giấc ngủ',
        value: _MockStats.sleepHours.toStringAsFixed(1),
        unit: 'giờ',
        color: const Color(0xFF8B5CF6),
        bgColor: const Color(0xFFF5F3FF),
        progress: _MockStats.sleepHours / _MockStats.sleepGoal,
      ),
      _StatItem(
        icon: Icons.directions_walk_rounded,
        label: 'Bước chân',
        value: _formatSteps(_MockStats.steps),
        unit: 'bước',
        color: const Color(0xFF3B82F6),
        bgColor: AppColors.primarySoft,
        progress: _MockStats.steps / _MockStats.stepsGoal,
      ),
      _StatItem(
        icon: Icons.favorite_rounded,
        label: 'Nhịp tim',
        value: '${_MockStats.heartRate}',
        unit: 'bpm',
        color: const Color(0xFFEF4444),
        bgColor: AppColors.errorSoft,
        progress: 1 - (_MockStats.heartRate - 60) / 100,
      ),
      _StatItem(
        icon: Icons.psychology_rounded,
        label: 'Stress',
        value: '${_MockStats.stress.toInt()}',
        unit: 'điểm',
        color: const Color(0xFFF59E0B),
        bgColor: AppColors.warningSoft,
        progress: 1 - _MockStats.stress / 100,
      ),
      _StatItem(
        icon: Icons.monitor_weight_rounded,
        label: 'Cân nặng',
        value: weightKg.toStringAsFixed(1),
        unit: 'kg',
        color: const Color(0xFF10B981),
        bgColor: AppColors.successSoft,
        progress: 0.78,
      ),
      _StatItem(
        icon: Icons.height_rounded,
        label: 'Chiều cao',
        value: heightCm.toStringAsFixed(0),
        unit: 'cm',
        color: AppColors.secondary,
        bgColor: const Color(0xFFECFEFF),
        progress: 1.0,
      ),
    ];

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.78,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => _StatCard(stat: stats[i]),
    );
  }

  static String _formatSteps(int steps) {
    if (steps >= 1000) return '${(steps / 1000).toStringAsFixed(1)}k';
    return steps.toString();
  }
}

@immutable
class _StatItem {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  final Color bgColor;
  final double progress;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.bgColor,
    required this.progress,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: stat.bgColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(stat.icon, color: stat.color, size: 16),
          ),

          const SizedBox(height: 6),

          // Value
          Text(
            stat.value,
            style: AppTextStyles.heading4.copyWith(
              fontSize: 15,
              fontWeight: AppTypography.bold,
              letterSpacing: -0.2,
            ),
          ),
          Text(
            stat.unit,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textHint,
              fontSize: 9,
            ),
          ),

          const SizedBox(height: 4),

          // Mini progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.circular),
            child: LinearProgressIndicator(
              value: stat.progress.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: stat.bgColor,
              valueColor: AlwaysStoppedAnimation<Color>(stat.color),
            ),
          ),

          const SizedBox(height: 4),

          // Label
          Text(
            stat.label,
            style: AppTextStyles.overline.copyWith(
              fontSize: 9,
              color: AppColors.textHint,
              letterSpacing: 0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// AI INSIGHT SECTION
// ============================================================

class _AiInsightSection extends StatelessWidget {
  final List<_InsightData> insights;
  final String concern;

  const _AiInsightSection({required this.insights, required this.concern});

  @override
  Widget build(BuildContext context) {
    final allInsights = concern.isNotEmpty
        ? [
            _InsightData(
              type: _InsightType.warning,
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
          child: _InsightCard(data: allInsights[i]),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final _InsightData data;

  const _InsightCard({required this.data});

  Color get _accentColor => switch (data.type) {
    _InsightType.recommendation => AppColors.primary,
    _InsightType.warning => AppColors.warning,
    _InsightType.tip => const Color(0xFF8B5CF6),
  };

  Color get _bgColor => switch (data.type) {
    _InsightType.recommendation => AppColors.primarySoft,
    _InsightType.warning => AppColors.warningSoft,
    _InsightType.tip => const Color(0xFFF5F3FF),
  };

  List<Color> get _gradientColors => switch (data.type) {
    _InsightType.recommendation => [
      const Color(0xFF1D4ED8),
      const Color(0xFF2563EB),
    ],
    _InsightType.warning => [const Color(0xFFB45309), const Color(0xFFD97706)],
    _InsightType.tip => [const Color(0xFF6D28D9), const Color(0xFF7C3AED)],
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.sm,
        border: Border.all(color: _accentColor.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon container with gradient
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: _accentColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(data.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      data.title,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: AppTypography.semiBold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _bgColor,
                        borderRadius: BorderRadius.circular(AppRadius.circular),
                      ),
                      child: Text(
                        _typeLabel,
                        style: AppTextStyles.overline.copyWith(
                          color: _accentColor,
                          fontWeight: AppTypography.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  data.body,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _typeLabel => switch (data.type) {
    _InsightType.recommendation => 'AI',
    _InsightType.warning => 'Alert',
    _InsightType.tip => 'Tip',
  };
}

// ============================================================
// DAILY TIMELINE
// ============================================================

class _DailyTimeline extends StatelessWidget {
  final List<_TimelineEvent> events;

  const _DailyTimeline({required this.events});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: List.generate(events.length, (i) {
          final event = events[i];
          final isLast = i == events.length - 1;
          return _TimelineRow(event: event, isLast: isLast);
        }),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final _TimelineEvent event;
  final bool isLast;

  const _TimelineRow({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 46,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                event.time,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint,
                  fontWeight: AppTypography.medium,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Timeline line + dot
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: event.color.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: event.color.withOpacity(0.4),
                    width: 1.5,
                  ),
                ),
                child: Icon(event.icon, color: event.color, size: 14),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 1.5, color: AppColors.borderLight),
                ),
            ],
          ),

          const SizedBox(width: AppSpacing.sm),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: 4,
                bottom: isLast ? 0 : AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.label,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: AppTypography.semiBold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.detail,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GOAL PROGRESS SECTION
// ============================================================

class _GoalProgressSection extends StatelessWidget {
  final List<_GoalData> goals;

  const _GoalProgressSection({required this.goals});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: List.generate(
          goals.length,
          (i) => Padding(
            padding: EdgeInsets.only(
              bottom: i < goals.length - 1 ? AppSpacing.md : 0,
            ),
            child: _GoalProgressRow(goal: goals[i]),
          ),
        ),
      ),
    );
  }
}

class _GoalProgressRow extends StatelessWidget {
  final _GoalData goal;

  const _GoalProgressRow({required this.goal});

  @override
  Widget build(BuildContext context) {
    final percent = (goal.progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: goal.color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(goal.icon, color: goal.color, size: 15),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                goal.label,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: AppTypography.medium,
                ),
              ),
            ),
            Text(
              '${goal.current.toInt()} / ${goal.target.toInt()} ${goal.unit}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 34,
              child: Text(
                '$percent%',
                style: AppTextStyles.labelMedium.copyWith(
                  color: goal.color,
                  fontWeight: AppTypography.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            // Track
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: goal.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.circular),
              ),
            ),
            // Progress
            FractionallySizedBox(
              widthFactor: goal.progress.clamp(0.0, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [goal.color.withOpacity(0.7), goal.color],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                  boxShadow: [
                    BoxShadow(
                      color: goal.color.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// SMART LIFESTYLE SECTION
// ============================================================

class _SmartLifestyleSection extends StatelessWidget {
  final String sleepQuality;
  final String activityLevel;
  final String waterPerDay;
  final List<String> conditions;

  const _SmartLifestyleSection({
    required this.sleepQuality,
    required this.activityLevel,
    required this.waterPerDay,
    required this.conditions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Lifestyle metrics row
        Row(
          children: [
            Expanded(
              child: _LifestyleMetricCard(
                icon: Icons.bedtime_rounded,
                title: 'Giấc ngủ',
                value: sleepQuality,
                detail: '${_MockStats.sleepHours}h đêm qua',
                color: const Color(0xFF8B5CF6),
                bgGradient: const LinearGradient(
                  colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE)],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _LifestyleMetricCard(
                icon: Icons.directions_run_rounded,
                title: 'Vận động',
                value: activityLevel,
                detail: '${_MockStats.steps} bước',
                color: const Color(0xFF3B82F6),
                bgGradient: const LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _LifestyleMetricCard(
                icon: Icons.water_drop_rounded,
                title: 'Hydration',
                value: waterPerDay,
                detail: '${_MockStats.waterLiters}L / ${_MockStats.waterGoal}L',
                color: const Color(0xFF06B6D4),
                bgGradient: const LinearGradient(
                  colors: [Color(0xFFECFEFF), Color(0xFFCFFAFE)],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _LifestyleMetricCard(
                icon: Icons.psychology_rounded,
                title: 'Stress',
                value: 'Thấp',
                detail: 'Điểm: ${_MockStats.stress.toInt()}/100',
                color: const Color(0xFF22C55E),
                bgGradient: const LinearGradient(
                  colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                ),
              ),
            ),
          ],
        ),

        // Conditions section
        if (conditions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _ConditionsCard(conditions: conditions),
        ],
      ],
    );
  }
}

class _LifestyleMetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Color color;
  final Gradient bgGradient;

  const _LifestyleMetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
    required this.color,
    required this.bgGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: bgGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTextStyles.labelSmall.copyWith(
                  color: color.withOpacity(0.8),
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTextStyles.heading4.copyWith(
              color: AppColors.textPrimary,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionsCard extends StatelessWidget {
  final List<String> conditions;

  const _ConditionsCard({required this.conditions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.errorSoft),
        boxShadow: AppShadows.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.medical_information_rounded,
                color: AppColors.error,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Tình trạng cần theo dõi',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.error,
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...conditions.map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      c,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GOAL CHIPS GRID
// ============================================================

class _GoalChipsGrid extends StatelessWidget {
  final List<String> goals;

  const _GoalChipsGrid({required this.goals});

  static const _goalIcons = <String, IconData>{
    'Giảm cân': Icons.trending_down_rounded,
    'Tăng cơ': Icons.fitness_center_rounded,
    'Cải thiện giấc ngủ': Icons.bedtime_rounded,
    'Tăng sức bền': Icons.directions_run_rounded,
    'Giảm stress': Icons.spa_rounded,
    'Ăn lành mạnh': Icons.restaurant_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: goals.map((goal) {
        final icon = _goalIcons[goal] ?? Icons.check_circle_rounded;
        return _GoalChip(label: goal, icon: icon);
      }).toList(),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _GoalChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primarySoft, Color(0xFFDBEAFE)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.circular),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.primary, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.primaryDark,
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION HEADER
// ============================================================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.heading4.copyWith(
                fontWeight: AppTypography.bold,
              ),
            ),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ============================================================
// LOADING STATE
// ============================================================

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _SkeletonBox(
            height: 280,
            radius: AppRadius.xxl,
            margin: EdgeInsets.zero,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: AppSpacing.lg),
              const _SkeletonBox(height: 200),
              const SizedBox(height: AppSpacing.lg),
              const Row(
                children: [
                  Expanded(child: _SkeletonBox(height: 80)),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: _SkeletonBox(height: 80)),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: _SkeletonBox(height: 80)),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(child: _SkeletonBox(height: 80)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SkeletonBox(height: 160),
              const SizedBox(height: AppSpacing.lg),
              const _SkeletonBox(height: 240),
            ]),
          ),
        ),
      ],
    );
  }
}

class _SkeletonBox extends StatefulWidget {
  final double height;
  final double radius;
  final EdgeInsets? margin;

  const _SkeletonBox({
    required this.height,
    this.radius = AppRadius.lg,
    this.margin,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          color: Color.lerp(
            const Color(0xFFE2E8F0),
            const Color(0xFFF1F5F9),
            _animation.value,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ERROR STATE
// ============================================================

class _DashboardError extends StatelessWidget {
  final String error;

  const _DashboardError({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Có lỗi xảy ra',
              style: AppTextStyles.heading3.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

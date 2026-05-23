import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/dashboard/presentation/models/dashboard_mock_stats.dart';
import 'package:nano_app/features/dashboard/presentation/widgets/common/section_header.dart';
import 'package:nano_app/features/dashboard/presentation/widgets/goals/goal_chips_grid.dart';
import 'package:nano_app/features/dashboard/presentation/widgets/goals/goal_progress_section.dart';
import 'package:nano_app/features/dashboard/presentation/widgets/hero/hero_header.dart';
import 'package:nano_app/features/dashboard/presentation/widgets/insights/ai_insight_section.dart';
import 'package:nano_app/features/dashboard/presentation/widgets/lifestyle/smart_lifestyle_section.dart';
import 'package:nano_app/features/dashboard/presentation/widgets/score/health_score_card.dart';
import 'package:nano_app/features/dashboard/presentation/widgets/stats/quick_stats_grid.dart';
import 'package:nano_app/features/dashboard/presentation/widgets/states/dashboard_error.dart';
import 'package:nano_app/features/dashboard/presentation/widgets/states/dashboard_loading.dart';
import 'package:nano_app/features/dashboard/presentation/widgets/timeline/daily_timeline.dart';
import 'package:nano_app/features/dashboard/providers/dashboard_provider.dart';

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
      if (mounted) {
        _scoreController.forward();
      }
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
        loading: () => const DashboardLoading(),
        error: (error, _) => DashboardError(error: error.toString()),
        data: (dashboard) => AppAnimations.fade(
          animation: _fadeIn,
          child: AppAnimations.slide(
            animation: _slideUp,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: HeroHeader(
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
                      HealthScoreCard(
                        bmi: dashboard.bmi,
                        sleepQuality: dashboard.sleepQuality,
                        activityLevel: dashboard.activityLevel,
                        scoreAnimation: _scoreProgress,
                        pulseAnimation: _pulseController,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      QuickStatsGrid(
                        weightKg: dashboard.weightKg,
                        heightCm: dashboard.heightCm,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const SectionHeader(
                        title: 'AI Insights',
                        subtitle: 'Phân tích thời gian thực',
                        icon: Icons.auto_awesome_rounded,
                        iconColor: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AiInsightSection(
                        insights: DashboardMockStats.insights,
                        concern: dashboard.concernText,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const SectionHeader(
                        title: 'Hành trình hôm nay',
                        subtitle: 'Theo dõi hoạt động',
                        icon: Icons.timeline_rounded,
                        iconColor: AppColors.secondary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DailyTimeline(events: DashboardMockStats.timeline),
                      const SizedBox(height: AppSpacing.lg),
                      const SectionHeader(
                        title: 'Mục tiêu ngày',
                        subtitle: 'Tiến độ & thành tích',
                        icon: Icons.flag_rounded,
                        iconColor: Color(0xFF8B5CF6),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GoalProgressSection(goals: DashboardMockStats.goals),
                      const SizedBox(height: AppSpacing.lg),
                      const SectionHeader(
                        title: 'Smart Lifestyle',
                        subtitle: 'Chất lượng cuộc sống',
                        icon: Icons.spa_rounded,
                        iconColor: Color(0xFF22C55E),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SmartLifestyleSection(
                        sleepQuality: dashboard.sleepQuality,
                        activityLevel: dashboard.activityLevel,
                        waterPerDay: dashboard.waterPerDay,
                        conditions: dashboard.conditions,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const SectionHeader(
                        title: 'Mục tiêu sức khoẻ',
                        subtitle: 'Kế hoạch cá nhân',
                        icon: Icons.track_changes_rounded,
                        iconColor: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GoalChipsGrid(goals: dashboard.goals),
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

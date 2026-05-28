import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/onboarding_constants.dart';
import '../../../../core/theme/theme.dart';
import '../controllers/onboarding_controller.dart';
import 'health_chip.dart';
import 'onboarding_step_shell.dart';

class LifestyleStep extends ConsumerStatefulWidget {
  const LifestyleStep({super.key});

  @override
  ConsumerState<LifestyleStep> createState() =>
      _LifestyleStepState();
}

class _LifestyleStepState
    extends ConsumerState<LifestyleStep>
    with TickerProviderStateMixin {
  late final AnimationController
      _backgroundController;

  late final AnimationController
      _floatingController;

  @override
  void initState() {
    super.initState();

    _backgroundController =
        AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 12),
    )..repeat();

    _floatingController =
        AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(onboardingProvider);

    final controller =
        ref.read(
      onboardingProvider.notifier,
    );

    final selectedHabits =
        state.habits.length;

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation:
                _backgroundController,
            builder:
                (context, child) {
              return CustomPaint(
                painter:
                    _LifestyleBackgroundPainter(
                  animation:
                      _backgroundController
                          .value,
                ),
              );
            },
          ),
        ),

        Positioned(
          top: -120,
          right: -70,
          child: _FloatingOrb(
            controller:
                _floatingController,
            size: 280,
            color: AppColors.success
                .withOpacity(0.08),
          ),
        ),

        Positioned(
          bottom: -160,
          left: -90,
          child: _FloatingOrb(
            controller:
                _floatingController,
            size: 340,
            color: AppColors.secondary
                .withOpacity(0.08),
          ),
        ),

        Positioned.fill(
          child: SafeArea(
            child: OnboardingStepShell(
              stepIndex: 4,
              title: '',
              subtitle: '',
              onBack:
                  controller.previousStep,
              onNext:
                  controller.nextStep,
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.only(
                  bottom: 40,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    _AnimatedAppear(
                      delay: 0,
                      child: _HeaderSection(
                        selectedHabits:
                            selectedHabits,
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    _AnimatedAppear(
                      delay: 100,
                      child:
                          _LifestyleSummaryCard(
                        selectedHabits:
                            selectedHabits,
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    const _SectionTitle(
                      title:
                          'Thói quen ăn uống',
                      subtitle:
                          'Phần này giúp BioAI hiểu cách bạn đang sinh hoạt mỗi ngày.',
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    _AnimatedAppear(
                      delay: 200,
                      child:
                          _HabitsGrid(
                        state: state,
                        controller:
                            controller,
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    const _SectionTitle(
                      title:
                          'Giấc ngủ & vận động',
                      subtitle:
                          'Thông tin này giúp AI tối ưu kế hoạch sức khỏe cho bạn.',
                    ),

                    const SizedBox(
                      height: 18,
                    ),

                    _AnimatedAppear(
                      delay: 300,
                      child: _GlassCard(
                        child: Column(
                          children: [
                            _ModernDropdown(
                              label:
                                  'Giấc ngủ hiện tại',
                              icon:
                                  Icons
                                      .bedtime_rounded,
                              value:
                                  state
                                      .sleepQuality,
                              items:
                                  OnboardingCatalog
                                      .sleepQualities,
                              onChanged:
                                  (value) {
                                if (value !=
                                    null) {
                                  controller
                                      .updateSleepQuality(
                                    value,
                                  );
                                }
                              },
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            _ModernDropdown(
                              label:
                                  'Mức độ vận động',
                              icon:
                                  Icons
                                      .directions_run_rounded,
                              value:
                                  state
                                      .activityLevel,
                              items:
                                  OnboardingCatalog
                                      .activityLevels,
                              onChanged:
                                  (value) {
                                if (value !=
                                    null) {
                                  controller
                                      .updateActivityLevel(
                                    value,
                                  );
                                }
                              },
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            _ModernDropdown(
                              label:
                                  'Lượng nước mỗi ngày',
                              icon:
                                  Icons
                                      .water_drop_rounded,
                              value:
                                  state
                                      .waterPerDay,
                              items:
                                  OnboardingCatalog
                                      .waterIntakeOptions,
                              onChanged:
                                  (value) {
                                if (value !=
                                    null) {
                                  controller
                                      .updateWaterPerDay(
                                    value,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 28,
                    ),

                    _AnimatedAppear(
                      delay: 450,
                      child:
                          _LifestyleInsightCard(
                        selectedHabits:
                            selectedHabits,
                        sleepQuality:
                            state.sleepQuality,
                        activityLevel:
                            state.activityLevel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderSection
    extends StatelessWidget {
  final int selectedHabits;

  const _HeaderSection({
    required this.selectedHabits,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success,
            AppColors.secondary,
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          AppRadius.xxl,
        ),
        boxShadow:
            AppShadows.primary,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white
                      .withOpacity(0.14),
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),

              const Spacer(),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white
                      .withOpacity(0.14),
                  borderRadius:
                      BorderRadius.circular(
                    AppRadius.circular,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons
                          .auto_awesome_rounded,
                      color: Colors.white,
                      size: 18,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      'BioAI',
                      style:
                          AppTextStyles
                              .labelLarge
                              .copyWith(
                        color:
                            Colors.white,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          Text(
            'Thói quen sinh hoạt',
            style:
                AppTextStyles
                    .displaySmall
                    .copyWith(
              color: Colors.white,
              fontWeight:
                  FontWeight.w800,
              height: 1.1,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'BioAI sẽ phân tích lối sống và thói quen hàng ngày để xây dựng kế hoạch sức khỏe tối ưu.',
            style:
                AppTextStyles
                    .bodyLarge
                    .copyWith(
              color: Colors.white
                  .withOpacity(0.92),
              height: 1.6,
            ),
          ),

          const SizedBox(height: 28),

          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  title:
                      'Đã chọn',
                  value:
                      '$selectedHabits mục',
                ),
              ),

              const SizedBox(width: 12),

              const Expanded(
                child: _MiniStat(
                  title:
                      'AI Status',
                  value:
                      'Đang học',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat
    extends StatelessWidget {
  final String title;

  final String value;

  const _MiniStat({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white
            .withOpacity(0.12),
        borderRadius:
            BorderRadius.circular(
          AppRadius.lg,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                AppTextStyles
                    .bodySmall
                    .copyWith(
              color: Colors.white
                  .withOpacity(0.82),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style:
                AppTextStyles
                    .heading4
                    .copyWith(
              color: Colors.white,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LifestyleSummaryCard
    extends StatelessWidget {
  final int selectedHabits;

  const _LifestyleSummaryCard({
    required this.selectedHabits,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.lg,
      ),
      decoration:
          AppDecoration.glass(
        opacity: 0.72,
        blurRadius: 20,
        radius: AppRadius.xl,
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.success,
                  AppColors.secondary,
                ],
              ),
              borderRadius:
                  BorderRadius.circular(
                AppRadius.lg,
              ),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  'AI Lifestyle Analysis',
                  style:
                      AppTextStyles
                          .heading4
                          .copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  selectedHabits == 0
                      ? 'Hãy chọn các thói quen để AI hiểu rõ hơn về lối sống của bạn.'
                      : 'BioAI đang xây dựng hồ sơ sinh hoạt và sức khỏe cá nhân hóa.',
                  style:
                      AppTextStyles
                          .bodyMedium
                          .copyWith(
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle
    extends StatelessWidget {
  final String title;

  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              AppTextStyles
                  .heading3
                  .copyWith(
            fontWeight:
                FontWeight.w700,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          subtitle,
          style:
              AppTextStyles
                  .bodyMedium
                  .copyWith(
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

class _HabitsGrid
    extends StatelessWidget {
  final dynamic state;

  final dynamic controller;

  const _HabitsGrid({
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children:
          OnboardingCatalog.habits.map(
        (item) {
          final selected =
              state.habits.contains(
            item.code,
          );

          return HealthChip(
            label: item.label,
            emoji: item.emoji,
            selected: selected,
            onTap:
                () => controller
                    .toggleHabit(
                  item.code,
                ),
          );
        },
      ).toList(),
    );
  }
}

class _ModernDropdown
    extends StatelessWidget {
  final String label;

  final IconData icon;

  final String? value;

  final List<String> items;

  final ValueChanged<String?>
      onChanged;

  const _ModernDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient:
                    AppGradients.primary,
                borderRadius:
                    BorderRadius.circular(
                  AppRadius.md,
                ),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 22,
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Text(
                label,
                style:
                    AppTextStyles
                        .labelLarge
                        .copyWith(
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        DropdownButtonFormField<String>(
          value:
              value != null &&
                      value!.isNotEmpty
                  ? value
                  : null,
          items:
              items
                  .map(
                    (item) =>
                        DropdownMenuItem<
                          String
                        >(
                          value: item,
                          child: Text(
                            item,
                          ),
                        ),
                  )
                  .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal:
                  AppSpacing.lg,
              vertical:
                  AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                AppRadius.lg,
              ),
              borderSide: BorderSide.none,
            ),
            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                AppRadius.lg,
              ),
              borderSide: BorderSide(
                color: AppColors.border
                    .withOpacity(0.5),
              ),
            ),
            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(
                AppRadius.lg,
              ),
              borderSide:
                  const BorderSide(
                color:
                    AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassCard
    extends StatelessWidget {
  final Widget child;

  const _GlassCard({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white
            .withOpacity(0.88),
        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),
        border: Border.all(
          color: AppColors.border
              .withOpacity(0.5),
        ),
        boxShadow:
            AppShadows.soft,
      ),
      child: child,
    );
  }
}

class _LifestyleInsightCard
    extends StatelessWidget {
  final int selectedHabits;

  final String sleepQuality;

  final String activityLevel;

  const _LifestyleInsightCard({
    required this.selectedHabits,
    required this.sleepQuality,
    required this.activityLevel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success,
            AppColors.secondary,
          ],
        ),
        borderRadius:
            BorderRadius.circular(
          AppRadius.xxl,
        ),
        boxShadow:
            AppShadows.primary,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration:
                    BoxDecoration(
                  color: Colors.white
                      .withOpacity(
                    0.14,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    AppRadius.lg,
                  ),
                ),
                child: const Icon(
                  Icons
                      .psychology_alt_rounded,
                  color:
                      Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(
                width: 16,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'AI Lifestyle Insight',
                      style:
                          AppTextStyles
                              .heading4
                              .copyWith(
                        color: Colors
                            .white,
                        fontWeight:
                            FontWeight
                                .w700,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      'Đánh giá lối sống',
                      style:
                          AppTextStyles
                              .bodyMedium
                              .copyWith(
                        color: Colors
                            .white
                            .withOpacity(
                          0.82,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          _InsightRow(
            icon:
                Icons.restaurant_rounded,
            title:
                'Thói quen đã chọn',
            value:
                '$selectedHabits',
          ),

          const SizedBox(height: 16),

          _InsightRow(
            icon:
                Icons.bedtime_rounded,
            title:
                'Giấc ngủ',
            value:
                sleepQuality.isEmpty
                    ? '--'
                    : sleepQuality,
          ),

          const SizedBox(height: 16),

          _InsightRow(
            icon:
                Icons.directions_run_rounded,
            title:
                'Vận động',
            value:
                activityLevel.isEmpty
                    ? '--'
                    : activityLevel,
          ),
        ],
      ),
    );
  }
}

class _InsightRow
    extends StatelessWidget {
  final IconData icon;

  final String title;

  final String value;

  const _InsightRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            title,
            style:
                AppTextStyles
                    .bodyLarge
                    .copyWith(
              color: Colors.white,
            ),
          ),
        ),

        Text(
          value,
          style:
              AppTextStyles
                  .labelLarge
                  .copyWith(
            color: Colors.white,
            fontWeight:
                FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AnimatedAppear
    extends StatefulWidget {
  final Widget child;

  final int delay;

  const _AnimatedAppear({
    required this.child,
    required this.delay,
  });

  @override
  State<_AnimatedAppear>
      createState() =>
          _AnimatedAppearState();
}

class _AnimatedAppearState
    extends State<_AnimatedAppear>
    with
        SingleTickerProviderStateMixin {
  late final AnimationController
      _controller;

  late final Animation<double>
      _opacity;

  late final Animation<Offset>
      _offset;

  @override
  void initState() {
    super.initState();

    _controller =
        AnimationController(
      vsync: this,
      duration:
          const Duration(
        milliseconds: 700,
      ),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _offset =
        Tween<Offset>(
      begin:
          const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve:
            Curves.easeOutCubic,
      ),
    );

    Future.delayed(
      Duration(
        milliseconds:
            widget.delay,
      ),
      () {
        if (mounted) {
          _controller.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: widget.child,
      ),
    );
  }
}

class _FloatingOrb
    extends StatelessWidget {
  final AnimationController
      controller;

  final double size;

  final Color color;

  const _FloatingOrb({
    required this.controller,
    required this.size,
    required this.color,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return AnimatedBuilder(
      animation: controller,
      builder:
          (context, child) {
        return Transform.translate(
          offset: Offset(
            math.sin(
                      controller
                              .value *
                          math.pi *
                          2,
                    ) *
                    14,
            math.cos(
                      controller
                              .value *
                          math.pi *
                          2,
                    ) *
                    14,
          ),
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration:
            BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}

class _LifestyleBackgroundPainter
    extends CustomPainter {
  final double animation;

  const _LifestyleBackgroundPainter({
    required this.animation,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final rect =
        Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );

    final paint = Paint()
      ..shader =
          LinearGradient(
        begin:
            Alignment.topLeft,
        end:
            Alignment.bottomRight,
        colors: [
          AppColors.background,
          AppColors.success
              .withOpacity(0.08),
          Colors.white,
        ],
        transform:
            GradientRotation(
          animation * math.pi,
        ),
      ).createShader(rect);

    canvas.drawRect(
      rect,
      paint,
    );

    final gridPaint =
        Paint()
          ..color = AppColors
              .success
              .withOpacity(
                0.03,
              )
          ..strokeWidth = 1;

    for (
      double i = 0;
      i < size.width;
      i += 40
    ) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(
          i,
          size.height,
        ),
        gridPaint,
      );
    }

    for (
      double i = 0;
      i < size.height;
      i += 40
    ) {
      canvas.drawLine(
        Offset(0, i),
        Offset(
          size.width,
          i,
        ),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant
    _LifestyleBackgroundPainter
        oldDelegate,
  ) {
    return oldDelegate
            .animation !=
        animation;
  }
}
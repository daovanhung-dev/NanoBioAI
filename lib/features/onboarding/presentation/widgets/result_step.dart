import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

class ResultStep extends StatefulWidget {
  final double healthScore;

  final String userName;

  final String message;

  final VoidCallback? onContinue;

  final VoidCallback? onRestart;

  const ResultStep({
    super.key,
    this.healthScore = 78,
    this.userName = 'Bạn',
    this.message =
        'BioAI đã sẵn sàng đồng hành cùng bạn',
    this.onContinue,
    this.onRestart,
  });

  @override
  State<ResultStep> createState() =>
      _ResultStepState();
}

class _ResultStepState
    extends State<ResultStep>
    with TickerProviderStateMixin {
  late final AnimationController
      _backgroundController;

  late final AnimationController
      _scoreController;

  late final AnimationController
      _floatingController;

  late final Animation<double>
      _scoreAnimation;

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

    _scoreController =
        AnimationController(
      vsync: this,
      duration:
          const Duration(seconds: 2),
    );

    _scoreAnimation =
        Tween<double>(
      begin: 0,
      end: widget.healthScore,
    ).animate(
      CurvedAnimation(
        parent: _scoreController,
        curve:
            Curves.easeOutCubic,
      ),
    );

    Future.delayed(
      const Duration(
        milliseconds: 300,
      ),
      () {
        if (mounted) {
          _scoreController.forward();
        }
      },
    );
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _scoreController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    _ResultBackgroundPainter(
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
          right: -80,
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
            color: AppColors.primary
                .withOpacity(0.08),
          ),
        ),

        Positioned.fill(
          child: SafeArea(
            child: SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.all(
                24,
              ),
              child: Column(
                children: [
                  const SizedBox(
                    height: 20,
                  ),

                  _AnimatedAppear(
                    delay: 0,
                    child:
                        _SuccessHeader(
                      userName:
                          widget.userName,
                    ),
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  _AnimatedAppear(
                    delay: 150,
                    child:
                        _HealthScoreCard(
                      animation:
                          _scoreAnimation,
                    ),
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  _AnimatedAppear(
                    delay: 250,
                    child:
                        _AIInsightCard(
                      score:
                          widget
                              .healthScore,
                    ),
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  _AnimatedAppear(
                    delay: 350,
                    child:
                        _JourneyCard(
                      message:
                          widget.message,
                    ),
                  ),

                  const SizedBox(
                    height: 28,
                  ),

                  _AnimatedAppear(
                    delay: 450,
                    child:
                        _FeaturePreviewCard(),
                  ),

                  const SizedBox(
                    height: 32,
                  ),

                  _AnimatedAppear(
                    delay: 550,
                    child:
                        _BottomActions(
                      onContinue:
                          widget
                              .onContinue,
                      onRestart:
                          widget
                              .onRestart,
                    ),
                  ),

                  const SizedBox(
                    height: 40,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessHeader
    extends StatelessWidget {
  final String userName;

  const _SuccessHeader({
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient:
                LinearGradient(
              colors: [
                AppColors.success,
                AppColors.primary,
              ],
            ),
            boxShadow:
                AppShadows.primary,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 54,
          ),
        ),

        const SizedBox(height: 28),

        Text(
          'Hoàn tất hồ sơ',
          textAlign:
              TextAlign.center,
          style:
              AppTextStyles
                  .displayMedium
                  .copyWith(
            fontWeight:
                FontWeight.w800,
            height: 1.1,
          ),
        ),

        const SizedBox(height: 14),

        Text(
          'Chúc mừng $userName! BioAI đã phân tích thành công dữ liệu sức khỏe của bạn.',
          textAlign:
              TextAlign.center,
          style:
              AppTextStyles
                  .bodyLarge
                  .copyWith(
            color:
                AppColors.textSecondary,
            height: 1.7,
          ),
        ),
      ],
    );
  }
}

class _HealthScoreCard
    extends StatelessWidget {
  final Animation<double>
      animation;

  const _HealthScoreCard({
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.xxl,
      ),
      decoration:
          AppDecoration.glass(
        opacity: 0.88,
        blurRadius: 24,
        radius: AppRadius.xxl,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  gradient:
                      AppGradients.primary,
                  borderRadius:
                      BorderRadius.circular(
                    AppRadius.lg,
                  ),
                ),
                child: const Icon(
                  Icons
                      .monitor_heart_rounded,
                  color:
                      Colors.white,
                  size: 30,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Health Score',
                      style:
                          AppTextStyles
                              .heading3
                              .copyWith(
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Text(
                      'Đánh giá sức khỏe tổng quan bởi AI',
                      style:
                          AppTextStyles
                              .bodyMedium
                              .copyWith(
                        color: AppColors
                            .textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          AnimatedBuilder(
            animation: animation,
            builder:
                (context, child) {
              return SizedBox(
                width: 240,
                height: 240,
                child: Stack(
                  alignment:
                      Alignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      height: 240,
                      child:
                          CircularProgressIndicator(
                        value:
                            animation.value /
                            100,
                        strokeWidth:
                            14,
                        backgroundColor:
                            AppColors
                                .border
                                .withOpacity(
                                  0.25,
                                ),
                        valueColor:
                            AlwaysStoppedAnimation(
                          AppColors
                              .primary,
                        ),
                      ),
                    ),

                    Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Text(
                          animation.value
                              .toInt()
                              .toString(),
                          style:
                              AppTextStyles
                                  .displayLarge
                                  .copyWith(
                            fontWeight:
                                FontWeight
                                    .w900,
                            color:
                                AppColors
                                    .primary,
                          ),
                        ),

                        Text(
                          '/100',
                          style:
                              AppTextStyles
                                  .heading4
                                  .copyWith(
                            color: AppColors
                                .textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient:
                  LinearGradient(
                colors: [
                  AppColors.success,
                  AppColors.primary,
                ],
              ),
              borderRadius:
                  BorderRadius.circular(
                999,
              ),
            ),
            child: Text(
              'AI Health Analysis Complete',
              style:
                  AppTextStyles
                      .labelLarge
                      .copyWith(
                color: Colors.white,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AIInsightCard
    extends StatelessWidget {
  final double score;

  const _AIInsightCard({
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    String status = 'Ổn định';
    String desc =
        'Bạn đang có nền tảng sức khỏe khá tốt.';

    if (score < 50) {
      status = 'Cần cải thiện';
      desc =
          'BioAI khuyến nghị cải thiện chế độ sinh hoạt.';
    } else if (score < 80) {
      status = 'Khá tốt';
      desc =
          'Bạn đang duy trì sức khỏe ở mức ổn định.';
    }

    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        gradient:
            LinearGradient(
          colors: [
            AppColors.primary,
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
                      'AI Insight',
                      style:
                          AppTextStyles
                              .heading4
                              .copyWith(
                        color: Colors
                            .white,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      'Phân tích tổng quan',
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
                Icons.favorite_rounded,
            title:
                'Tình trạng sức khỏe',
            value: status,
          ),

          const SizedBox(height: 16),

          const _InsightRow(
            icon:
                Icons.auto_graph_rounded,
            title:
                'AI Tracking',
            value:
                'Đã kích hoạt',
          ),

          const SizedBox(height: 16),

          const _InsightRow(
            icon:
                Icons.shield_rounded,
            title:
                'Health Monitoring',
            value:
                'Realtime',
          ),

          const SizedBox(height: 24),

          Container(
            padding:
                const EdgeInsets.all(
              AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: Colors.white
                  .withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(
                AppRadius.lg,
              ),
            ),
            child: Text(
              desc,
              style:
                  AppTextStyles
                      .bodyLarge
                      .copyWith(
                color: Colors.white,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyCard
    extends StatelessWidget {
  final String message;

  const _JourneyCard({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.xl,
      ),
      decoration:
          AppDecoration.glass(
        opacity: 0.88,
        blurRadius: 22,
        radius: AppRadius.xxl,
      ),
      child: Column(
        children: [
          Text(
            '🎉',
            style:
                const TextStyle(
              fontSize: 72,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            message,
            textAlign:
                TextAlign.center,
            style:
                AppTextStyles
                    .displaySmall
                    .copyWith(
              fontWeight:
                  FontWeight.w800,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 18),

          Text(
            'Từ bây giờ BioAI sẽ đồng hành và đưa ra các gợi ý sức khỏe được cá nhân hóa riêng cho bạn.',
            textAlign:
                TextAlign.center,
            style:
                AppTextStyles
                    .bodyLarge
                    .copyWith(
              color:
                  AppColors.textSecondary,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePreviewCard
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.xl,
      ),
      decoration:
          AppDecoration.glass(
        opacity: 0.88,
        blurRadius: 22,
        radius: AppRadius.xxl,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Tính năng đã kích hoạt',
            style:
                AppTextStyles
                    .heading3
                    .copyWith(
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(height: 24),

          const _FeatureTile(
            icon:
                Icons.restaurant_rounded,
            title:
                'Meal AI',
            subtitle:
                'Gợi ý thực đơn cá nhân hóa',
          ),

          const SizedBox(height: 16),

          const _FeatureTile(
            icon:
                Icons.monitor_heart_rounded,
            title:
                'Health Tracking',
            subtitle:
                'Theo dõi sức khỏe realtime',
          ),

          const SizedBox(height: 16),

          const _FeatureTile(
            icon:
                Icons.psychology_alt_rounded,
            title:
                'AI Recommendations',
            subtitle:
                'Đề xuất cải thiện sức khỏe',
          ),
        ],
      ),
    );
  }
}

class _FeatureTile
    extends StatelessWidget {
  final IconData icon;

  final String title;

  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          AppRadius.xl,
        ),
        border: Border.all(
          color: AppColors.border
              .withOpacity(0.4),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient:
                  AppGradients.primary,
              borderRadius:
                  BorderRadius.circular(
                AppRadius.lg,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
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
                  title,
                  style:
                      AppTextStyles
                          .labelLarge
                          .copyWith(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  subtitle,
                  style:
                      AppTextStyles
                          .bodyMedium
                          .copyWith(
                    color: AppColors
                        .textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.check_circle_rounded,
            color:
                AppColors.success,
          ),
        ],
      ),
    );
  }
}

class _BottomActions
    extends StatelessWidget {
  final VoidCallback? onContinue;

  final VoidCallback? onRestart;

  const _BottomActions({
    this.onContinue,
    this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onContinue,
          child: Container(
            width: double.infinity,
            height: 64,
            decoration: BoxDecoration(
              gradient:
                  AppGradients.primary,
              borderRadius:
                  BorderRadius.circular(
                AppRadius.xl,
              ),
              boxShadow:
                  AppShadows.primary,
            ),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                Text(
                  'Bắt đầu trải nghiệm',
                  style:
                      AppTextStyles
                          .labelLarge
                          .copyWith(
                    color: Colors.white,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),

                const SizedBox(width: 12),

                const Icon(
                  Icons
                      .arrow_forward_rounded,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),

        if (onRestart != null) ...[
          const SizedBox(height: 16),

          GestureDetector(
            onTap: onRestart,
            child: Container(
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  AppRadius.xl,
                ),
                border: Border.all(
                  color: AppColors
                      .border,
                ),
              ),
              child: Center(
                child: Text(
                  'Làm lại khảo sát',
                  style:
                      AppTextStyles
                          .labelLarge
                          .copyWith(
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
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
                    16,
            math.cos(
                      controller
                              .value *
                          math.pi *
                          2,
                    ) *
                    16,
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

class _ResultBackgroundPainter
    extends CustomPainter {
  final double animation;

  const _ResultBackgroundPainter({
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
    _ResultBackgroundPainter
        oldDelegate,
  ) {
    return oldDelegate
            .animation !=
        animation;
  }
}
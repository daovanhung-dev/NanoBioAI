import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme.dart';
import '../../providers/onboarding_provider.dart';
import 'onboarding_step_shell.dart';

class BasicInfoStep extends ConsumerStatefulWidget {
  const BasicInfoStep({super.key});

  @override
  ConsumerState<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends ConsumerState<BasicInfoStep>
    with TickerProviderStateMixin {
  late final AnimationController _backgroundController;
  late final AnimationController _floatingController;

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
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
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    final size = MediaQuery.sizeOf(context);
    final width = size.width;

    final isTablet = width >= AppTypography.mobileBreakpoint;

    final completed = _completedFields(state);
    final progress = completed / 6;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (_, __) {
                return CustomPaint(
                  painter: _OnboardingBackgroundPainter(
                    animation: _backgroundController.value,
                  ),
                );
              },
            ),
          ),

          Positioned(
            top: -120,
            right: -100,
            child: AnimatedBuilder(
              animation: _floatingController,
              builder: (_, __) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    math.sin(_floatingController.value * math.pi) * 20,
                  ),
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: AppDecoration.circle(
                      gradient: AppGradients.primary,
                      shadows: AppShadows.primary,
                    ).copyWith(color: AppColors.primary.withOpacity(0.12)),
                  ),
                );
              },
            ),
          ),

          Positioned(
            bottom: -140,
            left: -120,
            child: AnimatedBuilder(
              animation: _floatingController,
              builder: (_, __) {
                return Transform.translate(
                  offset: Offset(
                    0,
                    -math.sin(_floatingController.value * math.pi) * 18,
                  ),
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: AppDecoration.circle(
                      gradient: AppGradients.ai,
                    ).copyWith(color: AppColors.secondary.withOpacity(0.08)),
                  ),
                );
              },
            ),
          ),

          SafeArea(
            child: OnboardingStepShell(
              stepIndex: 1,
              title: '',
              subtitle: '',
              onBack: controller.previousStep,
              onNext: controller.nextStep,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.pagePadding,
                  AppSpacing.sm,
                  AppSpacing.pagePadding,
                  AppSpacing.xxxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FadeSlideIn(delay: 0, child: _HeroCard()),

                    const SizedBox(height: AppSpacing.xl),

                    _FadeSlideIn(
                      delay: 100,
                      child: _ProgressCard(
                        completed: completed,
                        progress: progress,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    _FadeSlideIn(
                      delay: 160,
                      child: _SectionHeader(
                        title: 'Cho mình làm quen với bạn nhé',
                        subtitle:
                            'Bạn chia sẻ càng rõ, mình càng có thể chăm sóc bạn theo cách phù hợp.',
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    _FadeSlideIn(
                      delay: 220,
                      child: _GlassCard(
                        child: Column(
                          children: [
                            _ModernInput(
                              icon: AppIcons.profile,
                              title: 'Họ và tên',
                              hint: 'Nguyễn Văn A',
                              initialValue: state.fullName,
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.name],
                              onChanged: controller.updateFullName,
                            ),

                            const SizedBox(height: AppSpacing.lg),

                            _ModernInput(
                              icon: AppIcons.calendar,
                              title: 'Năm sinh',
                              hint: '2000',
                              initialValue: state.birthYear == 0
                                  ? ''
                                  : state.birthYear.toString(),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              onChanged: controller.updateBirthYear,
                            ),

                            const SizedBox(height: AppSpacing.lg),

                            _ModernInput(
                              icon: AppIcons.dashboard,
                              title: 'Nghề nghiệp',
                              hint: 'Nhân viên văn phòng',
                              initialValue: state.occupation,
                              keyboardType: TextInputType.text,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.jobTitle],
                              onChanged: controller.updateOccupation,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    _FadeSlideIn(
                      delay: 300,
                      child: _SectionHeader(
                        title: 'Bạn muốn mình ghi nhận giới tính thế nào?',
                        subtitle:
                            'Thông tin này giúp các phân tích sức khỏe sát với bạn hơn.',
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    _FadeSlideIn(
                      delay: 360,
                      child: _GenderGrid(
                        value: state.gender,
                        onChanged: controller.updateGender,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    _FadeSlideIn(
                      delay: 420,
                      child: _SectionHeader(
                        title: 'Mình xin thêm một chút về thể trạng nhé',
                        subtitle:
                            'Chiều cao và cân nặng giúp mình tính toán kế hoạch vừa sức với bạn.',
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    _FadeSlideIn(
                      delay: 480,
                      child: _GlassCard(
                        child: isTablet
                            ? Row(
                                children: [
                                  Expanded(
                                    child: _MetricInput(
                                      icon: AppIcons.fitness,
                                      title: 'Chiều cao',
                                      unit: 'cm',
                                      value: state.heightCm <= 0
                                          ? ''
                                          : state.heightCm.toStringAsFixed(1),
                                      hint: '170',
                                      onChanged: controller.updateHeight,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.lg),
                                  Expanded(
                                    child: _MetricInput(
                                      icon: AppIcons.weight,
                                      title: 'Cân nặng',
                                      unit: 'kg',
                                      value: state.weightKg <= 0
                                          ? ''
                                          : state.weightKg.toStringAsFixed(1),
                                      hint: '65',
                                      onChanged: controller.updateWeight,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _MetricInput(
                                    icon: AppIcons.fitness,
                                    title: 'Chiều cao',
                                    unit: 'cm',
                                    value: state.heightCm <= 0
                                        ? ''
                                        : state.heightCm.toStringAsFixed(1),
                                    hint: '170',
                                    onChanged: controller.updateHeight,
                                  ),

                                  const SizedBox(height: AppSpacing.lg),

                                  _MetricInput(
                                    icon: AppIcons.weight,
                                    title: 'Cân nặng',
                                    unit: 'kg',
                                    value: state.weightKg <= 0
                                        ? ''
                                        : state.weightKg.toStringAsFixed(1),
                                    hint: '65',
                                    onChanged: controller.updateWeight,
                                  ),
                                ],
                              ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    _FadeSlideIn(
                      delay: 540,
                      child: _TipCard(progress: progress),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _completedFields(dynamic state) {
    int count = 0;

    if (state.fullName.trim().isNotEmpty) count++;
    if (state.birthYear > 0) count++;
    if (state.occupation.trim().isNotEmpty) count++;
    if (state.gender.trim().isNotEmpty) count++;
    if (state.heightCm > 0) count++;
    if (state.weightKg > 0) count++;

    return count;
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    final percent = int.parse(((2 / 7) * 100).toStringAsFixed(0));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecoration.premiumGradient(radius: AppRadius.xxl),
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: AppDecoration.circle(
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),

          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: AppDecoration.circle(
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: AppDecoration.glass(
                      opacity: 0.16,
                      radius: AppRadius.circular,
                    ),
                    child: const Icon(
                      AppIcons.health,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),

                  const Spacer(),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: AppDecoration.glass(
                      opacity: 0.14,
                      radius: AppRadius.circular,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'BioAI',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                'Hành trình sức khỏe\nbắt đầu từ hôm nay',
                style: AppTextStyles.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Text(
                '“Mỗi lựa chọn nhỏ hôm nay sẽ tạo nên một cơ thể khỏe mạnh hơn trong tương lai.”',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.92),
                  fontStyle: FontStyle.italic,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Row(
                children: [
                  Expanded(
                    child: _MiniInfo(
                      title: '$percent%',
                      subtitle: 'Hoàn thiện',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: _MiniInfo(title: 'AI', subtitle: 'Cá nhân hóa'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: _MiniInfo(title: '24/7', subtitle: 'Đồng hành'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final String title;
  final String subtitle;

  const _MiniInfo({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: AppDecoration.glass(opacity: 0.12, radius: AppRadius.lg),
      child: Column(
        children: [
          Text(
            title,
            style: AppTextStyles.heading3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int completed;
  final double progress;

  const _ProgressCard({required this.completed, required this.progress});

  @override
  Widget build(BuildContext context) {
    final percent = 29;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.glass(opacity: 0.85, radius: AppRadius.xl),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: AppDecoration.primaryGradient(radius: AppRadius.lg),
                child: const Icon(AppIcons.success, color: Colors.white),
              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tiến độ hồ sơ',
                      style: AppTextStyles.heading5.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Text(
                      '2/7 thông tin đã hoàn thành',
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
              ),

              Text(
                '$percent%',
                style: AppTextStyles.heading3.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.circular),
            child: LinearProgressIndicator(
              value: 0.29,
              minHeight: 10,
              backgroundColor: AppColors.primarySoft,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading2.copyWith(fontWeight: FontWeight.w800),
        ),

        const SizedBox(height: AppSpacing.sm),

        Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(height: 1.6)),
      ],
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.glass(
        opacity: 0.92,
        radius: AppRadius.xl,
        shadows: AppShadows.soft,
      ),
      child: child,
    );
  }
}

class _ModernInput extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final String initialValue;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final ValueChanged<String> onChanged;

  const _ModernInput({
    required this.icon,
    required this.title,
    required this.hint,
    required this.initialValue,
    required this.keyboardType,
    required this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: AppDecoration.primaryGradient(radius: AppRadius.md),
              child: Icon(icon, color: Colors.white, size: 22),
            ),

            const SizedBox(width: AppSpacing.md),

            Expanded(
              child: Text(
                title,
                style: AppTextStyles.heading5.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: AppDecoration.outlined(
                color: AppColors.primarySoft,
                borderColor: AppColors.primary.withOpacity(0.2),
                radius: AppRadius.circular,
              ),
              child: Text(
                'Bắt buộc',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        TextFormField(
          initialValue: initialValue,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _MetricInput extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final String unit;
  final String value;
  final ValueChanged<String> onChanged;

  const _MetricInput({
    required this.icon,
    required this.title,
    required this.hint,
    required this.unit,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: AppDecoration.container(
        color: AppColors.surface,
        radius: AppRadius.lg,
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        shadows: AppShadows.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: AppDecoration.gradient(
                  colors: [
                    AppColors.primary.withOpacity(0.12),
                    AppColors.secondary.withOpacity(0.08),
                  ],
                  radius: AppRadius.md,
                ),
                child: Icon(icon, color: AppColors.primary),
              ),

              const SizedBox(width: AppSpacing.sm),

              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          TextFormField(
            initialValue: value,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            onChanged: onChanged,
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w800),
            decoration: InputDecoration(
              hintText: hint,
              suffixIconConstraints: const BoxConstraints(),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Center(
                  widthFactor: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: AppDecoration.gradient(
                      colors: [AppColors.primarySoft, AppColors.secondarySoft],
                      radius: AppRadius.circular,
                    ),
                    child: Text(
                      unit,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderGrid extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _GenderGrid({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final genders = [
      (
        code: 'male',
        title: 'Nam',
        icon: Icons.male_rounded,
        gradient: AppGradients.primary,
      ),
      (
        code: 'female',
        title: 'Nữ',
        icon: Icons.female_rounded,
        gradient: AppGradients.meditation,
      ),
    ];

    return Row(
      children: genders.map((item) {
        final selected = value == item.code;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: item.code == 'male' ? AppSpacing.sm : 0,
            ),
            child: GestureDetector(
              onTap: () => onChanged(item.code),
              child: AnimatedContainer(
                duration: AppDuration.normal,
                curve: AppAnimations.smoothCurve,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: selected
                    ? AppDecoration.gradient(
                        colors: item.gradient.colors,
                        radius: AppRadius.xl,
                        shadows: AppShadows.primary,
                      )
                    : AppDecoration.card(
                        radius: AppRadius.xl,
                        border: Border.all(color: AppColors.border),
                        shadows: AppShadows.sm,
                      ),
                child: Column(
                  children: [
                    AnimatedContainer(
                      duration: AppDuration.normal,
                      width: 68,
                      height: 68,
                      decoration: AppDecoration.circle(
                        color: selected
                            ? Colors.white.withOpacity(0.14)
                            : AppColors.primarySoft,
                      ),
                      child: Icon(
                        item.icon,
                        color: selected ? Colors.white : AppColors.primary,
                        size: 34,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    Text(
                      item.title,
                      style: AppTextStyles.heading4.copyWith(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    AnimatedContainer(
                      duration: AppDuration.normal,
                      width: 30,
                      height: 30,
                      decoration: AppDecoration.circle(
                        color: selected
                            ? Colors.white.withOpacity(0.18)
                            : AppColors.primarySoft,
                      ),
                      child: Icon(
                        selected
                            ? Icons.check_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: selected ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TipCard extends StatelessWidget {
  final double progress;

  const _TipCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecoration.gradient(
        colors: [AppColors.primarySoft, Colors.white],
        radius: AppRadius.xl,
        shadows: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: AppDecoration.primaryGradient(radius: AppRadius.lg),
            child: const Icon(AppIcons.info, color: Colors.white),
          ),

          const SizedBox(width: AppSpacing.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BioAI Insight',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                Text(
                  progress < 1
                      ? 'Hãy hoàn thành đầy đủ thông tin để AI xây dựng kế hoạch sức khỏe và dinh dưỡng chính xác hơn.'
                      : 'Hồ sơ của bạn đã hoàn tất. BioAI đã sẵn sàng cá nhân hóa trải nghiệm sức khỏe dành riêng cho bạn.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    height: 1.6,
                    color: AppColors.textSecondary,
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

class _FadeSlideIn extends StatefulWidget {
  final Widget child;
  final int delay;

  const _FadeSlideIn({required this.child, required this.delay});

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: AppDuration.slow);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.smoothCurve,
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppAnimations.fadeSlide(child: widget.child, animation: _animation);
  }
}

class _OnboardingBackgroundPainter extends CustomPainter {
  final double animation;

  const _OnboardingBackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.background,
          AppColors.primarySoft.withOpacity(0.8),
          Colors.white,
          AppColors.secondarySoft.withOpacity(0.45),
        ],
        transform: GradientRotation(animation * math.pi * 2),
      ).createShader(rect);

    canvas.drawRect(rect, backgroundPaint);

    final gridPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.03)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OnboardingBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

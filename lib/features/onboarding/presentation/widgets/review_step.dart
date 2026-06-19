import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/router/router.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/services/ai/ai_exceptions.dart';
import 'package:nano_app/shared/widgets/loading_genAI.dart';

import '../../providers/onboarding_provider.dart';

class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key});

  static const _sectionGap = SizedBox(height: AppSpacing.sectionSpacing);

  String _normalize(String value) {
    final text = value.trim();

    if (text.isEmpty) {
      return 'Chưa cập nhật';
    }

    return text;
  }

  String _formatFallback(String value) {
    final raw = value.trim();

    if (raw.isEmpty) {
      return 'Chưa cập nhật';
    }

    final normalized = raw.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ');

    return normalized
        .split(' ')
        .map((word) {
          if (word.isEmpty) {
            return word;
          }

          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  String _choiceLabel(List<OnboardingChoiceOption> options, String code) {
    final normalizedCode = code.trim();

    if (normalizedCode.isEmpty) {
      return 'Chưa cập nhật';
    }

    for (final option in options) {
      if (option.code == normalizedCode) {
        return option.label;
      }
    }

    return _formatFallback(normalizedCode);
  }

  String _number(double value, {String suffix = ''}) {
    return '${value.toStringAsFixed(1)}$suffix';
  }

  bool _hasValue(String value) {
    return value.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    final personalItems = <_ReviewInfo>[
      _ReviewInfo(
        title: 'Họ và tên',
        value: _normalize(state.fullName),
        icon: AppIcons.profile,
      ),
      if (_hasValue(state.email))
        _ReviewInfo(
          title: 'Email',
          value: _normalize(state.email),
          icon: AppIcons.email,
        ),
      if (_hasValue(state.phone))
        _ReviewInfo(
          title: 'Số điện thoại',
          value: _normalize(state.phone),
          icon: AppIcons.call,
        ),
      _ReviewInfo(
        title: 'Giới tính',
        value: _choiceLabel(OnboardingCatalog.genders, state.gender),
        icon: AppIcons.account,
      ),
      _ReviewInfo(
        title: 'Năm sinh',
        value: state.birthYear.toString(),
        icon: AppIcons.calendar,
      ),
      _ReviewInfo(
        title: 'Nghề nghiệp',
        value: _normalize(state.occupation),
        icon: AppIcons.dashboard,
      ),
    ];

    final goals = <String>[
      ...state.goals.map((code) => _choiceLabel(OnboardingCatalog.goals, code)),
      if (_hasValue(state.otherGoal)) _normalize(state.otherGoal),
    ];

    final conditions = <String>[
      ...state.conditions.map(
        (code) => _choiceLabel(OnboardingCatalog.conditions, code),
      ),
      if (_hasValue(state.otherCondition)) _normalize(state.otherCondition),
    ];

    final habits = state.habits
        .map((code) => _choiceLabel(OnboardingCatalog.habits, code))
        .toList();

    final contactLine = _hasValue(state.email)
        ? _normalize(state.email)
        : _hasValue(state.phone)
        ? _normalize(state.phone)
        : 'Hồ sơ sức khỏe cá nhân';

    final hasAllergy =
        _hasValue(state.allergyName) || _hasValue(state.allergyNote);

    final hasTreatment =
        _hasValue(state.treatmentName) ||
        _hasValue(state.medicationName) ||
        _hasValue(state.treatmentNote);

    return Container(
      decoration: AppDecoration.base(gradient: AppGradients.onboarding),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewTopBar(onBack: controller.previousStep),

              const SizedBox(height: AppSpacing.lg),

              TweenAnimationBuilder<double>(
                duration: AppDuration.normal,
                tween: Tween(begin: 0, end: 1),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 24 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: _HeroSection(
                  name: _normalize(state.fullName),
                  email: contactLine,
                  bmi: state.bmi,
                  gender: _choiceLabel(OnboardingCatalog.genders, state.gender),
                ),
              ),

              _sectionGap,

              _AnimatedSection(
                delay: 80,
                child: _SectionContainer(
                  title: 'Mình đã hiểu bạn thế này',
                  subtitle: 'Bạn xem lại thông tin cá nhân giúp mình nhé.',
                  icon: AppIcons.profile,
                  child: Column(
                    children: personalItems
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.itemSpacing,
                            ),
                            child: _InfoTile(item: item),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),

              _sectionGap,

              _AnimatedSection(
                delay: 140,
                child: _SectionContainer(
                  title: 'Thể trạng hiện tại của bạn',
                  subtitle: 'Đây là cơ sở để mình đưa ra gợi ý phù hợp hơn.',
                  icon: AppIcons.health,
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.itemSpacing,
                    mainAxisSpacing: AppSpacing.itemSpacing,
                    childAspectRatio: 1.08,
                    children: [
                      _MetricCard(
                        icon: AppIcons.steps,
                        title: 'Chiều cao',
                        value: _number(state.heightCm, suffix: ' cm'),
                        gradient: AppGradients.primary,
                      ),
                      _MetricCard(
                        icon: AppIcons.weight,
                        title: 'Cân nặng',
                        value: _number(state.weightKg, suffix: ' kg'),
                        gradient: AppGradients.health,
                      ),
                      _MetricCard(
                        icon: AppIcons.health,
                        title: 'BMI',
                        value: state.bmi.toStringAsFixed(1),
                        gradient: AppGradients.ai,
                      ),
                      _MetricCard(
                        icon: AppIcons.favorite,
                        title: 'Đánh giá',
                        value: _bmiLabel(state.bmi),
                        gradient: AppGradients.premium,
                      ),
                    ],
                  ),
                ),
              ),

              _sectionGap,

              _AnimatedSection(
                delay: 220,
                child: _SectionContainer(
                  title: 'Điều bạn muốn cùng mình cải thiện',
                  subtitle:
                      'Mình sẽ ưu tiên những mục tiêu này trong hành trình sắp tới.',
                  icon: AppIcons.star,
                  child: _ChipGroup(items: goals),
                ),
              ),

              _sectionGap,

              _AnimatedSection(
                delay: 300,
                child: _SectionContainer(
                  title: 'Những điều mình cần lưu ý',
                  subtitle: 'Mình sẽ cẩn thận hơn khi đưa ra gợi ý cho bạn.',
                  icon: AppIcons.warning,
                  child: _ChipGroup(items: conditions),
                ),
              ),

              _sectionGap,

              _AnimatedSection(
                delay: 380,
                child: _SectionContainer(
                  title: 'Nhịp sống hằng ngày của bạn',
                  subtitle: 'Mỗi thói quen nhỏ đều giúp mình hiểu bạn rõ hơn.',
                  icon: AppIcons.meditation,
                  child: Column(
                    children: [
                      _ChipGroup(items: habits),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      _LifestyleTile(
                        icon: AppIcons.sleep,
                        title: 'Chất lượng giấc ngủ',
                        value: _normalize(state.sleepQuality),
                      ),
                      const SizedBox(height: AppSpacing.itemSpacing),
                      _LifestyleTile(
                        icon: AppIcons.fitness,
                        title: 'Mức vận động',
                        value: _normalize(state.activityLevel),
                      ),
                      const SizedBox(height: AppSpacing.itemSpacing),
                      _LifestyleTile(
                        icon: AppIcons.water,
                        title: 'Lượng nước mỗi ngày',
                        value: _normalize(state.waterPerDay),
                      ),
                    ],
                  ),
                ),
              ),

              if (hasAllergy) ...[
                _sectionGap,
                _AnimatedSection(
                  delay: 440,
                  child: _SectionContainer(
                    title: 'Dị ứng',
                    subtitle: 'Thông tin dị ứng',
                    icon: AppIcons.warning,
                    child: Column(
                      children: [
                        _InfoTile(
                          item: _ReviewInfo(
                            title: 'Tên dị ứng',
                            value: _normalize(state.allergyName),
                            icon: AppIcons.warning,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.itemSpacing),
                        _InfoTile(
                          item: _ReviewInfo(
                            title: 'Ghi chú',
                            value: _normalize(state.allergyNote),
                            icon: AppIcons.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (hasTreatment) ...[
                _sectionGap,
                _AnimatedSection(
                  delay: 500,
                  child: _SectionContainer(
                    title: 'Điều trị hiện tại',
                    subtitle: 'Thông tin thuốc và điều trị',
                    icon: AppIcons.health,
                    child: Column(
                      children: [
                        _InfoTile(
                          item: _ReviewInfo(
                            title: 'Điều trị',
                            value: _normalize(state.treatmentName),
                            icon: AppIcons.health,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.itemSpacing),
                        _InfoTile(
                          item: _ReviewInfo(
                            title: 'Thuốc đang dùng',
                            value: _normalize(state.medicationName),
                            icon: AppIcons.favorite,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.itemSpacing),
                        _InfoTile(
                          item: _ReviewInfo(
                            title: 'Ghi chú',
                            value: _normalize(state.treatmentNote),
                            icon: AppIcons.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              _sectionGap,

              _AnimatedSection(
                delay: 560,
                child: _SectionContainer(
                  title: 'Điều bạn đang băn khoăn',
                  subtitle: 'Mình đã ghi nhớ để quan tâm đúng điều bạn cần.',
                  icon: AppIcons.chat,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.cardPadding),
                    decoration: AppDecoration.container(
                      color: AppColors.primarySoft,
                      radius: AppRadius.lg,
                    ),
                    child: Text(
                      _normalize(state.concernText),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.7,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: AppDecoration.primaryGradient(
                    radius: AppRadius.buttonLarge,
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!state.agreed) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Bạn hãy đồng ý với điều khoản để mình có thể bắt đầu đồng hành cùng bạn nhé.',
                            ),
                          ),
                        );
                        controller.goToStep(6);
                        return;
                      }

                      if (!state.canSave) {
                        // Kiểm tra từng trường bắt buộc và tạo thông báo chi tiết
                        final missingFields = <String>[];
                        if (state.fullName.trim().isEmpty) {
                          missingFields.add('Họ và tên');
                        }
                        if (state.gender.trim().isEmpty) {
                          missingFields.add('Giới tính');
                        }
                        if (state.birthYear <= 1900) {
                          missingFields.add('Năm sinh');
                        }
                        if (state.occupation.trim().isEmpty) {
                          missingFields.add('Nghề nghiệp');
                        }

                        final message = missingFields.isEmpty
                            ? 'Mình còn thiếu một vài thông tin bắt buộc. Bạn kiểm tra lại giúp mình nhé.'
                            : 'Bạn còn thiếu: ${missingFields.join(', ')}. Vui lòng quay lại bước 2 để điền đầy đủ nhé.';

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(message),
                            duration: const Duration(seconds: 4),
                            action: SnackBarAction(
                              label: 'Quay lại',
                              textColor: Colors.white,
                              onPressed: () {
                                controller.goToStep(1); // Quay về BasicInfoStep
                              },
                            ),
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AIGeneratingPage(),
                        ),
                      );

                      try {
                        await controller.saveOnboarding();

                        if (context.mounted) {
                          AppNavigator.goMenu(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);

                          final message = e is AIOverloadedException
                              ? AIOverloadedException.userMessage
                              : e is StateError
                              ? e.message.toString()
                              : 'Mình chưa thể hoàn tất lúc này. Bạn thử lại giúp mình nhé.';

                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(message)));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.large,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppRadius.buttonLarge,
                        ),
                      ),
                    ),
                    child: Text(
                      'Bắt đầu đồng hành cùng mình',
                      style: AppTextStyles.button.copyWith(
                        fontWeight: AppTypography.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _bmiLabel(double bmi) {
    if (bmi < 18.5) {
      return 'Thiếu cân';
    }

    if (bmi < 25) {
      return 'Ổn định';
    }

    if (bmi < 30) {
      return 'Thừa cân';
    }

    return 'Cần theo dõi';
  }
}

class _ReviewTopBar extends StatelessWidget {
  const _ReviewTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              width: AppSpacing.touchTargetMin,
              height: AppSpacing.touchTargetMin,
              decoration: AppDecoration.glass(
                radius: AppRadius.lg,
                opacity: 0.18,
                borderColor: AppColors.border,
              ),
              child: const Icon(AppIcons.back, color: AppColors.textPrimary),
            ),
          ),
        ),

        const SizedBox(width: AppSpacing.md),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Bước ${OnboardingCatalog.totalSteps}/${OnboardingCatalog.totalSteps}',
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Xem lại hồ sơ',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.circular),
                child: const LinearProgressIndicator(
                  value: 1,
                  minHeight: 6,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedSection extends StatelessWidget {
  const _AnimatedSection({required this.child, required this.delay});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: AppDuration.normal.inMilliseconds),
      tween: Tween(begin: 0, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, widget) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: widget,
          ),
        );
      },
      child: child,
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.name,
    required this.email,
    required this.bmi,
    required this.gender,
  });

  final String name;
  final String email;
  final double bmi;
  final String gender;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      decoration: AppDecoration.primaryGradient(radius: AppRadius.cardLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: AppDecoration.glass(radius: AppRadius.xl),
            child: const Icon(AppIcons.health, size: 34, color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Xem lại hồ sơ sức khỏe',
            style: AppTextStyles.heading2.copyWith(
              color: Colors.white,
              fontWeight: AppTypography.extraBold,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'AI sẽ sử dụng dữ liệu khảo sát để phân tích và cá nhân hóa trải nghiệm sức khỏe.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.92),
              height: 1.7,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: AppDecoration.glass(radius: AppRadius.xl),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: AppDecoration.circle(
                    color: Colors.white.withOpacity(0.14),
                  ),
                  child: const Icon(AppIcons.profile, color: Colors.white),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading4.copyWith(
                          color: Colors.white,
                          fontWeight: AppTypography.extraBold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _GlassPill(
                icon: AppIcons.health,
                text: 'BMI ${bmi.toStringAsFixed(1)}',
              ),
              _GlassPill(icon: AppIcons.profile, text: gender),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionContainer extends StatelessWidget {
  const _SectionContainer({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPaddingLarge),
      decoration: AppDecoration.premiumCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: AppDecoration.primaryGradient(radius: AppRadius.lg),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.sectionTitle.copyWith(
                        fontWeight: AppTypography.extraBold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(subtitle, style: AppTextStyles.sectionSubtitle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.item});

  final _ReviewInfo item;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: AppDecoration.container(
        color: AppColors.cardAlt,
        radius: AppRadius.lg,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: AppDecoration.circle(color: AppColors.primarySoft),
            child: Icon(item.icon, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: AppTextStyles.labelMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.value,
                  style: AppTextStyles.bodyEmphasis.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: AppTypography.semiBold,
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String value;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: AppDecoration.card(
        gradient: gradient,
        radius: AppRadius.xl,
        shadows: AppShadows.primary,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: AppDecoration.glass(radius: AppRadius.lg),
            child: Icon(icon, color: Colors.white),
          ),
          const Spacer(),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: AppTextStyles.heading4.copyWith(
              color: Colors.white,
              fontWeight: AppTypography.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _LifestyleTile extends StatelessWidget {
  const _LifestyleTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: AppDecoration.container(
        color: AppColors.surface,
        radius: AppRadius.lg,
        border: AppDecoration.border(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: AppDecoration.circle(color: AppColors.secondarySoft),
            child: Icon(icon, color: AppColors.secondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.labelMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: AppTextStyles.bodyEmphasis.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: AppTypography.semiBold,
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

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'Bạn chưa chia sẻ mục này với mình.',
        style: AppTextStyles.bodyMedium,
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items.map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.buttonPaddingHorizontal,
            vertical: AppSpacing.buttonPaddingVertical,
          ),
          decoration: AppDecoration.gradient(
            colors: [AppColors.primarySoft, Colors.white],
            radius: AppRadius.circular,
            shadows: AppShadows.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.checkIn, size: 16, color: AppColors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                item,
                style: AppTextStyles.chipLabel.copyWith(
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: AppDecoration.glass(radius: AppRadius.circular),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: AppSpacing.xs),
          Text(
            text,
            style: AppTextStyles.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: AppTypography.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewInfo {
  const _ReviewInfo({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/onboarding_constants.dart';
import '../../../../core/theme/theme.dart';
import '../controllers/onboarding_controller.dart';
import 'onboarding_step_shell.dart';

class BasicInfoStep extends ConsumerStatefulWidget {
  const BasicInfoStep({super.key});

  @override
  ConsumerState<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends ConsumerState<BasicInfoStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _backgroundController;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final controller = ref.read(onboardingProvider.notifier);

    final width = MediaQuery.sizeOf(context).width;
    final isTablet = width >= 700;

    final completedFields = _completedFieldCount(state);
    final progress = completedFields / 5.0;

    return Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              return CustomPaint(
                painter: _BackgroundPainter(
                  animation: _backgroundController.value,
                ),
              );
            },
          ),
        ),
        Positioned.fill(
          child: SafeArea(
            child: OnboardingStepShell(
              stepIndex: 1,
              title: '',
              subtitle: '',
              onBack: controller.previousStep,
              onNext: controller.nextStep,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AnimatedAppear(delay: 0, child: const _HealthQuoteHero()),
                    const SizedBox(height: 18),
                    _AnimatedAppear(
                      delay: 90,
                      child: _ProfileProgressCard(
                        progress: progress,
                        completedFields: completedFields,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const _SectionTitle(
                      title: 'Thông tin cá nhân',
                      subtitle:
                          'Chỉ cần điền những thông tin cơ bản để hệ thống cá nhân hóa trải nghiệm tốt hơn.',
                    ),
                    const SizedBox(height: 16),
                    _AnimatedAppear(
                      delay: 150,
                      child: _FormCard(
                        child: Column(
                          children: [
                            _ProfessionalInputField(
                              icon: Icons.person_rounded,
                              label: 'Họ và tên',
                              hint: 'Nhập họ và tên của bạn',
                              helper:
                                  'Dùng để hiển thị đúng tên trong hồ sơ cá nhân.',
                              initialValue: state.fullName,
                              textCapitalization: TextCapitalization.words,
                              keyboardType: TextInputType.name,
                              autofillHints: const [AutofillHints.name],
                              onChanged: controller.updateFullName,
                            ),
                            const SizedBox(height: 18),
                            _ProfessionalInputField(
                              icon: Icons.cake_rounded,
                              label: 'Năm sinh',
                              hint: 'Ví dụ: 2000',
                              helper: 'Chỉ nhập 4 chữ số.',
                              initialValue: state.birthYear.toString(),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              onChanged: controller.updateBirthYear,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const _SectionTitle(
                      title: 'Giới tính',
                      subtitle:
                          'Dùng để đưa ra gợi ý phù hợp hơn với hồ sơ của bạn.',
                    ),
                    const SizedBox(height: 16),
                    _AnimatedAppear(
                      delay: 230,
                      child: _GenderSelector(
                        currentGender: state.gender,
                        onChanged: controller.updateGender,
                      ),
                    ),
                    const SizedBox(height: 28),
                    const _SectionTitle(
                      title: 'Thông số cơ thể',
                      subtitle:
                          'Các chỉ số này giúp hệ thống tối ưu nội dung phù hợp hơn.',
                    ),
                    const SizedBox(height: 16),
                    _AnimatedAppear(
                      delay: 310,
                      child: _FormCard(
                        child: Column(
                          children: [
                            isTablet
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: _MetricField(
                                          label: 'Chiều cao',
                                          hint: 'Nhập chiều cao',
                                          unit: 'cm',
                                          icon: Icons.height_rounded,
                                          value: state.heightCm.toStringAsFixed(
                                            1,
                                          ),
                                          onChanged: controller.updateHeight,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _MetricField(
                                          label: 'Cân nặng',
                                          hint: 'Nhập cân nặng',
                                          unit: 'kg',
                                          icon: Icons.monitor_weight_rounded,
                                          value: state.weightKg.toStringAsFixed(
                                            1,
                                          ),
                                          onChanged: controller.updateWeight,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _MetricField(
                                        label: 'Chiều cao',
                                        hint: 'Nhập chiều cao',
                                        unit: 'cm',
                                        icon: Icons.height_rounded,
                                        value: state.heightCm.toStringAsFixed(
                                          1,
                                        ),
                                        onChanged: controller.updateHeight,
                                      ),
                                      const SizedBox(height: 16),
                                      _MetricField(
                                        label: 'Cân nặng',
                                        hint: 'Nhập cân nặng',
                                        unit: 'kg',
                                        icon: Icons.monitor_weight_rounded,
                                        value: state.weightKg.toStringAsFixed(
                                          1,
                                        ),
                                        onChanged: controller.updateWeight,
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    _AnimatedAppear(
                      delay: 390,
                      child: _BottomNote(
                        progress: progress,
                        completedFields: completedFields,
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

  int _completedFieldCount(dynamic state) {
    int count = 0;
    if (state.fullName.trim().isNotEmpty) count++;
    if (state.birthYear > 0) count++;
    if (state.gender.trim().isNotEmpty) count++;
    if (state.heightCm > 0) count++;
    if (state.weightKg > 0) count++;
    return count;
  }
}

class _HealthQuoteHero extends StatelessWidget {
  const _HealthQuoteHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D8CFF), Color(0xFF18A8E4)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D8CFF).withOpacity(0.22),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -24,
            right: -18,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -18,
            left: -12,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
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
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(AppRadius.circular),
                      border: Border.all(color: Colors.white.withOpacity(0.16)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
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
              const SizedBox(height: 26),
              Text(
                'Sức khỏe là nền tảng của mọi thành công',
                style: AppTextStyles.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '“Chăm sóc cơ thể hôm nay là cách bạn chuẩn bị cho một tương lai bền vững hơn.”',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: Colors.white.withOpacity(0.94),
                  height: 1.55,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _QuoteChip(text: 'Cá nhân hóa'),
                  _QuoteChip(text: 'Tối ưu trải nghiệm'),
                  _QuoteChip(text: 'Thiết kế rõ ràng'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuoteChip extends StatelessWidget {
  final String text;

  const _QuoteChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(AppRadius.circular),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Text(
          text,
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ProfileProgressCard extends StatelessWidget {
  final double progress;
  final int completedFields;

  const _ProfileProgressCard({
    required this.progress,
    required this.completedFields,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: AppDecoration.glass(
        opacity: 0.82,
        blurRadius: 18,
        radius: AppRadius.xl,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: AppGradients.primary,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mức độ hoàn thiện hồ sơ',
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hiện tại hồ sơ đã hoàn thành $percent% • càng đầy đủ, gợi ý càng chính xác.',
                  style: AppTextStyles.bodyMedium.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNote extends StatelessWidget {
  final double progress;
  final int completedFields;

  const _BottomNote({required this.progress, required this.completedFields});

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.84),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 22,
            color: AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              completedFields < 5
                  ? 'Bạn đã hoàn thành $percent% thông tin. Chỉ cần thêm vài mục nữa để tối ưu trải nghiệm cá nhân hóa.'
                  : 'Hồ sơ đã gần như hoàn chỉnh. Hệ thống sẽ dùng dữ liệu này để tạo trải nghiệm phù hợp hơn cho bạn.',
              style: AppTextStyles.bodyMedium.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(height: 1.55)),
      ],
    );
  }
}

class _FormCard extends StatelessWidget {
  final Widget child;

  const _FormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border.withOpacity(0.42)),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );
  }
}

class _ProfessionalInputField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final String helper;
  final String initialValue;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final ValueChanged<String> onChanged;

  const _ProfessionalInputField({
    required this.icon,
    required this.label,
    required this.hint,
    required this.helper,
    required this.initialValue,
    required this.keyboardType,
    required this.onChanged,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppGradients.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primarySoft.withOpacity(0.42),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(AppRadius.circular),
                      ),
                      child: Text(
                        'Bắt buộc',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: initialValue,
                  keyboardType: keyboardType,
                  textCapitalization: textCapitalization,
                  inputFormatters: inputFormatters,
                  autofillHints: autofillHints,
                  onChanged: onChanged,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    helperText: helper,
                    prefixIcon: Icon(icon, color: AppColors.primary),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: AppColors.border.withOpacity(0.55),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: AppColors.border.withOpacity(0.55),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricField extends StatelessWidget {
  final String label;
  final String hint;
  final String value;
  final String unit;
  final IconData icon;
  final ValueChanged<String> onChanged;

  const _MetricField({
    required this.label,
    required this.hint,
    required this.value,
    required this.unit,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primarySoft.withOpacity(0.40),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
              suffixIcon: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(AppRadius.circular),
                ),
                child: Text(
                  unit,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(
                  color: AppColors.border.withOpacity(0.55),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(
                  color: AppColors.border.withOpacity(0.55),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderSelector extends StatelessWidget {
  final String currentGender;
  final ValueChanged<String> onChanged;

  const _GenderSelector({required this.currentGender, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = <_GenderOption>[
      const _GenderOption(
        code: 'male',
        label: 'Nam',
        emoji: '👨',
        icon: Icons.male_rounded,
      ),
      const _GenderOption(
        code: 'female',
        label: 'Nữ',
        emoji: '👩',
        icon: Icons.female_rounded,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 118,
      ),
      itemBuilder: (context, index) {
        final item = options[index];
        final isSelected = currentGender == item.code;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(item.code),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: AnimatedContainer(
              duration: AppDuration.normal,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isSelected ? AppGradients.primary : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.border.withOpacity(0.7),
                ),
                boxShadow: isSelected ? AppShadows.primary : AppShadows.xs,
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: AppDuration.normal,
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withOpacity(0.18)
                          : AppColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item.icon,
                      color: isSelected ? Colors.white : AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: AppTextStyles.labelLarge.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedScale(
                    scale: isSelected ? 1 : 0.92,
                    duration: AppDuration.normal,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.18)
                            : AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.check_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 18,
                        color: isSelected ? Colors.white : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GenderOption {
  final String code;
  final String label;
  final String emoji;
  final IconData icon;

  const _GenderOption({
    required this.code,
    required this.label,
    required this.emoji,
    required this.icon,
  });
}

class _AnimatedAppear extends StatefulWidget {
  final Widget child;
  final int delay;

  const _AnimatedAppear({required this.child, required this.delay});

  @override
  State<_AnimatedAppear> createState() => _AnimatedAppearState();
}

class _AnimatedAppearState extends State<_AnimatedAppear>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _offset = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

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
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  final double animation;

  const _BackgroundPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.background,
          AppColors.primarySoft.withOpacity(0.32),
          Colors.white,
        ],
        transform: GradientRotation(animation * math.pi),
      ).createShader(rect);

    canvas.drawRect(rect, paint);

    final gridPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.025)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 42) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }

    for (double i = 0; i < size.height; i += 42) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

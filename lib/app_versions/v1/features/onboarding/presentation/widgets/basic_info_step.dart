import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/theme/theme.dart';
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
      duration: const Duration(seconds: 22),
    )..repeat();

    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, rootConstraints) {
          final spec = _ResponsiveSpec.fromWidth(rootConstraints.maxWidth);
          final reduceMotion = MediaQuery.of(context).disableAnimations;

          return Stack(
            children: [
              Positioned.fill(
                child: reduceMotion
                    ? const ColoredBox(color: AppColors.background)
                    : AnimatedBuilder(
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
              if (!spec.isPhone && !reduceMotion) ...[
                _FloatingBubble(
                  controller: _floatingController,
                  top: -120,
                  right: -100,
                  size: spec.isDesktop ? 260 : 220,
                  verticalRange: 20,
                  gradient: AppGradients.primary,
                  opacity: 0.12,
                ),
                _FloatingBubble(
                  controller: _floatingController,
                  bottom: -140,
                  left: -120,
                  size: spec.isDesktop ? 290 : 230,
                  verticalRange: -18,
                  gradient: AppGradients.ai,
                  opacity: 0.08,
                ),
              ],
              SafeArea(
                child: OnboardingStepShell(
                  stepIndex: 1,
                  title: '',
                  subtitle: '',
                  onBack: controller.previousStep,
                  onNext: controller.nextStep,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      spec.pagePadding,
                      AppSpacing.sm,
                      spec.pagePadding,
                      AppSpacing.xxxl,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: spec.contentMaxWidth,
                        ),
                        child: _AdaptiveContent(
                          spec: spec,
                          state: state,
                          controller: controller,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdaptiveContent extends StatelessWidget {
  final _ResponsiveSpec spec;
  final dynamic state;
  final dynamic controller;
  const _AdaptiveContent({
    required this.spec,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final profile = _ProfileForm(state: state, controller: controller);
    final bodyMetrics = _BodyMetricsForm(state: state, controller: controller);

    if (!spec.isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FadeSlideIn(delay: 0, child: _HeroCard()),
          SizedBox(height: spec.sectionGap),
          _FadeSlideIn(delay: 100, child: profile),
          SizedBox(height: spec.sectionGap),
          _FadeSlideIn(delay: 170, child: bodyMetrics),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [const _FadeSlideIn(delay: 0, child: _HeroCard())],
          ),
        ),
        SizedBox(width: spec.sectionGap),
        Expanded(
          flex: 7,
          child: Column(
            children: [
              _FadeSlideIn(delay: 120, child: profile),
              SizedBox(height: spec.sectionGap),
              _FadeSlideIn(delay: 180, child: bodyMetrics),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileForm extends StatelessWidget {
  final dynamic state;
  final dynamic controller;

  const _ProfileForm({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          eyebrow: 'Bước 2',
          title: 'Nami muốn hiểu bạn hơn một chút',
          subtitle:
              'Bạn chỉ cần chọn hoặc nhập nhanh vài thông tin cơ bản. Nami sẽ dùng những dữ liệu này để gợi ý chăm sóc sức khỏe gần gũi và vừa vặn hơn.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _GlassCard(
          child: Column(
            children: [
              _NameInput(
                value: state.fullName,
                onChanged: controller.updateFullName,
              ),
              const SizedBox(height: AppSpacing.lg),
              _AdaptiveWrap(
                minItemWidth: 260,
                children: [
                  _YearPickerField(
                    icon: AppIcons.calendar,
                    title: 'Bạn sinh năm nào?',
                    subtitle: 'Chạm để chọn nhanh, hoặc tự nhập nếu bạn muốn.',
                    value: state.birthYear > 0 ? state.birthYear : null,
                    onChanged: (value) =>
                        controller.updateBirthYear(value.toString()),
                  ),
                  _OptionPickerField(
                    icon: AppIcons.dashboard,
                    title: 'Một ngày của bạn thường như thế nào?',
                    subtitle:
                        'Chọn nhóm gần đúng nhất để Nami hiểu nhịp sống của bạn.',
                    value: state.occupation,
                    hint: 'Chọn nhóm công việc',
                    options: _OccupationOptions.items,
                    onChanged: controller.updateOccupation,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _SectionHeader(
          eyebrow: 'Cá nhân hóa',
          title: 'Nami nên ghi nhận giới tính của bạn thế nào?',
          subtitle:
              'Thông tin này giúp các gợi ý về dinh dưỡng, năng lượng và thể trạng sát với bạn hơn.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _GenderSelector(
          value: state.gender,
          onChanged: controller.updateGender,
        ),
      ],
    );
  }
}

class _BodyMetricsForm extends StatelessWidget {
  final dynamic state;
  final dynamic controller;

  const _BodyMetricsForm({required this.state, required this.controller});

  @override
  Widget build(BuildContext context) {
    final heights = List<int>.generate(111, (index) => 120 + index);
    final weights = List<int>.generate(136, (index) => 35 + index);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          eyebrow: 'Thể trạng hiện tại',
          title: 'Nami xin thêm chiều cao và cân nặng nhé',
          subtitle:
              'Bạn có thể chọn nhanh hoặc tự nhập con số riêng. Chỉ cần gần đúng là đủ để Nami bắt đầu cá nhân hóa kế hoạch.',
        ),
        const SizedBox(height: AppSpacing.lg),
        _GlassCard(
          child: _AdaptiveWrap(
            minItemWidth: 250,
            children: [
              _NumberPickerField(
                icon: AppIcons.fitness,
                title: 'Chiều cao hiện tại',
                subtitle: 'Giúp Nami ước tính BMI và mức vận động phù hợp.',
                value: state.heightCm > 0 ? state.heightCm.round() : null,
                hint: 'Chọn chiều cao',
                unit: 'cm',
                items: heights,
                onChanged: (value) => controller.updateHeight(value.toString()),
              ),
              _NumberPickerField(
                icon: AppIcons.weight,
                title: 'Cân nặng hiện tại',
                subtitle:
                    'Không cần quá chính xác ngay lúc này, Nami sẽ cùng bạn cập nhật sau.',
                value: state.weightKg > 0 ? state.weightKg.round() : null,
                hint: 'Chọn cân nặng',
                unit: 'kg',
                items: weights,
                onChanged: (value) => controller.updateWeight(value.toString()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;
        final padding = compact ? AppSpacing.lg : AppSpacing.xl;
        final iconSize = compact ? 54.0 : 64.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xxl),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(padding),
            decoration: AppDecoration.premiumGradient(radius: AppRadius.xxl),
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned(
                  top: -56,
                  right: -48,
                  child: _HeroGlow(size: compact ? 130 : 170, opacity: 0.08),
                ),
                Positioned(
                  bottom: -70,
                  left: -52,
                  child: _HeroGlow(size: compact ? 120 : 150, opacity: 0.06),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: [
                        Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: AppDecoration.glass(
                            opacity: 0.16,
                            radius: AppRadius.circular,
                          ),
                          child: Icon(
                            AppIcons.health,
                            color: Colors.white,
                            size: compact ? 26 : 30,
                          ),
                        ),
                        _HeroBadge(compact: compact),
                      ],
                    ),
                    SizedBox(height: compact ? AppSpacing.lg : AppSpacing.xl),
                    Text(
                      'Nami sẽ chăm sóc bạn\ntheo cách riêng của bạn',
                      style:
                          (compact
                                  ? AppTextStyles.heading1
                                  : AppTextStyles.displaySmall)
                              .copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                height: 1.12,
                              ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Mình là Nami, trợ lý sức khỏe ảo của bạn. Chỉ vài thông tin nhẹ nhàng thôi, Nami sẽ giúp bạn xây một lộ trình dễ theo, vừa sức và có thể duy trì mỗi ngày.',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: Colors.white.withOpacity(0.92),
                        height: 1.62,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HeroBadge extends StatelessWidget {
  final bool compact;

  const _HeroBadge({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: AppDecoration.glass(
        opacity: 0.14,
        radius: AppRadius.circular,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.ai, size: 16, color: Colors.white),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Nami đồng hành',
            style: AppTextStyles.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroGlow extends StatelessWidget {
  final double size;
  final double opacity;

  const _HeroGlow({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: AppDecoration.circle(
        color: Colors.white.withOpacity(opacity),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: AppDecoration.outlined(
                color: AppColors.primarySoft,
                borderColor: AppColors.primary.withOpacity(0.18),
                radius: AppRadius.circular,
              ),
              child: Text(
                eyebrow.toUpperCase(),
                style: AppTextStyles.overline.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: (compact ? AppTextStyles.heading3 : AppTextStyles.heading2)
                  .copyWith(fontWeight: FontWeight.w900, height: 1.24),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.62,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg),
          decoration: AppDecoration.glass(
            opacity: 0.94,
            radius: AppRadius.xl,
            shadows: AppShadows.soft,
          ).copyWith(border: Border.all(color: Colors.white.withOpacity(0.72))),
          child: child,
        );
      },
    );
  }
}

class _AdaptiveWrap extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double gap;

  const _AdaptiveWrap({
    required this.children,
    this.minItemWidth = 260,
    this.gap = AppSpacing.lg,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = _columnsFor(
          maxWidth,
          minItemWidth,
          gap,
          children.length,
        );
        final itemWidth = columns == 1
            ? maxWidth
            : (maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map(
                (child) => SizedBox(
                  width: itemWidth.isFinite ? itemWidth : maxWidth,
                  child: child,
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }

  int _columnsFor(double maxWidth, double minWidth, double gap, int itemCount) {
    if (!maxWidth.isFinite || maxWidth <= 0) return 1;

    final columns = ((maxWidth + gap) / (minWidth + gap)).floor();
    return columns.clamp(1, itemCount).toInt();
  }
}

class _NameInput extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _NameInput({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _FieldFrame(
      icon: AppIcons.profile,
      title: 'Mình nên gọi bạn là gì?',
      subtitle: 'Bạn có thể nhập tên thật hoặc tên thân mật đều được.',
      requiredLabel: true,
      child: TextFormField(
        initialValue: value,
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
        autofillHints: const [AutofillHints.name],
        onChanged: onChanged,
        style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: 'Ví dụ: Hùng, Minh Anh...',
          prefixIcon: const Icon(AppIcons.profile, color: AppColors.primary),
          suffixIcon: value.trim().isNotEmpty
              ? const Icon(AppIcons.success, color: AppColors.success)
              : null,
        ),
      ),
    );
  }
}

class _YearPickerField extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int? value;
  final ValueChanged<int> onChanged;

  const _YearPickerField({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List<int>.generate(86, (index) => currentYear - 10 - index);

    return _FieldFrame(
      icon: icon,
      title: title,
      subtitle: subtitle,
      requiredLabel: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelectionSummary(
            icon: icon,
            label: value == null ? 'Chọn năm sinh' : '$value',
            selected: value != null,
            onTap: () => _showYearPicker(context, years),
          ),
          const SizedBox(height: AppSpacing.sm),
          _InlineActionButton(
            label: 'Tự nhập năm sinh khác',
            onPressed: () => _showCustomYearInput(context),
          ),
        ],
      ),
    );
  }

  void _showYearPicker(BuildContext context, List<int> years) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PickerSheet(
          title: 'Chọn năm sinh',
          subtitle:
              'Nami sẽ dùng năm sinh để cá nhân hóa nhịp ăn uống, vận động và lời nhắc phù hợp hơn.',
          child: _YearPickerList(
            years: years,
            selectedYear: value,
            onSelected: (year) {
              Navigator.of(context).pop();
              onChanged(year);
            },
          ),
        );
      },
    );
  }

  void _showCustomYearInput(BuildContext context) {
    final textController = TextEditingController(
      text: value == null ? '' : value.toString(),
    );

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: _PickerSheet(
            title: 'Tự nhập năm sinh',
            subtitle:
                'Bạn nhập 4 chữ số của năm sinh nhé. Ví dụ: 2005, 1998, 1985.',
            actionLabel: 'Lưu năm sinh',
            onAction: () {
              final year = int.tryParse(textController.text.trim());
              final currentYear = DateTime.now().year;

              if (year == null || year < 1900 || year > currentYear) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Năm sinh chưa hợp lệ, bạn kiểm tra lại nhé.',
                    ),
                  ),
                );
                return;
              }

              Navigator.of(context).pop();
              onChanged(year);
            },
            child: TextFormField(
              controller: textController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 4,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                hintText: 'Ví dụ: 2005',
                prefixIcon: Icon(AppIcons.calendar, color: AppColors.primary),
                counterText: '',
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OptionPickerField extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final String hint;
  final List<_OptionItem> options;
  final ValueChanged<String> onChanged;

  const _OptionPickerField({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.hint,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value.trim().isNotEmpty;

    return _FieldFrame(
      icon: icon,
      title: title,
      subtitle: subtitle,
      requiredLabel: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelectionSummary(
            icon: icon,
            label: selected ? value : hint,
            selected: selected,
            onTap: () => _showOptions(context),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ...options.take(5).map((option) {
                final isSelected = value == option.label;

                return _ChoicePill(
                  label: option.label,
                  icon: option.icon,
                  selected: isSelected,
                  onTap: () {
                    if (option.label == 'Khác') {
                      _showCustomInput(context);
                    } else {
                      onChanged(option.label);
                    }
                  },
                );
              }),
              _ChoicePill(
                label: 'Tự nhập',
                icon: Icons.edit_rounded,
                selected:
                    selected && !options.any((option) => option.label == value),
                onTap: () => _showCustomInput(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PickerSheet(
          title: 'Chọn nhóm công việc gần nhất với bạn',
          subtitle:
              'Nếu chưa có lựa chọn đúng, bạn chọn “Khác” hoặc bấm “Tự nhập”.',
          child: _ResponsiveOptionGrid(
            itemCount: options.length + 1,
            itemBuilder: (context, index) {
              if (index == options.length) {
                return _OptionTile(
                  option: const _OptionItem('Tự nhập', Icons.edit_rounded),
                  selected:
                      value.trim().isNotEmpty &&
                      !options.any((option) => option.label == value),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showCustomInput(context);
                  },
                );
              }

              final option = options[index];
              final selected = value == option.label;

              return _OptionTile(
                option: option,
                selected: selected,
                onTap: () {
                  Navigator.of(context).pop();

                  if (option.label == 'Khác') {
                    _showCustomInput(context);
                  } else {
                    onChanged(option.label);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }

  void _showCustomInput(BuildContext context) {
    final textController = TextEditingController(
      text: options.any((option) => option.label == value) ? '' : value,
    );

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: _PickerSheet(
            title: 'Bạn muốn tự nhập công việc?',
            subtitle:
                'Bạn cứ viết theo cách tự nhiên nhất. Ví dụ: “làm ca đêm”, “freelancer”, “đang tìm việc”.',
            actionLabel: 'Lưu thông tin',
            onAction: () {
              final text = textController.text.trim();

              if (text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Bạn nhập thêm một chút để mình ghi nhận nhé.',
                    ),
                  ),
                );
                return;
              }

              Navigator.of(context).pop();
              onChanged(text);
            },
            child: TextFormField(
              controller: textController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: AppTextStyles.bodyLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
              decoration: const InputDecoration(
                hintText: 'Ví dụ: Nội trợ, làm văn phòng hoặc đã nghỉ hưu',
                prefixIcon: Icon(AppIcons.dashboard, color: AppColors.primary),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NumberPickerField extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int? value;
  final String hint;
  final String unit;
  final List<int> items;
  final ValueChanged<int> onChanged;

  const _NumberPickerField({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.hint,
    required this.unit,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _FieldFrame(
      icon: icon,
      title: title,
      subtitle: subtitle,
      requiredLabel: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelectionSummary(
            icon: icon,
            label: value == null ? hint : '$value $unit',
            selected: value != null,
            onTap: () => _showPicker(context),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ..._quickValues().map((quickValue) {
                final selected = value == quickValue;

                return _ChoicePill(
                  label: '$quickValue $unit',
                  selected: selected,
                  onTap: () => onChanged(quickValue),
                );
              }),
              _ChoicePill(
                label: 'Tự nhập',
                icon: Icons.edit_rounded,
                selected: value != null && !items.contains(value),
                onTap: () => _showCustomNumberInput(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<int> _quickValues() {
    if (unit == 'cm') return [155, 160, 165, 170, 175, 180];
    return [45, 50, 55, 60, 65, 70];
  }

  void _showPicker(BuildContext context) {
    var selectedIndex = value == null
        ? items.length ~/ 2
        : items.indexOf(value!);
    if (selectedIndex < 0) selectedIndex = items.length ~/ 2;

    final scrollController = FixedExtentScrollController(
      initialItem: selectedIndex,
    );

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _PickerSheet(
              title: title,
              subtitle:
                  'Kéo để chọn nhanh, hoặc bấm “Tự nhập” nếu muốn nhập con số riêng.',
              actionLabel: 'Chọn ${items[selectedIndex]} $unit',
              onAction: () {
                Navigator.of(context).pop();
                onChanged(items[selectedIndex]);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 220,
                    child: ListWheelScrollView.useDelegate(
                      controller: scrollController,
                      itemExtent: 56,
                      physics: const FixedExtentScrollPhysics(),
                      perspective: 0.004,
                      onSelectedItemChanged: (index) {
                        setModalState(() {
                          selectedIndex = index;
                        });
                      },
                      childDelegate: ListWheelChildBuilderDelegate(
                        childCount: items.length,
                        builder: (context, index) {
                          final item = items[index];
                          final selected = index == selectedIndex;

                          return Center(
                            child: AnimatedDefaultTextStyle(
                              duration: AppDuration.fast,
                              style: selected
                                  ? AppTextStyles.heading2.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w900,
                                    )
                                  : AppTextStyles.bodyLarge.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              child: Text('$item $unit'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showCustomNumberInput(context);
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: Text('Tự nhập $unit khác'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(scrollController.dispose);
  }

  void _showCustomNumberInput(BuildContext context) {
    final textController = TextEditingController(
      text: value == null ? '' : value.toString(),
    );

    final min = unit == 'cm' ? 80 : 20;
    final max = unit == 'cm' ? 250 : 250;
    final example = unit == 'cm' ? '178' : '72';

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: _PickerSheet(
            title: 'Tự nhập $title',
            subtitle:
                'Bạn nhập con số gần đúng là được. Sau này có thay đổi, mình sẽ cập nhật lại cùng bạn.',
            actionLabel: 'Lưu $title',
            onAction: () {
              final number = int.tryParse(textController.text.trim());

              if (number == null || number < min || number > max) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Giá trị chưa hợp lệ. Bạn nhập trong khoảng $min - $max $unit nhé.',
                    ),
                  ),
                );
                return;
              }

              Navigator.of(context).pop();
              onChanged(number);
            },
            child: TextFormField(
              controller: textController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.heading3.copyWith(
                fontWeight: FontWeight.w800,
              ),
              decoration: InputDecoration(
                hintText: 'Ví dụ: $example',
                prefixIcon: Icon(icon, color: AppColors.primary),
                suffixText: unit,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FieldFrame extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool requiredLabel;
  final Widget child;

  const _FieldFrame({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
    this.requiredLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
          decoration: AppDecoration.container(
            color: AppColors.surface,
            radius: AppRadius.lg,
            border: Border.all(color: AppColors.border.withOpacity(0.55)),
            shadows: AppShadows.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              compact
                  ? _CompactFieldHeader(
                      icon: icon,
                      title: title,
                      subtitle: subtitle,
                      requiredLabel: requiredLabel,
                    )
                  : _RegularFieldHeader(
                      icon: icon,
                      title: title,
                      subtitle: subtitle,
                      requiredLabel: requiredLabel,
                    ),
              const SizedBox(height: AppSpacing.md),
              child,
            ],
          ),
        );
      },
    );
  }
}

class _RegularFieldHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool requiredLabel;

  const _RegularFieldHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.requiredLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FieldIcon(icon: icon),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTextStyles.heading5.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.28,
                      ),
                    ),
                  ),
                  if (requiredLabel) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const _RequiredBadge(),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompactFieldHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool requiredLabel;

  const _CompactFieldHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.requiredLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _FieldIcon(icon: icon, size: 40),
            const Spacer(),
            if (requiredLabel) const _RequiredBadge(),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          title,
          style: AppTextStyles.heading5.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.28,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _FieldIcon extends StatelessWidget {
  final IconData icon;
  final double size;

  const _FieldIcon({required this.icon, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: AppDecoration.gradient(
        colors: [
          AppColors.primary.withOpacity(0.14),
          AppColors.secondary.withOpacity(0.08),
        ],
        radius: AppRadius.md,
      ),
      child: Icon(icon, color: AppColors.primary, size: size * 0.5),
    );
  }
}

class _RequiredBadge extends StatelessWidget {
  const _RequiredBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: AppDecoration.outlined(
        color: AppColors.primarySoft,
        borderColor: AppColors.primary.withOpacity(0.18),
        radius: AppRadius.circular,
      ),
      child: Text(
        'Cần có',
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SelectionSummary extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectionSummary({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDuration.fast,
      curve: AppAnimations.smoothCurve,
      decoration: AppDecoration.container(
        color: selected ? null : AppColors.inputBackground,
        gradient: selected
            ? LinearGradient(
                colors: [
                  AppColors.primarySoft,
                  Colors.white,
                  AppColors.secondarySoft.withOpacity(0.48),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        radius: AppRadius.lg,
        border: Border.all(
          color: selected
              ? AppColors.primary.withOpacity(0.34)
              : AppColors.border.withOpacity(0.86),
          width: selected ? 1.35 : 1,
        ),
        shadows: selected ? AppShadows.focus : AppShadows.xs,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: selected
                      ? AppDecoration.primaryGradient(radius: AppRadius.md)
                      : AppDecoration.gradient(
                          colors: [
                            AppColors.primary.withOpacity(0.12),
                            AppColors.secondary.withOpacity(0.08),
                          ],
                          radius: AppRadius.md,
                        ),
                  child: Icon(
                    icon,
                    color: selected ? Colors.white : AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selected ? 'Đã chọn' : 'Chạm để chọn',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: selected
                              ? AppColors.primary
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: selected
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AnimatedContainer(
                  duration: AppDuration.fast,
                  width: 32,
                  height: 32,
                  decoration:
                      AppDecoration.circle(
                        color: selected ? AppColors.successSoft : Colors.white,
                      ).copyWith(
                        border: Border.all(
                          color: selected
                              ? AppColors.success.withOpacity(0.24)
                              : AppColors.border,
                        ),
                      ),
                  child: Icon(
                    selected ? AppIcons.success : AppIcons.expand,
                    size: selected ? 18 : 22,
                    color: selected ? AppColors.success : AppColors.primary,
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

class _ChoicePill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final maxChipWidth = math.max(160.0, MediaQuery.sizeOf(context).width - 88);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxChipWidth),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.circular),
          child: Ink(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: selected
                ? AppDecoration.gradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    radius: AppRadius.circular,
                    shadows: AppShadows.primary,
                  )
                : AppDecoration.outlined(
                    color: AppColors.surface,
                    borderColor: AppColors.border,
                    radius: AppRadius.circular,
                  ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? Colors.white : AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: selected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
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

class _GenderSelector extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _GenderSelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final genders = [
      _GenderOption(
        code: 'male',
        title: 'Nam',
        description: 'Mình sẽ tối ưu theo hồ sơ nam giới.',
        icon: Icons.male_rounded,
        gradient: AppGradients.primary,
      ),
      _GenderOption(
        code: 'female',
        title: 'Nữ',
        description: 'Mình sẽ tối ưu theo hồ sơ nữ giới.',
        icon: Icons.female_rounded,
        gradient: AppGradients.meditation,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columns = maxWidth >= 540 ? 2 : 1;
        const gap = AppSpacing.md;
        final itemWidth = columns == 1
            ? maxWidth
            : (maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: genders
              .map(
                (item) => SizedBox(
                  width: itemWidth.isFinite ? itemWidth : maxWidth,
                  child: _GenderCard(
                    item: item,
                    selected: value == item.code,
                    onTap: () => onChanged(item.code),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _GenderCard extends StatelessWidget {
  final _GenderOption item;
  final bool selected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: AnimatedContainer(
          duration: AppDuration.normal,
          curve: AppAnimations.smoothCurve,
          constraints: const BoxConstraints(minHeight: 118),
          padding: const EdgeInsets.all(AppSpacing.md),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: AppDuration.normal,
                    width: 44,
                    height: 44,
                    decoration: AppDecoration.circle(
                      color: selected
                          ? Colors.white.withOpacity(0.16)
                          : AppColors.primarySoft,
                    ),
                    child: Icon(
                      item.icon,
                      color: selected ? Colors.white : AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const Spacer(),
                  AnimatedContainer(
                    duration: AppDuration.normal,
                    width: 24,
                    height: 24,
                    decoration: AppDecoration.circle(
                      color: selected
                          ? Colors.white.withOpacity(0.20)
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
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.heading5.copyWith(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: selected
                      ? Colors.white.withOpacity(0.88)
                      : AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _PickerSheet({
    required this.title,
    required this.subtitle,
    required this.child,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          decoration: AppDecoration.bottomSheet(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: AppDecoration.container(
                      color: AppColors.border,
                      radius: AppRadius.circular,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  style: AppTextStyles.heading3.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                child,
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResponsiveOptionGrid extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  const _ResponsiveOptionGrid({
    required this.itemCount,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 720
            ? 3
            : width >= 360
            ? 2
            : 1;
        final childAspectRatio = crossAxisCount == 1 ? 3.1 : 1.38;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        );
      },
    );
  }
}

class _YearPickerList extends StatelessWidget {
  final List<int> years;
  final int? selectedYear;
  final ValueChanged<int> onSelected;

  const _YearPickerList({
    required this.years,
    required this.selectedYear,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: math.min(MediaQuery.sizeOf(context).height * 0.46, 360),
      child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        itemCount: years.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final year = years[index];
          final selected = year == selectedYear;

          return _PickerListTile(
            icon: AppIcons.calendar,
            title: '$year',
            subtitle: 'Khoảng ${DateTime.now().year - year} tuổi',
            selected: selected,
            onTap: () => onSelected(year),
          );
        },
      ),
    );
  }
}

class _PickerListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PickerListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDuration.fast,
      curve: AppAnimations.smoothCurve,
      decoration: selected
          ? AppDecoration.gradient(
              colors: [AppColors.primary, AppColors.secondary],
              radius: AppRadius.lg,
              shadows: AppShadows.primary,
            )
          : AppDecoration.card(
              radius: AppRadius.lg,
              border: Border.all(color: AppColors.border),
              shadows: AppShadows.xs,
            ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: AppDecoration.circle(
                    color: selected
                        ? Colors.white.withOpacity(0.18)
                        : AppColors.primarySoft,
                  ),
                  child: Icon(
                    icon,
                    color: selected ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading5.copyWith(
                          color: selected
                              ? Colors.white
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: selected
                              ? Colors.white.withOpacity(0.86)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(
                  selected ? AppIcons.success : AppIcons.forward,
                  color: selected ? Colors.white : AppColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final _OptionItem option;
  final bool selected;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: selected
              ? AppDecoration.gradient(
                  colors: [AppColors.primary, AppColors.secondary],
                  radius: AppRadius.lg,
                  shadows: AppShadows.primary,
                )
              : AppDecoration.card(
                  radius: AppRadius.lg,
                  border: Border.all(color: AppColors.border),
                  shadows: AppShadows.xs,
                ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final oneLine = constraints.maxWidth > constraints.maxHeight;

              if (oneLine) {
                return Row(
                  children: [
                    _OptionIcon(option: option, selected: selected),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _OptionLabel(option: option, selected: selected),
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _OptionIcon(option: option, selected: selected),
                  const Spacer(),
                  _OptionLabel(option: option, selected: selected),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OptionIcon extends StatelessWidget {
  final _OptionItem option;
  final bool selected;

  const _OptionIcon({required this.option, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: AppDecoration.circle(
        color: selected
            ? Colors.white.withOpacity(0.18)
            : AppColors.primarySoft,
      ),
      child: Icon(
        option.icon,
        color: selected ? Colors.white : AppColors.primary,
        size: 20,
      ),
    );
  }
}

class _OptionLabel extends StatelessWidget {
  final _OptionItem option;
  final bool selected;

  const _OptionLabel({required this.option, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Text(
      option.label,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.labelMedium.copyWith(
        color: selected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w900,
        height: 1.28,
      ),
    );
  }
}

class _InlineActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _InlineActionButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _FloatingBubble extends StatelessWidget {
  final AnimationController controller;
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double size;
  final double verticalRange;
  final Gradient gradient;
  final double opacity;

  const _FloatingBubble({
    required this.controller,
    required this.size,
    required this.verticalRange,
    required this.gradient,
    required this.opacity,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            return Transform.translate(
              offset: Offset(
                0,
                math.sin(controller.value * math.pi) * verticalRange,
              ),
              child: Container(
                width: size,
                height: size,
                decoration: AppDecoration.circle(
                  gradient: gradient,
                ).copyWith(color: AppColors.primary.withOpacity(opacity)),
              ),
            );
          },
        ),
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
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
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
          AppColors.primarySoft.withOpacity(0.82),
          Colors.white,
          AppColors.secondarySoft.withOpacity(0.48),
        ],
        transform: GradientRotation(animation * math.pi * 2),
      ).createShader(rect);

    canvas.drawRect(rect, backgroundPaint);

    final gridPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.026)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += 42) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OnboardingBackgroundPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

class _ResponsiveSpec {
  final double width;
  final bool isPhone;
  final bool isTablet;
  final bool isDesktop;
  final double pagePadding;
  final double contentMaxWidth;
  final double sectionGap;

  const _ResponsiveSpec({
    required this.width,
    required this.isPhone,
    required this.isTablet,
    required this.isDesktop,
    required this.pagePadding,
    required this.contentMaxWidth,
    required this.sectionGap,
  });

  factory _ResponsiveSpec.fromWidth(double width) {
    final isPhone = width < 600;
    final isTablet = width >= 600 && width < 1100;
    final isDesktop = width >= 1100;

    return _ResponsiveSpec(
      width: width,
      isPhone: isPhone,
      isTablet: isTablet,
      isDesktop: isDesktop,
      pagePadding: isDesktop
          ? AppSpacing.xl
          : isTablet
          ? AppSpacing.lg
          : AppSpacing.md,
      contentMaxWidth: isDesktop
          ? 1180
          : isTablet
          ? 760
          : 640,
      sectionGap: isPhone ? AppSpacing.lg : AppSpacing.xl,
    );
  }
}

class _OccupationOptions {
  static const items = [
    _OptionItem('Học sinh / Sinh viên', Icons.school_rounded),
    _OptionItem('Nhân viên văn phòng', Icons.business_center_rounded),
    _OptionItem('Kinh doanh / Bán hàng', Icons.storefront_rounded),
    _OptionItem('Lao động tự do', Icons.work_outline_rounded),
    _OptionItem('Nội trợ / chăm sóc gia đình', Icons.home_rounded),
    _OptionItem('Nghỉ hưu', Icons.spa_rounded),
    _OptionItem('Khác', Icons.more_horiz_rounded),
  ];
}

class _OptionItem {
  final String label;
  final IconData icon;

  const _OptionItem(this.label, this.icon);
}

class _GenderOption {
  final String code;
  final String title;
  final String description;
  final IconData icon;
  final LinearGradient gradient;

  const _GenderOption({
    required this.code,
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}

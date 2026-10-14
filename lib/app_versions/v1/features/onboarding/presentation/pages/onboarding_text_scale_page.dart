import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/onboarding_stitch_components.dart';
import 'package:nano_app/core/theme/app_text_scale.dart';
import 'package:nano_app/core/theme/theme.dart';

class OnboardingTextScaleGate extends ConsumerWidget {
  const OnboardingTextScaleGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appTextScaleControllerProvider);
    return state.when(
      data: (value) =>
          value.isConfigured ? child : const OnboardingTextScalePage(),
      loading: () => const MedicalPageScaffold(
        body: Center(
          child: CircularProgressIndicator(color: NabiPalette.greenPrimary),
        ),
      ),
      error: (_, __) => const OnboardingTextScalePage(),
    );
  }
}

class OnboardingTextScalePage extends ConsumerWidget {
  const OnboardingTextScalePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appTextScaleControllerProvider).value;
    final selected = state?.preset ?? AppTextScalePreset.standard;
    final controller = ref.read(appTextScaleControllerProvider.notifier);
    final colors = context.semanticColors;
    final presets = AppTextScalePreset.values;
    final selectedIndex = presets.indexOf(selected);

    return MedicalPageScaffold(
      backgroundColor: colors.background,
      body: NabiAmbientBackground(
        strong: true,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: IconButton.filledTonal(
                        key: const Key('onboarding_text_scale_back'),
                        tooltip: 'Quay lại',
                        onPressed: () {
                          if (GoRouter.of(context).canPop()) {
                            GoRouter.of(context).pop();
                          }
                        },
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: colors.card,
                          foregroundColor: colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cài đặt hiển thị',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: colors.textSecondary,
                              letterSpacing: 0,
                            ),
                          ),
                          Text(
                            'Kích thước chữ',
                            style: AppTextStyles.heading5.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.format_size_rounded,
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 620,
                          minHeight: constraints.maxHeight - 30,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.secondarySoft,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  child: Text(
                                    'CÁ NHÂN HÓA',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: colors.secondaryDark,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.35,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.remove_red_eye_outlined,
                                      color: colors.secondary,
                                      size: 17,
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Text(
                                      'Thân thiện thị giác',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: colors.secondaryDark,
                                        letterSpacing: 0,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Chữ vừa mắt bạn',
                              style: AppTextStyles.displaySmall.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Chọn kích thước chữ giúp bạn đọc thoải mái trên toàn bộ ứng dụng.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: colors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const OnboardingNabiNote(
                              mood: NabiOnboardingMood.guide,
                              eyebrow: 'NABI GỢI Ý',
                              compact: true,
                              message:
                                  'Cỡ chữ phù hợp giúp mắt thả lỏng suốt quá trình chăm sóc bản thân.',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Khung xem trước trực tiếp',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.primarySoft,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  child: Text(
                                    'Cỡ chữ: ${_label(selected)}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            _PreviewCard(fontSize: 14 + selectedIndex * 2),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Mức kích thước',
                                    style: AppTextStyles.labelLarge.copyWith(
                                      color: colors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '4 mức tùy chọn',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: colors.textSecondary,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: colors.primarySoft,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.xl,
                                ),
                              ),
                              child: Row(
                                children: [
                                  for (
                                    var index = 0;
                                    index < presets.length;
                                    index++
                                  )
                                    Expanded(
                                      child: _ScaleOption(
                                        preset: presets[index],
                                        selected: selected == presets[index],
                                        fontSize: 14 + index * 2,
                                        onTap: () =>
                                            controller.select(presets[index]),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                Icon(
                                  Icons.text_decrease_rounded,
                                  size: 17,
                                  color: colors.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                    child: LinearProgressIndicator(
                                      value:
                                          (selectedIndex + 1) / presets.length,
                                      minHeight: 4,
                                      backgroundColor: colors.primarySoft,
                                      color: colors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Icon(
                                  Icons.text_increase_rounded,
                                  size: 21,
                                  color: colors.textSecondary,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: colors.card,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.lg,
                                ),
                                border: Border.all(color: colors.borderLight),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.accessibility_new_rounded,
                                    color: colors.secondaryDark,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text.rich(
                                      TextSpan(
                                        text:
                                            'Bạn có thể thay đổi lại bất cứ lúc nào trong ',
                                        children: [
                                          TextSpan(
                                            text: 'Cài đặt cá nhân.',
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                                  color: colors.textPrimary,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: colors.textSecondary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                decoration: BoxDecoration(
                  color: colors.background.withValues(alpha: 0.96),
                  border: Border(top: BorderSide(color: colors.divider)),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: SizedBox(
                      width: double.infinity,
                      child: NabiPrimaryButton(
                        key: const Key('onboarding_text_scale_continue'),
                        onPressed: controller.markConfigured,
                        label: 'Bắt đầu trải nghiệm',
                        icon: Icons.arrow_forward_rounded,
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

  static String _label(AppTextScalePreset preset) => switch (preset) {
    AppTextScalePreset.small => 'Nhỏ (14px)',
    AppTextScalePreset.standard => 'Vừa (16px)',
    AppTextScalePreset.large => 'Lớn (18px)',
    AppTextScalePreset.veryLarge => 'Rất lớn (20px)',
  };
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.fontSize});

  final int fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return OnboardingStitchCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colors.secondarySoft,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    NabiOnboardingMood.guide.assetPath,
                    fit: BoxFit.cover,
                    cacheWidth: 110,
                    semanticLabel: 'Nabi',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Nabi',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'Vừa xong',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textMuted,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Text(
              'Nabi chào bạn! Một giấc ngủ trọn vẹn và vài ngụm nước ấm đầu ngày là khởi đầu dịu dàng cho cơ thể.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textPrimary,
                fontSize: fontSize.toDouble(),
                height: 1.42,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.favorite_rounded, size: 15, color: colors.secondary),
              const SizedBox(width: 5),
              Text(
                'Tự chăm sóc',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.secondaryDark,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.schedule_rounded, size: 15, color: colors.textMuted),
              const SizedBox(width: 5),
              Text(
                'Hôm nay',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScaleOption extends StatelessWidget {
  const _ScaleOption({
    required this.preset,
    required this.selected,
    required this.fontSize,
    required this.onTap,
  });

  final AppTextScalePreset preset;
  final bool selected;
  final int fontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final label = switch (preset) {
      AppTextScalePreset.small => 'Nhỏ',
      AppTextScalePreset.standard => 'Vừa',
      AppTextScalePreset.large => 'Lớn',
      AppTextScalePreset.veryLarge => 'Rất lớn',
    };
    return Semantics(
      button: true,
      selected: selected,
      label: 'Cỡ chữ $label, $fontSize',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AnimatedContainer(
            duration: nabiReducedMotion(context)
                ? Duration.zero
                : const Duration(milliseconds: 160),
            constraints: const BoxConstraints(minHeight: 68),
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 7),
            decoration: BoxDecoration(
              color: selected ? colors.card : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.10),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : const [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Aa',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: fontSize.toDouble(),
                    height: 1.08,
                    fontWeight: FontWeight.w700,
                    color: selected ? colors.primary : colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: selected ? colors.primary : colors.textSecondary,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  '${fontSize}px',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.textMuted,
                    fontSize: 10,
                    letterSpacing: 0,
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

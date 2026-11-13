import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/onboarding_stitch_components.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/onboarding_voice_step.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/data/onboarding_voice_runtime.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_voice_provider.dart';
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
    final voiceMode = ref.watch(
      onboardingVoiceProvider.select((state) => state.isVoiceMode),
    );
    if (voiceMode && OnboardingVoiceRuntime.platformIsSupported) {
      return const OnboardingVoiceTextScalePage();
    }
    final state = ref.watch(appTextScaleControllerProvider).value;
    final selected = state?.preset ?? AppTextScalePreset.standard;
    final controller = ref.read(appTextScaleControllerProvider.notifier);
    final colors = context.semanticColors;
    final presets = AppTextScalePreset.values;
    final selectedIndex = presets.indexOf(selected);

    return MedicalPageScaffold(
      backgroundColor: colors.background,
      body: NabiAmbientBackground(
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
                            'Cỡ chữ',
                            style: AppTextStyles.heading5.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (OnboardingVoiceRuntime.platformIsSupported)
                      IconButton.filledTonal(
                        key: const Key('onboarding_text_scale_voice_toggle'),
                        tooltip: 'Bật chế độ giọng nói',
                        onPressed: () => ref
                            .read(onboardingVoiceProvider.notifier)
                            .enterVoiceMode(
                              stepIndex: -1,
                              questionId: 'text_scale',
                            ),
                        icon: const Icon(Icons.mic_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: colors.card,
                          foregroundColor: colors.textPrimary,
                        ),
                      )
                    else
                      Icon(
                        Icons.format_size_rounded,
                        color: colors.textSecondary,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final mascotSize =
                        constraints.maxWidth < 360 ||
                            constraints.maxHeight < 460
                        ? 88.0
                        : 112.0;
                    return SingleChildScrollView(
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
                              Text(
                                'Xem trước',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Align(
                                child: Image.asset(
                                  key: const Key('onboarding_text_scale_nabi'),
                                  NabiOnboardingMood.guide.assetPath,
                                  width: mascotSize,
                                  height: mascotSize,
                                  fit: BoxFit.contain,
                                  cacheWidth: (mascotSize * 3).round(),
                                  semanticLabel: 'Nabi',
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _PreviewCard(fontSize: 14 + selectedIndex * 2),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                'Chọn cỡ chữ',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
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
                            ],
                          ),
                        ),
                      ),
                    );
                  },
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
                        label: 'Tiếp tục',
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
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.fontSize});

  final int fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return OnboardingStitchCard(
      padding: const EdgeInsets.all(18),
      child: Text(
        'Một ngày mới, một bước chăm sóc bản thân.',
        style: AppTextStyles.bodyMedium.copyWith(
          color: colors.textPrimary,
          fontSize: fontSize.toDouble(),
          height: 1.42,
        ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

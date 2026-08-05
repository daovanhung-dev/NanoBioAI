import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart';
import 'package:nano_app/app_versions/v1/features/settings/presentation/widgets/font_scale_selector.dart';
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

    return MedicalPageScaffold(
      backgroundColor: NabiPalette.pageBackground,
      body: NabiAmbientBackground(
        strong: true,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.pagePadding),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 580,
                    minHeight: constraints.maxHeight - AppSpacing.pagePadding * 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                        decoration: BoxDecoration(
                          gradient: NabiPalette.hero,
                          borderRadius: BorderRadius.circular(AppRadius.xxl),
                          boxShadow: [
                            BoxShadow(
                              color: NabiPalette.greenDeep
                                  .withValues(alpha: 0.22),
                              blurRadius: 26,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const NabiCompanionAvatar(
                              size: 112,
                              mood: NabiOnboardingMood.guide,
                              showStatus: false,
                              hero: true,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Chữ vừa mắt bạn',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.heading3.copyWith(
                                color: AppColors.surface,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Bạn có thể đổi lại sau.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.surface.withValues(alpha: 0.84),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      NabiGlassPanel(
                        child: FontScaleSelector(
                          value: selected,
                          onChanged: controller.select,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      NabiPrimaryButton(
                        key: const Key('onboarding_text_scale_continue'),
                        onPressed: controller.markConfigured,
                        label: 'Tiếp tục',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

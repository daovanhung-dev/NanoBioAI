import 'package:flutter/material.dart';

import 'package:nano_app/core/theme/theme.dart';

import 'nabi_onboarding_experience.dart';

class ResultStep extends StatelessWidget {
  final double healthScore;
  final String userName;
  final String message;
  final VoidCallback? onContinue;
  final VoidCallback? onRestart;

  const ResultStep({
    super.key,
    this.healthScore = 82,
    this.userName = 'Bạn',
    this.message = 'Hồ sơ đã sẵn sàng.',
    this.onContinue,
    this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return MedicalPageScaffold(
      ambientBackground: false,
      backgroundColor: Colors.transparent,
      body: NabiAmbientBackground(
        strong: true,
        child: SafeArea(
          child: NabiCelebrationBurst(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                        decoration: BoxDecoration(
                          gradient: NabiPalette.hero,
                          borderRadius: BorderRadius.circular(AppRadius.xxl),
                          boxShadow: [
                            BoxShadow(
                              color: NabiPalette.greenDeep
                                  .withValues(alpha: 0.24),
                              blurRadius: 30,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const NabiCompanionAvatar(
                              size: 144,
                              mood: NabiOnboardingMood.celebrate,
                              showStatus: false,
                              hero: true,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Sẵn sàng rồi, $userName!',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.heading2.copyWith(
                                color: AppColors.surface,
                                fontWeight: FontWeight.w900,
                                height: 1.08,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.tiny),
                            Text(
                              message,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.surface.withValues(alpha: 0.86),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      NabiGlassPanel(
                        padding: const EdgeInsets.all(AppSpacing.cardPadding),
                        child: Row(
                          children: [
                            _ScoreRing(score: healthScore),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Điểm khởi đầu',
                                    style: AppTextStyles.heading5.copyWith(
                                      color: NabiPalette.ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'NaBi sẽ đồng hành và điều chỉnh theo tiến trình của bạn.',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: NabiPalette.mutedInk,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      SizedBox(
                        width: double.infinity,
                        child: NabiPrimaryButton(
                          onPressed: onContinue,
                          label: 'Vào ứng dụng',
                          icon: Icons.arrow_forward_rounded,
                        ),
                      ),
                      if (onRestart != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        NabiSecondaryButton(
                          onPressed: onRestart,
                          label: 'Sửa hồ sơ',
                          icon: Icons.edit_rounded,
                        ),
                      ],
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

class _ScoreRing extends StatelessWidget {
  final double score;

  const _ScoreRing({required this.score});

  @override
  Widget build(BuildContext context) {
    final normalized = (score / 100).clamp(0.0, 1.0).toDouble();
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: normalized),
            duration: AppMotionScope.duration(
              context,
              AppDuration.xSlow,
            ),
            curve: AppAnimations.emphasizedCurve,
            builder: (context, value, _) => CircularProgressIndicator(
              value: value,
              strokeWidth: 9,
              backgroundColor: NabiPalette.greenSoft,
              valueColor: const AlwaysStoppedAnimation<Color>(
                NabiPalette.greenPrimary,
              ),
            ),
          ),
          Text(
            score.round().toString(),
            style: AppTextStyles.heading3.copyWith(
              color: NabiPalette.greenDeep,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

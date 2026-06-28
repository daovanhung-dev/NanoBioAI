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
    this.message = 'Hồ sơ đã sẵn sàng để bắt đầu hành trình.',
    this.onContinue,
    this.onRestart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NabiAmbientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: NabiGlassPanel(
                  padding: const EdgeInsets.all(18),
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const NabiCompanionAvatar(size: 112),
                      const SizedBox(height: 14),
                      Text(
                        'NaBi đã sẵn sàng cùng bạn, $userName!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.heading3.copyWith(
                          color: NabiPalette.ink,
                          fontWeight: FontWeight.w900,
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: NabiPalette.mutedInk,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: NabiPalette.hero,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                          boxShadow: [
                            BoxShadow(
                              color: NabiPalette.royalBlue.withValues(
                                alpha: 0.25,
                              ),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              healthScore.round().toString(),
                              style: AppTextStyles.displaySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'điểm khởi đầu hôm nay',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white.withValues(alpha: 0.86),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: NabiPrimaryButton(
                          onPressed: onContinue,
                          label: 'Vào hành trình của tôi',
                          icon: Icons.explore_rounded,
                        ),
                      ),
                      if (onRestart != null) ...[
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: onRestart,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Chỉnh lại hồ sơ'),
                          style: TextButton.styleFrom(
                            foregroundColor: NabiPalette.deepBlue,
                          ),
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

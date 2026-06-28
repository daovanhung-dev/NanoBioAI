import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/constants/routes/auth_route_paths.dart';
import 'package:nano_app/core/theme/theme.dart';

class OnboardingEntryPage extends StatelessWidget {
  const OnboardingEntryPage({super.key});

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
                constraints: const BoxConstraints(maxWidth: 440),
                child: NabiGlassPanel(
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const NabiCompanionAvatar(size: 106),
                      const SizedBox(height: 12),
                      ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) =>
                            NabiPalette.hero.createShader(bounds),
                        child: Text(
                          'Bắt đầu cùng NaBi',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Bạn có thể đăng nhập để đồng bộ hành trình, hoặc bắt đầu ngay để NaBi làm quen với bạn.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: NabiPalette.mutedInk,
                          height: 1.42,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          NabiMoodPill(
                            icon: Icons.cloud_sync_outlined,
                            label: 'Đồng bộ khi cần',
                            color: NabiPalette.cyan,
                          ),
                          NabiMoodPill(
                            icon: Icons.shield_outlined,
                            label: 'Dữ liệu riêng tư',
                            color: NabiPalette.violet,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: NabiPrimaryButton(
                          key: const Key('onboarding_entry_login_cta'),
                          onPressed: () => context.go(AuthRoutePaths.login),
                          label: 'Đăng nhập hoặc tạo tài khoản',
                          icon: Icons.login_rounded,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: NabiSecondaryButton(
                          key: const Key('onboarding_entry_guest_cta'),
                          onPressed: () => context.go(V1RoutePaths.onboarding),
                          label: 'Trải nghiệm ngay với NaBi',
                          icon: Icons.spa_outlined,
                        ),
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

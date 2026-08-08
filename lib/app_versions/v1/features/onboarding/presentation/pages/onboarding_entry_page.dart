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
    final colors = context.semanticColors;
    return MedicalPageScaffold(
      ambientBackground: false,
      backgroundColor: colors.background,
      body: NabiAmbientBackground(
        strong: true,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 720,
                    minHeight: constraints.maxHeight - 38,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _BrandBar(),
                      const SizedBox(height: AppSpacing.large),
                      const _GreenHero(),
                      const SizedBox(height: AppSpacing.md),
                      _EntryActionCard(
                        key: const Key('onboarding_entry_guest_card'),
                        icon: Icons.auto_awesome_rounded,
                        title: 'Tạo lộ trình của bạn',
                        description: 'Bắt đầu ngay trên thiết bị này.',
                        accent: NabiPalette.greenPrimary,
                        primary: true,
                        action: NabiPrimaryButton(
                          key: const Key('onboarding_entry_guest_cta'),
                          onPressed: () =>
                              context.push(V1RoutePaths.onboarding),
                          label: 'Bắt đầu',
                          icon: Icons.arrow_forward_rounded,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _EntryActionCard(
                        key: const Key('onboarding_entry_login_card'),
                        icon: Icons.cloud_done_rounded,
                        title: 'Đã có tài khoản?',
                        description: 'Đăng nhập để đồng bộ dữ liệu.',
                        accent: NabiPalette.calmBlue,
                        action: NabiSecondaryButton(
                          key: const Key('onboarding_entry_login_cta'),
                          onPressed: () => context.push(AuthRoutePaths.login),
                          label: 'Đăng nhập',
                          icon: Icons.login_rounded,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const _PrivacyLine(),
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

class _BrandBar extends StatelessWidget {
  const _BrandBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: NabiPalette.button,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: NabiPalette.greenPrimary.withValues(alpha: 0.24),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.eco_rounded, color: AppColors.textInverse),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NanoBio',
                style: AppTextStyles.heading4.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Sức khỏe theo cách của bạn',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const NabiMoodPill(icon: Icons.verified_rounded, label: 'Riêng tư'),
      ],
    );
  }
}

class _GreenHero extends StatelessWidget {
  const _GreenHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        gradient: NabiPalette.hero,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: [
          BoxShadow(
            color: NabiPalette.greenDeep.withValues(alpha: 0.24),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned(
            top: AppSpacing.sm,
            right: AppSpacing.sm,
            child: _HeroOrb(
              icon: Icons.favorite_rounded,
              color: NabiPalette.careCoral,
            ),
          ),
          const Positioned(
            left: AppSpacing.xs,
            bottom: AppSpacing.xl,
            child: _HeroOrb(
              icon: Icons.bedtime_rounded,
              color: NabiPalette.calmBlue,
              small: true,
            ),
          ),
          Column(
            children: [
              const NabiCompanionAvatar(
                size: 136,
                mood: NabiOnboardingMood.welcome,
                showStatus: false,
                hero: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Khỏe hơn, nhẹ nhàng hơn',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.textInverse,
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'NaBi hiểu bạn và tạo lộ trình mỗi ngày.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textInverse.withValues(alpha: 0.86),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HeroTag(icon: Icons.person_rounded, label: 'Cá nhân hóa'),
                  _HeroTag(icon: Icons.schedule_rounded, label: 'Dễ theo dõi'),
                  _HeroTag(icon: Icons.favorite_rounded, label: 'Nhẹ nhàng'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroOrb extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool small;

  const _HeroOrb({required this.icon, required this.color, this.small = false});

  @override
  Widget build(BuildContext context) {
    final size = small ? 38.0 : 46.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.textInverse.withValues(alpha: 0.16),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.textInverse.withValues(alpha: 0.20),
        ),
      ),
      child: Icon(icon, color: color, size: small ? 19 : 22),
    );
  }
}

class _HeroTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.textInverse.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.textInverse.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textInverse, size: 15),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textInverse,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final Widget action;
  final bool primary;

  const _EntryActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    required this.action,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return NabiGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      elevated: primary,
      borderColor: accent.withValues(alpha: primary ? 0.24 : 0.14),
      shadowColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.heading5.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      description,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          action,
        ],
      ),
    );
  }
}

class _PrivacyLine extends StatelessWidget {
  const _PrivacyLine();

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 16,
          color: NabiPalette.greenDeep,
        ),
        const SizedBox(width: AppSpacing.tiny),
        Flexible(
          child: Text(
            'Bạn quyết định thông tin được chia sẻ.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

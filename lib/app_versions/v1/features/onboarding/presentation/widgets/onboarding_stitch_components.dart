import 'package:flutter/material.dart';
import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';

import 'nabi_onboarding_experience.dart';

IconData _conditionIconFor(String code) => switch (code) {
  'stomach_pain' => Icons.sick_outlined,
  'acid_reflux' => Icons.local_fire_department_outlined,
  'constipation' => Icons.wc_rounded,
  'bloating' => Icons.air_rounded,
  'diarrhea' => Icons.water_drop_outlined,
  'insomnia' => Icons.bedtime_outlined,
  'stress' || 'anxiety' => Icons.psychology_outlined,
  'joint_pain' || 'back_pain' => Icons.accessibility_new_rounded,
  'headache' => Icons.headphones_outlined,
  'high_blood_sugar' => Icons.bloodtype_outlined,
  'blood_pressure_issue' => Icons.favorite_border_rounded,
  'high_cholesterol' => Icons.science_outlined,
  'fatty_liver' => Icons.health_and_safety_outlined,
  'thyroid_issue' => Icons.monitor_heart_outlined,
  'respiratory_issue' => Icons.air_rounded,
  'kidney_issue' => Icons.water_drop_outlined,
  'skin_issue' => Icons.spa_outlined,
  'tired_always' => Icons.battery_2_bar_rounded,
  'overweight' || 'underweight' => Icons.monitor_weight_outlined,
  'menstrual_issue' => Icons.calendar_month_outlined,
  'other_condition' => Icons.edit_note_rounded,
  _ => Icons.health_and_safety_outlined,
};

/// White, low-elevation surface used by the Stitch onboarding layouts.
class OnboardingStitchCard extends StatelessWidget {
  const OnboardingStitchCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.color,
    this.borderColor,
    this.radius = AppRadius.xl,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? colors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? colors.borderLight),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class OnboardingScreenHeading extends StatelessWidget {
  const OnboardingScreenHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.eyebrow,
    this.icon,
    this.bottomSpacing = AppSpacing.md,
  });

  final String title;
  final String subtitle;
  final String? eyebrow;
  final IconData? icon;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow != null || icon != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: colors.primary),
                  const SizedBox(width: AppSpacing.xs),
                ],
                if (eyebrow != null)
                  Text(
                    eyebrow!.toUpperCase(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.45,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            title,
            style: AppTextStyles.displaySmall.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.15,
            ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
                height: 1.48,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A short Nabi message that uses the bundled character art and no remote media.
class OnboardingNabiNote extends StatelessWidget {
  const OnboardingNabiNote({
    super.key,
    required this.message,
    required this.mood,
    this.eyebrow = 'LỜI NHẮN TỪ NABI',
    this.compact = false,
    this.tint,
  });

  final String message;
  final NabiOnboardingMood mood;
  final String eyebrow;
  final bool compact;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final background = tint ?? colors.secondarySoft;
    final size = compact ? 48.0 : 62.0;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.secondary.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              mood.assetPath,
              width: size * 0.94,
              height: size * 0.94,
              fit: BoxFit.contain,
              cacheWidth: 180,
              semanticLabel: 'Nabi đồng hành',
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        eyebrow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colors.secondaryDark,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(Icons.eco_rounded, size: 16, color: colors.secondary),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  message,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textPrimary,
                    fontSize: compact ? 13 : 14,
                    height: 1.4,
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

class OnboardingChoiceRow extends StatelessWidget {
  const OnboardingChoiceRow({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
    this.leading,
    this.height = 64,
  });

  final OnboardingChoiceOption option;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AnimatedContainer(
            duration: nabiReducedMotion(context)
                ? Duration.zero
                : const Duration(milliseconds: 170),
            constraints: BoxConstraints(minHeight: height),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? colors.primarySubtle : colors.card,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selected ? colors.primary : colors.borderLight,
                width: selected ? 1.25 : 0.7,
              ),
              boxShadow: [
                if (!selected)
                  BoxShadow(
                    color: colors.textPrimary.withValues(alpha: 0.025),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpacing.sm),
                ] else ...[
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _conditionIconFor(option.code),
                      size: 20,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    option.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AnimatedContainer(
                  duration: nabiReducedMotion(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: selected ? colors.primary : colors.primarySoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: selected
                      ? Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: colors.onBrand,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OnboardingAccordionCard extends StatelessWidget {
  const OnboardingAccordionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.expanded,
    required this.onToggle,
    required this.child,
    this.accent,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final tint = accent ?? colors.primary;
    return OnboardingStitchCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Semantics(
            button: true,
            expanded: expanded,
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: tint.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(icon, color: tint, size: 21),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: nabiReducedMotion(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: child,
            ),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: nabiReducedMotion(context)
                ? Duration.zero
                : const Duration(milliseconds: 200),
            sizeCurve: Curves.easeOutCubic,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../feedback/feedback.dart';
import 'app_colors.dart';
import 'app_gradients.dart';
import 'app_motion.dart';
import 'app_duration.dart';
import 'app_radius.dart';
import 'app_semantic_colors.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Shared visual shell for the calm, trustworthy NaBi Green Wellness experience.
class MedicalPageScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Widget? drawer;
  final bool ambientBackground;
  final bool safeArea;
  final bool extendBody;
  final bool resizeToAvoidBottomInset;
  final Color? backgroundColor;

  const MedicalPageScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.drawer,
    this.ambientBackground = true,
    this.safeArea = false,
    this.extendBody = false,
    this.resizeToAvoidBottomInset = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = safeArea ? SafeArea(child: body) : body;

    if (ambientBackground) {
      content = Stack(
        fit: StackFit.expand,
        children: [const MedicalAmbientBackground(), content],
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor ?? context.semanticColors.background,
      appBar: appBar,
      body: AppViewMotion(child: content),
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
      extendBody: extendBody,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

/// Standard responsive, scrollable page used by informational and form views.
class MedicalScrollPage extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final List<Widget> actions;
  final LinearGradient gradient;
  final double maxContentWidth;
  final EdgeInsetsGeometry? padding;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const MedicalScrollPage({
    super.key,
    this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.actions = const [],
    this.gradient = AppGradients.hero,
    this.maxContentWidth = 760,
    this.padding,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return MedicalPageScaffold(
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 720
                ? AppSpacing.xl
                : AppSpacing.md;
            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverPadding(
                  padding:
                      padding ??
                      EdgeInsets.fromLTRB(
                        horizontal,
                        AppSpacing.md,
                        horizontal,
                        AppSpacing.xxxl,
                      ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxContentWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MedicalPageHero(
                              eyebrow: eyebrow,
                              title: title,
                              subtitle: subtitle,
                              icon: icon,
                              gradient: gradient,
                              actions: actions,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            ..._withSectionSpacing(
                              children.indexed
                                  .map(
                                    (entry) => AppViewMotion(
                                      delay: Duration(
                                        milliseconds:
                                            AppDuration.stagger.inMilliseconds *
                                            entry.$1.clamp(0, 5),
                                      ),
                                      child: entry.$2,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static List<Widget> _withSectionSpacing(List<Widget> source) {
    if (source.isEmpty) return const [];
    final result = <Widget>[];
    for (var index = 0; index < source.length; index++) {
      result.add(source[index]);
      if (index != source.length - 1) {
        result.add(const SizedBox(height: AppSpacing.md));
      }
    }
    return result;
  }
}

class MedicalAmbientBackground extends StatelessWidget {
  const MedicalAmbientBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.background, colors.surfaceSoft],
              ),
            ),
          ),
          Positioned(
            top: -150,
            right: -120,
            child: _AmbientGlow(
              size: 320,
              colors: [
                colors.primary.withValues(alpha: .12),
                colors.primary.withValues(alpha: 0),
              ],
            ),
          ),
          Positioned(
            bottom: -190,
            left: -140,
            child: _AmbientGlow(
              size: 380,
              colors: [
                colors.secondary.withValues(alpha: .10),
                colors.secondary.withValues(alpha: 0),
              ],
            ),
          ),
          Positioned(
            top: 280,
            left: -90,
            child: _AmbientGlow(
              size: 220,
              colors: [
                colors.tertiary.withValues(alpha: .055),
                colors.tertiary.withValues(alpha: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final double size;
  final List<Color> colors;

  const _AmbientGlow({required this.size, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class MedicalPageHero extends StatelessWidget {
  final String? eyebrow;
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final List<Widget> actions;

  const MedicalPageHero({
    super.key,
    this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.gradient = AppGradients.hero,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final onBrand = context.semanticColors.onBrand;
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.primary,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        child: Stack(
          children: [
            const Positioned.fill(child: _HeroPattern()),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 540;
                  final content = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (eyebrow != null) ...[
                        MedicalStatusPill(
                          label: eyebrow!,
                          icon: Icons.verified_user_outlined,
                          foregroundColor: onBrand,
                          backgroundColor: onBrand.withValues(alpha: .14),
                          borderColor: onBrand.withValues(alpha: .22),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Text(
                        title,
                        style: AppTextStyles.heading1.copyWith(
                          color: onBrand,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: onBrand,
                          height: 1.55,
                        ),
                      ),
                      if (actions.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: actions,
                        ),
                      ],
                    ],
                  );

                  if (compact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MedicalIconBadge(
                          icon: icon,
                          color: onBrand,
                          backgroundColor: onBrand.withValues(alpha: .15),
                          size: 58,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        content,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: content),
                      const SizedBox(width: AppSpacing.lg),
                      MedicalIconBadge(
                        icon: icon,
                        color: onBrand,
                        backgroundColor: onBrand.withValues(alpha: .15),
                        size: 74,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroPattern extends StatelessWidget {
  const _HeroPattern();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -38,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.semanticColors.onBrand.withValues(alpha: .10),
                  width: 24,
                ),
              ),
            ),
          ),
          Positioned(
            right: 72,
            bottom: -62,
            child: Container(
              width: 124,
              height: 124,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.semanticColors.onBrand.withValues(alpha: .055),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MedicalSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final LinearGradient? gradient;
  final VoidCallback? onTap;
  final bool elevated;
  final double? radius;
  final String? semanticLabel;

  const MedicalSurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color,
    this.borderColor,
    this.gradient,
    this.onTap,
    this.elevated = false,
    this.radius,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final borderRadius = BorderRadius.circular(radius ?? AppRadius.xl);
    final decoration = BoxDecoration(
      color: gradient == null ? (color ?? colors.card) : null,
      gradient: gradient,
      borderRadius: borderRadius,
      border: Border.all(color: borderColor ?? colors.borderLight),
      boxShadow: elevated ? AppShadows.cardRaised : AppShadows.card,
    );
    final paddedChild = Padding(padding: padding, child: child);

    final content = onTap == null
        ? DecoratedBox(decoration: decoration, child: paddedChild)
        : Material(
            color: Colors.transparent,
            child: Ink(
              decoration: decoration,
              child: InkWell(
                borderRadius: borderRadius,
                onTap: () {
                  AppFeedbackService.instance.emit(AppFeedbackType.selection);
                  onTap?.call();
                },
                child: paddedChild,
              ),
            ),
          );

    final responsiveContent = onTap == null
        ? content
        : AppPressScale(child: content);

    if (semanticLabel == null) return responsiveContent;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: responsiveContent,
    );
  }
}

class MedicalSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData? icon;
  final Color? color;

  const MedicalSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final resolvedColor = _resolveSemanticTone(colors, color);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          MedicalIconBadge(
            icon: icon!,
            color: resolvedColor,
            backgroundColor: resolvedColor.withValues(alpha: .10),
            size: 42,
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: AppTextStyles.sectionSubtitle.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: AppSpacing.sm), action!],
      ],
    );
  }
}

class MedicalIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final double size;

  const MedicalIconBadge({
    super.key,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * .31),
        border: Border.all(color: color.withValues(alpha: .12)),
      ),
      child: Icon(icon, color: color, size: size * .48),
    );
  }
}

class MedicalStatusPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final Color? borderColor;

  const MedicalStatusPill({
    super.key,
    required this.label,
    this.icon,
    this.foregroundColor,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final foreground = foregroundColor ?? colors.primaryDark;
    final background = backgroundColor ?? colors.primarySoft;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.tiny,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.circular),
        border: Border.all(
          color: borderColor ?? foreground.withValues(alpha: .16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MedicalMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? helper;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const MedicalMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.helper,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final resolvedColor = _resolveSemanticTone(colors, color);
    return MedicalSurfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      semanticLabel: '$label: $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              MedicalIconBadge(
                icon: icon,
                color: resolvedColor,
                backgroundColor: resolvedColor.withValues(alpha: .10),
                size: 40,
              ),
              const Spacer(),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_rounded,
                  color: resolvedColor,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: AppTextStyles.heading3.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              helper!,
              style: AppTextStyles.caption.copyWith(color: colors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class MedicalEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color? color;
  final Widget? action;

  const MedicalEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final resolvedColor = _resolveSemanticTone(colors, color);
    return MedicalSurfaceCard(
      borderColor: resolvedColor.withValues(alpha: .16),
      gradient: LinearGradient(
        colors: [resolvedColor.withValues(alpha: .08), colors.card],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          MedicalIconBadge(
            icon: icon,
            color: resolvedColor,
            backgroundColor: resolvedColor.withValues(alpha: .10),
            size: 64,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading4.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
              height: 1.55,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}

class MedicalComingSoonPage extends StatelessWidget {
  final String title;
  final String message;
  final String eyebrow;
  final IconData icon;
  final Color? color;
  final List<String> previewItems;

  const MedicalComingSoonPage({
    super.key,
    required this.title,
    required this.message,
    required this.eyebrow,
    required this.icon,
    this.color,
    this.previewItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final resolvedColor = _resolveSemanticTone(colors, color);
    return MedicalScrollPage(
      eyebrow: eyebrow,
      title: title,
      subtitle: message,
      icon: icon,
      gradient: LinearGradient(
        colors: [colors.clinicalNavy, resolvedColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      children: [
        MedicalEmptyState(
          icon: icon,
          color: resolvedColor,
          title: 'Nabi đang hoàn thiện mục này',
          message: 'Bạn vẫn có thể dùng các mục đang hoạt động.',
        ),
        if (previewItems.isNotEmpty)
          MedicalSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MedicalSectionHeader(
                  title: 'Đang chuẩn bị',
                  subtitle: 'Rõ ràng, riêng tư và dễ dùng.',
                  icon: Icons.fact_check_outlined,
                  color: resolvedColor,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final item in previewItems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: resolvedColor,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            item,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

Color _resolveSemanticTone(AppSemanticColors colors, Color? legacy) {
  if (legacy == null ||
      legacy == AppColors.primary ||
      legacy == AppColors.primaryDark) {
    return colors.primary;
  }
  if (legacy == AppColors.primaryLight) return colors.primaryLight;
  if (legacy == AppColors.secondary || legacy == AppColors.secondaryDark) {
    return colors.secondary;
  }
  if (legacy == AppColors.tertiary) return colors.tertiary;
  if (legacy == AppColors.success) return colors.success;
  if (legacy == AppColors.warning) return colors.warning;
  if (legacy == AppColors.error) return colors.error;
  if (legacy == AppColors.info) return colors.info;
  return legacy;
}

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_gradients.dart';
import 'app_radius.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

/// Shared visual shell for a calm, trustworthy healthcare experience.
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
      backgroundColor: backgroundColor ?? AppColors.background,
      appBar: appBar,
      body: content,
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
                            ..._withSectionSpacing(children),
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
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(gradient: AppGradients.medicalBackground),
          ),
          Positioned(
            top: -150,
            right: -120,
            child: _AmbientGlow(
              size: 320,
              colors: [
                AppColors.primary.withValues(alpha: .12),
                AppColors.primary.withValues(alpha: 0),
              ],
            ),
          ),
          Positioned(
            bottom: -190,
            left: -140,
            child: _AmbientGlow(
              size: 380,
              colors: [
                AppColors.secondary.withValues(alpha: .10),
                AppColors.secondary.withValues(alpha: 0),
              ],
            ),
          ),
          Positioned(
            top: 280,
            left: -90,
            child: _AmbientGlow(
              size: 220,
              colors: [
                AppColors.tertiary.withValues(alpha: .055),
                AppColors.tertiary.withValues(alpha: 0),
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
                          foregroundColor: AppColors.textInverse,
                          backgroundColor: Colors.white.withValues(alpha: .14),
                          borderColor: Colors.white.withValues(alpha: .22),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      Text(
                        title,
                        style: AppTextStyles.heading1.copyWith(
                          color: AppColors.textInverse,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textInverse.withValues(alpha: .88),
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
                          color: AppColors.textInverse,
                          backgroundColor: Colors.white.withValues(alpha: .15),
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
                        color: AppColors.textInverse,
                        backgroundColor: Colors.white.withValues(alpha: .15),
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
                  color: Colors.white.withValues(alpha: .10),
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
                color: Colors.white.withValues(alpha: .055),
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
    final borderRadius = BorderRadius.circular(radius ?? AppRadius.xl);
    final decoration = BoxDecoration(
      color: gradient == null ? (color ?? AppColors.surface) : null,
      gradient: gradient,
      borderRadius: borderRadius,
      border: Border.all(color: borderColor ?? AppColors.borderLight),
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
                onTap: onTap,
                child: paddedChild,
              ),
            ),
          );

    if (semanticLabel == null) return content;
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: content,
    );
  }
}

class MedicalSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final IconData? icon;
  final Color color;

  const MedicalSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.icon,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          MedicalIconBadge(
            icon: icon!,
            color: color,
            backgroundColor: color.withValues(alpha: .10),
            size: 42,
          ),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.sectionTitle),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle!, style: AppTextStyles.sectionSubtitle),
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
  final Color foregroundColor;
  final Color backgroundColor;
  final Color? borderColor;

  const MedicalStatusPill({
    super.key,
    required this.label,
    this.icon,
    this.foregroundColor = AppColors.primaryDark,
    this.backgroundColor = AppColors.primarySoft,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.tiny,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.circular),
        border: Border.all(
          color: borderColor ?? foregroundColor.withValues(alpha: .16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foregroundColor),
            const SizedBox(width: AppSpacing.xs),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 240),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w800,
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
  final Color color;
  final VoidCallback? onTap;

  const MedicalMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.helper,
    required this.icon,
    this.color = AppColors.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                color: color,
                backgroundColor: color.withValues(alpha: .10),
                size: 40,
              ),
              const Spacer(),
              if (onTap != null)
                Icon(Icons.arrow_forward_rounded, color: color, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: AppTextStyles.heading3),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(helper!, style: AppTextStyles.caption),
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
  final Color color;
  final Widget? action;

  const MedicalEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color = AppColors.primary,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return MedicalSurfaceCard(
      borderColor: color.withValues(alpha: .16),
      gradient: LinearGradient(
        colors: [color.withValues(alpha: .08), AppColors.surface],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        children: [
          MedicalIconBadge(
            icon: icon,
            color: color,
            backgroundColor: color.withValues(alpha: .10),
            size: 64,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading4,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.55),
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
  final Color color;
  final List<String> previewItems;

  const MedicalComingSoonPage({
    super.key,
    required this.title,
    required this.message,
    required this.eyebrow,
    required this.icon,
    this.color = AppColors.primary,
    this.previewItems = const [],
  });

  @override
  Widget build(BuildContext context) {
    return MedicalScrollPage(
      eyebrow: eyebrow,
      title: title,
      subtitle: message,
      icon: icon,
      gradient: LinearGradient(
        colors: [AppColors.clinicalNavy, color],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      children: [
        MedicalEmptyState(
          icon: icon,
          color: color,
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
                  color: color,
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
                          color: color,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(item, style: AppTextStyles.bodyMedium),
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

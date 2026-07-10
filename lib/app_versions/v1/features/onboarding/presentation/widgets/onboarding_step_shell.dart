import 'package:flutter/material.dart';

import 'package:nano_app/core/constants/onboarding_constants.dart';
import 'package:nano_app/core/theme/theme.dart';

import 'nabi_onboarding_experience.dart';

/// Shared responsive visual frame for the entire NaBi onboarding journey.
class OnboardingStepShell extends StatelessWidget {
  final int stepIndex;
  final int totalSteps;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final String? nextLabel;
  final bool showBack;
  final bool isScrollable;
  final bool safeArea;

  const OnboardingStepShell({
    super.key,
    required this.stepIndex,
    required this.title,
    required this.subtitle,
    required this.child,
    this.totalSteps = OnboardingCatalog.totalSteps,
    this.footer,
    this.onBack,
    this.onNext,
    this.nextLabel,
    this.showBack = true,
    this.isScrollable = true,
    this.safeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaQuery = MediaQuery.of(context);
        final layout = _OnboardingLayout.fromSize(
          width: constraints.maxWidth,
          height: mediaQuery.size.height,
        );

        final progress = ((stepIndex + 1) / totalSteps)
            .clamp(0.0, 1.0)
            .toDouble();

        final page = Column(
          children: [
            _TopBar(
              stepIndex: stepIndex,
              totalSteps: totalSteps,
              progress: progress,
              showBack: showBack,
              onBack: onBack,
              layout: layout,
            ),
            Expanded(
              child: _OnboardingBody(
                title: title,
                subtitle: subtitle,
                isScrollable: isScrollable,
                layout: layout,
                child: child,
              ),
            ),
            if (footer != null || onNext != null)
              _BottomAction(
                footer: footer,
                onNext: onNext,
                nextLabel: nextLabel,
                layout: layout,
              ),
          ],
        );

        return safeArea ? SafeArea(child: page) : page;
      },
    );
  }
}

class _OnboardingBody extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool isScrollable;
  final _OnboardingLayout layout;

  const _OnboardingBody({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.isScrollable,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardOpened = MediaQuery.of(context).viewInsets.bottom > 0;

    // Khi màn hình thấp hoặc đang mở bàn phím, luôn cho phép cuộn
    // để tránh overflow và không che input.
    final shouldScroll = isScrollable || layout.isShortScreen || keyboardOpened;

    final content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: layout.contentMaxWidth),
        child: _Content(
          title: title,
          subtitle: subtitle,
          layout: layout,
          child: child,
        ),
      ),
    );

    final padding = EdgeInsets.fromLTRB(
      layout.horizontalPadding,
      layout.bodyTopPadding,
      layout.horizontalPadding,
      layout.bodyBottomPadding,
    );

    if (shouldScroll) {
      return SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: padding,
        child: content,
      );
    }

    return Padding(
      padding: padding,
      child: Align(alignment: Alignment.topCenter, child: content),
    );
  }
}

class _Content extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final _OnboardingLayout layout;

  const _Content({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final hasTitle = title.trim().isNotEmpty;
    final hasSubtitle = subtitle.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasTitle) ...[
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: NabiPalette.hero.createShader,
            child: Text(
              title,
              style: AppTextStyles.heading2.copyWith(
                color: Colors.white,
                fontSize: layout.titleFontSize,
                fontWeight: FontWeight.w900,
                height: 1.12,
                letterSpacing: -0.45,
              ),
            ),
          ),
          if (hasSubtitle) ...[
            SizedBox(height: layout.subtitleSpacing),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(
                color: NabiPalette.mutedInk,
                fontSize: layout.subtitleFontSize,
                height: 1.43,
              ),
            ),
          ],
          SizedBox(height: layout.contentSpacing),
        ],
        child,
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final int stepIndex;
  final int totalSteps;
  final double progress;
  final bool showBack;
  final VoidCallback? onBack;
  final _OnboardingLayout layout;

  const _TopBar({
    required this.stepIndex,
    required this.totalSteps,
    required this.progress,
    required this.showBack,
    required this.onBack,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        layout.horizontalPadding,
        layout.topBarTopPadding,
        layout.horizontalPadding,
        layout.topBarBottomPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: layout.contentMaxWidth),
          child: NabiGlassPanel(
            elevated: false,
            padding: EdgeInsets.fromLTRB(
              layout.compact ? 7 : 8,
              layout.compact ? 7 : 8,
              layout.compact ? 8 : 11,
              layout.compact ? 7 : 8,
            ),
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.86),
                const Color(0xFFF5FAFF).withValues(alpha: 0.86),
              ],
            ),
            child: Row(
              children: [
                _BackButton(
                  showBack: showBack,
                  onBack: onBack,
                  size: layout.compact ? 36 : 38,
                ),
                SizedBox(width: layout.compact ? 7 : 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _TopBarLabel(compact: layout.compact),
                      SizedBox(height: layout.compact ? 5 : 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 420),
                          curve: Curves.easeOutCubic,
                          tween: Tween<double>(begin: 0, end: progress),
                          builder: (context, value, _) {
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: layout.compact ? 5 : 6,
                              backgroundColor: NabiPalette.line,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                NabiPalette.royalBlue,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: layout.compact ? 7 : 10),
                _StepBadge(
                  current: stepIndex + 1,
                  total: totalSteps,
                  compact: layout.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBarLabel extends StatelessWidget {
  final bool compact;

  const _TopBarLabel({required this.compact});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: NabiPalette.cyan,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'HỒ SƠ CÁ NHÂN',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: NabiPalette.deepBlue,
                fontWeight: FontWeight.w900,
                fontSize: 9.5,
                letterSpacing: 0.45,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: NabiPalette.cyan,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'HỒ SƠ CÙNG NaBi · đang cá nhân hoá',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall.copyWith(
              color: NabiPalette.deepBlue,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.25,
            ),
          ),
        ),
      ],
    );
  }
}

class _StepBadge extends StatelessWidget {
  final int current;
  final int total;
  final bool compact;

  const _StepBadge({
    required this.current,
    required this.total,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: compact ? 42 : 48),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: NabiPalette.royalBlue.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        '$current/$total',
        textAlign: TextAlign.center,
        style: AppTextStyles.labelMedium.copyWith(
          color: NabiPalette.deepBlue,
          fontSize: compact ? 11 : null,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final bool showBack;
  final VoidCallback? onBack;
  final double size;

  const _BackButton({
    required this.showBack,
    required this.onBack,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBack) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          gradient: NabiPalette.button,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.auto_awesome_rounded,
          color: Colors.white,
          size: size * 0.48,
        ),
      );
    }

    return Material(
      color: NabiPalette.royalBlue.withValues(alpha: 0.08),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onBack,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.arrow_back_rounded,
            size: size * 0.52,
            color: NabiPalette.deepBlue,
          ),
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final Widget? footer;
  final VoidCallback? onNext;
  final String? nextLabel;
  final _OnboardingLayout layout;

  const _BottomAction({
    required this.footer,
    required this.onNext,
    required this.nextLabel,
    required this.layout,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardOpened = MediaQuery.of(context).viewInsets.bottom > 0;

    final action =
        footer ??
        NabiPrimaryButton(
          onPressed: onNext,
          label: nextLabel ?? 'Tiếp tục cùng NaBi',
        );

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(
        layout.horizontalPadding,
        7,
        layout.horizontalPadding,
        keyboardOpened ? 8 : layout.bottomActionPadding,
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: layout.contentMaxWidth),
            child: SizedBox(width: double.infinity, child: action),
          ),
        ),
      ),
    );
  }
}

class _OnboardingLayout {
  final bool compact;
  final bool isShortScreen;
  final double horizontalPadding;
  final double contentMaxWidth;
  final double topBarTopPadding;
  final double topBarBottomPadding;
  final double bodyTopPadding;
  final double bodyBottomPadding;
  final double bottomActionPadding;
  final double titleFontSize;
  final double subtitleFontSize;
  final double subtitleSpacing;
  final double contentSpacing;

  const _OnboardingLayout({
    required this.compact,
    required this.isShortScreen,
    required this.horizontalPadding,
    required this.contentMaxWidth,
    required this.topBarTopPadding,
    required this.topBarBottomPadding,
    required this.bodyTopPadding,
    required this.bodyBottomPadding,
    required this.bottomActionPadding,
    required this.titleFontSize,
    required this.subtitleFontSize,
    required this.subtitleSpacing,
    required this.contentSpacing,
  });

  factory _OnboardingLayout.fromSize({
    required double width,
    required double height,
  }) {
    final compact = width < 360;
    final shortScreen = height < 680;
    final wideScreen = width >= 600;

    return _OnboardingLayout(
      compact: compact,
      isShortScreen: shortScreen,
      horizontalPadding: compact
          ? 12
          : width < 390
          ? 16
          : wideScreen
          ? 24
          : 18,
      contentMaxWidth: wideScreen ? 680 : 560,
      topBarTopPadding: shortScreen ? 6 : 11,
      topBarBottomPadding: shortScreen ? 1 : 3,
      bodyTopPadding: compact ? 8 : 10,
      bodyBottomPadding: shortScreen ? 18 : 28,
      bottomActionPadding: compact ? 10 : 14,
      titleFontSize: compact
          ? 22
          : wideScreen
          ? 28
          : 25,
      subtitleFontSize: compact ? 13 : 14,
      subtitleSpacing: compact ? 5 : 6,
      contentSpacing: compact ? 12 : 15,
    );
  }
}

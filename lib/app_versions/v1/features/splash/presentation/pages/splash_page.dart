import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/router/router.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/features/nabi/domain/nabi_animation_type.dart';
import 'package:nano_app/features/nabi/presentation/widgets/nabi_animation_player.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';

import '../../domain/services/splash_route_decision.dart';
import '../../providers/splash_provider.dart';

enum _BootStage { preparing, checkingProfile, ready }

extension _BootStagePresentation on _BootStage {
  String get message {
    switch (this) {
      case _BootStage.preparing:
        return 'Nabi đang chuẩn bị trải nghiệm của bạn';
      case _BootStage.checkingProfile:
        return 'Đang tìm điểm bắt đầu phù hợp';
      case _BootStage.ready:
        return 'Sẵn sàng';
    }
  }

  double get progress {
    switch (this) {
      case _BootStage.preparing:
        return 0.34;
      case _BootStage.checkingProfile:
        return 0.72;
      case _BootStage.ready:
        return 1;
    }
  }

  IconData get icon {
    switch (this) {
      case _BootStage.preparing:
        return Icons.auto_awesome_rounded;
      case _BootStage.checkingProfile:
        return Icons.person_search_rounded;
      case _BootStage.ready:
        return Icons.check_circle_rounded;
    }
  }
}

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({
    super.key,
    this.title = 'NanoBio',
    this.subtitle = 'Cùng Nabi chăm sóc sức khỏe mỗi ngày.',
  });

  final String title;
  final String subtitle;

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _hasNavigated = false;
  _BootStage _bootStage = _BootStage.preparing;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    _setStage(_BootStage.preparing);

    final onboardingCompletedFuture = _readOnboardingCompletedSafely();

    await Future.wait([
      _initializeSafely(),
      Future<void>.delayed(AppDuration.loading),
      _advanceToProfileCheckStage(),
    ]);

    final onboardingCompleted = await onboardingCompletedFuture;

    if (!mounted || _hasNavigated) return;

    _setStage(_BootStage.ready);

    final target = const SplashRouteDecision().resolve(
      hasAuthenticatedSession: currentSupabaseUserIdOrNull() != null,
      onboardingCompleted: onboardingCompleted,
    );

    _navigate(target);
  }

  Future<void> _advanceToProfileCheckStage() async {
    await Future<void>.delayed(AppDuration.navigation);

    if (!mounted || _hasNavigated) return;
    _setStage(_BootStage.checkingProfile);
  }

  void _setStage(_BootStage stage) {
    if (!mounted || _bootStage == stage) return;

    setState(() {
      _bootStage = stage;
    });
  }

  Future<void> _initializeSafely() async {
    try {
      await ref.read(splashProvider.notifier).initialize();
    } catch (error, stackTrace) {
      debugPrint('Splash initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<bool> _readOnboardingCompletedSafely() async {
    try {
      return await AppPrefs.isOnboardingCompleted();
    } catch (error, stackTrace) {
      debugPrint('Unable to read onboarding state: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  void _navigate(SplashRouteTarget target) {
    if (!mounted || _hasNavigated) return;

    _hasNavigated = true;

    switch (target) {
      case SplashRouteTarget.authGate:
        V1AppNavigator.goAuthGate(context);
        break;
      case SplashRouteTarget.onboardingEntry:
        V1AppNavigator.goOnboardingEntry(context);
        break;
      case SplashRouteTarget.menu:
        V1AppNavigator.goMenu(context);
        break;
      case SplashRouteTarget.onboarding:
        V1AppNavigator.goOnboarding(context);
        break;
    }
  }


  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;

    return MedicalPageScaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = _SplashLayout.fromConstraints(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            );
            final minContentHeight = (constraints.maxHeight -
                    (layout.verticalPadding * 2))
                .clamp(0.0, double.infinity)
                .toDouble();

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: layout.horizontalPadding,
                vertical: layout.verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minContentHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: layout.maxContentWidth,
                    ),
                    child: _SplashExperience(
                      title: widget.title,
                      subtitle: widget.subtitle,
                      stage: _bootStage,
                      layout: layout,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

}

class _SplashLayout {
  const _SplashLayout({
    required this.isCompact,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.maxContentWidth,
    required this.nabiSize,
    required this.brandFontSize,
  });

  final bool isCompact;
  final double horizontalPadding;
  final double verticalPadding;
  final double maxContentWidth;
  final double nabiSize;
  final double brandFontSize;

  factory _SplashLayout.fromConstraints({
    required double width,
    required double height,
  }) {
    final isCompact = width < 360 || height < 640;
    final isExpanded = width >= 700;

    return _SplashLayout(
      isCompact: isCompact,
      horizontalPadding: width < 360
          ? AppSpacing.compactPagePadding
          : isExpanded
              ? AppSpacing.pagePaddingLarge
              : AppSpacing.pagePadding,
      verticalPadding:
          isCompact ? AppSpacing.compactPagePadding : AppSpacing.pagePadding,
      maxContentWidth: isExpanded ? 560 : 480,
      nabiSize: isCompact
          ? 142
          : isExpanded
              ? 210
              : 184,
      brandFontSize: isCompact
          ? 34
          : isExpanded
              ? 44
              : 40,
    );
  }
}

class _SplashExperience extends StatelessWidget {
  const _SplashExperience({
    required this.title,
    required this.subtitle,
    required this.stage,
    required this.layout,
  });

  final String title;
  final String subtitle;
  final _BootStage stage;
  final _SplashLayout layout;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;

    return Semantics(
      label: 'NanoBio, trợ lý sức khỏe cá nhân cùng Nabi',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NabiHero(size: layout.nabiSize),
          SizedBox(
            height: layout.isCompact
                ? AppSpacing.md
                : AppSpacing.sectionSpacing,
          ),
          Text(
            'TRỢ LÝ SỨC KHỎE CÁ NHÂN',
            textAlign: TextAlign.center,
            style: AppTextStyles.overline.copyWith(
              color: colors.primary,
              fontSize: layout.isCompact ? 10 : 11,
              letterSpacing: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.displayLarge.copyWith(
              color: colors.textPrimary,
              fontSize: layout.brandFontSize,
              height: 1.04,
              letterSpacing: -1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLarge.copyWith(
                color: colors.textSecondary,
                fontSize: layout.isCompact ? 14 : 16,
                height: 1.45,
              ),
            ),
          ),
          SizedBox(
            height: layout.isCompact
                ? AppSpacing.lg
                : AppSpacing.sectionSpacingLarge,
          ),
          _BootIndicator(
            stage: stage,
            compact: layout.isCompact,
          ),
        ],
      ),
    );
  }
}

class _NabiHero extends StatelessWidget {
  const _NabiHero({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;

    return Semantics(
      image: true,
      label: 'Nabi, trợ lý sức khỏe của NanoBio',
      child: SizedBox.square(
        dimension: size * 1.18,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size * 1.12,
              height: size * 1.12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.16),
                    colors.primary.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Container(
              width: size * 0.92,
              height: size * 0.92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surface.withValues(alpha: 0.74),
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.12),
                ),
              ),
            ),
            NabiAnimationPlayer(
              animationType: NabiAnimationType.idle,
              size: size,
              filterQuality: FilterQuality.medium,
              fallbackIcon: Icon(
                Icons.auto_awesome_rounded,
                size: size * 0.34,
                color: colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BootIndicator extends StatelessWidget {
  const _BootIndicator({
    required this.stage,
    required this.compact,
  });

  final _BootStage stage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final accent = stage == _BootStage.ready ? colors.success : colors.primary;
    final progressDuration = AppMotionScope.duration(
      context,
      AppDuration.progress,
    );

    return Semantics(
      liveRegion: true,
      label: stage.message,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppStateSwitcher(
              child: Row(
                key: ValueKey(stage),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    stage.icon,
                    color: accent,
                    size: compact ? 17 : 19,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      stage.message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: TweenAnimationBuilder<double>(
                duration: progressDuration,
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: stage.progress),
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: compact ? 4 : 5,
                    backgroundColor: colors.primarySoft,
                    color: accent,
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

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/onboarding_schedule_progress_panel.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_provider.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/onboarding_completion_provider.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/providers/repository_providers.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_exceptions.dart';
import 'package:nano_app/app_versions/v1/services/ai/ai_text_client.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_service.dart';
import 'package:nano_app/app_versions/v1/features/onboarding/presentation/widgets/nabi_onboarding_experience.dart';
import 'package:nano_app/app_versions/v1/router/v1_route_paths.dart';
import 'package:nano_app/core/constants/routes/auth_route_paths.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/core/theme/theme.dart';
import 'package:nano_app/shared/widgets/generated_plan_progress_panel.dart';
import 'package:nano_app/shared/widgets/loading_gen_ai.dart';

final _retryableInitialPlanProvider = FutureProvider<bool>((ref) async {
  try {
    return await ref
        .read(generatedPlanServiceProvider)
        .hasRetryableInitialGuestPlan();
  } catch (_) {
    return false;
  }
});

class OnboardingEntryPage extends ConsumerStatefulWidget {
  const OnboardingEntryPage({super.key});

  @override
  ConsumerState<OnboardingEntryPage> createState() =>
      _OnboardingEntryPageState();
}

class _OnboardingEntryPageState extends ConsumerState<OnboardingEntryPage> {
  bool _retrying = false;
  String? _retryFailureDetails;

  Future<void> _retrySavedPlan() async {
    if (_retrying) return;
    setState(() {
      _retrying = true;
      _retryFailureDetails = null;
    });

    var progressPageOpen = false;
    void openProgressPage() {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const AIGeneratingPage(
            progressContent: OnboardingScheduleProgressPanel(),
          ),
        ),
      );
      progressPageOpen = true;
    }

    void closeProgressPage() {
      if (!progressPageOpen || !mounted) return;
      Navigator.of(context).pop();
      progressPageOpen = false;
    }

    try {
      openProgressPage();
      final result = await ref.read(onboardingCompletionCallbackProvider)(
        onProgress: ref
            .read(onboardingProvider.notifier)
            .updateInitialPlanProgress,
      );
      var proposal = result.pendingMealProposal;
      if (result.awaitingMealApproval && proposal == null) {
        throw const _SavedPlanRetryException();
      }
      if (!result.generatedInitialPlan && !result.awaitingMealApproval) {
        throw const _SavedPlanRetryException();
      }
      closeProgressPage();

      var completionSavedByController = false;
      while (proposal != null) {
        if (!mounted) return;
        final decision = await showGeneratedCustomMealDecisionDialog(
          context,
          proposal: proposal,
        );
        if (decision == null || !mounted) return;

        openProgressPage();
        try {
          final resumed = await ref
              .read(onboardingProvider.notifier)
              .respondToPendingCustomMeal(
                proposal: proposal,
                approve: decision,
              );
          if (resumed.awaitingMealApproval) {
            proposal = resumed.pendingMealProposal;
            if (proposal == null) {
              throw const _SavedPlanRetryException();
            }
          } else {
            proposal = null;
            completionSavedByController = true;
          }
        } finally {
          closeProgressPage();
        }
      }

      if (!result.generatedInitialPlan && !completionSavedByController) {
        throw const _SavedPlanRetryException();
      }
      if (!completionSavedByController) {
        await ref.read(onboardingRepositoryProvider).markCompleted();
        await AppPrefs.setOnboardingCompleted(true);
      }
      if (!mounted) return;
      context.go(V1RoutePaths.dashboard);
    } catch (error, stackTrace) {
      closeProgressPage();
      if (kDebugMode) {
        final providerStatus = switch (error) {
          AIOverloadedException(:final providerStatus) => providerStatus,
          AiInferenceException(:final status) => status,
          _ => null,
        };
        final safeProviderStatus =
            providerStatus != null &&
                RegExp(r'^[A-Za-z0-9_.-]{1,64}$').hasMatch(providerStatus)
            ? providerStatus
            : 'none';
        final providerStatusCode = switch (error) {
          AIOverloadedException(:final providerStatusCode) =>
            providerStatusCode,
          AiInferenceException(:final statusCode) => statusCode,
          _ => null,
        };
        final providerErrorCode = switch (error) {
          AIOverloadedException(:final providerErrorCode) => providerErrorCode,
          AiInferenceException(:final backendErrorCode) => backendErrorCode,
          _ => null,
        };
        final debugDetails =
            'type=${error.runtimeType}; http=${providerStatusCode ?? 'none'}; '
            'status=$safeProviderStatus; code=${providerErrorCode ?? 'none'}';
        setState(() => _retryFailureDetails = debugDetails);
        debugPrint(
          '[NABI_AI_SCHEDULE] component=ONBOARDING_RETRY '
          'stage=initial_plan_retry errorType=${error.runtimeType} '
          'statusCode=${providerStatusCode ?? 'none'} '
          'status=$safeProviderStatus '
          'errorCode=${providerErrorCode ?? 'none'}',
        );
        for (final line in stackTrace.toString().split('\n').take(8)) {
          if (line.trim().isNotEmpty) {
            debugPrint('[NABI_AI_SCHEDULE] stack=$line');
          }
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 30),
            content: Text(_retryFailureMessage(error)),
          ),
        );
      ref.invalidate(_retryableInitialPlanProvider);
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  String _retryFailureMessage(Object error) {
    if (AIAuthenticationException.matches(error)) {
      return AIAuthenticationException.userMessage;
    }
    return switch (error) {
      ScheduleMealClassificationException(:final userMessage) => userMessage,
      ScheduleCandidatesUnavailableException(:final userMessage) => userMessage,
      OnboardingInitialPlanException(:final message) => message,
      AIOverloadedException() => AIOverloadedException.userMessage,
      _ => 'Hồ sơ vẫn được lưu. Chưa tạo được lịch; bạn có thể thử lại sau.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    final canRetryPlan = ref.watch(_retryableInitialPlanProvider);
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
                    maxWidth: 560,
                    minHeight: (constraints.maxHeight - 38)
                        .clamp(0.0, 1200.0)
                        .toDouble(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _BrandBar(),
                      const SizedBox(height: AppSpacing.md),
                      const _EntryHero(),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Lắng nghe cơ thể, sống trọn an lành cùng Nabi',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.displaySmall.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                          height: 1.14,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Lộ trình chăm sóc sức khỏe sinh học được cá nhân hóa theo nhịp sống tự nhiên của riêng bạn.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppViewMotion(
                        key: const Key('onboarding_entry_guest_motion'),
                        offset: const Offset(-1, 0),
                        duration: AppDuration.emphasized,
                        child: SizedBox(
                          key: const Key('onboarding_entry_guest_card'),
                          width: double.infinity,
                          child: NabiPrimaryButton(
                            key: const Key('onboarding_entry_guest_cta'),
                            onPressed: () =>
                                context.push(V1RoutePaths.onboarding),
                            label: 'Tạo lộ trình của bạn',
                            icon: Icons.arrow_forward_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppViewMotion(
                        key: const Key('onboarding_entry_login_motion'),
                        offset: const Offset(1, 0),
                        duration: AppDuration.emphasized,
                        delay: AppDuration.stagger,
                        child: SizedBox(
                          key: const Key('onboarding_entry_login_card'),
                          width: double.infinity,
                          child: NabiSecondaryButton(
                            key: const Key('onboarding_entry_login_cta'),
                            onPressed: () => context.push(AuthRoutePaths.login),
                            label: 'Đăng nhập',
                            icon: Icons.login_rounded,
                          ),
                        ),
                      ),
                      if (canRetryPlan.asData?.value == true) ...[
                        const SizedBox(height: AppSpacing.md),
                        _RetryPlanCard(
                          key: const Key('onboarding_entry_retry_plan_card'),
                          retrying: _retrying,
                          failureDetails: kDebugMode
                              ? _retryFailureDetails
                              : null,
                          onRetry: _retrySavedPlan,
                        ),
                      ],
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

class _SavedPlanRetryException implements Exception {
  const _SavedPlanRetryException();
}

class _BrandBar extends StatelessWidget {
  const _BrandBar();

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: colors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: colors.primary.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Image.asset(
                'assets/logo.jpg',
                width: 30,
                height: 30,
                fit: BoxFit.cover,
                cacheWidth: 90,
                semanticLabel: 'Logo NanoBioAI',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'NanoBioAI',
              style: AppTextStyles.labelLarge.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryHero extends StatelessWidget {
  const _EntryHero();

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return AspectRatio(
      key: const Key('onboarding_entry_hero'),
      aspectRatio: 4 / 3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxxl),
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.primarySubtle,
                    colors.infoSoft,
                    colors.secondarySoft,
                  ],
                ),
              ),
            ),
            Positioned(
              left: -44,
              top: -68,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: -30,
              bottom: -56,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.09),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _EntryNaturePainter(
                    water: colors.primary.withValues(alpha: 0.20),
                    leaf: colors.secondary.withValues(alpha: 0.30),
                  ),
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Image.asset(
                  NabiOnboardingMood.welcome.assetPath,
                  width: 236,
                  height: 236,
                  fit: BoxFit.contain,
                  cacheWidth: 480,
                  semanticLabel: 'Nabi đồng hành cùng bạn',
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: colors.card.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: colors.card.withValues(alpha: 0.55),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop_rounded,
                      size: 15,
                      color: colors.secondaryDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Lắng nghe cơ thể',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.card.withValues(alpha: 0.84),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Nabi sẵn sàng',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.secondaryDark,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryNaturePainter extends CustomPainter {
  const _EntryNaturePainter({required this.water, required this.leaf});

  final Color water;
  final Color leaf;

  @override
  void paint(Canvas canvas, Size size) {
    final waterPaint = Paint()
      ..color = water
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final leafPaint = Paint()
      ..color = leaf
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 3; index++) {
      final y = size.height * (.18 + index * .045);
      canvas.drawPath(
        Path()
          ..moveTo(size.width * .62, y)
          ..cubicTo(
            size.width * .76,
            y - 16,
            size.width * .88,
            y + 14,
            size.width * 1.02,
            y,
          ),
        waterPaint,
      );
    }
    final stem = Path()
      ..moveTo(size.width * .85, size.height * .92)
      ..cubicTo(
        size.width * .78,
        size.height * .67,
        size.width * .82,
        size.height * .45,
        size.width * .95,
        size.height * .31,
      );
    canvas.drawPath(stem, leafPaint);
    for (var index = 0; index < 3; index++) {
      final y = size.height * (.73 - index * .11);
      final leafPath = Path()
        ..moveTo(size.width * .83, y)
        ..quadraticBezierTo(size.width * .73, y - 20, size.width * .69, y - 7)
        ..quadraticBezierTo(size.width * .73, y + 5, size.width * .83, y);
      canvas.drawPath(leafPath, leafPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EntryNaturePainter oldDelegate) =>
      oldDelegate.water != water || oldDelegate.leaf != leaf;
}

class _RetryPlanCard extends StatelessWidget {
  const _RetryPlanCard({
    super.key,
    required this.retrying,
    required this.failureDetails,
    required this.onRetry,
  });

  final bool retrying;
  final String? failureDetails;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.semanticColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardAlt,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Icons.restore_page_rounded, color: colors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khôi phục phiên chưa hoàn tất',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Hồ sơ đã lưu. Bạn có thể thử lại nếu quá trình bị gián đoạn.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          NabiPrimaryButton(
            key: const Key('onboarding_entry_retry_plan_cta'),
            onPressed: retrying ? null : onRetry,
            label: 'Thử lại phiên gần nhất',
            icon: Icons.sync_rounded,
            isLoading: retrying,
          ),
          if (failureDetails != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                failureDetails!,
                key: const Key('onboarding_retry_failure_details'),
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.cardAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 15,
            color: colors.secondaryDark,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              'Thông tin cá nhân luôn trong quyền kiểm soát của bạn.',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: colors.textSecondary,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/providers/membership_entitlement_providers.dart';
import 'package:nano_app/core/membership/membership_upgrade_route.dart';
import 'package:nano_app/core/theme/theme.dart';

/// Keeps the voice controller and microphone unmounted until the current
/// signed-in account has server-derived paid access.
class AiVoiceAccessGate extends ConsumerWidget {
  const AiVoiceAccessGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentAuthUserIdProvider);
    final access = ref.watch(effectiveAccessProvider);

    return AppStateSwitcher(
      child: access.when(
        loading: () => const KeyedSubtree(
          key: ValueKey<String>('ai-voice-access-loading'),
          child: _VoiceAccessPage.loading(),
        ),
        error: (_, __) => KeyedSubtree(
          key: const ValueKey<String>('ai-voice-access-error'),
          child: _VoiceAccessPage.unavailable(onRetry: _retry(ref)),
        ),
        data: (effectiveAccess) {
          if (currentUserId == null ||
              effectiveAccess == null ||
              effectiveAccess.userId != currentUserId ||
              effectiveAccess.isAnonymous) {
            return KeyedSubtree(
              key: const ValueKey<String>('ai-voice-access-unavailable'),
              child: _VoiceAccessPage.unavailable(onRetry: _retry(ref)),
            );
          }

          if (effectiveAccess.hasPaidAccess) {
            return KeyedSubtree(
              key: ValueKey<String>(
                'ai-voice-access-authorized-$currentUserId',
              ),
              child: child,
            );
          }

          if (!effectiveAccess.isFree) {
            return KeyedSubtree(
              key: const ValueKey<String>('ai-voice-access-unavailable'),
              child: _VoiceAccessPage.unavailable(onRetry: _retry(ref)),
            );
          }

          return KeyedSubtree(
            key: const ValueKey<String>('ai-voice-access-plus-required'),
            child: _VoiceAccessPage.plusRequired(
              onUpgrade: () => _openUpgrade(context, ref),
              onRetry: _retry(ref),
            ),
          );
        },
      ),
    );
  }

  VoidCallback _retry(WidgetRef ref) {
    return () {
      ref.invalidate(effectiveAccessProvider);
    };
  }

  Future<void> _openUpgrade(BuildContext context, WidgetRef ref) async {
    await context.push(buildMembershipUpgradeRoute(MembershipUpgradePlan.plus));
    if (!context.mounted) return;
    ref.invalidate(effectiveAccessProvider);
  }
}

class _VoiceAccessPage extends StatelessWidget {
  const _VoiceAccessPage._({
    required this.title,
    required this.message,
    required this.icon,
    this.action,
    this.showProgress = false,
  });

  const _VoiceAccessPage.loading()
    : this._(
        title: 'Đang kiểm tra gói Plus',
        message:
            'Nabi đang xác nhận gói của bạn trước khi bật trò chuyện giọng nói.',
        icon: Icons.workspace_premium_outlined,
        showProgress: true,
      );

  _VoiceAccessPage.plusRequired({
    required VoidCallback onUpgrade,
    required VoidCallback onRetry,
  }) : this._(
         title: 'Trò chuyện bằng giọng nói dành cho Plus',
         message: 'Nâng cấp gói Plus để trò chuyện cùng Nabi bằng giọng nói.',
         icon: Icons.workspace_premium_rounded,
         action: _VoiceAccessActions(onUpgrade: onUpgrade, onRetry: onRetry),
       );

  _VoiceAccessPage.unavailable({required VoidCallback onRetry})
    : this._(
        title: 'Chưa kiểm tra được gói Plus',
        message: 'Bạn kiểm tra kết nối rồi thử lại nhé.',
        icon: Icons.cloud_off_outlined,
        action: _VoiceAccessActions(onRetry: onRetry),
      );

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return MedicalScrollPage(
      eyebrow: 'TRÒ CHUYỆN GIỌNG NÓI',
      title: title,
      subtitle: message,
      icon: icon,
      children: [
        MedicalEmptyState(
          icon: icon,
          title: title,
          message: message,
          action: showProgress
              ? const SizedBox.square(
                  dimension: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                )
              : action,
        ),
      ],
    );
  }
}

class _VoiceAccessActions extends StatelessWidget {
  const _VoiceAccessActions({this.onUpgrade, this.onRetry});

  final VoidCallback? onUpgrade;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        if (onUpgrade != null)
          FilledButton.icon(
            key: const Key('ai_voice_upgrade_plus'),
            onPressed: onUpgrade,
            icon: const Icon(Icons.workspace_premium_rounded),
            label: const Text('Nâng cấp Plus'),
          ),
        if (onRetry != null)
          OutlinedButton.icon(
            key: const Key('ai_voice_retry_access'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
          ),
      ],
    );
  }
}

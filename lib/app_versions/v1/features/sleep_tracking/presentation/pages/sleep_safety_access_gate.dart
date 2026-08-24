import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/providers/membership_entitlement_providers.dart';
import 'package:nano_app/core/membership/membership_upgrade_route.dart';

import '../../providers/sleep_safety_providers.dart';

class SleepSafetyAccessGate extends ConsumerWidget {
  const SleepSafetyAccessGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentAuthUserIdProvider);
    final access = ref.watch(effectiveAccessProvider);

    return access.when(
      loading: () => const _GateState(
        icon: Icons.workspace_premium_outlined,
        title: 'Đang kiểm tra gói của bạn',
        message: 'Nabi đang xác nhận quyền sử dụng trước khi bật micro.',
      ),
      error: (_, __) => _GateState(
        icon: Icons.cloud_off_outlined,
        title: 'Chưa kiểm tra được gói',
        message: 'Bạn kiểm tra kết nối rồi thử lại nhé.',
        action: OutlinedButton(
          onPressed: () => ref.invalidate(effectiveAccessProvider),
          child: const Text('Thử lại'),
        ),
      ),
      data: (value) {
        if (userId == null ||
            value == null ||
            value.userId != userId ||
            value.isAnonymous) {
          return const _GateState(
            icon: Icons.lock_outline_rounded,
            title: 'Bạn cần đăng nhập',
            message: 'Đăng nhập để sử dụng Giám sát giấc ngủ.',
          );
        }

        if (!value.hasPaidAccess) {
          return _GateState(
            icon: Icons.workspace_premium_rounded,
            title: 'Giám sát giấc ngủ dành cho Plus',
            message:
                'Nâng cấp Plus hoặc FamilyPlus để sử dụng giám sát âm thanh và cảnh báo an toàn.',
            action: FilledButton(
              onPressed: () => _openUpgrade(context, ref),
              child: const Text('Nâng cấp Plus'),
            ),
          );
        }

        final rollout = ref.watch(sleepSafetyRolloutProvider);
        return rollout.when(
          loading: () => const _GateState(
            icon: Icons.shield_outlined,
            title: 'Đang kiểm tra trạng thái an toàn',
            message: 'Nabi đang xác nhận tính năng đã sẵn sàng trên hệ thống.',
          ),
          error: (_, __) => _GateState(
            icon: Icons.cloud_off_outlined,
            title: 'Chưa thể bật giám sát',
            message:
                'Trạng thái an toàn chưa được xác nhận. Tính năng sẽ không tự mở micro.',
            action: OutlinedButton(
              onPressed: () => ref.invalidate(sleepSafetyRolloutProvider),
              child: const Text('Thử lại'),
            ),
          ),
          data: (enabled) => enabled
              ? child
              : _GateState(
                  icon: Icons.shield_outlined,
                  title: 'Giám sát giấc ngủ đang tạm dừng',
                  message:
                      'Tính năng đang được tạm dừng từ hệ thống. Micro sẽ không tự bật; bạn có thể kiểm tra lại sau.',
                  action: OutlinedButton(
                    onPressed: () => ref.invalidate(sleepSafetyRolloutProvider),
                    child: const Text('Kiểm tra lại'),
                  ),
                ),
        );
      },
    );
  }

  Future<void> _openUpgrade(BuildContext context, WidgetRef ref) async {
    await context.push(
      buildMembershipUpgradeRoute(MembershipUpgradePlan.plus),
    );
    if (!context.mounted) return;
    ref.invalidate(effectiveAccessProvider);
    ref.invalidate(sleepSafetyRolloutProvider);
  }
}

class _GateState extends StatelessWidget {
  const _GateState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giám sát giấc ngủ')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center),
                if (action != null) ...[
                  const SizedBox(height: 20),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

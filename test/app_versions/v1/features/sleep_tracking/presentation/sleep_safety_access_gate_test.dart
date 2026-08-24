import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_safety_access_gate.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/providers/sleep_safety_providers.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/entities/effective_access.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/providers/membership_entitlement_providers.dart';

void main() {
  const userId = 'user-1';

  testWidgets('Free account remains upgrade-gated', (tester) async {
    await tester.pumpWidget(
      _app(
        userId: userId,
        access: _access(userId: userId, membershipPlan: 'free'),
        rollout: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Giám sát giấc ngủ dành cho Plus'), findsOneWidget);
    expect(find.text('Nâng cấp Plus'), findsOneWidget);
    expect(find.text('sleep-safety-child'), findsNothing);
  });

  for (final plan in ['plus', 'family_plus']) {
    testWidgets('$plan account with rollout enabled renders feature', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          userId: userId,
          access: _access(userId: userId, membershipPlan: plan),
          rollout: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('sleep-safety-child'), findsOneWidget);
    });
  }

  testWidgets('Paid account is fail-closed when rollout is off', (tester) async {
    await tester.pumpWidget(
      _app(
        userId: userId,
        access: _access(userId: userId, membershipPlan: 'plus'),
        rollout: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Giám sát giấc ngủ đang tạm dừng'), findsOneWidget);
    expect(find.text('sleep-safety-child'), findsNothing);
  });

  testWidgets('Anonymous access does not render monitoring runtime', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        userId: userId,
        access: _access(
          userId: userId,
          membershipPlan: 'plus',
          isAnonymous: true,
        ),
        rollout: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bạn cần đăng nhập'), findsOneWidget);
    expect(find.text('sleep-safety-child'), findsNothing);
  });

  testWidgets('Mismatched access user is blocked', (tester) async {
    await tester.pumpWidget(
      _app(
        userId: userId,
        access: _access(userId: 'other-user', membershipPlan: 'plus'),
        rollout: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bạn cần đăng nhập'), findsOneWidget);
    expect(find.text('sleep-safety-child'), findsNothing);
  });

  testWidgets('Rollout error fails closed', (tester) async {
    await tester.pumpWidget(
      _app(
        userId: userId,
        access: _access(userId: userId, membershipPlan: 'plus'),
        rollout: true,
        rolloutThrows: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chưa thể bật giám sát'), findsOneWidget);
    expect(find.text('sleep-safety-child'), findsNothing);
  });

}

Widget _app({
  required String userId,
  required EffectiveAccess access,
  required bool rollout,
  bool rolloutThrows = false,
}) {
  return ProviderScope(
    overrides: [
      currentAuthUserIdProvider.overrideWithValue(userId),
      effectiveAccessProvider.overrideWith((ref) async => access),
      sleepSafetyRolloutProvider.overrideWith((ref) async {
        if (rolloutThrows) throw StateError('rollout unavailable');
        return rollout;
      }),
    ],
    child: const MaterialApp(
      home: SleepSafetyAccessGate(
        child: Scaffold(body: Text('sleep-safety-child')),
      ),
    ),
  );
}

EffectiveAccess _access({
  required String userId,
  required String membershipPlan,
  bool isAnonymous = false,
}) {
  return EffectiveAccess(
    userId: userId,
    isAnonymous: isAnonymous,
    productAccess: membershipPlan,
    membershipPlan: membershipPlan,
    saleStatus: 'none',
    onboardingStatus: 'completed',
    updatedAt: DateTime(2026, 8, 24),
  );
}

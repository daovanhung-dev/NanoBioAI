import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_access_gate.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/entities/effective_access.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/repositories/effective_access_repository.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/providers/membership_entitlement_providers.dart';
import 'package:nano_app/core/membership/membership_upgrade_route.dart';

final _testAuthUserIdProvider =
    NotifierProvider<_TestAuthUserIdController, String?>(
      _TestAuthUserIdController.new,
    );

void main() {
  testWidgets('Free fails closed and offers the Plus upgrade action', (
    tester,
  ) async {
    await _pumpGate(tester, access: _access(membershipPlan: 'free'));

    expect(find.byKey(const Key('voice-mount-probe')), findsNothing);
    expect(find.text('Trò chuyện bằng giọng nói dành cho Plus'), findsWidgets);
    expect(find.byKey(const Key('ai_voice_upgrade_plus')), findsOneWidget);
    expect(
      buildMembershipUpgradeRoute(MembershipUpgradePlan.plus),
      '/v2/payments?plan=plus',
    );
  });

  testWidgets('missing authenticated identity fails closed', (tester) async {
    await _pumpGate(
      tester,
      currentUserId: null,
      access: _access(membershipPlan: 'plus'),
    );

    expect(find.byKey(const Key('voice-mount-probe')), findsNothing);
    expect(
      find.byKey(const Key('ai-voice-access-unavailable')),
      findsOneWidget,
    );
  });

  testWidgets('Plus and FamilyPlus mount the protected voice child', (
    tester,
  ) async {
    for (final plan in ['plus', 'family_plus']) {
      await _pumpGate(tester, access: _access(membershipPlan: plan));

      expect(
        find.byKey(const Key('voice-mount-probe')),
        findsOneWidget,
        reason: plan,
      );
    }
  });

  testWidgets('unresolved and user-mismatched access fail closed', (
    tester,
  ) async {
    final deniedCases = <EffectiveAccess?>[
      null,
      _access(membershipPlan: 'plus', isAnonymous: true),
      _access(membershipPlan: 'plus', userId: 'another-user'),
      _access(membershipPlan: 'unknown'),
    ];

    for (final access in deniedCases) {
      await _pumpGate(tester, access: access);

      expect(find.byKey(const Key('voice-mount-probe')), findsNothing);
      expect(
        find.byKey(const Key('ai-voice-access-unavailable')),
        findsOneWidget,
      );
    }
  });

  testWidgets('loading keeps the protected child unmounted', (tester) async {
    final pendingAccess = Completer<EffectiveAccess?>();
    await _pumpGateFuture(tester, access: pendingAccess.future);

    expect(find.byKey(const Key('voice-mount-probe')), findsNothing);
    expect(find.byKey(const Key('ai-voice-access-loading')), findsOneWidget);

    pendingAccess.complete(_access(membershipPlan: 'free'));
    await tester.pump();
  });

  testWidgets('access errors keep the protected child unmounted', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentAuthUserIdProvider.overrideWithValue('user-1'),
          effectiveAccessProvider.overrideWith(
            (ref) => Future<EffectiveAccess?>.error(StateError('offline')),
          ),
        ],
        child: const MaterialApp(
          home: AiVoiceAccessGate(child: _VoiceMountProbe()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('voice-mount-probe')), findsNothing);
    expect(find.byKey(const Key('ai-voice-access-error')), findsOneWidget);
    expect(find.byKey(const Key('ai_voice_retry_access')), findsOneWidget);
  });

  test(
    'effective access is refetched after the authenticated account changes',
    () async {
      late ProviderContainer container;
      final repository = _ActorAwareAccessRepository(
        () => container.read(_testAuthUserIdProvider),
      );
      container = ProviderContainer(
        overrides: [
          currentAuthUserIdProvider.overrideWith(
            (ref) => ref.watch(_testAuthUserIdProvider),
          ),
          effectiveAccessRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        effectiveAccessProvider,
        (_, __) {},
      );
      addTearDown(subscription.close);

      final accountA = await container.read(effectiveAccessProvider.future);
      expect(accountA?.userId, 'account-a');

      container.read(_testAuthUserIdProvider.notifier).switchTo('account-b');
      final accountB = await container.read(effectiveAccessProvider.future);
      expect(accountB?.userId, 'account-b');

      container.read(_testAuthUserIdProvider.notifier).switchTo(null);
      final signedOut = await container.read(effectiveAccessProvider.future);
      expect(signedOut, isNull);
      expect(repository.requestedActors, ['account-a', 'account-b']);
    },
  );
}

Future<void> _pumpGate(
  WidgetTester tester, {
  String? currentUserId = 'user-1',
  required EffectiveAccess? access,
}) {
  return _pumpGateFuture(
    tester,
    currentUserId: currentUserId,
    access: Future.value(access),
  );
}

Future<void> _pumpGateFuture(
  WidgetTester tester, {
  String? currentUserId = 'user-1',
  required Future<EffectiveAccess?> access,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentAuthUserIdProvider.overrideWithValue(currentUserId),
        effectiveAccessProvider.overrideWith((ref) => access),
      ],
      child: const MaterialApp(
        home: AiVoiceAccessGate(child: _VoiceMountProbe()),
      ),
    ),
  );
  await tester.pump();
}

EffectiveAccess _access({
  String userId = 'user-1',
  bool isAnonymous = false,
  required String membershipPlan,
}) {
  return EffectiveAccess(
    userId: userId,
    isAnonymous: isAnonymous,
    productAccess: 'member',
    membershipPlan: membershipPlan,
    saleStatus: 'none',
    onboardingStatus: 'completed',
  );
}

class _VoiceMountProbe extends StatelessWidget {
  const _VoiceMountProbe();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(key: Key('voice-mount-probe'));
  }
}

class _TestAuthUserIdController extends Notifier<String?> {
  @override
  String? build() => 'account-a';

  void switchTo(String? userId) {
    state = userId;
  }
}

class _ActorAwareAccessRepository implements EffectiveAccessRepository {
  _ActorAwareAccessRepository(this._currentActor);

  final String? Function() _currentActor;
  final List<String> requestedActors = [];

  @override
  Future<EffectiveAccess?> fetchCurrentAccess() async {
    final actor = _currentActor();
    if (actor == null) return null;
    requestedActors.add(actor);
    return _access(userId: actor, membershipPlan: 'plus');
  }
}

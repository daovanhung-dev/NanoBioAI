import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/entities/effective_access.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/repositories/effective_access_repository.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/providers/membership_entitlement_providers.dart';
import 'package:nano_app/app_versions/v3/features/familyplus/familyplus.dart';

final _testAuthUserIdProvider =
    NotifierProvider<_TestAuthUserIdController, String?>(
      _TestAuthUserIdController.new,
    );

void main() {
  test('context provider returns auth-required without user id', () async {
    final container = ProviderContainer(
      overrides: [familyPlusCurrentUserIdProvider.overrideWithValue(null)],
    );
    addTearDown(container.dispose);

    final result = await container.read(familyPlusContextProvider.future);

    expect(result.status, FamilyPlusViewStatus.authRequired);
  });

  test('context provider returns locked for Free access', () async {
    final container = ProviderContainer(
      overrides: [
        familyPlusCurrentUserIdProvider.overrideWithValue('u1'),
        familyPlusEffectiveAccessProvider.overrideWith(
          (ref) async => _access('free'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(familyPlusContextProvider.future);

    expect(result.status, FamilyPlusViewStatus.locked);
  });

  test('context provider returns ready for FamilyPlus access', () async {
    final repository = _FakeFamilyPlusRepository(_readyContext());
    final container = ProviderContainer(
      overrides: [
        familyPlusCurrentUserIdProvider.overrideWithValue('u1'),
        familyPlusEffectiveAccessProvider.overrideWith(
          (ref) async => _access('family_plus'),
        ),
        familyPlusRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(familyPlusContextProvider.future);

    expect(result.status, FamilyPlusViewStatus.ready);
    expect(result.context?.activeMembers, hasLength(1));
  });

  test('account switch never reuses the previous FamilyPlus context', () async {
    late ProviderContainer container;
    final accessRepository = _ActorAwareEffectiveAccessRepository(
      () => container.read(_testAuthUserIdProvider),
    );
    final familyRepository = _ActorAwareFamilyPlusRepository(
      () => container.read(_testAuthUserIdProvider),
    );
    container = ProviderContainer(
      overrides: [
        currentAuthUserIdProvider.overrideWith(
          (ref) => ref.watch(_testAuthUserIdProvider),
        ),
        effectiveAccessRepositoryProvider.overrideWithValue(accessRepository),
        familyPlusRepositoryProvider.overrideWithValue(familyRepository),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(
      familyPlusContextProvider,
      (_, __) {},
    );
    addTearDown(subscription.close);

    final accountA = await container.read(familyPlusContextProvider.future);
    expect(accountA.status, FamilyPlusViewStatus.ready);
    expect(accountA.context?.actorId, 'account-a');
    expect(
      accountA.context?.activeMembers.map((member) => member.displayName),
      contains('Member A'),
    );

    container.read(_testAuthUserIdProvider.notifier).switchTo(null);
    final signedOut = await container.read(familyPlusContextProvider.future);
    expect(signedOut.status, FamilyPlusViewStatus.authRequired);
    expect(signedOut.context, isNull);

    container.read(_testAuthUserIdProvider.notifier).switchTo('account-b');
    final accountB = await container.read(familyPlusContextProvider.future);
    final accountBMemberNames = accountB.context?.activeMembers
        .map((member) => member.displayName)
        .toList(growable: false);

    expect(accountB.status, FamilyPlusViewStatus.ready);
    expect(accountB.context?.actorId, 'account-b');
    expect(accountBMemberNames, contains('Member B'));
    expect(accountBMemberNames, isNot(contains('Member A')));
    expect(accessRepository.requestedActors, ['account-a', 'account-b']);
    expect(familyRepository.requestedActors, ['account-a', 'account-b']);
  });

  test('create default group uses repository and refreshes context', () async {
    final repository = _FakeFamilyPlusRepository(_emptyContext());
    final container = ProviderContainer(
      overrides: [
        familyPlusCurrentUserIdProvider.overrideWithValue('u1'),
        familyPlusEffectiveAccessProvider.overrideWith(
          (ref) async => _access('family_plus'),
        ),
        familyPlusRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    await container.read(familyPlusCreateDefaultGroupProvider)();

    expect(repository.groupCalls, 1);
    expect(repository.lastGroupName, 'Gia đình của tôi');
    expect(repository.lastGroupKey, startsWith('family-group-'));
  });
}

EffectiveAccess _access(String membershipPlan, {String userId = 'u1'}) {
  return EffectiveAccess(
    userId: userId,
    isAnonymous: false,
    productAccess: 'member',
    membershipPlan: membershipPlan,
    saleStatus: 'none',
    onboardingStatus: 'completed',
  );
}

FamilyPlusContext _contextForActor(String actorId) {
  final suffix = actorId == 'account-a' ? 'A' : 'B';
  return FamilyPlusContext(
    actorId: actorId,
    selfSubjectId: 'subject-$actorId',
    hasFamilyPlus: true,
    group: FamilyPlusGroup(
      id: 'group-$actorId',
      ownerUserId: actorId,
      displayName: 'Family $suffix',
      status: 'active',
    ),
    members: [
      FamilyPlusMember(
        id: 'member-$actorId',
        familyGroupId: 'group-$actorId',
        subjectId: 'subject-$actorId',
        userId: actorId,
        displayName: 'Member $suffix',
        role: 'owner',
        status: 'active',
        canView: true,
        canEdit: true,
      ),
    ],
  );
}

FamilyPlusContext _emptyContext() {
  return const FamilyPlusContext(
    actorId: 'u1',
    selfSubjectId: 'subject-self',
    hasFamilyPlus: true,
    group: FamilyPlusGroup(
      id: 'group-1',
      ownerUserId: 'u1',
      displayName: 'Gia dinh',
      status: 'active',
    ),
  );
}

FamilyPlusContext _readyContext() {
  return const FamilyPlusContext(
    actorId: 'u1',
    selfSubjectId: 'subject-self',
    hasFamilyPlus: true,
    group: FamilyPlusGroup(
      id: 'group-1',
      ownerUserId: 'u1',
      displayName: 'Gia dinh',
      status: 'active',
    ),
    members: [
      FamilyPlusMember(
        id: 'member-1',
        familyGroupId: 'group-1',
        subjectId: 'subject-1',
        displayName: 'Me',
        role: 'adult',
        status: 'active',
        canView: true,
        canEdit: true,
      ),
    ],
  );
}

class _FakeFamilyPlusRepository implements FamilyPlusRepository {
  FamilyPlusContext context;
  int groupCalls = 0;
  String? lastGroupName;
  String? lastGroupKey;

  _FakeFamilyPlusRepository(this.context);

  @override
  Future<FamilyPlusContext> fetchContext() async => context;

  @override
  Future<FamilyPlusContext> upsertGroup(
    FamilyPlusUpsertGroupCommand command,
  ) async {
    groupCalls++;
    lastGroupName = command.displayName;
    lastGroupKey = command.idempotencyKey;
    context = _readyContext();
    return context;
  }

  @override
  Future<FamilyPlusContext> upsertMember(
    FamilyPlusUpsertMemberCommand command,
  ) async {
    return context;
  }

  @override
  Future<FamilyPlusContext> removeMember(
    FamilyPlusRemoveMemberCommand command,
  ) async {
    return context;
  }

  @override
  String switchSubjectContext(
    FamilyPlusContext context, {
    required String requestedSubjectId,
  }) {
    return requestedSubjectId;
  }
}

class _TestAuthUserIdController extends Notifier<String?> {
  @override
  String? build() => 'account-a';

  void switchTo(String? userId) {
    state = userId;
  }
}

class _ActorAwareEffectiveAccessRepository extends Fake
    implements EffectiveAccessRepository {
  _ActorAwareEffectiveAccessRepository(this._readActor);

  final String? Function() _readActor;
  final List<String> requestedActors = [];

  @override
  Future<EffectiveAccess?> fetchCurrentAccess() async {
    final actorId = _readActor();
    if (actorId == null) return null;
    requestedActors.add(actorId);
    return _access('family_plus', userId: actorId);
  }
}

class _ActorAwareFamilyPlusRepository extends Fake
    implements FamilyPlusRepository {
  _ActorAwareFamilyPlusRepository(this._readActor);

  final String? Function() _readActor;
  final List<String> requestedActors = [];

  @override
  Future<FamilyPlusContext> fetchContext() async {
    final actorId = _readActor();
    if (actorId == null) throw const FamilyPlusException.authRequired();
    requestedActors.add(actorId);
    return _contextForActor(actorId);
  }
}

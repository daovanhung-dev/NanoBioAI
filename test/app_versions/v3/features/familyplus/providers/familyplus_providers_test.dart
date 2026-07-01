import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/domain/entities/effective_access.dart';
import 'package:nano_app/app_versions/v3/features/familyplus/familyplus.dart';

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
    expect(repository.lastGroupName, 'Gia dinh cua toi');
    expect(repository.lastGroupKey, startsWith('family-group-'));
  });
}

EffectiveAccess _access(String membershipPlan) {
  return EffectiveAccess(
    userId: 'u1',
    isAnonymous: false,
    productAccess: 'member',
    membershipPlan: membershipPlan,
    saleStatus: 'none',
    onboardingStatus: 'completed',
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

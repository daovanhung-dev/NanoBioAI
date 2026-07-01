import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v3/features/familyplus/data/datasources/familyplus_remote_datasource.dart';
import 'package:nano_app/app_versions/v3/features/familyplus/data/repositories/supabase_familyplus_repository.dart';
import 'package:nano_app/app_versions/v3/features/familyplus/familyplus.dart';

void main() {
  group('SupabaseFamilyPlusRepository', () {
    test('upsert group trims payload and requires idempotency key', () async {
      final datasource = _FakeFamilyPlusDatasource();
      final repository = SupabaseFamilyPlusRepository(datasource: datasource);

      await repository.upsertGroup(
        const FamilyPlusUpsertGroupCommand(
          displayName: ' Gia dinh ',
          idempotencyKey: ' group-key ',
        ),
      );

      expect(datasource.lastGroupName, 'Gia dinh');
      expect(datasource.lastIdempotencyKey, 'group-key');
      await expectLater(
        repository.upsertGroup(
          const FamilyPlusUpsertGroupCommand(
            displayName: '',
            idempotencyKey: 'missing-name',
          ),
        ),
        throwsA(isA<FamilyPlusException>()),
      );
    });

    test('upsert member forwards role, permissions and idempotency', () async {
      final datasource = _FakeFamilyPlusDatasource();
      final repository = SupabaseFamilyPlusRepository(datasource: datasource);

      await repository.upsertMember(
        const FamilyPlusUpsertMemberCommand(
          subjectId: ' subject-1 ',
          displayName: ' Me ',
          role: 'adult',
          canEdit: true,
          idempotencyKey: 'member-key',
        ),
      );

      expect(datasource.lastMemberSubjectId, 'subject-1');
      expect(datasource.lastMemberDisplayName, 'Me');
      expect(datasource.lastMemberRole, 'adult');
      expect(datasource.lastMemberCanEdit, isTrue);
      expect(datasource.lastIdempotencyKey, 'member-key');
    });

    test('switch subject allows self and viewable active members only', () {
      final repository = SupabaseFamilyPlusRepository(
        datasource: _FakeFamilyPlusDatasource(),
      );
      final context = _context();

      expect(
        repository.switchSubjectContext(
          context,
          requestedSubjectId: 'subject-self',
        ),
        'subject-self',
      );
      expect(
        repository.switchSubjectContext(
          context,
          requestedSubjectId: 'subject-view',
        ),
        'subject-view',
      );
      expect(
        () => repository.switchSubjectContext(
          context,
          requestedSubjectId: 'owner-1',
        ),
        throwsA(isA<FamilyPlusException>()),
      );
      expect(
        () => repository.switchSubjectContext(
          context,
          requestedSubjectId: 'subject-hidden',
        ),
        throwsA(isA<FamilyPlusException>()),
      );
    });
  });
}

FamilyPlusContext _context() {
  return const FamilyPlusContext(
    actorId: 'owner-1',
    selfSubjectId: 'subject-self',
    hasFamilyPlus: true,
    group: FamilyPlusGroup(
      id: 'group-1',
      ownerUserId: 'owner-1',
      displayName: 'Gia dinh',
      status: 'active',
    ),
    members: [
      FamilyPlusMember(
        id: 'member-view',
        familyGroupId: 'group-1',
        subjectId: 'subject-view',
        displayName: 'Duoc xem',
        role: 'member',
        status: 'active',
        canView: true,
        canEdit: false,
      ),
      FamilyPlusMember(
        id: 'member-hidden',
        familyGroupId: 'group-1',
        subjectId: 'subject-hidden',
        displayName: 'An',
        role: 'member',
        status: 'active',
        canView: false,
        canEdit: false,
      ),
    ],
  );
}

class _FakeFamilyPlusDatasource implements FamilyPlusRemoteDatasource {
  String? lastGroupName;
  String? lastIdempotencyKey;
  String? lastMemberSubjectId;
  String? lastMemberDisplayName;
  String? lastMemberRole;
  bool? lastMemberCanEdit;

  @override
  Future<Map<String, Object?>> getContext() async => _contextMap();

  @override
  Future<Map<String, Object?>> upsertGroup({
    required String displayName,
    required String idempotencyKey,
  }) async {
    lastGroupName = displayName;
    lastIdempotencyKey = idempotencyKey;
    return _contextMap();
  }

  @override
  Future<Map<String, Object?>> upsertMember({
    required String subjectId,
    required String displayName,
    required String role,
    required bool canView,
    required bool canEdit,
    required String idempotencyKey,
  }) async {
    lastMemberSubjectId = subjectId;
    lastMemberDisplayName = displayName;
    lastMemberRole = role;
    lastMemberCanEdit = canEdit;
    lastIdempotencyKey = idempotencyKey;
    return _contextMap();
  }

  @override
  Future<Map<String, Object?>> removeMember({
    required String memberId,
    required String idempotencyKey,
  }) async {
    lastIdempotencyKey = idempotencyKey;
    return _contextMap();
  }

  Map<String, Object?> _contextMap() => {
    'actor_id': 'owner-1',
    'self_subject_id': 'subject-self',
    'has_family_plus': true,
    'group': {
      'id': 'group-1',
      'owner_user_id': 'owner-1',
      'display_name': 'Gia dinh',
      'status': 'active',
    },
    'members': const [],
  };
}

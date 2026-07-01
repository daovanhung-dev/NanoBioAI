import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v3/features/familyplus/familyplus.dart';

void main() {
  group('FamilyPlusContext', () {
    test('parses context payload and member limit from Supabase RPC', () {
      final context = FamilyPlusContext.fromMap({
        'actor_id': 'owner-1',
        'self_subject_id': 'subject-self',
        'has_family_plus': true,
        'group': {
          'id': 'group-1',
          'owner_user_id': 'owner-1',
          'display_name': 'Gia dinh',
          'status': 'active',
        },
        'members': List.generate(
          familyPlusMaxMembers,
          (index) => {
            'id': 'member-$index',
            'family_group_id': 'group-1',
            'subject_id': 'subject-$index',
            'display_name': 'Thanh vien $index',
            'status': 'active',
            'can_view': 1,
            'can_edit': index == 0 ? 1 : 0,
          },
        ),
        'selected_subject_id': 'subject-self',
      });

      expect(context.actorId, 'owner-1');
      expect(context.selfSubjectId, 'subject-self');
      expect(context.canManage, isTrue);
      expect(context.activeMembers, hasLength(familyPlusMaxMembers));
      expect(context.isAtMemberLimit, isTrue);
    });

    test('ignores removed members for active member limit', () {
      final context = FamilyPlusContext.fromMap({
        'actor_id': 'owner-1',
        'has_family_plus': true,
        'group': {
          'id': 'group-1',
          'owner_user_id': 'owner-1',
          'display_name': 'Gia dinh',
        },
        'members': const [
          {
            'id': 'member-1',
            'family_group_id': 'group-1',
            'subject_id': 'subject-1',
            'display_name': 'Da go',
            'status': 'removed',
            'can_view': true,
          },
        ],
      });

      expect(context.activeMembers, isEmpty);
      expect(context.isAtMemberLimit, isFalse);
    });
  });
}

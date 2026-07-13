import 'package:nano_app/core/access/subject_access_context.dart';

const familyPlusMaxMembers = 5;

enum FamilyPlusViewStatus { authRequired, locked, empty, ready, failure }

class FamilyPlusGroup {
  final String id;
  final String ownerUserId;
  final String displayName;
  final String status;

  const FamilyPlusGroup({
    required this.id,
    required this.ownerUserId,
    required this.displayName,
    required this.status,
  });

  factory FamilyPlusGroup.fromMap(Map<String, Object?> map) {
    return FamilyPlusGroup(
      id: _readString(map['id']),
      ownerUserId: _readString(map['owner_user_id']),
      displayName: _readString(map['display_name'], fallback: 'Gia đình'),
      status: _readString(map['status'], fallback: 'active'),
    );
  }
}

class FamilyPlusMember {
  final String id;
  final String familyGroupId;
  final String subjectId;
  final String? userId;
  final String displayName;
  final String role;
  final String status;
  final bool canView;
  final bool canEdit;

  const FamilyPlusMember({
    required this.id,
    required this.familyGroupId,
    required this.subjectId,
    this.userId,
    required this.displayName,
    required this.role,
    required this.status,
    required this.canView,
    required this.canEdit,
  });

  factory FamilyPlusMember.fromMap(Map<String, Object?> map) {
    return FamilyPlusMember(
      id: _readString(map['id']),
      familyGroupId: _readString(map['family_group_id']),
      subjectId: _readString(map['subject_id']),
      userId: _readNullableString(map['user_id']),
      displayName: _readString(map['display_name'], fallback: 'Thành viên'),
      role: _readString(map['role'], fallback: 'member'),
      status: _readString(map['status'], fallback: 'active'),
      canView: _readBool(map['can_view'], fallback: true),
      canEdit: _readBool(map['can_edit']),
    );
  }

  bool get isActive => status == 'active';
}

class FamilyPlusContext {
  final String actorId;
  final bool hasFamilyPlus;
  final String? selfSubjectId;
  final FamilyPlusGroup? group;
  final List<FamilyPlusMember> members;
  final String? selectedSubjectId;

  const FamilyPlusContext({
    required this.actorId,
    required this.hasFamilyPlus,
    this.selfSubjectId,
    this.group,
    this.members = const [],
    this.selectedSubjectId,
  });

  factory FamilyPlusContext.fromMap(Map<String, Object?> map) {
    return FamilyPlusContext(
      actorId: _readString(map['actor_id']),
      hasFamilyPlus: _readBool(map['has_family_plus']),
      selfSubjectId: _readNullableString(map['self_subject_id']),
      group: _readMap(map['group']) == null
          ? null
          : FamilyPlusGroup.fromMap(_readMap(map['group'])!),
      members: _readList(
        map['members'],
      ).map(FamilyPlusMember.fromMap).toList(growable: false),
      selectedSubjectId: _readNullableString(map['selected_subject_id']),
    );
  }

  bool get isOwner => group?.ownerUserId == actorId;
  bool get canManage => hasFamilyPlus && isOwner;
  bool get isEmpty => group == null || members.isEmpty;
  bool get isAtMemberLimit => activeMembers.length >= familyPlusMaxMembers;

  List<FamilyPlusMember> get activeMembers {
    return members.where((member) => member.isActive).toList(growable: false);
  }

  SubjectAccessContext subjectAccessFor(String? requestedSubjectId) {
    return SubjectAccessContext(
      actorId: actorId,
      requestedSubjectId: requestedSubjectId,
      isFamilyPlus: hasFamilyPlus,
    );
  }
}

class FamilyPlusViewModel {
  final FamilyPlusViewStatus status;
  final FamilyPlusContext? context;
  final String message;

  const FamilyPlusViewModel._({
    required this.status,
    this.context,
    required this.message,
  });

  const FamilyPlusViewModel.authRequired()
    : this._(
        status: FamilyPlusViewStatus.authRequired,
        message: 'Cần đăng nhập để quản lý FamilyPlus.',
      );

  const FamilyPlusViewModel.locked()
    : this._(
        status: FamilyPlusViewStatus.locked,
        message: 'Tính năng này chỉ dành cho gói FamilyPlus đang hoạt động.',
      );

  const FamilyPlusViewModel.empty(FamilyPlusContext context)
    : this._(
        status: FamilyPlusViewStatus.empty,
        context: context,
        message: 'Chưa có nhóm gia đình. Hãy tạo nhóm để bắt đầu.',
      );

  const FamilyPlusViewModel.ready(FamilyPlusContext context)
    : this._(status: FamilyPlusViewStatus.ready, context: context, message: '');

  const FamilyPlusViewModel.failure(String message)
    : this._(status: FamilyPlusViewStatus.failure, message: message);
}

class FamilyPlusUpsertGroupCommand {
  final String displayName;
  final String idempotencyKey;

  const FamilyPlusUpsertGroupCommand({
    required this.displayName,
    required this.idempotencyKey,
  });
}

class FamilyPlusUpsertMemberCommand {
  final String subjectId;
  final String displayName;
  final String role;
  final bool canView;
  final bool canEdit;
  final String idempotencyKey;

  const FamilyPlusUpsertMemberCommand({
    required this.subjectId,
    required this.displayName,
    this.role = 'member',
    this.canView = true,
    this.canEdit = false,
    required this.idempotencyKey,
  });
}

class FamilyPlusRemoveMemberCommand {
  final String memberId;
  final String idempotencyKey;

  const FamilyPlusRemoveMemberCommand({
    required this.memberId,
    required this.idempotencyKey,
  });
}

class FamilyPlusException implements Exception {
  final String code;
  final String safeMessage;

  const FamilyPlusException(this.code, this.safeMessage);

  const FamilyPlusException.authRequired()
    : this('AUTH_REQUIRED', 'Cần đăng nhập để quản lý FamilyPlus.');

  const FamilyPlusException.forbidden()
    : this('FORBIDDEN', 'Tài khoản chưa có quyền FamilyPlus phù hợp.');

  const FamilyPlusException.invalidCommand()
    : this('INVALID_COMMAND', 'Thông tin FamilyPlus chưa hợp lệ.');

  @override
  String toString() => '$code: $safeMessage';
}

String _readString(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String? _readNullableString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

bool _readBool(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}

Map<String, Object?>? _readMap(Object? value) {
  if (value is! Map) return null;
  return value.map((key, value) => MapEntry(key.toString(), value));
}

List<Map<String, Object?>> _readList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((row) => row.map((key, value) => MapEntry(key.toString(), value)))
      .toList(growable: false);
}

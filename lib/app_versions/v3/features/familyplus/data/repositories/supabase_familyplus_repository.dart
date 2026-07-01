import '../../domain/entities/familyplus_models.dart';
import '../../domain/repositories/familyplus_repository.dart';
import '../datasources/familyplus_remote_datasource.dart';

class SupabaseFamilyPlusRepository implements FamilyPlusRepository {
  final FamilyPlusRemoteDatasource datasource;

  const SupabaseFamilyPlusRepository({required this.datasource});

  @override
  Future<FamilyPlusContext> fetchContext() async {
    return FamilyPlusContext.fromMap(await datasource.getContext());
  }

  @override
  Future<FamilyPlusContext> upsertGroup(
    FamilyPlusUpsertGroupCommand command,
  ) async {
    _requireText(command.displayName);
    _requireText(command.idempotencyKey);
    return FamilyPlusContext.fromMap(
      await datasource.upsertGroup(
        displayName: command.displayName.trim(),
        idempotencyKey: command.idempotencyKey.trim(),
      ),
    );
  }

  @override
  Future<FamilyPlusContext> upsertMember(
    FamilyPlusUpsertMemberCommand command,
  ) async {
    _requireText(command.subjectId);
    _requireText(command.displayName);
    _requireText(command.idempotencyKey);
    return FamilyPlusContext.fromMap(
      await datasource.upsertMember(
        subjectId: command.subjectId.trim(),
        displayName: command.displayName.trim(),
        role: command.role.trim().isEmpty ? 'member' : command.role.trim(),
        canView: command.canView,
        canEdit: command.canEdit,
        idempotencyKey: command.idempotencyKey.trim(),
      ),
    );
  }

  @override
  Future<FamilyPlusContext> removeMember(
    FamilyPlusRemoveMemberCommand command,
  ) async {
    _requireText(command.memberId);
    _requireText(command.idempotencyKey);
    return FamilyPlusContext.fromMap(
      await datasource.removeMember(
        memberId: command.memberId.trim(),
        idempotencyKey: command.idempotencyKey.trim(),
      ),
    );
  }

  @override
  String switchSubjectContext(
    FamilyPlusContext context, {
    required String requestedSubjectId,
  }) {
    final subjectId = context
        .subjectAccessFor(requestedSubjectId)
        .resolveSubjectId();
    final selfSubjectId = context.selfSubjectId?.trim();
    if (selfSubjectId != null &&
        selfSubjectId.isNotEmpty &&
        subjectId == selfSubjectId) {
      return subjectId;
    }
    if ((selfSubjectId == null || selfSubjectId.isEmpty) &&
        subjectId == context.actorId) {
      return subjectId;
    }
    final canRead = context.activeMembers.any(
      (member) => member.subjectId == subjectId && member.canView,
    );
    if (!canRead) {
      throw const FamilyPlusException.forbidden();
    }
    return subjectId;
  }

  void _requireText(String value) {
    if (value.trim().isEmpty) {
      throw const FamilyPlusException.invalidCommand();
    }
  }
}

import '../entities/familyplus_models.dart';

abstract class FamilyPlusRepository {
  Future<FamilyPlusContext> fetchContext();

  Future<FamilyPlusContext> upsertGroup(FamilyPlusUpsertGroupCommand command);

  Future<FamilyPlusContext> upsertMember(FamilyPlusUpsertMemberCommand command);

  Future<FamilyPlusContext> removeMember(FamilyPlusRemoveMemberCommand command);

  String switchSubjectContext(
    FamilyPlusContext context, {
    required String requestedSubjectId,
  });
}

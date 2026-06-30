class SubjectAccessContext {
  final String actorId;
  final String? requestedSubjectId;
  final bool isFamilyPlus;

  const SubjectAccessContext({
    required this.actorId,
    this.requestedSubjectId,
    this.isFamilyPlus = false,
  });

  String resolveSubjectId() {
    final normalizedActorId = actorId.trim();
    if (normalizedActorId.isEmpty) {
      throw const SubjectAccessException.authRequired();
    }

    final normalizedSubjectId = requestedSubjectId?.trim();
    if (normalizedSubjectId == null || normalizedSubjectId.isEmpty) {
      return normalizedActorId;
    }

    if (normalizedSubjectId == normalizedActorId || isFamilyPlus) {
      return normalizedSubjectId;
    }

    throw const SubjectAccessException.familyPlusRequired();
  }
}

class SubjectAccessException implements Exception {
  final String code;
  final String safeMessage;

  const SubjectAccessException(this.code, this.safeMessage);

  const SubjectAccessException.authRequired()
    : this('AUTH_REQUIRED', 'Can dang nhap de xem du lieu suc khoe.');

  const SubjectAccessException.familyPlusRequired()
    : this(
        'FAMILY_PLUS_REQUIRED',
        'Chi goi FamilyPlus moi duoc xem ho so suc khoe cua thanh vien khac.',
      );

  @override
  String toString() => '$code: $safeMessage';
}

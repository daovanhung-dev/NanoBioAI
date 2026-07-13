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
    : this('AUTH_REQUIRED', 'Cần đăng nhập để xem dữ liệu sức khỏe.');

  const SubjectAccessException.familyPlusRequired()
    : this(
        'FAMILY_PLUS_REQUIRED',
        'Chỉ gói FamilyPlus mới được xem hồ sơ sức khỏe của thành viên khác.',
      );

  @override
  String toString() => '$code: $safeMessage';
}

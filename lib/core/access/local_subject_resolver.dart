import 'subject_access_context.dart';

typedef CurrentActorIdReader = String? Function();
typedef PendingGuestUserIdReader = Future<String?> Function();
typedef SubjectAccessContextReader = SubjectAccessContext? Function();

class LocalSubjectResolutionException implements Exception {
  final String safeMessage;

  const LocalSubjectResolutionException([
    this.safeMessage = 'Nabi chưa xác định được hồ sơ đang sử dụng.',
  ]);

  @override
  String toString() => safeMessage;
}

/// Resolves the local subject explicitly from the authenticated access context
/// or from the durable guest identity. Storage recency is never used as an
/// identity signal.
class LocalSubjectResolver {
  final CurrentActorIdReader currentActorId;
  final PendingGuestUserIdReader pendingGuestUserId;
  final SubjectAccessContextReader subjectAccessContext;

  const LocalSubjectResolver({
    required this.currentActorId,
    required this.pendingGuestUserId,
    this.subjectAccessContext = _noSubjectAccessContext,
  });

  Future<String> resolve() async {
    final actorId = currentActorId()?.trim();
    if (actorId != null && actorId.isNotEmpty) {
      final access =
          subjectAccessContext() ?? SubjectAccessContext(actorId: actorId);
      final subjectId = access.resolveSubjectId().trim();
      if (subjectId.isEmpty) {
        throw const LocalSubjectResolutionException();
      }
      return subjectId;
    }

    final guestId = (await pendingGuestUserId())?.trim();
    if (guestId != null && guestId.isNotEmpty) {
      return guestId;
    }

    throw const LocalSubjectResolutionException();
  }
}

SubjectAccessContext? _noSubjectAccessContext() => null;

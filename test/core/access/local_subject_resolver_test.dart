import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/access/local_subject_resolver.dart';
import 'package:nano_app/core/access/subject_access_context.dart';

void main() {
  test('resolves authenticated actor by default', () async {
    final resolver = LocalSubjectResolver(
      currentActorId: () => 'actor-a',
      pendingGuestUserId: () async => 'guest-1',
    );

    expect(await resolver.resolve(), 'actor-a');
  });

  test('resolves selected FamilyPlus subject from access context', () async {
    final resolver = LocalSubjectResolver(
      currentActorId: () => 'actor-a',
      pendingGuestUserId: () async => null,
      subjectAccessContext: () => const SubjectAccessContext(
        actorId: 'actor-a',
        requestedSubjectId: 'child-b',
        isFamilyPlus: true,
      ),
    );

    expect(await resolver.resolve(), 'child-b');
  });

  test('rejects cross-subject access without FamilyPlus', () async {
    final resolver = LocalSubjectResolver(
      currentActorId: () => 'actor-a',
      pendingGuestUserId: () async => null,
      subjectAccessContext: () => const SubjectAccessContext(
        actorId: 'actor-a',
        requestedSubjectId: 'child-b',
      ),
    );

    expect(resolver.resolve, throwsA(isA<SubjectAccessException>()));
  });

  test('uses durable guest identity when there is no authenticated actor', () async {
    final resolver = LocalSubjectResolver(
      currentActorId: () => null,
      pendingGuestUserId: () async => 'guest-local-1',
    );

    expect(await resolver.resolve(), 'guest-local-1');
  });

  test('never falls back to storage recency when no identity exists', () async {
    final resolver = LocalSubjectResolver(
      currentActorId: () => null,
      pendingGuestUserId: () async => null,
    );

    expect(
      resolver.resolve,
      throwsA(isA<LocalSubjectResolutionException>()),
    );
  });
}

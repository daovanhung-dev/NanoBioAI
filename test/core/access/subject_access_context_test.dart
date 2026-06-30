import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/access/subject_access_context.dart';

void main() {
  group('SubjectAccessContext', () {
    test('resolves self subject by default', () {
      const context = SubjectAccessContext(actorId: 'actor-1');

      expect(context.resolveSubjectId(), 'actor-1');
    });

    test('allows FamilyPlus actor to read another subject', () {
      const context = SubjectAccessContext(
        actorId: 'actor-1',
        requestedSubjectId: 'member-1',
        isFamilyPlus: true,
      );

      expect(context.resolveSubjectId(), 'member-1');
    });

    test('blocks non-FamilyPlus actor from another subject', () {
      const context = SubjectAccessContext(
        actorId: 'actor-1',
        requestedSubjectId: 'member-1',
      );

      expect(context.resolveSubjectId, throwsA(isA<SubjectAccessException>()));
    });
  });
}

import 'health_context_snapshot.dart';

abstract interface class HealthContextReader {
  Future<HealthContextSnapshot> read({String? subjectId});
}

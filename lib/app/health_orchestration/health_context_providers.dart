import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/features/nabi/application/care/nabi_care_controller.dart';
import 'package:nano_app/services/health_context/health_context_snapshot.dart';

import 'app_health_context_builder.dart';

final appHealthContextBuilderProvider = Provider<AppHealthContextBuilder>((ref) {
  return AppHealthContextBuilder(
    repository: ref.watch(nabiCareRepositoryProvider),
  );
});

final healthContextProvider =
    FutureProvider.family<HealthContextSnapshot, String>((ref, subjectId) {
  return ref.watch(appHealthContextBuilderProvider).read(subjectId: subjectId);
});

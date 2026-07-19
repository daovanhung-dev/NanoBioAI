/// Provenance for a generated personal schedule.
///
/// `localFallback` is deliberately sticky: if any meal or exercise chunk is
/// built from the local catalog, the complete schedule must be presented as a
/// basic suggestion and must not consume a member AI-generation quota.
enum PlanGenerationSource {
  ai,
  localFallback,
  unknown;

  String get storageValue => switch (this) {
    PlanGenerationSource.ai => 'ai',
    PlanGenerationSource.localFallback => 'local_fallback',
    PlanGenerationSource.unknown => 'unknown',
  };

  bool get isFullyAiGenerated => this == PlanGenerationSource.ai;

  bool get isBasicSuggestion => !isFullyAiGenerated;

  static PlanGenerationSource fromStorage(Object? value) {
    return switch (value?.toString().trim().toLowerCase()) {
      'ai' => PlanGenerationSource.ai,
      'local_fallback' => PlanGenerationSource.localFallback,
      _ => PlanGenerationSource.unknown,
    };
  }

  static PlanGenerationSource combine(Iterable<PlanGenerationSource> sources) {
    final values = sources.toList(growable: false);
    if (values.any((source) => source == PlanGenerationSource.localFallback)) {
      return PlanGenerationSource.localFallback;
    }
    if (values.isNotEmpty &&
        values.every((source) => source == PlanGenerationSource.ai)) {
      return PlanGenerationSource.ai;
    }
    return PlanGenerationSource.unknown;
  }
}

/// Generated values together with their safe provenance.
class AIGenerationResult<T> {
  final T value;
  final PlanGenerationSource source;

  const AIGenerationResult({required this.value, required this.source});
}

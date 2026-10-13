import 'package:nano_app/app_versions/v1/features/meal_plan/data/datasources/food_evidence_remote_datasource.dart';
import 'package:nano_app/core/storage/localdb/datasources/ai_catalog_local_datasource.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';

class FoodEvidenceEnrichmentService {
  final AiCatalogLocalDatasource catalogDatasource;
  final FoodEvidenceRemoteDatasource remoteDatasource;
  final DateTime Function() now;

  const FoodEvidenceEnrichmentService({
    this.catalogDatasource = const AiCatalogLocalDatasource(),
    this.remoteDatasource = const FoodEvidenceRemoteDatasource(),
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<AiCatalogBundle> ensureEvidence(AiCatalogBundle bundle) async {
    final byNormalizedName = <String, String>{};
    for (final name
        in bundle.meals
            .expand((meal) => meal.ingredientQuantities)
            .map((ingredient) => ingredient.name.trim())
            .where((name) => name.isNotEmpty)) {
      byNormalizedName.putIfAbsent(normalizeFoodEvidenceName(name), () => name);
    }
    final names = byNormalizedName.values.toList(growable: false);
    // Older source catalog rows do not yet have normalized ingredient
    // quantities. There is nothing reliable to query in that case; preserve
    // the original unknown metadata and let local safety rules decide.
    if (names.isEmpty) return bundle;

    final missing = names
        .where((name) {
          final evidence =
              bundle.ingredientEvidenceByName[normalizeFoodEvidenceName(name)];
          if (evidence == null) return true;
          final retrievedAt = DateTime.tryParse(evidence.retrievedAt);
          if (retrievedAt == null) return true;
          return now().difference(retrievedAt).inDays >= 180;
        })
        .toList(growable: false);

    for (var offset = 0; offset < missing.length; offset += 30) {
      final chunk = missing.skip(offset).take(30).toList(growable: false);
      final fresh = await remoteDatasource.lookupIngredients(chunk);
      await catalogDatasource.cacheFoodEvidence(fresh);
    }

    final refreshed = await catalogDatasource.loadActiveBundle();
    final refreshedNames = refreshed.ingredientEvidenceByName;
    return AiCatalogBundle(
      meals: bundle.meals,
      exercises: bundle.exercises,
      scheduleTasks: bundle.scheduleTasks,
      ingredientEvidenceByName: {
        ...bundle.ingredientEvidenceByName,
        ...refreshedNames,
      },
    );
  }
}

import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';
import 'package:nano_app/core/network/backend_api_client.dart';

class FoodEvidenceLookupException implements Exception {
  const FoodEvidenceLookupException();

  @override
  String toString() => 'Trusted food evidence lookup failed.';
}

class FoodEvidenceRemoteDatasource {
  final BackendApiClient? clientOverride;

  const FoodEvidenceRemoteDatasource({this.clientOverride});

  Future<List<FoodIngredientEvidence>> lookupIngredients(
    List<String> ingredients,
  ) async {
    final byNormalizedName = <String, String>{};
    for (final value in ingredients) {
      final name = value.trim();
      final normalized = normalizeFoodEvidenceName(name);
      if (normalized.isNotEmpty) {
        byNormalizedName.putIfAbsent(normalized, () => name);
      }
    }
    final names = byNormalizedName.values.toList(growable: false);
    if (names.isEmpty || names.length > 30) {
      throw const FoodEvidenceLookupException();
    }

    try {
      final client = clientOverride ?? BackendApiClient.shared;
      final data = await client.requestMap(
        'POST',
        '/api/v1/food/evidence',
        body: {'ingredients': names},
      );
      if (data['foods'] is! List) {
        throw const FoodEvidenceLookupException();
      }
      final records = (data['foods'] as List)
          .whereType<Map>()
          .map(
            (entry) => FoodIngredientEvidence.fromMap(
              Map<String, Object?>.from(entry),
            ),
          )
          .toList(growable: false);
      const trustedSources = {
        'USDA FoodData Central',
        'Viện Dinh dưỡng Quốc gia',
      };
      if (records.length != names.length ||
          records.any(
            (record) => !trustedSources.contains(record.sourceName),
          )) {
        throw const FoodEvidenceLookupException();
      }
      return records;
    } catch (_) {
      throw const FoodEvidenceLookupException();
    }
  }
}

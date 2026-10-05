import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/fitness_training_catalog.dart';

class FitnessTrainingCatalogAssetDatasource {
  const FitnessTrainingCatalogAssetDatasource({this.bundle});

  static const _exercisePath =
      'assets/data/fitness_training/fitness_exercise_equipment_draft_v1.json';
  static const _ingredientPath =
      'assets/data/fitness_training/fitness_ingredients_draft_v1.json';
  static const _recipePath =
      'assets/data/fitness_training/fitness_recipes_draft_v1.json';
  static const _atlasPath =
      'assets/data/fitness_training/fitness_image_atlases_draft_v1.json';

  final AssetBundle? bundle;

  Future<FitnessTrainingCatalog> load() async {
    final assetBundle = bundle ?? rootBundle;
    final sources = await Future.wait([
      assetBundle.loadString(_exercisePath),
      assetBundle.loadString(_ingredientPath),
      assetBundle.loadString(_recipePath),
      assetBundle.loadString(_atlasPath),
    ]);
    try {
      return FitnessTrainingCatalog.fromJsonSources(
        exercisesSource: _decode(sources[0]),
        ingredientsSource: _decode(sources[1]),
        recipesSource: _decode(sources[2]),
        atlasesSource: _decode(sources[3]),
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Fitness pilot catalog could not be loaded.');
    }
  }

  Map<String, Object?> _decode(String source) {
    final value = jsonDecode(source);
    if (value is Map) return Map<String, Object?>.from(value);
    throw const FormatException('Fitness catalog file must contain an object.');
  }
}

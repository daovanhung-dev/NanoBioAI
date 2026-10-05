class FitnessAtlas {
  const FitnessAtlas({
    required this.id,
    required this.asset,
    required this.columns,
    required this.rows,
  });

  final String id;
  final String asset;
  final int columns;
  final int rows;

  factory FitnessAtlas.fromJson(Map<String, Object?> json) => FitnessAtlas(
    id: _text(json['id']),
    asset: _text(json['asset']),
    columns: _integer(json['grid_columns'], fallback: 1),
    rows: _integer(json['grid_rows'], fallback: 1),
  );

  String get assetPath => fitnessCatalogAssetPath(asset);
}

class FitnessIllustration {
  const FitnessIllustration({required this.atlasId, required this.cellIndex});

  final String atlasId;
  final int cellIndex;

  factory FitnessIllustration.fromJson(Map<String, Object?> json) =>
      FitnessIllustration(
        atlasId: _text(json['illustration_atlas_id']),
        cellIndex: _integer(json['illustration_cell_index_1based']),
      );
}

class FitnessEquipment {
  const FitnessEquipment({
    required this.id,
    required this.name,
    required this.description,
    required this.illustration,
    required this.provenance,
    required this.reviewStatus,
  });

  final String id;
  final String name;
  final String description;
  final FitnessIllustration illustration;
  final String provenance;
  final String reviewStatus;

  factory FitnessEquipment.fromJson(Map<String, Object?> json) =>
      FitnessEquipment(
        id: _text(json['id']),
        name: _text(json['name_vi']),
        description: _text(json['description_vi']),
        illustration: FitnessIllustration.fromJson(json),
        provenance: _text(json['provenance']),
        reviewStatus: _text(json['review_status']),
      );
}

class FitnessExercise {
  const FitnessExercise({
    required this.id,
    required this.name,
    required this.venue,
    required this.gearIds,
    required this.level,
    required this.muscleGroups,
    required this.steps,
    required this.safetyNotes,
    required this.bounds,
    required this.illustration,
    required this.videoId,
    required this.videoReviewStatus,
    required this.provenance,
    required this.reviewStatus,
    required this.movementType,
  });

  final String id;
  final String name;
  final String venue;
  final List<String> gearIds;
  final String level;
  final List<String> muscleGroups;
  final List<String> steps;
  final String safetyNotes;
  final Map<String, Object?> bounds;
  final FitnessIllustration illustration;
  final String? videoId;
  final String videoReviewStatus;
  final String provenance;
  final String reviewStatus;
  final String movementType;

  bool get hasApprovedVideo =>
      videoId != null && videoReviewStatus == 'approved_public_embeddable';

  factory FitnessExercise.fromJson(Map<String, Object?> json) =>
      FitnessExercise(
        id: _text(json['id']),
        name: _text(json['name_vi']),
        venue: _text(json['venue']),
        gearIds: _strings(json['gear_ids']),
        level: _text(json['level_candidate']),
        muscleGroups: _strings(json['muscle_groups']),
        steps: _strings(json['instruction_steps_vi']),
        safetyNotes: _text(json['safety_notes_vi']),
        bounds: _objectMap(json['program_bounds_candidate']),
        illustration: FitnessIllustration.fromJson(json),
        videoId: _nullableText(json['youtube_video_id']),
        videoReviewStatus: _text(json['video_review_status']),
        provenance: _text(json['provenance']),
        reviewStatus: _text(json['review_status']),
        movementType: _text(json['movement_type']),
      );
}

class FitnessIngredient {
  const FitnessIngredient({
    required this.id,
    required this.name,
    required this.foodGroup,
    required this.allergens,
    required this.nutrientsPer100g,
    required this.fdcId,
    required this.sourceDescription,
    required this.sourceRelease,
    required this.reviewStatus,
    required this.categoryIcon,
  });

  final String id;
  final String name;
  final String foodGroup;
  final List<String> allergens;
  final Map<String, double> nutrientsPer100g;
  final int fdcId;
  final String sourceDescription;
  final String sourceRelease;
  final String reviewStatus;
  final FitnessIllustration categoryIcon;

  factory FitnessIngredient.fromJson(Map<String, Object?> json) {
    final source = _objectMap(json['source']);
    final nutrients = _objectMap(json['nutrition_per_100g']);
    return FitnessIngredient(
      id: _text(json['id']),
      name: _text(json['name_vi']),
      foodGroup: _text(json['food_group']),
      allergens: _strings(json['allergens']),
      nutrientsPer100g: {
        for (final entry in nutrients.entries)
          if (entry.value is num) entry.key: (entry.value as num).toDouble(),
      },
      fdcId: _integer(source['fdc_id']),
      sourceDescription: _text(json['fdc_description']),
      sourceRelease: _text(source['release_file']),
      reviewStatus: _text(json['review_status']),
      categoryIcon: FitnessIllustration(
        atlasId: _text(json['category_icon_atlas_id']),
        cellIndex: _integer(json['category_icon_cell_index_1based']),
      ),
    );
  }
}

class FitnessRecipeIngredient {
  const FitnessRecipeIngredient({
    required this.ingredientId,
    required this.amountGrams,
  });

  final String ingredientId;
  final double amountGrams;

  factory FitnessRecipeIngredient.fromJson(Map<String, Object?> json) =>
      FitnessRecipeIngredient(
        ingredientId: _text(json['ingredient_id']),
        amountGrams: _number(json['amount_g']),
      );
}

class FitnessRecipe {
  const FitnessRecipe({
    required this.id,
    required this.name,
    required this.mealSlot,
    required this.servings,
    required this.ingredients,
    required this.steps,
    required this.allergens,
    required this.nutrientsPerServing,
    required this.illustration,
    required this.provenance,
    required this.reviewStatus,
  });

  final String id;
  final String name;
  final String mealSlot;
  final int servings;
  final List<FitnessRecipeIngredient> ingredients;
  final List<String> steps;
  final List<String> allergens;
  final Map<String, double> nutrientsPerServing;
  final FitnessIllustration illustration;
  final String provenance;
  final String reviewStatus;

  factory FitnessRecipe.fromJson(Map<String, Object?> json) {
    final nutrition = _objectMap(json['nutrition_per_serving_draft']);
    final ingredientRows = _list(json['ingredients']);
    return FitnessRecipe(
      id: _text(json['id']),
      name: _text(json['name_vi']),
      mealSlot: _text(json['meal_slot']),
      servings: _integer(json['servings'], fallback: 1),
      ingredients: [
        for (final row in ingredientRows)
          FitnessRecipeIngredient.fromJson(_objectMap(row)),
      ],
      steps: _strings(json['instructions_vi']),
      allergens: _strings(json['allergens']),
      nutrientsPerServing: {
        for (final entry in nutrition.entries)
          if (entry.value is num) entry.key: (entry.value as num).toDouble(),
      },
      illustration: FitnessIllustration.fromJson(json),
      provenance: _text(json['provenance']),
      reviewStatus: _text(json['review_status']),
    );
  }
}

class FitnessTrainingCatalog {
  FitnessTrainingCatalog({
    required this.version,
    required this.equipment,
    required this.exercises,
    required this.ingredients,
    required this.recipes,
    required this.atlases,
  }) : equipmentById = {for (final item in equipment) item.id: item},
       exercisesById = {for (final item in exercises) item.id: item},
       ingredientsById = {for (final item in ingredients) item.id: item},
       recipesById = {for (final item in recipes) item.id: item},
       atlasesById = {for (final item in atlases) item.id: item};

  final String version;
  final List<FitnessEquipment> equipment;
  final List<FitnessExercise> exercises;
  final List<FitnessIngredient> ingredients;
  final List<FitnessRecipe> recipes;
  final List<FitnessAtlas> atlases;
  final Map<String, FitnessEquipment> equipmentById;
  final Map<String, FitnessExercise> exercisesById;
  final Map<String, FitnessIngredient> ingredientsById;
  final Map<String, FitnessRecipe> recipesById;
  final Map<String, FitnessAtlas> atlasesById;

  factory FitnessTrainingCatalog.fromJsonSources({
    required Map<String, Object?> exercisesSource,
    required Map<String, Object?> ingredientsSource,
    required Map<String, Object?> recipesSource,
    required Map<String, Object?> atlasesSource,
  }) {
    final atlasRows = _list(atlasesSource['atlases']);
    final equipmentRows = _list(exercisesSource['equipment']);
    final exerciseRows = _list(exercisesSource['exercises']);
    final ingredientRows = _list(ingredientsSource['items']);
    final recipeRows = _list(recipesSource['items']);
    final catalog = FitnessTrainingCatalog(
      version: _text(exercisesSource['version']),
      equipment: [
        for (final row in equipmentRows)
          FitnessEquipment.fromJson(_objectMap(row)),
      ],
      exercises: [
        for (final row in exerciseRows)
          FitnessExercise.fromJson(_objectMap(row)),
      ],
      ingredients: [
        for (final row in ingredientRows)
          FitnessIngredient.fromJson(_objectMap(row)),
      ],
      recipes: [
        for (final row in recipeRows) FitnessRecipe.fromJson(_objectMap(row)),
      ],
      atlases: [
        for (final row in atlasRows) FitnessAtlas.fromJson(_objectMap(row)),
      ],
    );
    catalog.validateIntegrity();
    return catalog;
  }

  void validateIntegrity() {
    _requireUniqueIds(equipment.map((item) => item.id), 'equipment');
    _requireUniqueIds(exercises.map((item) => item.id), 'exercise');
    _requireUniqueIds(ingredients.map((item) => item.id), 'ingredient');
    _requireUniqueIds(recipes.map((item) => item.id), 'recipe');
    if (exercises.length != 24 ||
        equipment.length != 10 ||
        recipes.length != 35 ||
        ingredients.length != 47) {
      throw const FormatException('Fitness pilot catalog count is invalid.');
    }
    for (final exercise in exercises) {
      if (!atlasesById.containsKey(exercise.illustration.atlasId) ||
          exercise.illustration.cellIndex < 1) {
        throw FormatException('Missing illustration for ${exercise.id}.');
      }
      if (exercise.venue != 'gym' && exercise.venue != 'home') {
        throw FormatException('Unsupported venue for ${exercise.id}.');
      }
      if (!exercise.gearIds.every(equipmentById.containsKey)) {
        throw FormatException('Unknown equipment reference in ${exercise.id}.');
      }
    }
    for (final item in equipment) {
      if (!atlasesById.containsKey(item.illustration.atlasId)) {
        throw FormatException('Missing equipment illustration for ${item.id}.');
      }
    }
    for (final recipe in recipes) {
      if (!atlasesById.containsKey(recipe.illustration.atlasId) ||
          recipe.ingredients.isEmpty ||
          !recipe.ingredients.every(
            (item) => ingredientsById.containsKey(item.ingredientId),
          )) {
        throw FormatException('Invalid recipe source for ${recipe.id}.');
      }
    }
    for (final item in ingredients) {
      if (item.fdcId <= 0 ||
          item.sourceRelease.isEmpty ||
          !atlasesById.containsKey(item.categoryIcon.atlasId)) {
        throw FormatException('Missing USDA source for ${item.id}.');
      }
    }
  }

  FitnessAtlas? atlasFor(FitnessIllustration illustration) =>
      atlasesById[illustration.atlasId];

  List<FitnessExercise> eligibleExercises({
    required String venue,
    required Set<String> equipmentIds,
    required Set<String> excludedMovementGroups,
  }) => exercises
      .where((exercise) {
        if (exercise.venue != venue) return false;
        if (venue == 'gym' && !exercise.gearIds.every(equipmentIds.contains)) {
          return false;
        }
        if (excludedMovementGroups.any(
          (group) => _movementMatches(exercise, group),
        )) {
          return false;
        }
        return true;
      })
      .toList(growable: false);

  List<FitnessRecipe> eligibleRecipes({
    required Set<String> excludedAllergens,
    required Set<String> availableFoodGroups,
  }) =>
      excludedAllergens.any(
        (tag) => tag.startsWith('unknown:') || !allergenTags.contains(tag),
      )
      ? const []
      : recipes
            .where((recipe) {
              if (_intersects(recipe.allergens.toSet(), excludedAllergens)) {
                return false;
              }
              for (final item in recipe.ingredients) {
                final ingredient = ingredientsById[item.ingredientId];
                if (ingredient == null ||
                    _intersects(
                      ingredient.allergens.toSet(),
                      excludedAllergens,
                    )) {
                  return false;
                }
                if (availableFoodGroups.isNotEmpty &&
                    !availableFoodGroups.contains(ingredient.foodGroup)) {
                  return false;
                }
              }
              return true;
            })
            .toList(growable: false);

  Set<String> get allergenTags => {
    for (final ingredient in ingredients) ...ingredient.allergens,
    for (final recipe in recipes) ...recipe.allergens,
  };

  Set<String> get foodGroups => {
    for (final ingredient in ingredients) ingredient.foodGroup,
  };

  static bool _movementMatches(FitnessExercise exercise, String group) {
    final text = '${exercise.muscleGroups.join(' ')} ${exercise.name}'
        .toLowerCase();
    switch (group) {
      case 'upper_body':
        return _containsAny(text, const ['ngực', 'vai', 'tay', 'cánh tay']);
      case 'back':
        return _containsAny(text, const ['lưng', 'xô']);
      case 'lower_body':
        return _containsAny(text, const [
          'chân',
          'đùi',
          'mông',
          'gối',
          'bắp chân',
        ]);
      case 'core':
        return _containsAny(text, const ['bụng', 'core', 'thân giữa']);
      case 'cardio':
        return exercise.movementType == 'cardio';
      default:
        return true;
    }
  }

  static bool _containsAny(String text, List<String> terms) =>
      terms.any(text.contains);

  static bool _intersects(Set<String> left, Set<String> right) =>
      left.any(right.contains);

  static void _requireUniqueIds(Iterable<String> ids, String kind) {
    final values = ids.toList(growable: false);
    if (values.toSet().length != values.length ||
        values.any((id) => id.trim().isEmpty)) {
      throw FormatException('Fitness $kind IDs must be unique and non-empty.');
    }
  }
}

String fitnessCatalogAssetPath(String relativePath) =>
    'assets/data/fitness_training/$relativePath';

Map<String, Object?> _objectMap(Object? value) {
  if (value is Map) return Map<String, Object?>.from(value);
  return const {};
}

List<Object?> _list(Object? value) =>
    value is List ? List<Object?>.from(value) : const [];

List<String> _strings(Object? value) => _list(value)
    .whereType<String>()
    .map((item) => item.trim())
    .where((item) => item.isNotEmpty)
    .toList(growable: false);

String _text(Object? value) => value?.toString().trim() ?? '';

String? _nullableText(Object? value) {
  final text = _text(value);
  return text.isEmpty ? null : text;
}

int _integer(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double _number(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

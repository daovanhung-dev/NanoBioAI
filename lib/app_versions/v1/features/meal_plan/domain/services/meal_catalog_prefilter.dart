import 'package:flutter/foundation.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/data/models/meal_plan_ai_normalizer.dart';
import 'package:nano_app/app_versions/v1/features/meal_plan/domain/services/meal_candidate_selector.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_profile_entity.dart';
import 'package:nano_app/core/storage/localdb/models/ai_catalog_models.dart';

enum MealSchedulePeriod { morning, midday, evening }

enum MealScheduleRole { main, side }

@immutable
class MealCandidateClassification {
  final String code;
  final String name;
  final String mealType;
  final MealSchedulePeriod period;
  final MealScheduleRole role;
  final bool isGeneralWellnessOnly;

  const MealCandidateClassification({
    required this.code,
    required this.name,
    required this.mealType,
    required this.period,
    required this.role,
    this.isGeneralWellnessOnly = false,
  });
}

@immutable
class MealCatalogPrefilterResult {
  final List<MealCatalogItemModel> meals;
  final List<MealCandidateClassification> candidates;
  final Map<String, Set<String>> eligibleCodesByType;
  final Map<String, int> eligibleCountsByType;
  final List<MealCatalogClassificationIssue> classificationIssues;
  final int minimumCandidatesPerPeriod;
  final bool usedGeneralWellnessFallback;

  MealCatalogPrefilterResult({
    required Iterable<MealCatalogItemModel> meals,
    required Iterable<MealCandidateClassification> candidates,
    required Map<String, Set<String>> eligibleCodesByType,
    required Map<String, int> eligibleCountsByType,
    Iterable<MealCatalogClassificationIssue> classificationIssues = const [],
    this.minimumCandidatesPerPeriod = 0,
    this.usedGeneralWellnessFallback = false,
  }) : meals = List.unmodifiable(meals),
       candidates = List.unmodifiable(candidates),
       eligibleCodesByType = Map.unmodifiable({
         for (final entry in eligibleCodesByType.entries)
           entry.key: Set<String>.unmodifiable(entry.value),
       }),
       eligibleCountsByType = Map.unmodifiable(eligibleCountsByType),
       classificationIssues = List.unmodifiable(classificationIssues);

  bool hasEnoughForDays(int days) =>
      eligibleCountsByType.values.every((count) => count >= days);

  bool get hasCandidatesForEverySlot =>
      eligibleCountsByType.values.every((count) => count > 0);

  Map<MealSchedulePeriod, int> get eligibleCountsByPeriod => Map.unmodifiable({
    for (final period in MealSchedulePeriod.values)
      period: candidates.where((meal) => meal.period == period).length,
  });

  Map<MealSchedulePeriod, int> get shortfallsByPeriod => Map.unmodifiable({
    for (final entry in eligibleCountsByPeriod.entries)
      if (entry.value < minimumCandidatesPerPeriod)
        entry.key: minimumCandidatesPerPeriod - entry.value,
  });

  bool get hasMinimumCandidatesPerPeriod => shortfallsByPeriod.isEmpty;
}

@immutable
class MealCatalogClassificationIssue {
  final String code;
  final String reason;

  const MealCatalogClassificationIssue({
    required this.code,
    required this.reason,
  });
}

class MealCatalogClassificationException implements Exception {
  final List<MealCatalogClassificationIssue> issues;

  MealCatalogClassificationException(
    Iterable<MealCatalogClassificationIssue> issues,
  ) : issues = List.unmodifiable(issues);

  String get userMessage =>
      'Danh mục món ăn có ${issues.length} món đủ điều kiện chưa được phân loại rõ. Nabi đã dừng trước khi tạo lịch. Cần kiểm tra nhãn buổi và loại bữa rồi thử lại.';

  @override
  String toString() => userMessage;
}

/// Classifies and filters the local schedule catalog before any AI request.
///
/// The rules are intentionally finite and conservative. A dish whose meal
/// slot cannot be inferred from an existing slot label or explicit dish-name
/// cues is excluded instead of being made available to every AI slot.
class MealCatalogPrefilter {
  const MealCatalogPrefilter({this.selector = const MealCandidateSelector()});

  static const minimumCandidatesPerPeriod = 50;

  final MealCandidateSelector selector;

  static const _periods = MealSchedulePeriod.values;

  static const _slotTypes = {
    'breakfast',
    'morning_snack',
    'lunch',
    'afternoon_snack',
    'dinner',
  };

  MealCatalogPrefilterResult filter({
    required Iterable<MealCatalogItemModel> catalog,
    required NutritionProfileEntity profile,
    Set<String> conditions = const {},
    Set<String> goals = const {},
    Set<String> additionalAllergies = const {},
    bool unparsedAllergyDetails = false,
    int minimumCandidatesPerPeriod =
        MealCatalogPrefilter.minimumCandidatesPerPeriod,
  }) {
    final catalogMeals = catalog.toList(growable: false);
    final classificationIssues = validateClassifications(catalogMeals);
    final classifiedByType = <String, List<MealCatalogItemModel>>{
      for (final slot in MealPlanAiNormalizer.mealSlots) slot.type: [],
    };
    final classificationByCode = <String, MealCandidateClassification>{};

    for (final meal in catalogMeals) {
      final classification = classify(meal);
      if (classification == null) continue;
      final code = meal.code.trim().toLowerCase();
      if (code.isEmpty || classificationByCode.containsKey(code)) continue;
      classificationByCode[code] = classification;
      classifiedByType[classification.mealType]!.add(meal);
    }

    final personalizedByType = <String, List<MealCatalogItemModel>>{};
    for (final slot in MealPlanAiNormalizer.mealSlots) {
      personalizedByType[slot.type] = selector.eligibleMeals(
        catalog: classifiedByType[slot.type]!,
        profile: profile,
        mealType: slot.type,
        conditions: conditions,
        goals: goals,
        additionalAllergies: additionalAllergies,
        unparsedAllergyDetails: unparsedAllergyDetails,
        selectionPolicy:
            MealCandidateSelectionPolicy.personalizedWellnessSchedule,
      );
    }

    final personalizedUniqueByType = _uniqueMealsByType(
      personalizedByType,
      classificationByCode,
    );
    final personalizedCountsByPeriod = _countByPeriod(
      personalizedUniqueByType,
      classificationByCode,
    );
    final fallbackPeriods = <MealSchedulePeriod>{
      for (final period in _periods)
        if ((personalizedCountsByPeriod[period] ?? 0) <
            minimumCandidatesPerPeriod)
          period,
    };
    final selectedByType = <String, List<MealCatalogItemModel>>{};
    for (final slot in MealPlanAiNormalizer.mealSlots) {
      final period = _periodForSlot(slot.type);
      if (!fallbackPeriods.contains(period)) {
        selectedByType[slot.type] = personalizedByType[slot.type]!;
        continue;
      }
      selectedByType[slot.type] = selector.eligibleMeals(
        catalog: classifiedByType[slot.type]!,
        profile: profile,
        mealType: slot.type,
        conditions: conditions,
        goals: goals,
        additionalAllergies: additionalAllergies,
        unparsedAllergyDetails: unparsedAllergyDetails,
        selectionPolicy: MealCandidateSelectionPolicy.wellnessSchedule,
      );
    }

    // Keep one stable representative for each normalized name across all
    // periods so a dish cannot inflate the 50-item threshold by duplication.
    final selectedUniqueByType = _uniqueMealsByType(
      selectedByType,
      classificationByCode,
    );
    final selectedCodes = <String>{
      for (final meals in selectedUniqueByType.values)
        for (final meal in meals) meal.code.trim().toLowerCase(),
    };
    final personalizedCodes = <String>{
      for (final meals in personalizedUniqueByType.values)
        for (final meal in meals) meal.code.trim().toLowerCase(),
    };
    final sortedCodes = selectedCodes.toList()..sort();
    final candidates = <MealCandidateClassification>[];
    final filteredMeals = <MealCatalogItemModel>[];
    final retainedCodesByType = <String, Set<String>>{
      for (final slot in MealPlanAiNormalizer.mealSlots) slot.type: {},
    };
    final mealsByCode = {
      for (final meals in selectedUniqueByType.values)
        for (final meal in meals) meal.code.trim().toLowerCase(): meal,
    };
    for (final code in sortedCodes) {
      final meal = mealsByCode[code]!;
      final classification = classificationByCode[code]!;
      candidates.add(
        MealCandidateClassification(
          code: classification.code,
          name: classification.name,
          mealType: classification.mealType,
          period: classification.period,
          role: classification.role,
          isGeneralWellnessOnly:
              !personalizedCodes.contains(code) || !meal.isPlanEligible,
        ),
      );
      filteredMeals.add(meal);
      retainedCodesByType[classification.mealType]!.add(code);
    }

    return MealCatalogPrefilterResult(
      meals: filteredMeals,
      candidates: candidates,
      eligibleCodesByType: retainedCodesByType,
      eligibleCountsByType: {
        for (final entry in retainedCodesByType.entries)
          entry.key: entry.value.length,
      },
      classificationIssues: classificationIssues,
      minimumCandidatesPerPeriod: minimumCandidatesPerPeriod,
      usedGeneralWellnessFallback: candidates.any(
        (candidate) => candidate.isGeneralWellnessOnly,
      ),
    );
  }

  Map<String, List<MealCatalogItemModel>> _uniqueMealsByType(
    Map<String, List<MealCatalogItemModel>> mealsByType,
    Map<String, MealCandidateClassification> classificationByCode,
  ) {
    final mealsByCode = <String, MealCatalogItemModel>{};
    for (final meals in mealsByType.values) {
      for (final meal in meals) {
        final code = meal.code.trim().toLowerCase();
        if (code.isNotEmpty) mealsByCode.putIfAbsent(code, () => meal);
      }
    }
    final retained = <String, List<MealCatalogItemModel>>{
      for (final slot in MealPlanAiNormalizer.mealSlots) slot.type: [],
    };
    final usedNames = <String>{};
    final codes = mealsByCode.keys.toList()..sort();
    for (final code in codes) {
      final meal = mealsByCode[code]!;
      final classification = classificationByCode[code];
      if (classification == null) continue;
      final name = _normalize(meal.mealName);
      if (name.isEmpty || !usedNames.add(name)) continue;
      retained[classification.mealType]!.add(meal);
    }
    return retained;
  }

  Map<MealSchedulePeriod, int> _countByPeriod(
    Map<String, List<MealCatalogItemModel>> mealsByType,
    Map<String, MealCandidateClassification> classificationByCode,
  ) {
    final counts = {for (final period in _periods) period: 0};
    for (final meals in mealsByType.values) {
      for (final meal in meals) {
        final period =
            classificationByCode[meal.code.trim().toLowerCase()]?.period;
        if (period != null) counts[period] = counts[period]! + 1;
      }
    }
    return counts;
  }

  MealSchedulePeriod _periodForSlot(String slotType) => switch (slotType) {
    'breakfast' || 'morning_snack' => MealSchedulePeriod.morning,
    'lunch' => MealSchedulePeriod.midday,
    'afternoon_snack' || 'dinner' => MealSchedulePeriod.evening,
    _ => throw ArgumentError.value(slotType, 'slotType'),
  };

  /// Checks rows eligible for a general wellness schedule before filtering.
  /// Explicit supported labels are authoritative; an unclassified row may
  /// use the local name rules and is dropped if those rules remain ambiguous.
  List<MealCatalogClassificationIssue> validateClassifications(
    Iterable<MealCatalogItemModel> catalog,
  ) {
    final issues = <MealCatalogClassificationIssue>[];
    final seenCodes = <String>{};
    for (final meal in catalog) {
      if (!meal.isSelectableForGeneralWellnessSchedule) continue;
      final code = meal.code.trim();
      final normalizedType = normalizeMealCatalogType(meal.mealType);
      if (code.isEmpty) {
        issues.add(
          const MealCatalogClassificationIssue(
            code: '<missing>',
            reason: 'missing_code',
          ),
        );
        continue;
      }
      if (!seenCodes.add(code.toLowerCase())) {
        issues.add(
          MealCatalogClassificationIssue(code: code, reason: 'duplicate_code'),
        );
        continue;
      }
      if (meal.mealName.trim().isEmpty) {
        issues.add(
          MealCatalogClassificationIssue(code: code, reason: 'missing_name'),
        );
      } else if (normalizedType == 'unclassified') {
        // `unclassified` is the explicit source status of the guarded local
        // candidate bundle. Runtime inference does not rewrite that source
        // status; ambiguous rows are simply omitted by `filter`.
        continue;
      } else if (!_slotTypes.contains(normalizedType)) {
        issues.add(
          MealCatalogClassificationIssue(
            code: code,
            reason: 'unsupported_meal_type',
          ),
        );
      }
    }
    return List.unmodifiable(issues);
  }

  MealCandidateClassification? classify(MealCatalogItemModel meal) {
    final code = meal.code.trim();
    final name = meal.mealName.trim();
    if (code.isEmpty || name.isEmpty) return null;

    final normalizedType = normalizeMealCatalogType(meal.mealType);
    final slotType = _slotTypes.contains(normalizedType)
        ? normalizedType
        : normalizedType == 'unclassified'
        ? _inferSlotType(meal)
        : null;
    if (slotType == null) return null;

    final period = switch (slotType) {
      'breakfast' || 'morning_snack' => MealSchedulePeriod.morning,
      'lunch' => MealSchedulePeriod.midday,
      'afternoon_snack' || 'dinner' => MealSchedulePeriod.evening,
      _ => null,
    };
    if (period == null) return null;

    return MealCandidateClassification(
      code: code,
      name: name,
      mealType: slotType,
      period: period,
      role: slotType.endsWith('_snack')
          ? MealScheduleRole.side
          : MealScheduleRole.main,
    );
  }

  String? _inferSlotType(MealCatalogItemModel meal) {
    final name = _normalize(meal.mealName);
    final ingredients = meal.ingredients.map(_normalize).join(' ');
    if (name.isEmpty) return null;

    if (_startsWithAny(name, const [
      'sinh to',
      'nuoc ep',
      'sua chua',
      'sua hat',
      'nuoc hat',
      'ngu coc',
      'yaourt',
      'salad trai cay',
      'trai cay',
      'hoa qua',
    ])) {
      return 'morning_snack';
    }
    if (_startsWithAny(name, const [
      'che',
      'tra',
      'kem',
      'thach',
      'rau cau',
      'pudding',
      'banh flan',
      'banh ngot',
      'banh quy',
      'banh bong lan',
      'banh da lon',
      'banh tro',
      'banh cam',
      'mut',
    ])) {
      return 'afternoon_snack';
    }
    if (_startsWithAny(name, const [
      'xoi',
      'chao',
      'pho',
      'bun',
      'mi',
      'mien',
      'hu tieu',
      'banh mi',
      'banh cuon',
      'banh uot',
      'banh bao',
      'banh gio',
      'banh canh',
      'banh hoi',
      'banh da nuoc',
    ])) {
      return 'breakfast';
    }
    if (_startsWithAny(name, const [
      'com',
      'banh xeo',
      'banh khoai',
      'banh khot',
      'banh beo',
      'banh bot loc',
      'banh nam',
      'banh trang cuon',
      'nem ran',
      'cao lau',
      'salad',
      'goi',
    ])) {
      return 'lunch';
    }

    final searchable = ' $name $ingredients ';
    if (_startsWithAny(name, const [
          'canh',
          'soup',
          'thit',
          'ca',
          'tom',
          'muc',
          'luon',
          'vit',
          'ga',
          'bo',
          'heo',
          'suon',
          'dau hu',
          'nam',
          'rau',
          'cha',
        ]) ||
        _containsAny(searchable, const [
          ' xao ',
          ' kho ',
          ' hap ',
          ' nuong ',
          ' chien ',
          ' rang ',
          ' ham ',
          ' om ',
          ' rim ',
          ' sot ',
          ' luoc ',
          ' ap chao ',
        ])) {
      return 'dinner';
    }
    return null;
  }

  bool _startsWithAny(String value, List<String> prefixes) => prefixes.any(
    (prefix) => value == prefix.trim() || value.startsWith('$prefix '),
  );

  bool _containsAny(String value, List<String> values) =>
      values.any(value.contains);

  String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd')
      .replaceAll('_', ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}

import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as image_codec;
import 'package:nano_app/app_versions/v1/services/ai/ai_text_client.dart';
import 'package:nano_app/core/network/backend_ai_text_client.dart';

import '../../application/food_scan_prompts.dart';
import '../../domain/entities/food_scan_models.dart';
import '../../domain/food_scan_exception.dart';

const foodScanVisionMaxImageDimension = 1024;

class FoodVisionAnalysis {
  final bool isFoodImage;
  final String inputType;
  final String imageQuality;
  final String imageQualityReason;
  final double confidence;
  final List<FoodScanItem> items;
  final List<int> nutritionIncompleteIndexes;
  final List<String> assumptions;
  final List<String> warnings;

  const FoodVisionAnalysis({
    required this.isFoodImage,
    required this.inputType,
    required this.imageQuality,
    required this.imageQualityReason,
    required this.confidence,
    required this.items,
    this.nutritionIncompleteIndexes = const [],
    required this.assumptions,
    required this.warnings,
  });
}

class FoodScanAiDatasource {
  final AiTextClient? clientOverride;
  final String? modelOverride;

  const FoodScanAiDatasource({this.clientOverride, this.modelOverride});

  Future<FoodVisionAnalysis> analyzeImage(String imagePath) async {
    final client = _client;
    final file = File(imagePath);
    if (!await file.exists()) {
      throw const FoodScanException(
        code: 'IMAGE_NOT_FOUND',
        userMessage: 'Ảnh món ăn không còn trên thiết bị. Bạn chụp lại nhé.',
      );
    }

    try {
      final imageBytes = _prepareVisionImage(await file.readAsBytes());
      final text = await client.generateText(
        model: _model(),
        messages: [
          AiMessage.user(
            FoodScanPrompts.vision(),
            images: [
              AiImageAttachment(bytes: imageBytes, mimeType: 'image/jpeg'),
            ],
          ),
        ],
        generationConfig: const AiGenerationConfig(
          maxOutputTokens: 192,
          temperature: 0.15,
          topP: 0.8,
          responseFormat: AiResponseFormat.json,
        ),
      );
      var analysis = _parseVision(text);
      if (analysis.isFoodImage &&
          analysis.nutritionIncompleteIndexes.isNotEmpty) {
        final missingIndexes = analysis.nutritionIncompleteIndexes;
        final missingItems = missingIndexes
            .map((index) => analysis.items[index])
            .toList(growable: false);
        final nutritionText = await client.generateText(
          model: _model(),
          messages: [
            AiMessage.user(
              FoodScanPrompts.visionNutritionFallback(missingItems),
            ),
          ],
          generationConfig: const AiGenerationConfig(
            maxOutputTokens: 384,
            temperature: 0.1,
            topP: 0.8,
            responseFormat: AiResponseFormat.json,
          ),
        );
        try {
          analysis = _mergeNutritionFallback(
            analysis,
            nutritionText,
            targetIndexes: missingIndexes,
          );
        } on FormatException {
          // Keep the vision result; FoodScanService will reject it if the
          // required energy estimate is still unavailable.
        }
      }
      return analysis;
    } on FoodScanException {
      rethrow;
    } on AiInferenceException catch (error) {
      throw _mapInferenceError(error);
    } catch (error) {
      throw FoodScanException(
        code: 'AI_VISION_FAILED',
        userMessage:
            'Dịch vụ AI chưa thể phân tích ảnh món ăn lúc này. Bạn kiểm tra kết nối rồi thử lại nhé.',
        cause: error,
      );
    }
  }

  Uint8List _prepareVisionImage(Uint8List sourceBytes) {
    final decoded = image_codec.decodeImage(sourceBytes);
    if (decoded == null) {
      throw const FormatException('Food Scan image could not be decoded.');
    }
    final oriented = image_codec.bakeOrientation(decoded);
    if (oriented.width <= foodScanVisionMaxImageDimension &&
        oriented.height <= foodScanVisionMaxImageDimension) {
      return sourceBytes;
    }

    final resized = oriented.width >= oriented.height
        ? image_codec.copyResize(
            oriented,
            width: foodScanVisionMaxImageDimension,
          )
        : image_codec.copyResize(
            oriented,
            height: foodScanVisionMaxImageDimension,
          );
    resized.exif.clear();
    return Uint8List.fromList(image_codec.encodeJpg(resized, quality: 85));
  }

  Future<FoodHealthEvaluation> evaluateHealth({
    required Map<String, Object?> healthContext,
    required List<FoodScanItem> items,
    required NutritionEstimate totalNutrition,
    required List<String> deterministicWarnings,
  }) async {
    if (_hasNoPersonalHealthContext(healthContext)) {
      return FoodHealthEvaluation.insufficient(
        summary:
            'Bạn chưa có đủ hồ sơ sức khỏe để Nabi cá nhân hóa đánh giá món ăn.',
        allergyWarnings: deterministicWarnings,
      );
    }

    try {
      final text = await _client.generateText(
        model: _model(),
        messages: [
          AiMessage.user(
            FoodScanPrompts.health(
              healthContext: healthContext,
              items: items,
              totalNutrition: totalNutrition,
              deterministicWarnings: deterministicWarnings,
            ),
          ),
        ],
        generationConfig: const AiGenerationConfig(
          temperature: 0.1,
          topP: 0.75,
          responseFormat: AiResponseFormat.json,
        ),
      );
      final decoded = _decodeObject(text);
      final evaluation = FoodHealthEvaluation.fromJson(decoded);
      final warnings = <String>{
        ...deterministicWarnings,
        ...evaluation.allergyWarnings,
      }.toList(growable: false);
      return FoodHealthEvaluation(
        status: evaluation.status,
        suitabilityScore: evaluation.suitabilityScore,
        summary: evaluation.summary,
        conditionReviews: evaluation.conditionReviews,
        allergyWarnings: warnings,
        suggestions: evaluation.suggestions,
        dailyGoalSummary: evaluation.dailyGoalSummary,
        dailyGoalNotes: evaluation.dailyGoalNotes,
        assumptions: evaluation.assumptions,
        missingHealthData: evaluation.missingHealthData,
        confidence: evaluation.confidence,
      );
    } on AiInferenceException catch (error) {
      throw _mapInferenceError(error, healthEvaluation: true);
    } catch (error) {
      throw FoodScanException(
        code: 'HEALTH_EVALUATION_FAILED',
        userMessage:
            'Dinh dưỡng đã phân tích xong nhưng Nabi chưa đánh giá được mức độ phù hợp với sức khỏe. Bạn có thể thử đánh giá lại.',
        cause: error,
      );
    }
  }

  AiTextClient get _client {
    final override = clientOverride;
    if (override != null) return override;
    return const BackendAiTextClient();
  }

  String _model() {
    final model = modelOverride?.trim();
    if (model != null && model.isNotEmpty) return model;
    return BackendAiTextClient.modelId;
  }

  FoodVisionAnalysis _parseVision(String source) {
    final json = _decodeObject(source);
    final isFood = _readBool(json['is_food_image'], fallback: false);
    final inputType = _readString(json['input_type']) ?? 'unclear';
    final foods = json['foods'];
    final items = <FoodScanItem>[];
    final nutritionIncompleteIndexes = <int>[];
    if (foods is List) {
      for (final raw in foods.whereType<Map>()) {
        final row = raw.map((key, value) => MapEntry(key.toString(), value));
        final nutrition = _nutritionMap(row);
        final item = FoodScanItem.fromJson({
          ...row,
          'id': _uuidV4(),
          'normalized_name': row['normalized_hint'] ?? row['normalized_name'],
          // Preserve an estimate returned under either accepted nutrition key.
          'nutrition': nutrition,
          'nutrition_source': 'ai_fallback',
        });
        if (item.name.trim().isEmpty) continue;
        if (!_hasCompleteCoreNutrition(nutrition)) {
          nutritionIncompleteIndexes.add(items.length);
        }
        items.add(item);
      }
    }

    if (!isFood) {
      return FoodVisionAnalysis(
        isFoodImage: false,
        inputType: inputType,
        imageQuality: _readString(json['image_quality']) ?? 'unknown',
        imageQualityReason: _readString(json['image_quality_reason']) ?? '',
        confidence: (_readDouble(json['analysis_confidence']) ?? 0)
            .clamp(0, 1)
            .toDouble(),
        items: const [],
        assumptions: _readStrings(json['assumptions']),
        warnings: _readStrings(json['warnings']),
      );
    }

    if (items.isEmpty) {
      throw const FoodScanException(
        code: 'EMPTY_FOOD_RESULT',
        userMessage:
            'Nabi thấy đây là ảnh đồ ăn nhưng chưa nhận diện đủ rõ. Bạn thử chụp gần hơn và đủ sáng nhé.',
      );
    }

    return FoodVisionAnalysis(
      isFoodImage: true,
      inputType: inputType,
      imageQuality: _readString(json['image_quality']) ?? 'unknown',
      imageQualityReason: _readString(json['image_quality_reason']) ?? '',
      confidence: (_readDouble(json['analysis_confidence']) ?? 0)
          .clamp(0, 1)
          .toDouble(),
      items: items.take(20).toList(growable: false),
      nutritionIncompleteIndexes: nutritionIncompleteIndexes
          .where((index) => index < 20)
          .toList(growable: false),
      assumptions: _readStrings(json['assumptions']),
      warnings: _readStrings(json['warnings']),
    );
  }

  FoodVisionAnalysis _mergeNutritionFallback(
    FoodVisionAnalysis analysis,
    String source, {
    required List<int> targetIndexes,
  }) {
    final json = _decodeObject(source);
    final foods = json['foods'];
    if (foods is! List) {
      throw const FormatException('Nutrition response must contain foods.');
    }

    final items = analysis.items.toList(growable: false);
    final remaining = <int>{...targetIndexes};
    for (final raw in foods.whereType<Map>()) {
      final row = raw.map((key, value) => MapEntry(key.toString(), value));
      final outputIndex = _readDouble(row['index']);
      if (outputIndex == null || outputIndex != outputIndex.roundToDouble()) {
        continue;
      }
      final responseIndex = outputIndex.toInt();
      if (responseIndex < 0 || responseIndex >= targetIndexes.length) continue;

      final itemIndex = targetIndexes[responseIndex];
      if (itemIndex < 0 || itemIndex >= items.length) continue;
      final calories = _readDouble(row['calories_kcal']);
      final protein = _readDouble(row['protein_g']);
      final carbohydrates = _readDouble(row['carbohydrates_g']);
      final fat = _readDouble(row['fat_g']);
      if (calories == null ||
          !calories.isFinite ||
          calories <= 0 ||
          protein == null ||
          !protein.isFinite ||
          protein < 0 ||
          carbohydrates == null ||
          !carbohydrates.isFinite ||
          carbohydrates < 0 ||
          fat == null ||
          !fat.isFinite ||
          fat < 0) {
        continue;
      }

      final item = items[itemIndex];
      final mergedNutrition = NutritionEstimate.fromJson({
        ...item.nutrition.toJson(),
        'calories_kcal': calories,
        'protein_g': protein,
        'carbohydrates_g': carbohydrates,
        'fat_g': fat,
      }).sanitized();
      items[itemIndex] = item.copyWith(nutrition: mergedNutrition);
      remaining.remove(itemIndex);
    }

    return FoodVisionAnalysis(
      isFoodImage: analysis.isFoodImage,
      inputType: analysis.inputType,
      imageQuality: analysis.imageQuality,
      imageQualityReason: analysis.imageQualityReason,
      confidence: analysis.confidence,
      items: items,
      nutritionIncompleteIndexes: remaining.toList(growable: false),
      assumptions: analysis.assumptions,
      warnings: analysis.warnings,
    );
  }

  Map<String, Object?> _nutritionMap(Map<String, Object?> row) {
    final nested = row['fallback_nutrition'] ?? row['nutrition'];
    if (nested is Map) {
      return nested.map((key, value) => MapEntry(key.toString(), value));
    }

    const coreKeys = ['calories_kcal', 'protein_g', 'carbohydrates_g', 'fat_g'];
    return {
      for (final key in coreKeys)
        if (row.containsKey(key)) key: row[key],
    };
  }

  bool _hasCompleteCoreNutrition(Map<String, Object?> nutrition) {
    final calories = _readDouble(nutrition['calories_kcal']);
    final protein = _readDouble(nutrition['protein_g']);
    final carbohydrates = _readDouble(nutrition['carbohydrates_g']);
    final fat = _readDouble(nutrition['fat_g']);
    return calories != null &&
        calories.isFinite &&
        calories > 0 &&
        protein != null &&
        protein.isFinite &&
        protein >= 0 &&
        carbohydrates != null &&
        carbohydrates.isFinite &&
        carbohydrates >= 0 &&
        fat != null &&
        fat.isFinite &&
        fat >= 0;
  }

  Map<String, Object?> _decodeObject(String source) {
    var cleaned = source
        .replaceAll('```json', '')
        .replaceAll('```JSON', '')
        .replaceAll('```', '')
        .trim();
    cleaned = cleaned
        .replaceAll(RegExp(r',\s*}'), '}')
        .replaceAll(RegExp(r',\s*]'), ']');
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw const FormatException('AI response must contain one JSON object.');
    }
    final decoded = jsonDecode(cleaned.substring(start, end + 1));
    if (decoded is! Map) {
      throw const FormatException('AI response root must be an object.');
    }
    return decoded.map((key, value) => MapEntry(key.toString(), value));
  }

  FoodScanException _mapInferenceError(
    AiInferenceException error, {
    bool healthEvaluation = false,
  }) {
    if (error.status == 'unsupported_platform') {
      return FoodScanException(
        code: 'AI_UNAVAILABLE_ON_PLATFORM',
        userMessage: error.message,
        cause: error,
      );
    }
    if (error.isAuthenticationFailure) {
      return FoodScanException(
        code: 'AI_AUTHENTICATION',
        userMessage: error.message,
        cause: error,
      );
    }
    if (error.isTransient || error.isNetworkFailure) {
      return FoodScanException(
        code: 'AI_TEMPORARILY_UNAVAILABLE',
        userMessage: healthEvaluation
            ? 'Dịch vụ AI chưa đánh giá được sức khỏe lúc này. Phần dinh dưỡng vẫn được giữ để bạn thử lại.'
            : 'Dịch vụ AI tạm thời chưa khả dụng. Bạn kiểm tra mạng rồi thử lại nhé.',
        cause: error,
      );
    }
    return FoodScanException(
      code: 'AI_REQUEST_FAILED',
      userMessage: healthEvaluation
          ? 'Nabi chưa thể đánh giá mức độ phù hợp với sức khỏe lúc này.'
          : 'Nabi chưa thể phân tích món ăn lúc này. Bạn thử lại nhé.',
      cause: error,
    );
  }

  bool _hasNoPersonalHealthContext(Map<String, Object?> value) {
    const useful = <String>[
      'health_profile',
      'lifestyle_habits',
      'nutrition_profile',
      'health_goals',
      'health_conditions',
      'food_allergies',
      'medical_treatments',
      'health_symptoms',
      'medication_records',
      'food_restrictions',
      'lab_results',
      'nutrition_goals',
    ];
    for (final key in useful) {
      final item = value[key];
      if (item is Map && item.isNotEmpty) return false;
      if (item is List && item.isNotEmpty) return false;
    }
    return true;
  }
}

String _uuidV4() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int value) => value.toRadixString(16).padLeft(2, '0');
  final all = bytes.map(hex).join();
  return '${all.substring(0, 8)}-'
      '${all.substring(8, 12)}-'
      '${all.substring(12, 16)}-'
      '${all.substring(16, 20)}-'
      '${all.substring(20)}';
}

String? _readString(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

double? _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '');
}

bool _readBool(Object? value, {required bool fallback}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == '1') return true;
  if (text == 'false' || text == '0') return false;
  return fallback;
}

List<String> _readStrings(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .take(30)
      .toList(growable: false);
}

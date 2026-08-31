import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:nano_app/app_versions/v1/services/ai/gemini_rest_client.dart';
import 'package:nano_app/app_versions/v1/services/ai/nabi_ai_backend_client.dart';
import 'package:nano_app/core/config/app_env.dart';

import '../../application/food_scan_prompts.dart';
import '../../domain/entities/food_scan_models.dart';
import '../../domain/food_scan_exception.dart';

class FoodVisionAnalysis {
  final bool isFoodImage;
  final String inputType;
  final String imageQuality;
  final String imageQualityReason;
  final double confidence;
  final List<FoodScanItem> items;
  final List<String> assumptions;
  final List<String> warnings;

  const FoodVisionAnalysis({
    required this.isFoodImage,
    required this.inputType,
    required this.imageQuality,
    required this.imageQualityReason,
    required this.confidence,
    required this.items,
    required this.assumptions,
    required this.warnings,
  });
}

class FoodScanAiDatasource {
  final AiTextClient? clientOverride;
  final String? modelOverride;

  const FoodScanAiDatasource({this.clientOverride, this.modelOverride});

  Future<FoodVisionAnalysis> analyzeImage(String imagePath) async {
    final client = _client(operation: 'vision');
    final file = File(imagePath);
    if (!await file.exists()) {
      throw const FoodScanException(
        code: 'IMAGE_NOT_FOUND',
        userMessage: 'Ảnh món ăn không còn trên thiết bị. Bạn chụp lại nhé.',
      );
    }

    try {
      final data = base64Encode(await file.readAsBytes());
      final text = await client.generateText(
        model: _model(),
        contents: [
          GeminiContent.userWithInlineData(
            text: FoodScanPrompts.vision(),
            mimeType: 'image/jpeg',
            base64Data: data,
          ),
        ],
        generationConfig: const GeminiGenerationConfig(
          candidateCount: 1,
          maxOutputTokens: 8192,
          temperature: 0.15,
          topP: 0.8,
          responseMimeType: 'application/json',
        ),
      );
      return _parseVision(text);
    } on FoodScanException {
      rethrow;
    } on GeminiApiException catch (error) {
      throw _mapGeminiError(error);
    } catch (error) {
      throw FoodScanException(
        code: 'AI_VISION_FAILED',
        userMessage:
            'Nabi chưa thể phân tích ảnh món ăn lúc này. Bạn kiểm tra mạng rồi thử lại nhé.',
        cause: error,
      );
    }
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
      final text = await _client(operation: 'health').generateText(
        model: _model(),
        contents: [
          GeminiContent.user(
            FoodScanPrompts.health(
              healthContext: healthContext,
              items: items,
              totalNutrition: totalNutrition,
              deterministicWarnings: deterministicWarnings,
            ),
          ),
        ],
        generationConfig: const GeminiGenerationConfig(
          candidateCount: 1,
          maxOutputTokens: 8192,
          temperature: 0.1,
          topP: 0.75,
          responseMimeType: 'application/json',
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
    } on GeminiApiException catch (error) {
      throw _mapGeminiError(error, healthEvaluation: true);
    } catch (error) {
      throw FoodScanException(
        code: 'HEALTH_EVALUATION_FAILED',
        userMessage:
            'Dinh dưỡng đã phân tích xong nhưng Nabi chưa đánh giá được mức độ phù hợp với sức khỏe. Bạn có thể thử đánh giá lại.',
        cause: error,
      );
    }
  }

  AiTextClient _client({required String operation}) {
    final override = clientOverride;
    if (override != null) return override;
    return NabiAiBackendClient(
      functionName: 'food-scan-analyze',
      operation: operation,
    );
  }

  String _model() {
    final model = modelOverride?.trim();
    if (model != null && model.isNotEmpty) return model;
    return AppEnv.maybeString('GEMINI_MODEL') ?? 'gemini-2.5-flash';
  }

  FoodVisionAnalysis _parseVision(String source) {
    final json = _decodeObject(source);
    final isFood = _readBool(json['is_food_image'], fallback: false);
    final inputType = _readString(json['input_type']) ?? 'unclear';
    final foods = json['foods'];
    final items = <FoodScanItem>[];
    if (foods is List) {
      for (final raw in foods.whereType<Map>()) {
        final row = raw.map((key, value) => MapEntry(key.toString(), value));
        final item = FoodScanItem.fromJson({
          ...row,
          'id': _uuidV4(),
          'normalized_name': row['normalized_hint'],
          'nutrition': row['fallback_nutrition'],
          'nutrition_source': 'ai_fallback',
        });
        if (item.name.trim().isEmpty) continue;
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
      assumptions: _readStrings(json['assumptions']),
      warnings: _readStrings(json['warnings']),
    );
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

  FoodScanException _mapGeminiError(
    GeminiApiException error, {
    bool healthEvaluation = false,
  }) {
    if (error.isAuthenticationFailure) {
      return FoodScanException(
        code: 'AI_AUTHENTICATION',
        userMessage: 'Dịch vụ AI chưa sẵn sàng. Bạn thử lại sau nhé.',
        cause: error,
      );
    }
    if (error.isTransient) {
      return FoodScanException(
        code: 'AI_TEMPORARILY_UNAVAILABLE',
        userMessage: healthEvaluation
            ? 'Nabi chưa đánh giá được sức khỏe lúc này. Phần dinh dưỡng vẫn được giữ để bạn thử lại.'
            : 'AI đang bận hoặc mạng chưa ổn định. Ảnh vẫn ở trên máy, bạn thử lại nhé.',
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

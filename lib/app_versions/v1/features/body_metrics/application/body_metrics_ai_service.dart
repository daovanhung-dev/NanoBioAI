import 'dart:async';
import 'dart:convert';

import 'package:nano_app/app_versions/v1/services/ai/gemini_rest_client.dart';
import 'package:nano_app/core/config/app_env.dart';

import '../domain/entities/basic_health_calculator_models.dart';
import '../domain/entities/body_metrics_personal_context.dart';

typedef BodyMetricsTextGenerator = Future<String> Function(String prompt);

class BodyMetricsAiService {
  final BodyMetricsTextGenerator? textGenerator;

  const BodyMetricsAiService({this.textGenerator});

  Future<BodyMetricsAiInsight> analyze({
    required BasicHealthReport report,
    required BodyMetricsThirtyDayScenario scenario,
    required double dataCompleteness,
  }) async {
    if (!scenario.hasEnoughPlanData) {
      return const BodyMetricsAiInsight.unavailable(
        currentStatus:
            'Nabi đã tính được các chỉ số hiện tại, nhưng dữ liệu kế hoạch chưa đủ để AI phân tích đáng tin cậy.',
        afterThirtyDays:
            'Hãy dùng thực đơn và lịch trình thêm vài ngày để Nabi có đủ dữ liệu cho dự báo xu hướng.',
      );
    }

    final prompt = _buildPrompt(
      report: report,
      scenario: scenario,
      dataCompleteness: dataCompleteness,
    );

    try {
      final raw = textGenerator != null
          ? await textGenerator!(prompt).timeout(const Duration(seconds: 20))
          : await _generateWithGemini(prompt);
      return _parseAndValidate(raw);
    } catch (_) {
      return const BodyMetricsAiInsight.unavailable();
    }
  }

  Future<String> _generateWithGemini(String prompt) async {
    final apiKey = AppEnv.maybeString('GEMINI_API_KEY');
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw StateError('Missing Gemini runtime configuration');
    }
    final client = GeminiRestClient(
      apiKey: apiKey,
      baseUrl: AppEnv.maybeString('GEMINI_BASE_URL'),
    );
    Object? lastError;
    for (final model in _modelCandidates()) {
      try {
        return await client
            .generateText(
              model: model,
              contents: [GeminiContent.user(prompt)],
              systemInstruction:
                  'Bạn là Nabi, trợ lý wellness. Chỉ diễn giải dữ liệu đã cung cấp; không chẩn đoán, không kê thuốc, không phát minh số liệu.',
              generationConfig: const GeminiGenerationConfig(
                maxOutputTokens: 650,
                temperature: 0.2,
                topP: 0.85,
                responseMimeType: 'application/json',
              ),
            )
            .timeout(const Duration(seconds: 20));
      } catch (error) {
        lastError = error;
      }
    }
    throw StateError('Body metrics AI unavailable: ${lastError.runtimeType}');
  }

  List<String> _modelCandidates() {
    final values = <String?>[
      AppEnv.maybeString('GEMINI_CHAT_MODEL'),
      AppEnv.maybeString('GEMINI_PLAN_MODEL'),
      ..._csv(AppEnv.maybeString('GEMINI_CHAT_FALLBACK_MODELS')),
      ..._csv(AppEnv.maybeString('GEMINI_PLAN_FALLBACK_MODELS')),
      'gemini-2.5-flash',
    ];
    final result = <String>[];
    for (final value in values) {
      final normalized = value?.trim();
      if (normalized != null && normalized.isNotEmpty && !result.contains(normalized)) {
        result.add(normalized);
      }
    }
    return result;
  }

  List<String?> _csv(String? value) =>
      value?.split(',').map((entry) => entry.trim()).toList() ?? const [];

  String _buildPrompt({
    required BasicHealthReport report,
    required BodyMetricsThirtyDayScenario scenario,
    required double dataCompleteness,
  }) {
    final energyDirection = switch (scenario.energyDirection) {
      BodyMetricsEnergyDirection.belowMaintenance => 'thấp hơn mức duy trì',
      BodyMetricsEnergyDirection.nearMaintenance => 'gần mức duy trì',
      BodyMetricsEnergyDirection.aboveMaintenance => 'cao hơn mức duy trì',
      BodyMetricsEnergyDirection.unknown => 'chưa đủ dữ liệu',
    };
    return '''
Phân tích wellness dựa CHỈ trên dữ liệu tổng hợp sau.
- BMI do app tính: ${report.bmi}
- Nhóm BMI: ${report.bmiCategory}
- BMR do app tính: ${report.bmrKcal} kcal/ngày
- RMR do app tính: ${report.rmrKcal} kcal/ngày
- TDEE do app tính: ${report.tdeeKcal} kcal/ngày
- Nước tham khảo do app tính: ${report.hydrationMl} ml/ngày
- Phiên bản công thức: ${report.formulaVersion}
- Hướng năng lượng của thực đơn so với TDEE: $energyDirection
- Số ngày có thực đơn: ${scenario.plannedMealDays}
- Số nhiệm vụ chăm sóc: ${scenario.plannedScheduleItems}
- Số nhiệm vụ vận động: ${scenario.plannedExerciseItems}
- Mức đầy đủ dữ liệu: ${(dataCompleteness * 100).round()} phần trăm

Yêu cầu:
1. Viết tiếng Việt, ngắn, không phán xét.
2. Không đưa ra chẩn đoán, điều trị, thuốc hoặc cam kết kết quả.
3. Không xuất BẤT KỲ chữ số nào trong các trường văn bản. App sẽ hiển thị số liệu xác định ở nơi khác.
4. Dự báo chỉ là xu hướng nếu người dùng duy trì thực đơn và lịch chăm sóc hiện tại.
5. Trả đúng JSON object:
{
  "current_status": "...",
  "after_thirty_days": "...",
  "confidence": "thap|vua|cao",
  "factors": ["..."],
  "assumptions": ["..."]
}
''';
  }

  BodyMetricsAiInsight _parseAndValidate(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*```$'), '')
        .trim();
    final decoded = jsonDecode(cleaned);
    if (decoded is! Map) throw const FormatException('AI body metrics payload is not an object');
    final map = decoded.map((key, value) => MapEntry(key.toString(), value));
    final current = _safeNarrative(map['current_status']);
    final after = _safeNarrative(map['after_thirty_days']);
    final confidence = _confidence(map['confidence']);
    final factors = _safeList(map['factors']);
    final assumptions = _safeList(map['assumptions']);
    return BodyMetricsAiInsight(
      currentStatus: current,
      afterThirtyDays: after,
      confidence: confidence,
      factors: factors,
      assumptions: assumptions,
      generatedByAi: true,
    );
  }

  String _safeNarrative(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.length < 12 || text.length > 420) {
      throw const FormatException('Invalid body metrics narrative length');
    }
    if (RegExp(r'\d').hasMatch(text)) {
      throw const FormatException('AI invented or repeated numeric content');
    }
    final normalized = text.toLowerCase();
    const blocked = [
      'được chẩn đoán',
      'bạn mắc',
      'có bệnh',
      'cần điều trị',
      'hãy điều trị',
      'kê thuốc',
      'hãy dùng thuốc',
      'chắc chắn sẽ',
      'cam kết kết quả',
    ];
    if (blocked.any(normalized.contains)) {
      throw const FormatException('Unsafe medical claim');
    }
    return text;
  }

  List<String> _safeList(Object? value) {
    if (value is! List) return const [];
    final result = <String>[];
    for (final item in value.take(5)) {
      final text = _safeNarrative(item);
      result.add(text);
    }
    return result;
  }

  String _confidence(Object? value) {
    return switch (value?.toString().trim().toLowerCase()) {
      'cao' => 'cao',
      'vua' || 'vừa' => 'vừa',
      _ => 'thấp',
    };
  }
}

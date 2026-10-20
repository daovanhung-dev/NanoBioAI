import 'dart:async';
import 'dart:convert';

import 'package:nano_app/app_versions/v1/services/ai/ai_text_client.dart';
import 'package:nano_app/core/ai_local/local_ai_text_client.dart';

import '../domain/entities/basic_health_calculator_models.dart';
import '../domain/entities/body_metrics_personal_context.dart';

typedef BodyMetricsTextGenerator = Future<String> Function(String prompt);

/// Thin text-generation adapter. Business orchestration, stage validation and
/// paid/free policy live outside this class so tests can inject a fake generator.
class BodyMetricsAiService {
  final BodyMetricsTextGenerator? textGenerator;

  const BodyMetricsAiService({this.textGenerator});

  Future<String> generateStage(String prompt) async {
    if (textGenerator != null) {
      return textGenerator!(prompt).timeout(const Duration(seconds: 20));
    }
    return _generateLocally(prompt).timeout(const Duration(seconds: 25));
  }

  /// Compatibility path for the legacy M04 page/tests. New code uses the
  /// multi-stage orchestrator.
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
    final prompt =
        '''
Bạn là Nabi, trợ lý wellness. Chỉ diễn giải dữ liệu app đã tính; không chẩn đoán, không kê thuốc, không phát minh số liệu.
BMI category: ${report.bmiCategory}
Formula version: ${report.formulaVersion}
Data completeness bucket: ${dataCompleteness >= .75
            ? 'cao'
            : dataCompleteness >= .45
            ? 'vua'
            : 'thap'}
Plan data available: ${scenario.hasEnoughPlanData}
Không xuất chữ số trong narrative.
Trả JSON: {"current_status":"...","after_thirty_days":"...","confidence":"thap|vua|cao","factors":["..."],"assumptions":["..."]}
''';
    try {
      final raw = await generateStage(prompt);
      return _parseLegacy(raw);
    } catch (_) {
      return const BodyMetricsAiInsight.unavailable();
    }
  }

  Future<String> _generateLocally(String prompt) async {
    const client = LocalAiTextClient(operation: 'body_metrics');
    return client
        .generateText(
          model: LocalAiTextClient.modelId,
          messages: [AiMessage.user(prompt)],
          systemInstruction:
              'Bạn là Nabi, trợ lý wellness. Chỉ dùng dữ liệu được cung cấp; không chẩn đoán, không kê thuốc, không đổi điều trị, không phát minh số.',
          generationConfig: const AiGenerationConfig(
            temperature: 0.2,
            topP: 0.85,
            responseFormat: AiResponseFormat.json,
          ),
        )
        .timeout(const Duration(seconds: 20));
  }

  BodyMetricsAiInsight _parseLegacy(String raw) {
    final cleaned = raw
        .replaceAll(RegExp(r'^```(?:json)?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s*```$'), '')
        .trim();
    final decoded = jsonDecode(cleaned);
    if (decoded is! Map) {
      throw const FormatException('AI body metrics payload is not an object');
    }
    String narrative(Object? value) {
      final text = value?.toString().trim() ?? '';
      if (text.length < 8 ||
          text.length > 420 ||
          RegExp(r'\d').hasMatch(text)) {
        throw const FormatException('Unsafe legacy narrative');
      }
      final normalized = text.toLowerCase();
      const blocked = <String>[
        'bạn mắc',
        'được chẩn đoán',
        'chẩn đoán là',
        'cần điều trị',
        'hãy dùng thuốc',
        'ngừng thuốc',
        'tăng liều',
        'giảm liều',
        'đổi thuốc',
        'kê thuốc',
        'chắc chắn sẽ',
        'cam kết',
      ];
      if (blocked.any(normalized.contains)) {
        throw const FormatException('Unsafe legacy medical claim');
      }
      return text;
    }

    List<String> list(Object? value) => value is List
        ? value.take(5).map(narrative).toList(growable: false)
        : const [];
    final confidence = switch (decoded['confidence']
        ?.toString()
        .trim()
        .toLowerCase()) {
      'cao' => 'cao',
      'vua' || 'vừa' => 'vừa',
      _ => 'thấp',
    };
    return BodyMetricsAiInsight(
      currentStatus: narrative(decoded['current_status']),
      afterThirtyDays: narrative(decoded['after_thirty_days']),
      confidence: confidence,
      factors: list(decoded['factors']),
      assumptions: list(decoded['assumptions']),
      generatedByAi: true,
    );
  }
}

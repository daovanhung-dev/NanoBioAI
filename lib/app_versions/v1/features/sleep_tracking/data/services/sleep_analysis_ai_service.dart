import 'dart:convert';

import 'package:nano_app/core/config/app_env.dart';
import 'package:nano_app/app_versions/v1/services/ai/gemini_rest_client.dart';
import 'package:nano_app/app_versions/v1/services/ai/nabi_ai_backend_client.dart';

import '../../domain/entities/sleep_night_analysis.dart';
import '../models/sleep_analysis_ai_models.dart';

typedef SleepAiTextGenerator =
    Future<String> Function({
      required String model,
      required Map<String, Object?> payload,
    });

class SleepAnalysisAIService {
  SleepAnalysisAIService({
    String? apiKeyOverride,
    String? modelOverride,
    GeminiRestClient? client,
    SleepAiTextGenerator? textGenerator,
  }) : _model =
           _clean(modelOverride) ??
           _clean(AppEnv.maybeString('GEMINI_SLEEP_MODEL')) ??
           _clean(AppEnv.maybeString('GEMINI_MODEL')) ??
           'gemini-3.5-flash',
       _textGenerator = textGenerator,
       _client = textGenerator != null
           ? client
           : client ?? const NabiAiBackendClient();

  final String _model;
  final AiTextClient? _client;
  final SleepAiTextGenerator? _textGenerator;

  bool get isConfigured => _textGenerator != null || _client != null;
  String get model => _model;

  Future<SleepAiAnalysisResult> generate(SleepNightAnalysis analysis) async {
    if (!isConfigured) {
      throw StateError('sleep_ai_missing_api_key');
    }
    final payload = analysis.toSafeAiPayload();
    final raw = _textGenerator != null
        ? await _textGenerator(model: _model, payload: payload)
        : await _client!.generateText(
            model: _model,
            contents: [GeminiContent.user(jsonEncode(payload))],
            generationConfig: const GeminiGenerationConfig(
              maxOutputTokens: 2400,
              temperature: 0.2,
              responseMimeType: 'application/json',
            ),
            systemInstruction: _systemInstruction,
          );
    final decoded = _decodeObject(raw);
    final sections = <SleepAiSection>[];
    for (final key in _sectionKeys) {
      final value = decoded[key];
      if (value is Map) {
        sections.add(
          SleepAiSection.fromJson(key, {
            for (final entry in value.entries)
              if (entry.key is String) entry.key as String: entry.value,
          }),
        );
      }
    }
    if (sections.isEmpty) {
      throw const FormatException('sleep_ai_empty_sections');
    }
    return SleepAiAnalysisResult(
      model: _model,
      generatedAt: DateTime.now(),
      sections: sections,
    );
  }

  static Map<String, Object?> _decodeObject(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```(?:json)?\s*'), '');
      text = text.replaceFirst(RegExp(r'\s*```$'), '');
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map) {
      throw const FormatException('sleep_ai_invalid_root');
    }
    return {
      for (final entry in decoded.entries)
        if (entry.key is String) entry.key as String: entry.value,
    };
  }

  static String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  static const _sectionKeys = <String>[
    'overall_summary',
    'night_pattern',
    'acoustic_event_analysis',
    'seven_night_trend',
    'wellness_observations',
    'recommended_actions',
    'what_to_monitor_next',
    'data_limitations',
    'care_guidance',
  ];

  static const _systemInstruction = '''
Bạn là Nabi của NanoBio. Phân tích dữ liệu giám sát giấc ngủ dạng số học và
metadata âm thanh, bằng tiếng Việt, nhẹ nhàng, cụ thể, không phán xét.

RÀNG BUỘC AN TOÀN:
- Đây không phải dữ liệu chẩn đoán y khoa.
- Không kết luận ngưng thở khi ngủ, co giật, đột quỵ, bệnh tim, bệnh phổi hoặc
  bất kỳ bệnh nào từ metadata âm thanh.
- Không nói người dùng chắc chắn an toàn hoặc nguy kịch.
- Không bịa REM/N1/N2/N3/deep sleep hoặc thời gian ngủ thật nếu input không có.
- Phân biệt rõ quan sát từ số liệu và suy luận thận trọng.
- Nếu dữ liệu ít/chất lượng thấp, phải nói rõ giới hạn.
- Chỉ dùng dữ liệu JSON người dùng gửi; không yêu cầu bản ghi âm.

Trả về DUY NHẤT một JSON object với đúng 9 key:
overall_summary, night_pattern, acoustic_event_analysis, seven_night_trend,
wellness_observations, recommended_actions, what_to_monitor_next,
data_limitations, care_guidance.

Mỗi key là object:
{
  "title": "...",
  "summary": "...",
  "evidence": ["..."],
  "recommendations": ["..."],
  "confidence": 0.0
}
Confidence từ 0 đến 1. Không markdown, không thêm key ngoài schema.
''';
}

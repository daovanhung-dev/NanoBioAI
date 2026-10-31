import 'dart:async';
import 'dart:convert';

import 'package:nano_app/app_versions/v1/services/ai/ai_text_client.dart';
import 'package:nano_app/core/network/backend_ai_text_client.dart';

import '../domain/entities/nutrition_intelligence_entity.dart';
import 'nutrition_ai_response_validator.dart';

typedef NutritionAiTextGenerator = Future<String> Function(String prompt);

class NutritionAiService {
  const NutritionAiService({
    this.textGenerator,
    this.validator = const NutritionAiResponseValidator(),
  });

  final NutritionAiTextGenerator? textGenerator;
  final NutritionAiResponseValidator validator;

  Future<NutritionAiReport> analyze(NutritionHealthSnapshot snapshot) async {
    final intelligence = snapshot.intelligence;
    if (!intelligence.hasUsefulData || intelligence.dataQuality.score < 20) {
      return NutritionAiReport.fallback(
        summary:
            'Nabi cần thêm dữ liệu bữa ăn hoặc thực đơn trước khi đưa ra phân tích cá nhân hóa.',
        missingData: intelligence.dataQuality.missingData,
      );
    }

    final allowedEvidence = _allowedEvidenceCodes(snapshot);
    final prompt = _buildPrompt(snapshot, allowedEvidence);
    try {
      final raw = textGenerator != null
          ? await textGenerator!(prompt).timeout(const Duration(seconds: 20))
          : await _generateWithBackend(
              prompt,
            ).timeout(const Duration(seconds: 25));
      return validator.parse(raw, allowedEvidenceCodes: allowedEvidence);
    } on AiInferenceException catch (error) {
      return NutritionAiReport.fallback(
        summary:
            error.isAuthenticationFailure ||
                error.status == 'unsupported_platform'
            ? error.message
            : error.isNetworkFailure || error.isTransient
            ? 'Dịch vụ AI tạm thời chưa khả dụng. Hãy kiểm tra mạng rồi thử lại.'
            : 'Nabi chưa thể phân tích dinh dưỡng lúc này. Bạn thử lại sau nhé.',
        missingData: intelligence.dataQuality.missingData,
      );
    } catch (_) {
      return NutritionAiReport.fallback(
        missingData: intelligence.dataQuality.missingData,
      );
    }
  }

  String _buildPrompt(
    NutritionHealthSnapshot snapshot,
    Set<String> allowedEvidence,
  ) {
    final payload = jsonEncode(snapshot.toPromptPayload());
    final evidence = allowedEvidence.toList()..sort();
    return '''
Bạn là Nabi, trợ lý wellness về dinh dưỡng trong ứng dụng NanoBio.

NGUYÊN TẮC TUYỆT ĐỐI:
- Chỉ diễn giải dữ liệu trong SNAPSHOT. Không tự tạo số, không ước lượng phần dữ liệu thiếu.
- Không chẩn đoán bệnh, không kê thuốc, không đổi/ngừng/tăng/giảm thuốc hoặc điều trị.
- Không khẳng định quan hệ nhân quả. Nếu thấy hai tín hiệu đi cùng nhau, chỉ gọi là "mối liên hệ cần theo dõi".
- Dữ liệu vi chất có data_coverage thấp hoặc status insufficientData phải được mô tả là chưa đủ dữ liệu.
- planned là thực đơn cá nhân trong app, KHÔNG được gọi là ngưỡng y khoa/RDA.
- Không viết chữ số trong summary/title/body/actions. Các con số đã có sẽ được UI hiển thị riêng.
- Mỗi insight bắt buộc có evidence_codes và chỉ được dùng code trong ALLOWED_EVIDENCE.
- Viết tiếng Việt tự nhiên, ngắn, cụ thể, ưu tiên hành động có thể làm ngay.

SNAPSHOT:
$payload

ALLOWED_EVIDENCE:
${jsonEncode(evidence)}

Trả duy nhất JSON đúng schema:
{
  "summary": "...",
  "insights": [
    {
      "title": "...",
      "body": "...",
      "evidence_codes": ["..."],
      "confidence": "low|medium|high",
      "priority": "low|medium|high"
    }
  ],
  "today_actions": ["..."],
  "weekly_actions": ["..."],
  "missing_data": ["..."],
  "safety_flags": ["..."],
  "confidence": "low|medium|high"
}
''';
  }

  Set<String> _allowedEvidenceCodes(NutritionHealthSnapshot snapshot) {
    final intelligence = snapshot.intelligence;
    final actual = intelligence.actual;
    final planned = intelligence.planned;
    final health = intelligence.healthContext;
    return {
      if (actual.energyKcal != null) 'actual:energy',
      if (actual.proteinG != null) 'actual:protein',
      if (actual.carbsG != null) 'actual:carbs',
      if (actual.fatG != null) 'actual:fat',
      if (planned.energyKcal != null) 'planned:energy',
      if (planned.proteinG != null) 'planned:protein',
      if (planned.carbsG != null) 'planned:carbs',
      if (planned.fatG != null) 'planned:fat',
      if (intelligence.dataQuality.daysWithLogsInLast7 > 0) 'trend:7d',
      if (intelligence.dataQuality.daysWithLogsInLast30 > 0) 'trend:30d',
      if (health.waterMl != null || health.sevenDayAverageWaterMl != null)
        'health:water',
      if (health.sleepHours != null || health.sevenDayAverageSleepHours != null)
        'health:sleep',
      if (health.stressLevel != null) 'health:stress',
      if (health.stepsCount != null || health.sevenDayAverageSteps != null)
        'health:steps',
      'data:quality',
      for (final item in intelligence.coverage)
        if (item.actual != null || item.planned != null)
          'nutrient:${item.code}',
      ...snapshot.allergyCodes,
      ...snapshot.avoidanceCodes,
      ...snapshot.symptomCodes,
      ...snapshot.labCodes,
      if (snapshot.primaryGoalCode != null) snapshot.primaryGoalCode!,
    };
  }

  Future<String> _generateWithBackend(String prompt) async {
    const client = BackendAiTextClient();
    return client
        .generateText(
          model: BackendAiTextClient.modelId,
          messages: [AiMessage.user(prompt)],
          systemInstruction:
              'Bạn là Nabi, trợ lý wellness dinh dưỡng. Chỉ dùng dữ liệu app cung cấp; không chẩn đoán, không kê thuốc, không phát minh số.',
          generationConfig: const AiGenerationConfig(
            temperature: 0.15,
            topP: 0.85,
            responseFormat: AiResponseFormat.json,
          ),
        )
        .timeout(const Duration(seconds: 20));
  }
}

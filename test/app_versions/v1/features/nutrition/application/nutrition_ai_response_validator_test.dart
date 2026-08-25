import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/application/nutrition_ai_response_validator.dart';

void main() {
  const validator = NutritionAiResponseValidator();

  test('accepts grounded insight and removes unknown evidence', () {
    final result = validator.parse(
      '''
      {
        "summary": "Nhịp ăn hôm nay đang khá gần với thực đơn đã lập.",
        "insights": [
          {
            "title": "Protein đang có nền tốt",
            "body": "Dữ liệu đã ghi cho thấy lượng đạm đang bám tương đối sát kế hoạch trong ứng dụng.",
            "evidence_codes": ["nutrient:protein", "unknown:code"],
            "confidence": "high",
            "priority": "medium"
          }
        ],
        "today_actions": ["Tiếp tục ghi đủ các bữa để Nabi nhìn rõ hơn phần vi chất."],
        "weekly_actions": [],
        "missing_data": ["Một số bữa chưa có dữ liệu vi chất."],
        "safety_flags": [],
        "confidence": "high"
      }
      ''',
      allowedEvidenceCodes: {'nutrient:protein'},
    );

    expect(result.generatedByAi, isTrue);
    expect(result.insights, hasLength(1));
    expect(result.insights.single.evidenceCodes, ['nutrient:protein']);
    expect(result.confidence, 'cao');
  });

  test('rejects diagnosis-like summary', () {
    expect(
      () => validator.parse(
        '''
        {
          "summary": "Bạn mắc bệnh do chế độ ăn hiện tại.",
          "insights": [],
          "today_actions": [],
          "weekly_actions": [],
          "missing_data": [],
          "safety_flags": [],
          "confidence": "low"
        }
        ''',
        allowedEvidenceCodes: const {},
      ),
      throwsFormatException,
    );
  });

  test('rejects narrative that invents numbers', () {
    expect(
      () => validator.parse(
        '''
        {
          "summary": "Bạn nên tăng thêm 20 gam protein mỗi ngày.",
          "insights": [],
          "today_actions": [],
          "weekly_actions": [],
          "missing_data": [],
          "safety_flags": [],
          "confidence": "low"
        }
        ''',
        allowedEvidenceCodes: const {},
      ),
      throwsFormatException,
    );
  });
}

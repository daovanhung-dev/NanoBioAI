import 'dart:convert';

import '../domain/entities/body_metrics_ai_models.dart';

class BodyMetricsPromptBuilder {
  const BodyMetricsPromptBuilder._();

  static const systemSafety = '''
Bạn là Nabi, trợ lý chăm sóc sức khỏe và wellness.
Chỉ sử dụng dữ liệu được cung cấp.
Không tự tạo số và không tự tính chỉ số mới.
Không chẩn đoán, không kê thuốc, không đổi liều, không thay đổi điều trị.
Không kết luận chắc chắn về nguyên nhân bệnh lý hoặc tương tác thuốc.
Phân biệt dữ liệu quan sát với diễn giải wellness.
Nếu dữ liệu thiếu phải nói rõ là dữ liệu thiếu.
Không lặp lại chữ số trong phần diễn giải; ứng dụng sở hữu toàn bộ numeric truth.
Trả đúng JSON, không markdown.
''';

  static String build({
    required String stageId,
    required BodyMetricsAiContext context,
    required List<BodyMetricsAiStageResult> dependencies,
  }) {
    final focus = _focus(stageId);
    final dependencyPayload = {
      for (final item in dependencies.where((item) => item.success)) item.stageId: item.payload,
    };
    return '''
$systemSafety

STAGE: $stageId
MỤC TIÊU: $focus

DỮ LIỆU XÁC ĐỊNH DO APP TÍNH/TỔNG HỢP:
${jsonEncode(context.payload)}

KẾT QUẢ STAGE TRƯỚC ĐÃ ĐƯỢC VALIDATE:
${jsonEncode(dependencyPayload)}

${_schema(stageId)}
''';
  }

  static String _focus(String id) => switch (id) {
        'P01' => 'Baseline cơ thể, BMI, năng lượng và vận động cơ bản.',
        'P02' => 'Xu hướng cân nặng, ngủ, stress, nước, bước chân và observation HR/SpO2.',
        'P03' => 'Dinh dưỡng: năng lượng, macro, chất xơ, khoáng, completion và dị ứng đã khai báo.',
        'P04' => 'Lifestyle: ngủ, stress, mood, vận động, lịch, thói quen và mục tiêu.',
        'P05' => 'Tổng hợp Free thành ưu tiên và hành động hôm nay, bảy ngày, ba mươi ngày.',
        'P06' => 'Phân tích sâu cân nặng và body metrics.',
        'P07' => 'Phân tích sâu energy balance.',
        'P08' => 'Phân tích sâu protein và macro.',
        'P09' => 'Phân tích sâu chất xơ, khoáng và chất lượng thực đơn.',
        'P10' => 'Phân tích hành vi hydration.',
        'P11' => 'Phân tích tương tác wellness giữa ngủ, stress và mood.',
        'P12' => 'Phân tích activity/exercise và bối cảnh HR dạng observation.',
        'P13' => 'Ưu tiên wellness dựa trên tình trạng, mục tiêu, dị ứng và treatment do người dùng khai báo; tuyệt đối không thay thuốc/liều.',
        'P14' => 'Chiến lược tối ưu hành vi và theo dõi trong ba mươi ngày, không cam kết outcome.',
        'P15' => 'Tổng hợp Premium cuối cùng từ các stage đã validate.',
        _ => 'Diễn giải wellness an toàn.',
      };

  static String _schema(String id) {
    if (id == 'P05' || id == 'P15') {
      return '''
JSON schema bắt buộc:
{
  "overview": "...",
  "strengths": ["..."],
  "priorities": ["..."],
  "actions_today": [
    {
      "action": "...",
      "reason": "...",
      "related_metric_ids": ["metric.id"],
      "priority": "thap|vua|cao",
      "difficulty": "de|vua|kho",
      "tracking_metric_ids": ["metric.id"]
    }
  ],
  "actions_7_days": [
    {
      "action": "...",
      "reason": "...",
      "related_metric_ids": ["metric.id"],
      "priority": "thap|vua|cao",
      "difficulty": "de|vua|kho",
      "tracking_metric_ids": ["metric.id"]
    }
  ],
  "actions_30_days": [
    {
      "action": "...",
      "reason": "...",
      "related_metric_ids": ["metric.id"],
      "priority": "thap|vua|cao",
      "difficulty": "de|vua|kho",
      "tracking_metric_ids": ["metric.id"]
    }
  ],
  "monitoring_metric_ids": ["metric.id"],
  "missing_data": ["..."],
  "confidence": "thap|vua|cao",
  "questions_for_clinician": ["..."]
}
Mỗi action list phải có ít nhất một và tối đa năm action; strengths/priorities tối đa ba mục.
''';
    }
    return '''
JSON schema bắt buộc:
{
  "summary": "...",
  "strengths": ["..."],
  "priorities": ["..."],
  "actions": ["..."],
  "related_metric_ids": ["metric.id"]
}
Giới hạn mỗi danh sách tối đa năm mục.
''';
  }
}

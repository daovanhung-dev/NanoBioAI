import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/body_metrics/application/body_metrics_ai_response_validator.dart';

void main() {
  test('rejects diagnosis wording', () {
    expect(
      () => BodyMetricsAiResponseValidator.validate(
        'P01',
        '{"summary":"Bạn mắc tiểu đường và cần điều trị ngay","strengths":[],"priorities":[],"actions":[],"related_metric_ids":[]}',
      ),
      throwsFormatException,
    );
  });

  test('rejects numeric narrative invented by AI', () {
    expect(
      () => BodyMetricsAiResponseValidator.validate(
        'P01',
        '{"summary":"Bạn nên uống 2000 ml nước mỗi ngày","strengths":[],"priorities":[],"actions":[],"related_metric_ids":[]}',
      ),
      throwsFormatException,
    );
  });

  test('rejects unknown metric id', () {
    expect(
      () => BodyMetricsAiResponseValidator.validate(
        'P01',
        '{"summary":"Dữ liệu hiện tại cho thấy nên tiếp tục theo dõi đều đặn","strengths":[],"priorities":[],"actions":[],"related_metric_ids":["made.up.metric"]}',
      ),
      throwsFormatException,
    );
  });

  test('accepts structured synthesis actions with whitelisted metric ids', () {
    final result = BodyMetricsAiResponseValidator.validate(
      'P05',
      '{"overview":"Nabi ưu tiên các thay đổi nhỏ và theo dõi đều đặn","strengths":[],"priorities":[],"actions_today":[{"action":"Duy trì việc theo dõi nước đều đặn","reason":"Dữ liệu hiện tại sẽ rõ hơn khi được ghi nhất quán","related_metric_ids":["hydration.water_average_7d"],"priority":"vua","difficulty":"de","tracking_metric_ids":["hydration.water_average_7d"]}],"actions_7_days":[{"action":"Theo dõi thói quen ngủ đều đặn","reason":"Xu hướng phục hồi cần dữ liệu liên tục để diễn giải","related_metric_ids":["recovery.sleep_average_7d"],"priority":"vua","difficulty":"de","tracking_metric_ids":["recovery.sleep_average_7d"]}],"actions_30_days":[{"action":"Duy trì lịch chăm sóc nhất quán","reason":"Mức thực hiện giúp Nabi đánh giá xu hướng hành vi","related_metric_ids":["adherence.schedule_completion"],"priority":"vua","difficulty":"vua","tracking_metric_ids":["adherence.schedule_completion"]}],"monitoring_metric_ids":["hydration.water_average_7d"],"missing_data":[],"confidence":"vua","questions_for_clinician":[]}',
    );
    final synthesis = BodyMetricsAiResponseValidator.synthesis(result);
    expect(synthesis.actionsToday.single.priority, 'vừa');
    expect(synthesis.actionsToday.single.relatedMetricIds, ['hydration.water_average_7d']);
  });

}

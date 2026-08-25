import '../../domain/care/nabi_care_models.dart';

class NabiCareSignalEngine {
  const NabiCareSignalEngine();

  List<NabiCareSignal> evaluate(NabiCareSnapshot snapshot) {
    final signals = <NabiCareSignal>[];
    final current = snapshot.current;
    final baselines = snapshot.baselines;

    final sleep = nabiCareNumber(current['sleep_hours']);
    final sleep7d = nabiCareNumber(baselines['sleep_hours_avg_7d']);
    if (sleep != null &&
        (sleep < 6 || (sleep7d != null && sleep < sleep7d * 0.8))) {
      signals.add(
        NabiCareSignal(
          code: 'sleep_below_recent_pattern',
          title: 'Giấc ngủ đang thấp hơn nhịp gần đây',
          description:
              'Thời lượng ngủ mới nhất thấp hơn mức thường thấy của bạn.',
          severity: sleep < 5
              ? NabiCareSeverity.medium
              : NabiCareSeverity.low,
          confidence: sleep7d == null ? 0.72 : 0.9,
          evidenceKeys: [
            'health.sleep_hours.current',
            if (sleep7d != null) 'baseline.sleep_hours_avg_7d',
          ],
        ),
      );
    } else if (sleep != null &&
        sleep7d != null &&
        sleep >= 7 &&
        sleep >= sleep7d * 1.08) {
      signals.add(
        const NabiCareSignal(
          code: 'sleep_improving',
          title: 'Giấc ngủ đang cải thiện',
          description:
              'Thời lượng ngủ mới nhất tốt hơn xu hướng 7 ngày gần đây.',
          severity: NabiCareSeverity.info,
          confidence: 0.86,
          evidenceKeys: [
            'health.sleep_hours.current',
            'baseline.sleep_hours_avg_7d',
          ],
          positive: true,
        ),
      );
    }

    final waterRestricted = snapshot.profile['water_restriction'] == true;
    final water = nabiCareNumber(current['water_ml']);
    final water7d = nabiCareNumber(baselines['water_ml_avg_7d']);
    if (!waterRestricted &&
        water != null &&
        water7d != null &&
        water7d >= 500 &&
        water < water7d * 0.7) {
      signals.add(
        const NabiCareSignal(
          code: 'water_below_personal_pattern',
          title: 'Lượng nước thấp hơn nhịp của bạn',
          description:
              'Lượng nước ghi nhận mới nhất thấp hơn đáng kể so với 7 ngày gần đây.',
          severity: NabiCareSeverity.low,
          confidence: 0.85,
          evidenceKeys: [
            'health.water_ml.current',
            'baseline.water_ml_avg_7d',
          ],
        ),
      );
    }

    final steps = nabiCareNumber(current['steps_count']);
    final steps7d = nabiCareNumber(baselines['steps_count_avg_7d']);
    if (steps != null &&
        steps7d != null &&
        steps7d >= 1000 &&
        steps < steps7d * 0.6) {
      signals.add(
        const NabiCareSignal(
          code: 'activity_below_personal_pattern',
          title: 'Vận động hôm nay thấp hơn thường lệ',
          description:
              'Số bước ghi nhận mới nhất thấp hơn nhịp 7 ngày của bạn.',
          severity: NabiCareSeverity.low,
          confidence: 0.84,
          evidenceKeys: [
            'health.steps_count.current',
            'baseline.steps_count_avg_7d',
          ],
        ),
      );
    }

    final stress = nabiCareNumber(current['stress_level']);
    final stress7d = nabiCareNumber(baselines['stress_level_avg_7d']);
    if (stress != null &&
        ((stress7d != null && stress >= stress7d + 1.5) || stress >= 4)) {
      signals.add(
        NabiCareSignal(
          code: 'stress_above_recent_pattern',
          title: 'Mức căng thẳng đang cao hơn',
          description:
              'Mức căng thẳng mới nhất cao hơn xu hướng gần đây của bạn.',
          severity: stress >= 5
              ? NabiCareSeverity.medium
              : NabiCareSeverity.low,
          confidence: stress7d == null ? 0.7 : 0.86,
          evidenceKeys: [
            'health.stress_level.current',
            if (stress7d != null) 'baseline.stress_level_avg_7d',
          ],
        ),
      );
    }

    final heartRate = nabiCareNumber(current['heart_rate_bpm']);
    final heartRate7d = nabiCareNumber(baselines['heart_rate_bpm_avg_7d']);
    if (heartRate != null &&
        heartRate7d != null &&
        heartRate7d > 0 &&
        ((heartRate - heartRate7d).abs() / heartRate7d) >= 0.2) {
      signals.add(
        const NabiCareSignal(
          code: 'heart_rate_changed_from_personal_baseline',
          title: 'Nhịp tim khác nhịp gần đây của bạn',
          description:
              'Giá trị mới nhất lệch đáng kể so với mức trung bình 7 ngày. Nabi chỉ ghi nhận xu hướng, không dùng dữ liệu này để chẩn đoán.',
          severity: NabiCareSeverity.medium,
          confidence: 0.82,
          evidenceKeys: [
            'health.heart_rate_bpm.current',
            'baseline.heart_rate_bpm_avg_7d',
          ],
        ),
      );
    }

    final oxygen = nabiCareNumber(current['oxygen_saturation']);
    final oxygen7d = nabiCareNumber(baselines['oxygen_saturation_avg_7d']);
    if (oxygen != null &&
        oxygen7d != null &&
        oxygen <= oxygen7d - 3) {
      signals.add(
        const NabiCareSignal(
          code: 'oxygen_changed_from_personal_baseline',
          title: 'SpO₂ khác nhịp gần đây của bạn',
          description:
              'Giá trị mới nhất thấp hơn mức trung bình cá nhân gần đây. Nabi chỉ dùng đây làm tín hiệu theo dõi.',
          severity: NabiCareSeverity.medium,
          confidence: 0.8,
          evidenceKeys: [
            'health.oxygen_saturation.current',
            'baseline.oxygen_saturation_avg_7d',
          ],
        ),
      );
    }

    final weight = nabiCareNumber(current['weight_kg']);
    final weight30d = nabiCareNumber(baselines['weight_kg_avg_30d']);
    if (weight != null &&
        weight30d != null &&
        weight30d > 0 &&
        ((weight - weight30d).abs() / weight30d) >= 0.025) {
      signals.add(
        const NabiCareSignal(
          code: 'weight_changed_from_30d_pattern',
          title: 'Cân nặng thay đổi so với tháng gần đây',
          description:
              'Giá trị mới nhất khác mức trung bình 30 ngày đủ để Nabi nhắc bạn theo dõi thêm.',
          severity: NabiCareSeverity.low,
          confidence: 0.78,
          evidenceKeys: [
            'health.weight_kg.current',
            'baseline.weight_kg_avg_30d',
          ],
        ),
      );
    }

    final adherenceToday = nabiCareNumber(snapshot.adherence['today_ratio']);
    final adherence7d = nabiCareNumber(snapshot.adherence['last_7d_ratio']);
    if (adherenceToday != null && adherenceToday < 0.5) {
      signals.add(
        NabiCareSignal(
          code: 'today_adherence_low',
          title: 'Hôm nay còn vài việc chăm sóc chưa hoàn thành',
          description:
              'Tỷ lệ hoàn thành lịch chăm sóc hôm nay đang thấp hơn một nửa.',
          severity: NabiCareSeverity.low,
          confidence: 0.92,
          evidenceKeys: const ['adherence.today_ratio'],
        ),
      );
    } else if (adherenceToday != null &&
        adherenceToday >= 0.8 &&
        (adherence7d == null || adherenceToday >= adherence7d)) {
      signals.add(
        const NabiCareSignal(
          code: 'today_adherence_positive',
          title: 'Bạn đang bám lịch rất tốt',
          description:
              'Phần lớn nhiệm vụ chăm sóc hôm nay đã được hoàn thành.',
          severity: NabiCareSeverity.info,
          confidence: 0.94,
          evidenceKeys: ['adherence.today_ratio'],
          positive: true,
        ),
      );
    }

    if (snapshot.symptoms.isNotEmpty) {
      signals.add(
        const NabiCareSignal(
          code: 'active_symptom_follow_up',
          title: 'Có triệu chứng đang được theo dõi',
          description:
              'Nabi nên hỏi lại diễn biến dựa trên dữ liệu triệu chứng đã lưu.',
          severity: NabiCareSeverity.medium,
          confidence: 0.95,
          evidenceKeys: ['health.symptoms'],
        ),
      );
    }

    if (snapshot.dataQuality.staleGroups.contains('tracking')) {
      signals.add(
        const NabiCareSignal(
          code: 'tracking_stale',
          title: 'Dữ liệu theo dõi đã cũ',
          description:
              'Nabi cần dữ liệu mới hơn để đưa ra chăm sóc sát tình trạng hiện tại.',
          severity: NabiCareSeverity.info,
          confidence: 1,
          evidenceKeys: [],
        ),
      );
    }

    if (snapshot.dataQuality.completeness < 0.45) {
      signals.add(
        const NabiCareSignal(
          code: 'care_data_incomplete',
          title: 'Cần thêm dữ liệu để chăm sóc chính xác hơn',
          description:
              'Một số nhóm dữ liệu quan trọng còn thiếu nên Nabi sẽ ưu tiên hỏi bổ sung.',
          severity: NabiCareSeverity.info,
          confidence: 1,
          evidenceKeys: [],
        ),
      );
    }

    signals.sort((left, right) {
      final severityOrder = right.severity.index.compareTo(left.severity.index);
      if (severityOrder != 0) return severityOrder;
      if (left.positive != right.positive) return left.positive ? 1 : -1;
      return right.confidence.compareTo(left.confidence);
    });
    return signals;
  }
}

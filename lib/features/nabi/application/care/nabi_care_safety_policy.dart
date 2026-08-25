import '../../domain/care/nabi_care_models.dart';

class NabiCareSafetyPolicy {
  static const _unsafeMedicationPhrases = <String>[
    'ngừng thuốc',
    'dừng thuốc',
    'đổi thuốc',
    'tăng liều',
    'giảm liều',
    'bắt đầu dùng thuốc',
    'uống thêm thuốc',
  ];

  static const _diagnosticPhrases = <String>[
    'chẩn đoán',
    'bạn bị ',
    'bạn mắc ',
    'chắc chắn là bệnh',
    'khẳng định mắc',
  ];

  const NabiCareSafetyPolicy();

  NabiCareAnalysis apply(
    NabiCareAnalysis input,
    NabiCareSnapshot snapshot,
  ) {
    final observations = input.observations
        .where((item) => _safeText(item.title) && _safeText(item.detail))
        .toList(growable: false);

    final actions = input.actions
        .where(
          (item) =>
              _safeText(item.title) &&
              _safeText(item.description) &&
              !_containsAny(item.description, _unsafeMedicationPhrases),
        )
        .map(
          (item) => NabiCareAction(
            id: item.id,
            title: item.title,
            description: item.description,
            priority: item.priority,
            suggestedTime: item.suggestedTime,
            // AI never decides native delivery. The notification subsystem
            // remains the authority for OS scheduling and quiet-hour policy.
            channelHint: item.channelHint == NabiCareChannelHint.localNotification
                ? NabiCareChannelHint.inApp
                : item.channelHint,
            evidenceKeys: item.evidenceKeys,
          ),
        )
        .toList(growable: false);

    final flags = input.attentionFlags
        .where((item) => _safeText(item.message))
        .toList(growable: false);

    final safeSummary = _safeText(input.summary)
        ? input.summary
        : 'NaBi đã xem dữ liệu gần đây và sẽ tiếp tục đồng hành cùng bạn.';

    final hasHighAttention = flags.any(
      (item) => item.severity == NabiCareSeverity.high,
    );
    final nextActions = <NabiCareAction>[...actions];
    if (hasHighAttention &&
        !nextActions.any(
          (item) => item.id == 'care_professional_follow_up',
        )) {
      final evidence = flags
          .where((item) => item.severity == NabiCareSeverity.high)
          .expand((item) => item.evidenceKeys)
          .where(snapshot.evidence.containsKey)
          .toSet()
          .toList(growable: false);
      if (evidence.isNotEmpty) {
        nextActions.insert(
          0,
          NabiCareAction(
            id: 'care_professional_follow_up',
            title: 'Nên trao đổi thêm với chuyên gia y tế',
            description:
                'Dữ liệu bạn đã ghi nhận có thay đổi đáng chú ý. Nếu bạn thấy không ổn hoặc tình trạng tiếp tục tăng, hãy liên hệ cơ sở y tế hoặc chuyên gia phù hợp để được đánh giá trực tiếp.',
            priority: 1,
            channelHint: NabiCareChannelHint.inApp,
            evidenceKeys: evidence,
          ),
        );
      }
    }

    return NabiCareAnalysis(
      overallStatus: input.overallStatus,
      summary: safeSummary,
      observations: observations.take(5).toList(growable: false),
      actions: nextActions.take(3).toList(growable: false),
      questions: input.questions.take(3).toList(growable: false),
      attentionFlags: flags.take(3).toList(growable: false),
      missingData: input.missingData,
      nextReviewAt: input.nextReviewAt,
      source: input.source,
    );
  }

  bool _safeText(String value) {
    final normalized = value.toLowerCase();
    return !_containsAny(normalized, _diagnosticPhrases) &&
        !_containsAny(normalized, _unsafeMedicationPhrases);
  }

  bool _containsAny(String value, Iterable<String> needles) {
    final normalized = value.toLowerCase();
    return needles.any(normalized.contains);
  }
}

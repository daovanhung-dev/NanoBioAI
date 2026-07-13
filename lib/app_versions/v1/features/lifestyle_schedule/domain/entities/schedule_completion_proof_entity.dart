class ScheduleCompletionProofStatuses {
  static const active = 'active';
  static const reversed = 'reversed';
}

class ScheduleProofPathKinds {
  static const relative = 'relative';
  static const legacyAbsolute = 'legacy_absolute';
}

class ScheduleProofUploadStatuses {
  static const localOnly = 'local_only';
  static const pending = 'pending';
  static const uploaded = 'uploaded';
  static const failed = 'failed';
}

class ScheduleProofRewardStatuses {
  static const notEligible = 'not_eligible';
  static const pending = 'pending';
  static const confirmed = 'confirmed';
  static const reversed = 'reversed';
  static const legacyNonRedeemable = 'legacy_non_redeemable';
}

class ScheduleCompletionProofEntity {
  final String id;
  final String? userId;
  final String scheduleItemId;
  final String? rewardEligibilityId;
  final String? completionAttemptId;
  final String scheduleDate;
  final String startTime;
  final String scheduleTitle;
  final String localPath;
  final String pathKind;
  final String capturedAt;
  final String completedAt;
  final String status;
  final String? cloudObjectPath;
  final String uploadStatus;
  final String rewardStatus;
  final String? reversedAt;
  final String createdAt;
  final String updatedAt;

  const ScheduleCompletionProofEntity({
    required this.id,
    this.userId,
    required this.scheduleItemId,
    this.rewardEligibilityId,
    this.completionAttemptId,
    required this.scheduleDate,
    required this.startTime,
    required this.scheduleTitle,
    required this.localPath,
    this.pathKind = ScheduleProofPathKinds.relative,
    required this.capturedAt,
    required this.completedAt,
    this.status = ScheduleCompletionProofStatuses.active,
    this.cloudObjectPath,
    this.uploadStatus = ScheduleProofUploadStatuses.localOnly,
    this.rewardStatus = ScheduleProofRewardStatuses.notEligible,
    this.reversedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isReversed => status == ScheduleCompletionProofStatuses.reversed;

  bool get hasRedeemableReward =>
      rewardStatus == ScheduleProofRewardStatuses.confirmed;
}

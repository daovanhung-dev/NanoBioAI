import '../../domain/entities/schedule_completion_proof_entity.dart';

class ScheduleCompletionProofModel extends ScheduleCompletionProofEntity {
  const ScheduleCompletionProofModel({
    required super.id,
    super.userId,
    required super.scheduleItemId,
    super.rewardEligibilityId,
    super.completionAttemptId,
    required super.scheduleDate,
    required super.startTime,
    required super.scheduleTitle,
    required super.localPath,
    super.pathKind,
    required super.capturedAt,
    required super.completedAt,
    super.status,
    super.cloudObjectPath,
    super.uploadStatus,
    super.rewardStatus,
    super.reversedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ScheduleCompletionProofModel.fromMap(Map<String, Object?> map) {
    return ScheduleCompletionProofModel(
      id: _string(map['id']),
      userId: _nullableString(map['user_id']),
      scheduleItemId: _string(map['schedule_item_id']),
      rewardEligibilityId: _nullableString(map['reward_eligibility_id']),
      completionAttemptId: _nullableString(map['completion_attempt_id']),
      scheduleDate: _string(map['schedule_date']),
      startTime: _string(map['start_time']),
      scheduleTitle: _string(map['schedule_title']),
      localPath: _string(map['local_path']),
      pathKind: _string(
        map['path_kind'],
        fallback: ScheduleProofPathKinds.relative,
      ),
      capturedAt: _string(map['captured_at']),
      completedAt: _string(map['completed_at']),
      status: _string(
        map['status'],
        fallback: ScheduleCompletionProofStatuses.active,
      ),
      cloudObjectPath: _nullableString(map['cloud_object_path']),
      uploadStatus: _string(
        map['upload_status'],
        fallback: ScheduleProofUploadStatuses.localOnly,
      ),
      rewardStatus: _string(
        map['reward_status'],
        fallback: ScheduleProofRewardStatuses.notEligible,
      ),
      reversedAt: _nullableString(map['reversed_at']),
      createdAt: _string(map['created_at']),
      updatedAt: _string(map['updated_at']),
    );
  }

  factory ScheduleCompletionProofModel.fromEntity(
    ScheduleCompletionProofEntity entity,
  ) {
    return ScheduleCompletionProofModel(
      id: entity.id,
      userId: entity.userId,
      scheduleItemId: entity.scheduleItemId,
      rewardEligibilityId: entity.rewardEligibilityId,
      completionAttemptId: entity.completionAttemptId,
      scheduleDate: entity.scheduleDate,
      startTime: entity.startTime,
      scheduleTitle: entity.scheduleTitle,
      localPath: entity.localPath,
      pathKind: entity.pathKind,
      capturedAt: entity.capturedAt,
      completedAt: entity.completedAt,
      status: entity.status,
      cloudObjectPath: entity.cloudObjectPath,
      uploadStatus: entity.uploadStatus,
      rewardStatus: entity.rewardStatus,
      reversedAt: entity.reversedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'schedule_item_id': scheduleItemId,
      'reward_eligibility_id': rewardEligibilityId,
      'completion_attempt_id': completionAttemptId,
      'schedule_date': scheduleDate,
      'start_time': startTime,
      'schedule_title': scheduleTitle,
      'local_path': localPath,
      'path_kind': pathKind,
      'captured_at': capturedAt,
      'completed_at': completedAt,
      'status': status,
      'cloud_object_path': cloudObjectPath,
      'upload_status': uploadStatus,
      'reward_status': rewardStatus,
      'reversed_at': reversedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static String _string(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

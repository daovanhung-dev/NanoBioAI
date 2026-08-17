import '../../application/schedule_health_checkin_reward_gateway.dart';
import '../../application/schedule_reward_online_gateway.dart';
import '../../domain/entities/daily_health_snapshot_entity.dart';
import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../domain/entities/manual_health_task_draft.dart';
import '../../domain/entities/schedule_health_action_type.dart';
import '../../domain/entities/schedule_health_reward_attempt_entity.dart';
import '../../domain/repositories/daily_health_hub_repository.dart';
import '../../domain/services/schedule_health_action_policy.dart';

class DailyHealthHubActionResult {
  final bool succeeded;
  final String message;
  final int pointsDelta;

  const DailyHealthHubActionResult({
    required this.succeeded,
    required this.message,
    this.pointsDelta = 0,
  });
}

class DailyHealthHubController {
  final DailyHealthHubRepository repository;
  final ScheduleHealthCheckInRewardGateway rewardGateway;
  final Future<void> Function() refreshSchedule;
  final Future<void> Function() rescheduleReminders;
  final void Function(DateTime date) invalidateSnapshot;

  const DailyHealthHubController({
    required this.repository,
    required this.rewardGateway,
    required this.refreshSchedule,
    required this.rescheduleReminders,
    required this.invalidateSnapshot,
  });

  Future<DailyHealthHubActionResult> recordStandaloneCheckIn({
    required DateTime date,
    required DailyHealthCheckInInput input,
  }) async {
    try {
      await repository.recordStandaloneCheckIn(date: date, input: input);
      invalidateSnapshot(date);
      return const DailyHealthHubActionResult(
        succeeded: true,
        message: 'Đã lưu ghi nhận sức khỏe hôm nay.',
      );
    } catch (error) {
      return DailyHealthHubActionResult(
        succeeded: false,
        message: _userMessage(error),
      );
    }
  }

  Future<DailyHealthHubActionResult> createManualTask(
    ManualHealthTaskDraft draft,
  ) async {
    try {
      await repository.createManualTaskSeries(draft);
      await _refreshAfterScheduleWrite();
      return const DailyHealthHubActionResult(
        succeeded: true,
        message: 'Nhiệm vụ chăm sóc đã được thêm vào lịch.',
      );
    } catch (error) {
      return DailyHealthHubActionResult(
        succeeded: false,
        message: _userMessage(error),
      );
    }
  }

  Future<DailyHealthHubActionResult> replaceManualTask({
    required LifestyleScheduleItemEntity existingItem,
    required ManualHealthTaskDraft draft,
  }) async {
    try {
      await repository.replaceManualTaskSeries(
        existingItem: existingItem,
        draft: draft,
      );
      await _refreshAfterScheduleWrite();
      return const DailyHealthHubActionResult(
        succeeded: true,
        message: 'Đã cập nhật nhiệm vụ cho các ngày tiếp theo.',
      );
    } catch (error) {
      return DailyHealthHubActionResult(
        succeeded: false,
        message: _userMessage(error),
      );
    }
  }

  Future<DailyHealthHubActionResult> deleteManualTask(
    LifestyleScheduleItemEntity item,
  ) async {
    try {
      await repository.deleteManualTaskSeries(item);
      await _refreshAfterScheduleWrite();
      return const DailyHealthHubActionResult(
        succeeded: true,
        message: 'Đã xóa nhiệm vụ tự tạo khỏi các ngày tiếp theo.',
      );
    } catch (error) {
      return DailyHealthHubActionResult(
        succeeded: false,
        message: _userMessage(error),
      );
    }
  }

  Future<DailyHealthHubActionResult> completeTask({
    required LifestyleScheduleItemEntity item,
    DailyHealthCheckInInput input = const DailyHealthCheckInInput(),
  }) async {
    final action = ScheduleHealthActionPolicy.forItem(item);
    if (action == ScheduleHealthActionType.photoProof) {
      return const DailyHealthHubActionResult(
        succeeded: false,
        message: 'Nhiệm vụ này cần hoàn thành bằng ảnh minh chứng.',
      );
    }

    try {
      final shouldQueueReward = rewardGateway.hasAuthenticatedUser;
      final updated = await repository.completeCheckInTask(
        item: item,
        input: input,
        queueReward: shouldQueueReward,
      );
      invalidateSnapshot(_parseDate(updated.scheduleDate));
      await refreshSchedule();
      await _rescheduleBestEffort();

      if (!shouldQueueReward) {
        return const DailyHealthHubActionResult(
          succeeded: true,
          message:
              'Nhiệm vụ đã hoàn thành. Đăng nhập trước khi thực hiện để hệ thống xét Điểm chăm sóc.',
        );
      }

      final attempt = await repository.latestRewardAttempt(updated.id);
      if (attempt == null) {
        return const DailyHealthHubActionResult(
          succeeded: true,
          message:
              'Nhiệm vụ đã hoàn thành. Điểm chăm sóc đang chờ hệ thống xác nhận.',
        );
      }
      return _syncRewardAttempt(updated, attempt, userFacing: true);
    } catch (error) {
      return DailyHealthHubActionResult(
        succeeded: false,
        message: _userMessage(error),
      );
    }
  }

  Future<DailyHealthHubActionResult> undoTask(
    LifestyleScheduleItemEntity item,
  ) async {
    final action = ScheduleHealthActionPolicy.forItem(item);
    if (action == ScheduleHealthActionType.photoProof) {
      return const DailyHealthHubActionResult(
        succeeded: false,
        message: 'Nhiệm vụ này cần hoàn tác bằng luồng ảnh minh chứng.',
      );
    }

    try {
      final attempt = await repository.latestRewardAttempt(item.id);
      var rewardUndoPending = false;
      if (attempt != null &&
          attempt.syncStatus != ScheduleHealthRewardAttemptStatuses.notEligible &&
          attempt.syncStatus != ScheduleHealthRewardAttemptStatuses.reversed) {
        if (rewardGateway.hasAuthenticatedUser) {
          try {
            await rewardGateway.undoCheckIn(
              scheduleItemId: item.id,
              idempotencyKey: attempt.undoIdempotencyKey,
            );
          } on ScheduleRewardException catch (error) {
            if (error.code != ScheduleRewardErrorCode.eligibilityUnavailable) {
              rewardUndoPending = true;
            }
          } catch (_) {
            rewardUndoPending = true;
          }
        } else {
          rewardUndoPending = true;
        }
      }

      final updated = await repository.undoCheckInTask(
        item,
        rewardUndoPending: rewardUndoPending,
      );
      invalidateSnapshot(_parseDate(updated.scheduleDate));
      await refreshSchedule();
      await _rescheduleBestEffort();
      return DailyHealthHubActionResult(
        succeeded: true,
        message: rewardUndoPending
            ? 'Đã hoàn tác nhiệm vụ. Phần Điểm chăm sóc sẽ tự đồng bộ lại khi có kết nối.'
            : 'Đã hoàn tác nhiệm vụ trong cửa sổ cho phép.',
      );
    } catch (error) {
      return DailyHealthHubActionResult(
        succeeded: false,
        message: _userMessage(error),
      );
    }
  }

  Future<void> reconcilePendingRewards() async {
    if (!rewardGateway.hasAuthenticatedUser) return;
    final pending = await repository.pendingRewardAttempts(limit: 12);
    for (final attempt in pending) {
      if (attempt.syncStatus == ScheduleHealthRewardAttemptStatuses.undoPending) {
        try {
          await rewardGateway.undoCheckIn(
            scheduleItemId: attempt.scheduleItemId,
            idempotencyKey: attempt.undoIdempotencyKey,
          );
          await repository.updateRewardAttempt(
            id: attempt.id,
            syncStatus: ScheduleHealthRewardAttemptStatuses.reversed,
            rewardStatus: 'reversed',
            pointsDelta: attempt.pointsDelta == 0
                ? null
                : -attempt.pointsDelta.abs(),
          );
        } on ScheduleRewardException catch (error) {
          if (error.code == ScheduleRewardErrorCode.eligibilityUnavailable) {
            await repository.updateRewardAttempt(
              id: attempt.id,
              syncStatus: ScheduleHealthRewardAttemptStatuses.reversed,
              rewardStatus: 'reversed',
            );
          }
        } catch (_) {
          // Durable undo remains queued for a later lifecycle retry.
        }
        continue;
      }

      final item = await repository.getScheduleItem(attempt.scheduleItemId);
      if (item == null || !item.isCompleted) continue;
      await _syncRewardAttempt(item, attempt, userFacing: false);
    }
  }

  Future<DailyHealthHubActionResult> _syncRewardAttempt(
    LifestyleScheduleItemEntity item,
    ScheduleHealthRewardAttemptEntity attempt, {
    required bool userFacing,
  }) async {
    try {
      final reward = await rewardGateway.finalizeCheckIn(
        item: item,
        actionType: attempt.actionType,
        input: attempt.input,
        idempotencyKey: attempt.finalizeIdempotencyKey,
      );
      await repository.updateRewardAttempt(
        id: attempt.id,
        syncStatus: ScheduleHealthRewardAttemptStatuses.confirmed,
        rewardStatus: reward.rewardStatus,
        pointsDelta: reward.pointsDelta,
      );
      if (reward.pointsDelta > 0) {
        return DailyHealthHubActionResult(
          succeeded: true,
          pointsDelta: reward.pointsDelta,
          message: userFacing
              ? 'Đã hoàn thành! +${reward.pointsDelta} Điểm chăm sóc đã được hệ thống xác nhận.'
              : '',
        );
      }
      return DailyHealthHubActionResult(
        succeeded: true,
        message: userFacing
            ? 'Nhiệm vụ đã hoàn thành. Lần này chưa có Điểm chăm sóc được xác nhận.'
            : '',
      );
    } on ScheduleRewardException catch (error) {
      final permanent = error.code == ScheduleRewardErrorCode.eligibilityUnavailable ||
          error.code == ScheduleRewardErrorCode.windowClosed;
      if (permanent) {
        await repository.updateRewardAttempt(
          id: attempt.id,
          syncStatus: ScheduleHealthRewardAttemptStatuses.notEligible,
          rewardStatus: 'not_eligible',
          lastErrorCode: error.code.name,
        );
      }
      return DailyHealthHubActionResult(
        succeeded: true,
        message: userFacing
            ? permanent
                ? 'Nhiệm vụ đã hoàn thành. ${error.message}'
                : 'Nhiệm vụ đã hoàn thành. Điểm chăm sóc sẽ tự thử đồng bộ lại khi có kết nối.'
            : '',
      );
    } catch (_) {
      return DailyHealthHubActionResult(
        succeeded: true,
        message: userFacing
            ? 'Nhiệm vụ đã hoàn thành. Điểm chăm sóc sẽ tự thử đồng bộ lại khi có kết nối.'
            : '',
      );
    }
  }

  Future<void> _refreshAfterScheduleWrite() async {
    await refreshSchedule();
    await _rescheduleBestEffort();
  }

  Future<void> _rescheduleBestEffort() async {
    try {
      await rescheduleReminders();
    } catch (_) {
      // Schedule persistence remains authoritative if the OS denies reminders.
    }
  }

  DateTime _parseDate(String value) {
    return DateTime.tryParse(value) ?? DateTime.now();
  }

  String _userMessage(Object error) {
    if (error is FormatException) {
      final message = error.message.toString().trim();
      if (message.isNotEmpty) return message;
    }
    if (error is ScheduleRewardException) return error.message;
    final text = error.toString().replaceFirst('Exception: ', '').trim();
    if (text.isNotEmpty && !text.contains('StateError')) return text;
    return 'Nabi chưa thể cập nhật lịch chăm sóc lúc này. Bạn thử lại nhé.';
  }
}

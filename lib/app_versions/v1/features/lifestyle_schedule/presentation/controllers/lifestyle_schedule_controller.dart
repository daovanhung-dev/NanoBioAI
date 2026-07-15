import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../domain/entities/schedule_completion_proof_entity.dart';
import '../../domain/entities/lifestyle_schedule_summary_entity.dart';
import '../../domain/repositories/lifestyle_schedule_repository.dart';
import '../../domain/services/lifestyle_schedule_window_policy.dart';
import '../../domain/services/schedule_completion_exception.dart';
import '../../application/schedule_proof_image_service.dart';
import '../../application/schedule_reward_online_gateway.dart';
import '../../providers/lifestyle_schedule_provider.dart';
import 'lifestyle_schedule_state.dart';

enum LifestyleScheduleToggleResult {
  completed,
  undone,
  cancelled,
  requiresNoRewardConfirmation,
  pendingRewardSync,
  blocked,
  ignored,
}

class LifestyleScheduleController
    extends AsyncNotifier<LifestyleScheduleState> {
  late final LifestyleScheduleRepository _repository;
  late final ScheduleRewardOnlineGateway _rewardGateway;
  late final DateTime Function() _now;
  final Set<String> _busyItemIds = <String>{};

  @override
  Future<LifestyleScheduleState> build() async {
    _repository = ref.read(lifestyleScheduleRepositoryProvider);
    _rewardGateway = ref.read(scheduleRewardOnlineGatewayProvider);
    _now = ref.read(lifestyleScheduleClockProvider);
    final summary = await _repository.getWeekSchedule();
    final proofs = await _repository.getCompletionProofs();
    final selectedDate = _defaultSelectedDate(summary.availableDates);
    return LifestyleScheduleState(
      summary: summary,
      selectedDate: selectedDate,
      completionProofs: proofs,
    );
  }

  Future<void> refresh() async {
    final current = state.whenOrNull(data: (value) => value);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final summary = await _repository.getWeekSchedule(
        anchorDate: current?.selectedDate,
      );
      final proofs = await _repository.getCompletionProofs();
      final selectedDate = current?.selectedDate;
      return LifestyleScheduleState(
        summary: summary,
        selectedDate:
            selectedDate ?? _defaultSelectedDate(summary.availableDates),
        completionProofs: proofs,
      );
    });
  }

  Future<void> selectDate(DateTime date) async {
    final current = state.whenOrNull(data: (value) => value);
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        selectedDate: DateUtils.dateOnly(date),
        clearFocus: true,
      ),
    );
  }

  void focusItem(String itemId) {
    final current = state.whenOrNull(data: (value) => value);
    final normalized = itemId.trim();
    if (current == null || normalized.isEmpty) return;
    final match = current.summary.items
        .where((item) => item.id == normalized || item.sourceId == normalized)
        .firstOrNull;
    if (match == null) {
      state = AsyncData(
        current.copyWith(
          lastErrorMessage:
              'Nabi chưa tìm thấy nhiệm vụ từ thông báo. Bạn làm mới lịch trình nhé.',
          clearEncouragement: true,
        ),
      );
      return;
    }
    final date = DateTime.tryParse(match.scheduleDate);
    state = AsyncData(
      current.copyWith(
        selectedDate: date == null
            ? current.selectedDate
            : DateUtils.dateOnly(date),
        focusedItemId: match.id,
        clearError: true,
      ),
    );
  }

  Future<LifestyleScheduleToggleResult> toggleItem(
    LifestyleScheduleItemEntity item, {
    bool allowWithoutReward = false,
  }) async {
    final current = state.whenOrNull(data: (value) => value);
    if (current == null || !_busyItemIds.add(item.id)) {
      return LifestyleScheduleToggleResult.ignored;
    }

    final nextCompleted = !item.isCompleted;
    String? completionProofPath;
    var localCommitted = false;
    ScheduleRewardCompletionAttempt? remoteAttempt;
    try {
      final windowStatus = item.completionStatusAt(_now());
      if (item.scheduledAt == null) {
        state = AsyncData(
          current.copyWith(
            lastErrorMessage:
                'Ngày hoặc giờ của nhiệm vụ chưa hợp lệ. Nabi đã khóa thao tác để bảo vệ kết quả của bạn.',
            clearEncouragement: true,
          ),
        );
        return LifestyleScheduleToggleResult.blocked;
      }
      if (windowStatus != CompletionWindowStatus.open &&
          !(item.isCompleted && item.isWithinCompletionWindow(_now()))) {
        final message = windowStatus == CompletionWindowStatus.waiting
            ? 'Nhiệm vụ chưa đến giờ thực hiện. Bạn quay lại đúng giờ nhé.'
            : 'Nhiệm vụ đã hết thời gian thực hiện và được khóa.';
        state = AsyncData(
          current.copyWith(lastErrorMessage: message, clearEncouragement: true),
        );
        return LifestyleScheduleToggleResult.blocked;
      }

      if (nextCompleted) {
        try {
          remoteAttempt = await _rewardGateway.beginCompletion(
            scheduleItemId: item.id,
            idempotencyKey: 'begin:${item.id}:v1',
          );
        } on ScheduleRewardException catch (error) {
          if (!error.canContinueWithoutReward) rethrow;
          if (!allowWithoutReward) {
            return LifestyleScheduleToggleResult.requiresNoRewardConfirmation;
          }
        }

        completionProofPath = await ref
            .read(scheduleProofImageServiceProvider)
            .captureProofForItem(item.id);
        if (completionProofPath == null) {
          return LifestyleScheduleToggleResult.cancelled;
        }
        if (!item.isWithinCompletionWindow(_now())) {
          await ref
              .read(scheduleProofImageServiceProvider)
              .deleteProof(completionProofPath);
          completionProofPath = null;
          state = AsyncData(
            current.copyWith(
              lastErrorMessage:
                  'Cửa sổ hoàn thành đã kết thúc khi camera đóng. Nabi chưa đánh dấu nhiệm vụ này.',
              clearEncouragement: true,
            ),
          );
          return LifestyleScheduleToggleResult.blocked;
        }
      } else {
        final activeProof = _activeProofFor(item.id, current.completionProofs);
        if (_hasServerReward(activeProof)) {
          await _rewardGateway.undoCompletion(
            scheduleItemId: item.id,
            idempotencyKey: 'undo:${item.id}:v1',
          );
        }
      }

      final updated = await _repository.updateItemCompletion(
        item: item,
        isCompleted: nextCompleted,
        completionProofPath: completionProofPath,
        rewardEligibilityId: remoteAttempt?.eligibilityId,
        completionAttemptId: remoteAttempt?.attemptId,
        completionProofCloudObjectPath: remoteAttempt?.storagePath,
      );
      localCommitted = true;
      var proofs = await _repository.getCompletionProofs();
      final items = current.summary.items
          .map((existing) => existing.id == updated.id ? updated : existing)
          .toList();
      HapticFeedback.lightImpact();
      state = AsyncData(
        current.copyWith(
          summary: LifestyleScheduleSummaryEntity(
            userId: current.summary.userId,
            fullName: current.summary.fullName,
            items: items,
          ),
          completionProofs: proofs,
          lastEncouragement: updated.isCompleted ? updated.encouragement : null,
          clearError: true,
        ),
      );
      if (nextCompleted && remoteAttempt != null) {
        return _uploadAndFinalize(
          attempt: remoteAttempt,
          completionProofPath: completionProofPath!,
        );
      }
      return nextCompleted
          ? LifestyleScheduleToggleResult.completed
          : LifestyleScheduleToggleResult.undone;
    } catch (error) {
      if (completionProofPath != null && !localCommitted) {
        await ref
            .read(scheduleProofImageServiceProvider)
            .deleteProof(completionProofPath);
      }
      final message = switch (error) {
        ScheduleProofException() => error.message,
        ScheduleCompletionException() => error.message,
        ScheduleRewardException() => error.message,
        _ => 'Nabi chưa thể cập nhật nhiệm vụ lúc này. Mình thử lại sau nhé.',
      };
      state = AsyncData(
        current.copyWith(lastErrorMessage: message, clearEncouragement: true),
      );
      return LifestyleScheduleToggleResult.blocked;
    } finally {
      _busyItemIds.remove(item.id);
    }
  }

  Future<LifestyleScheduleToggleResult> _uploadAndFinalize({
    required ScheduleRewardCompletionAttempt attempt,
    required String completionProofPath,
  }) async {
    var uploaded = false;
    try {
      final file = await ref
          .read(scheduleProofImageServiceProvider)
          .resolveProofFile(completionProofPath);
      await _rewardGateway.uploadProof(attempt: attempt, file: file);
      uploaded = true;
      await _updateAttemptProof(
        attempt,
        uploadStatus: ScheduleProofUploadStatuses.uploaded,
        rewardStatus: ScheduleProofRewardStatuses.pending,
      );
      await _rewardGateway.finalizeCompletion(
        attempt: attempt,
        idempotencyKey: 'finalize:${attempt.attemptId}:v1',
      );
      await _updateAttemptProof(
        attempt,
        uploadStatus: ScheduleProofUploadStatuses.uploaded,
        rewardStatus: ScheduleProofRewardStatuses.confirmed,
      );
      await _refreshProofProjection(clearError: true);
      return LifestyleScheduleToggleResult.completed;
    } on ScheduleRewardException catch (error) {
      final permanent =
          error.code == ScheduleRewardErrorCode.windowClosed ||
          error.code == ScheduleRewardErrorCode.invalidProof ||
          error.code == ScheduleRewardErrorCode.eligibilityUnavailable;
      await _updateAttemptProofSafely(
        attempt,
        uploadStatus: uploaded
            ? ScheduleProofUploadStatuses.uploaded
            : ScheduleProofUploadStatuses.failed,
        rewardStatus: permanent
            ? ScheduleProofRewardStatuses.notEligible
            : ScheduleProofRewardStatuses.pending,
      );
      await _refreshProofProjection(
        message: permanent
            ? 'Nhiệm vụ và ảnh đã được lưu, nhưng lần này không đủ điều kiện cộng 10 Điểm chăm sóc.'
            : 'Nhiệm vụ và ảnh đã được lưu. Điểm chăm sóc đang chờ đồng bộ khi có mạng.',
      );
      return LifestyleScheduleToggleResult.pendingRewardSync;
    } catch (_) {
      await _updateAttemptProofSafely(
        attempt,
        uploadStatus: uploaded
            ? ScheduleProofUploadStatuses.uploaded
            : ScheduleProofUploadStatuses.failed,
        rewardStatus: ScheduleProofRewardStatuses.pending,
      );
      await _refreshProofProjection(
        message:
            'Nhiệm vụ và ảnh đã được lưu. Điểm chăm sóc đang chờ đồng bộ khi có mạng.',
      );
      return LifestyleScheduleToggleResult.pendingRewardSync;
    }
  }

  Future<void> reconcilePendingRewards() async {
    if (state.whenOrNull(data: (value) => value) == null) return;
    if (!_rewardGateway.hasAuthenticatedUser) return;
    final proofs = await _repository.getCompletionProofs();
    for (final proof in proofs) {
      if (proof.isReversed ||
          proof.rewardStatus == ScheduleProofRewardStatuses.confirmed ||
          proof.rewardStatus == ScheduleProofRewardStatuses.notEligible ||
          proof.rewardEligibilityId == null ||
          proof.completionAttemptId == null ||
          proof.cloudObjectPath == null ||
          !_busyItemIds.add(proof.scheduleItemId)) {
        continue;
      }
      final attempt = ScheduleRewardCompletionAttempt(
        eligibilityId: proof.rewardEligibilityId!,
        attemptId: proof.completionAttemptId!,
        storagePath: proof.cloudObjectPath!,
      );
      try {
        if (proof.uploadStatus != ScheduleProofUploadStatuses.uploaded) {
          final file = await ref
              .read(scheduleProofImageServiceProvider)
              .resolveProofFile(proof.localPath);
          if (await file.exists()) {
            await _rewardGateway.uploadProof(attempt: attempt, file: file);
            await _updateAttemptProof(
              attempt,
              uploadStatus: ScheduleProofUploadStatuses.uploaded,
              rewardStatus: ScheduleProofRewardStatuses.pending,
            );
          }
        }
        await _rewardGateway.finalizeCompletion(
          attempt: attempt,
          idempotencyKey: 'finalize:${attempt.attemptId}:v1',
        );
        await _updateAttemptProof(
          attempt,
          uploadStatus: ScheduleProofUploadStatuses.uploaded,
          rewardStatus: ScheduleProofRewardStatuses.confirmed,
        );
      } on ScheduleRewardException catch (error) {
        final permanent =
            error.code == ScheduleRewardErrorCode.windowClosed ||
            error.code == ScheduleRewardErrorCode.invalidProof ||
            error.code == ScheduleRewardErrorCode.eligibilityUnavailable;
        if (permanent) {
          await _updateAttemptProofSafely(
            attempt,
            uploadStatus: proof.uploadStatus,
            rewardStatus: ScheduleProofRewardStatuses.notEligible,
          );
        }
      } catch (_) {
        // Reconciler chạy nền và sẽ thử lại khi ứng dụng resume/làm mới.
      } finally {
        _busyItemIds.remove(proof.scheduleItemId);
      }
    }
    await _refreshProofProjection();
  }

  Future<void> _updateAttemptProof(
    ScheduleRewardCompletionAttempt attempt, {
    required String uploadStatus,
    required String rewardStatus,
  }) async {
    final proofs = await _repository.getCompletionProofs();
    final proof = proofs
        .where((entry) => entry.completionAttemptId == attempt.attemptId)
        .firstOrNull;
    if (proof == null) return;
    await _repository.updateCompletionProofRemoteState(
      proofId: proof.id,
      rewardEligibilityId: attempt.eligibilityId,
      completionAttemptId: attempt.attemptId,
      cloudObjectPath: attempt.storagePath,
      uploadStatus: uploadStatus,
      rewardStatus: rewardStatus,
    );
  }

  Future<void> _updateAttemptProofSafely(
    ScheduleRewardCompletionAttempt attempt, {
    required String uploadStatus,
    required String rewardStatus,
  }) async {
    try {
      await _updateAttemptProof(
        attempt,
        uploadStatus: uploadStatus,
        rewardStatus: rewardStatus,
      );
    } catch (_) {
      // Server là nguồn chuẩn; projection cục bộ sẽ được reconcile lần sau.
    }
  }

  Future<void> _refreshProofProjection({
    String? message,
    bool clearError = false,
  }) async {
    final current = state.whenOrNull(data: (value) => value);
    if (current == null) return;
    final proofs = await _repository.getCompletionProofs();
    state = AsyncData(
      current.copyWith(
        completionProofs: proofs,
        lastErrorMessage: message,
        clearError: clearError || message == null,
      ),
    );
  }

  ScheduleCompletionProofEntity? _activeProofFor(
    String itemId,
    List<ScheduleCompletionProofEntity> proofs,
  ) {
    return proofs
        .where((proof) => proof.scheduleItemId == itemId && !proof.isReversed)
        .firstOrNull;
  }

  bool _hasServerReward(ScheduleCompletionProofEntity? proof) {
    if (proof == null ||
        proof.rewardEligibilityId == null ||
        proof.completionAttemptId == null) {
      return false;
    }
    return proof.rewardStatus != ScheduleProofRewardStatuses.notEligible &&
        proof.rewardStatus != ScheduleProofRewardStatuses.reversed;
  }

  void dismissEncouragement() {
    final current = state.whenOrNull(data: (value) => value);
    if (current == null) return;
    state = AsyncData(current.copyWith(clearEncouragement: true));
  }

  void dismissError() {
    final current = state.whenOrNull(data: (value) => value);
    if (current == null) return;
    state = AsyncData(current.copyWith(clearError: true));
  }

  DateTime _defaultSelectedDate(List<DateTime> availableDates) {
    final today = DateUtils.dateOnly(
      LifestyleScheduleWindowPolicy.vietnamNow(),
    );
    if (availableDates.any((date) => DateUtils.isSameDay(date, today))) {
      return today;
    }
    if (availableDates.isNotEmpty) return availableDates.first;
    return today;
  }
}

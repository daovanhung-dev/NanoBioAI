import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/feedback/feedback.dart';
import 'package:nano_app/services/image_picker/image_picker_service.dart';

import '../../application/schedule_proof_image_service.dart';
import '../../application/schedule_reward_eligibility_reconciler.dart';
import '../../application/schedule_reward_online_gateway.dart';
import '../../domain/entities/lifestyle_schedule_item_entity.dart';
import '../../domain/entities/schedule_completion_proof_entity.dart';
import '../../domain/repositories/lifestyle_schedule_repository.dart';
import '../../domain/services/lifestyle_schedule_window_policy.dart';
import '../../domain/services/schedule_completion_exception.dart';
import '../../providers/lifestyle_schedule_provider.dart';
import 'lifestyle_schedule_state.dart';

enum LifestyleScheduleToggleResult {
  completed,
  undone,
  cancelled,
  pendingRewardSync,
  blocked,
  ignored,
}

class LifestyleScheduleController
    extends AsyncNotifier<LifestyleScheduleState> {
  late final LifestyleScheduleRepository _repository;
  late final ScheduleRewardOnlineGateway _rewardGateway;
  late final ScheduleRewardEligibilityReconciler _eligibilityReconciler;
  late final DateTime Function() _now;
  final Set<String> _busyItemIds = <String>{};

  bool get hasActiveCompletionFlow => _busyItemIds.isNotEmpty;

  @override
  Future<LifestyleScheduleState> build() async {
    _repository = ref.read(lifestyleScheduleRepositoryProvider);
    _rewardGateway = ref.read(scheduleRewardOnlineGatewayProvider);
    _eligibilityReconciler = ref.read(
      scheduleRewardEligibilityReconcilerProvider,
    );
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
    if (hasActiveCompletionFlow) return;
    final current = state.whenOrNull(data: (value) => value);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _reconcileRewardEligibilitySafely();
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
    LifestyleScheduleItemEntity item,
  ) async {
    final current = state.whenOrNull(data: (value) => value);
    if (current == null || !_busyItemIds.add(item.id)) {
      return LifestyleScheduleToggleResult.ignored;
    }

    final nextCompleted = !item.isCompleted;
    String? completionProofPath;
    String? localOnlyCompletionMessage;
    var localCommitted = false;
    ScheduleRewardCompletionAttempt? remoteAttempt;
    try {
      final now = _now();
      final windowStatus = item.completionStatusAt(now);
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
          !(item.isCompleted && item.isWithinCompletionWindow(now))) {
        final message = windowStatus == CompletionWindowStatus.waiting
            ? 'Nhiệm vụ chưa đến giờ thực hiện. Bạn quay lại đúng giờ nhé.'
            : 'Nhiệm vụ đã hết thời gian thực hiện và được khóa.';
        state = AsyncData(
          current.copyWith(lastErrorMessage: message, clearEncouragement: true),
        );
        return LifestyleScheduleToggleResult.blocked;
      }

      if (nextCompleted) {
        // Camera is the first user-facing action after a valid tap. Reward
        // availability must never make the completion button feel unresponsive.
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
                  'Cửa sổ hoàn thành đã kết thúc khi camera đóng. Nabi chưa đánh dấu nhiệm vụ này và chưa cộng điểm.',
              clearEncouragement: true,
            ),
          );
          return LifestyleScheduleToggleResult.blocked;
        }

        if (_rewardGateway.hasAuthenticatedUser) {
          // Eligibility may have been generated while offline. Reconcile only
          // after proof capture so a slow network never blocks opening camera.
          await _reconcileRewardEligibilitySafely();
          try {
            remoteAttempt = await _rewardGateway.beginCompletion(
              scheduleItemId: item.id,
              idempotencyKey: 'begin:${item.id}:v1',
            );
          } on ScheduleRewardException catch (error) {
            if (!error.canContinueWithoutReward) {
              await ref
                  .read(scheduleProofImageServiceProvider)
                  .deleteProof(completionProofPath);
              completionProofPath = null;
              state = AsyncData(
                current.copyWith(
                  lastErrorMessage: error.message,
                  clearEncouragement: true,
                ),
              );
              return LifestyleScheduleToggleResult.blocked;
            }
            localOnlyCompletionMessage = _localOnlyCompletionMessage(error);
          } catch (_) {
            localOnlyCompletionMessage =
                'Ảnh vẫn được lưu trên thiết bị và nhiệm vụ vẫn có thể hoàn thành. '
                'Lần này chưa có Điểm chăm sóc vì kết nối xác nhận phần thưởng chưa sẵn sàng.';
          }
        } else {
          localOnlyCompletionMessage =
              'Ảnh sẽ được lưu trên thiết bị và nhiệm vụ vẫn được hoàn thành. '
              'Bạn cần đăng nhập và có kết nối mạng trước khi làm nhiệm vụ để nhận Điểm chăm sóc.';
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

      // The system camera resumes the app before this method returns. Always
      // rebuild the visible schedule from SQLite after the transaction instead
      // of mutating the pre-camera snapshot captured at method entry.
      await _reloadAuthoritativeProjection(
        fallback: current,
        encouragement: updated.isCompleted
            ? localOnlyCompletionMessage ?? updated.encouragement
            : null,
        clearError: true,
      );
      AppFeedbackService.instance.emit(AppFeedbackType.success);
      if (nextCompleted) {
        if (remoteAttempt == null) {
          return LifestyleScheduleToggleResult.completed;
        }
        return _uploadAndFinalize(
          attempt: remoteAttempt,
          completionProofPath: completionProofPath!,
        );
      }
      return LifestyleScheduleToggleResult.undone;
    } catch (error) {
      if (error is ScheduleCompletionException &&
          error.code == ScheduleCompletionErrorCode.alreadyCompleted &&
          nextCompleted) {
        // A lifecycle refresh or an earlier idempotent attempt may already have
        // committed this item. Treat that state as success, discard only the
        // newly captured orphan image, and reload SQLite as the source of truth.
        if (completionProofPath != null && !localCommitted) {
          await ref
              .read(scheduleProofImageServiceProvider)
              .deleteProof(completionProofPath);
          completionProofPath = null;
        }
        await _reloadAuthoritativeProjection(
          fallback: current,
          encouragement: 'Nhiệm vụ đã được ghi nhận hoàn thành.',
          clearError: true,
        );
        return LifestyleScheduleToggleResult.completed;
      }

      if (completionProofPath != null && !localCommitted) {
        await ref
            .read(scheduleProofImageServiceProvider)
            .deleteProof(completionProofPath);
      }
      final message = switch (error) {
        ScheduleProofException() => error.message,
        ImagePickerServiceException() => error.userMessage,
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
      final finalized = await _rewardGateway.finalizeCompletion(
        attempt: attempt,
        idempotencyKey: 'finalize:${attempt.attemptId}:v1',
      );
      if (finalized.pointsDelta <= 0) {
        throw const ScheduleRewardException(
          ScheduleRewardErrorCode.unknown,
          'Ảnh đã được ghi nhận nhưng hệ thống chưa xác nhận Điểm chăm sóc.',
          canContinueWithoutReward: false,
        );
      }
      await _updateAttemptProof(
        attempt,
        uploadStatus: ScheduleProofUploadStatuses.uploaded,
        rewardStatus: ScheduleProofRewardStatuses.confirmed,
      );
      await _refreshProofProjection(
        clearError: true,
        encouragement:
            'Đã hoàn thành! +${finalized.pointsDelta} Điểm chăm sóc đã được đồng bộ.',
      );
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
            ? '${error.message} Ảnh đã được lưu để Nabi hỗ trợ đối chiếu; nhiệm vụ chưa được coi là đã nhận điểm.'
            : 'Nhiệm vụ và ảnh đã được lưu. 10 Điểm chăm sóc đang chờ đồng bộ khi có mạng.',
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
            'Nhiệm vụ và ảnh đã được lưu. 10 Điểm chăm sóc đang chờ đồng bộ khi có mạng.',
      );
      return LifestyleScheduleToggleResult.pendingRewardSync;
    }
  }

  Future<void> reconcilePendingRewards() async {
    if (hasActiveCompletionFlow) return;
    if (state.whenOrNull(data: (value) => value) == null) return;
    if (!_rewardGateway.hasAuthenticatedUser) return;

    // Keep server eligibility projection warm before retrying proof/finalize.
    await _reconcileRewardEligibilitySafely();

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
        final finalized = await _rewardGateway.finalizeCompletion(
          attempt: attempt,
          idempotencyKey: 'finalize:${attempt.attemptId}:v1',
        );
        if (finalized.pointsDelta <= 0) {
          continue;
        }
        await _updateAttemptProof(
          attempt,
          uploadStatus: ScheduleProofUploadStatuses.uploaded,
          rewardStatus: ScheduleProofRewardStatuses.confirmed,
        );
      } on ScheduleRewardException catch (error) {
        final permanent =
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

  Future<void> _reconcileRewardEligibilitySafely() async {
    if (!_rewardGateway.hasAuthenticatedUser) return;
    try {
      await _eligibilityReconciler.registerPendingFutureSchedules();
    } catch (_) {
      // Eligibility registration is best-effort. The completion path decides
      // whether to continue as local-only based on beginCompletion result.
    }
  }

  String _localOnlyCompletionMessage(ScheduleRewardException error) {
    if (error.code == ScheduleRewardErrorCode.authenticationRequired) {
      return 'Ảnh đã được lưu trên thiết bị và nhiệm vụ vẫn được hoàn thành. '
          'Bạn cần đăng nhập và có kết nối mạng trước khi làm nhiệm vụ để nhận Điểm chăm sóc.';
    }
    if (error.code == ScheduleRewardErrorCode.eligibilityUnavailable) {
      return 'Ảnh đã được lưu trên thiết bị và nhiệm vụ vẫn được hoàn thành. '
          'Nhiệm vụ này chưa có xác nhận đủ điều kiện nhận Điểm chăm sóc.';
    }
    return 'Ảnh đã được lưu trên thiết bị và nhiệm vụ vẫn được hoàn thành. '
        'Lần này chưa có Điểm chăm sóc vì kết nối xác nhận phần thưởng chưa sẵn sàng.';
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

  Future<void> _reloadAuthoritativeProjection({
    required LifestyleScheduleState fallback,
    String? encouragement,
    String? message,
    bool clearError = false,
  }) async {
    final summary = await _repository.getWeekSchedule(
      anchorDate: fallback.selectedDate,
    );
    final proofs = await _repository.getCompletionProofs();
    final latest = state.whenOrNull(data: (value) => value) ?? fallback;
    state = AsyncData(
      latest.copyWith(
        summary: summary,
        selectedDate: fallback.selectedDate,
        completionProofs: proofs,
        lastEncouragement: encouragement,
        lastErrorMessage: message,
        clearEncouragement: encouragement == null,
        clearError: clearError || message == null,
      ),
    );
  }

  Future<void> _refreshProofProjection({
    String? message,
    bool clearError = false,
    String? encouragement,
  }) async {
    final current = state.whenOrNull(data: (value) => value);
    if (current == null) return;
    final proofs = await _repository.getCompletionProofs();
    state = AsyncData(
      current.copyWith(
        completionProofs: proofs,
        lastErrorMessage: message,
        lastEncouragement: encouragement,
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

import 'dart:io';
import 'dart:typed_data';

import 'package:nano_app/core/network/backend_api_client.dart';

class ScheduleRewardEligibilityItem {
  final String scheduleItemId;
  final String scheduleDate;
  final String startTime;
  final String title;
  final String sourceType;
  final String? sourceId;

  const ScheduleRewardEligibilityItem({
    required this.scheduleItemId,
    required this.scheduleDate,
    required this.startTime,
    required this.title,
    required this.sourceType,
    this.sourceId,
  });

  Map<String, Object?> toMap() => {
    'schedule_item_id': scheduleItemId,
    'schedule_date': scheduleDate,
    'start_time': startTime,
    'title': title,
    'source_type': sourceType,
    'source_id': sourceId,
  };
}

class ScheduleRewardRegistrationResult {
  final int registeredCount;
  final int existingCount;

  const ScheduleRewardRegistrationResult({
    required this.registeredCount,
    required this.existingCount,
  });
}

class ScheduleRewardCompletionAttempt {
  final String eligibilityId;
  final String attemptId;
  final String storagePath;
  final DateTime? windowEnd;

  const ScheduleRewardCompletionAttempt({
    required this.eligibilityId,
    required this.attemptId,
    required this.storagePath,
    this.windowEnd,
  });
}

class ScheduleRewardFinalizeResult {
  final String rewardStatus;
  final int pointsDelta;

  const ScheduleRewardFinalizeResult({
    required this.rewardStatus,
    required this.pointsDelta,
  });
}

enum ScheduleRewardErrorCode {
  authenticationRequired,
  eligibilityUnavailable,
  windowNotOpen,
  windowClosed,
  alreadyCompleted,
  invalidProof,
  uploadFailed,
  networkUnavailable,
  unknown,
}

class ScheduleRewardException implements Exception {
  final ScheduleRewardErrorCode code;
  final String message;
  final bool canContinueWithoutReward;

  const ScheduleRewardException(
    this.code,
    this.message, {
    this.canContinueWithoutReward = false,
  });

  factory ScheduleRewardException.fromStableCode(Object? value) {
    final normalized = value?.toString().trim().toLowerCase() ?? '';
    if (_containsAny(normalized, const ['auth_required', 'authentication'])) {
      return const ScheduleRewardException(
        ScheduleRewardErrorCode.authenticationRequired,
        'Bạn cần đăng nhập và có mạng để nhận Điểm chăm sóc.',
        canContinueWithoutReward: true,
      );
    }
    if (_containsAny(normalized, const [
      'eligibility_not_found',
      'eligibility_not_available',
      'not_eligible',
      'eligibility_unavailable',
      'schedule_request_not_eligible',
      'schedule_quota_commit_required',
      'health_subject_required',
      'member_account_required',
      'wellness_rewards_disabled',
    ])) {
      return const ScheduleRewardException(
        ScheduleRewardErrorCode.eligibilityUnavailable,
        'Nhiệm vụ này chưa đủ điều kiện nhận Điểm chăm sóc.',
        canContinueWithoutReward: true,
      );
    }
    if (_containsAny(normalized, const [
      'window_not_open',
      'schedule_window_not_open',
      'not_open',
      'too_early',
    ])) {
      return const ScheduleRewardException(
        ScheduleRewardErrorCode.windowNotOpen,
        'Nhiệm vụ chưa đến giờ thực hiện.',
      );
    }
    if (_containsAny(normalized, const [
      'window_closed',
      'window_expired',
      'schedule_window_locked',
      'undo_window_locked',
      'reward_cannot_be_undone',
      'proof_upload_outside_window',
      'too_late',
    ])) {
      return const ScheduleRewardException(
        ScheduleRewardErrorCode.windowClosed,
        'Nhiệm vụ đã hết cửa sổ 30 phút và được khóa.',
      );
    }
    if (_containsAny(normalized, const [
      'already_completed',
      'already_finalized',
      'schedule_already_completed',
    ])) {
      return const ScheduleRewardException(
        ScheduleRewardErrorCode.alreadyCompleted,
        'Nhiệm vụ này đã được xác nhận hoàn thành.',
      );
    }
    if (_containsAny(normalized, const [
      'invalid_proof',
      'invalid_storage_path',
      'storage_path_mismatch',
      'storage_path_required',
      'proof_not_found',
      'proof_not_uploaded',
      'proof_content_type_invalid',
      'proof_size_invalid',
      'completion_attempt_not_found',
      'completion_attempt_required',
      'completion_attempt_not_active',
      'active_proof_not_found',
      'invalid_mime',
      'file_too_large',
    ])) {
      return const ScheduleRewardException(
        ScheduleRewardErrorCode.invalidProof,
        'Ảnh minh chứng chưa hợp lệ. Bạn vui lòng chụp lại.',
      );
    }
    return const ScheduleRewardException(
      ScheduleRewardErrorCode.unknown,
      'Nabi chưa xác nhận được Điểm chăm sóc lúc này.',
    );
  }

  static ScheduleRewardException network() {
    return const ScheduleRewardException(
      ScheduleRewardErrorCode.networkUnavailable,
      'Thiết bị chưa kết nối được với hệ thống Điểm chăm sóc.',
      canContinueWithoutReward: true,
    );
  }

  @override
  String toString() => message;
}

abstract class ScheduleRewardOnlineGateway {
  bool get hasAuthenticatedUser;

  Future<ScheduleRewardRegistrationResult> registerEligibilities({
    required String requestId,
    required List<ScheduleRewardEligibilityItem> items,
    required String idempotencyKey,
  });

  Future<ScheduleRewardCompletionAttempt> beginCompletion({
    required String scheduleItemId,
    required String idempotencyKey,
  });

  Future<void> uploadProof({
    required ScheduleRewardCompletionAttempt attempt,
    required File file,
  });

  Future<ScheduleRewardFinalizeResult> finalizeCompletion({
    required ScheduleRewardCompletionAttempt attempt,
    required String idempotencyKey,
  });

  Future<ScheduleRewardFinalizeResult> undoCompletion({
    required String scheduleItemId,
    required String idempotencyKey,
  });

  Future<Uint8List> downloadProof(String storagePath);
}

class BackendScheduleRewardOnlineGateway
    implements ScheduleRewardOnlineGateway {
  static const bucketName = 'schedule-completion-proofs';
  static const maxProofBytes = 5 * 1024 * 1024;

  final BackendApiClient? clientOverride;

  const BackendScheduleRewardOnlineGateway({this.clientOverride});

  BackendApiClient get _client => clientOverride ?? BackendApiClient.shared;

  @override
  bool get hasAuthenticatedUser =>
      _client.currentUserId?.trim().isNotEmpty == true;

  @override
  Future<ScheduleRewardRegistrationResult> registerEligibilities({
    required String requestId,
    required List<ScheduleRewardEligibilityItem> items,
    required String idempotencyKey,
  }) async {
    if (requestId.trim().isEmpty ||
        idempotencyKey.trim().isEmpty ||
        items.isEmpty) {
      throw ScheduleRewardException.fromStableCode('eligibility_unavailable');
    }
    try {
      final row = await _client.requestMap(
        'POST',
        '/api/v1/schedule-rewards/eligibilities',
        body: {
          'request_id': requestId,
          'items': items.map((item) => item.toMap()).toList(growable: false),
          'idempotency_key': idempotencyKey,
        },
      );
      return ScheduleRewardRegistrationResult(
        registeredCount: _readInt(row['registered_count'] ?? row['count']),
        existingCount: _readInt(row['existing_count']),
      );
    } on BackendApiException catch (error) {
      throw _safeError(error);
    } catch (_) {
      throw ScheduleRewardException.network();
    }
  }

  @override
  Future<ScheduleRewardCompletionAttempt> beginCompletion({
    required String scheduleItemId,
    required String idempotencyKey,
  }) async {
    try {
      final row = await _client.requestMap(
        'POST',
        '/api/v1/schedule-rewards/completions/begin',
        body: {
          'schedule_item_id': scheduleItemId,
          'idempotency_key': idempotencyKey,
        },
      );
      final eligibilityId = _readString(row['eligibility_id']);
      final attemptId = _readString(row['attempt_id']);
      final storagePath = _readString(
        row['storage_path'] ?? row['object_path'],
      );
      if (eligibilityId.isEmpty || attemptId.isEmpty || storagePath.isEmpty) {
        throw ScheduleRewardException.fromStableCode(
          row['error_code'] ?? 'eligibility_unavailable',
        );
      }
      _validateOwnerPath(storagePath);
      return ScheduleRewardCompletionAttempt(
        eligibilityId: eligibilityId,
        attemptId: attemptId,
        storagePath: storagePath,
        windowEnd: DateTime.tryParse(row['window_end']?.toString() ?? ''),
      );
    } on BackendApiException catch (error) {
      throw _safeError(error);
    } on ScheduleRewardException {
      rethrow;
    } catch (_) {
      throw ScheduleRewardException.network();
    }
  }

  @override
  Future<void> uploadProof({
    required ScheduleRewardCompletionAttempt attempt,
    required File file,
  }) async {
    _validateOwnerPath(attempt.storagePath);
    final length = await file.length();
    if (length <= 0 || length > maxProofBytes) {
      throw ScheduleRewardException.fromStableCode('file_too_large');
    }
    try {
      await _client.uploadBytes(
        '/api/v1/schedule-rewards/completions/${Uri.encodeComponent(attempt.attemptId)}/proof',
        bytes: await file.readAsBytes(),
        fileName: 'completion.jpg',
        contentType: 'image/jpeg',
      );
    } on BackendApiException catch (error) {
      throw _safeError(error);
    } catch (_) {
      throw const ScheduleRewardException(
        ScheduleRewardErrorCode.uploadFailed,
        'Nabi chưa tải được ảnh minh chứng lên vùng lưu trữ riêng tư.',
        canContinueWithoutReward: true,
      );
    }
  }

  @override
  Future<ScheduleRewardFinalizeResult> finalizeCompletion({
    required ScheduleRewardCompletionAttempt attempt,
    required String idempotencyKey,
  }) async {
    _validateOwnerPath(attempt.storagePath);
    try {
      final row = await _client.requestMap(
        'POST',
        '/api/v1/schedule-rewards/completions/${Uri.encodeComponent(attempt.attemptId)}/finalize',
        body: {
          'storage_path': attempt.storagePath,
          'idempotency_key': idempotencyKey,
        },
      );
      return _finalizeResult(row);
    } on BackendApiException catch (error) {
      throw _safeError(error);
    } on ScheduleRewardException {
      rethrow;
    } catch (_) {
      throw ScheduleRewardException.network();
    }
  }

  @override
  Future<ScheduleRewardFinalizeResult> undoCompletion({
    required String scheduleItemId,
    required String idempotencyKey,
  }) async {
    try {
      final row = await _client.requestMap(
        'POST',
        '/api/v1/schedule-rewards/completions/undo',
        body: {
          'schedule_item_id': scheduleItemId,
          'idempotency_key': idempotencyKey,
        },
      );
      return _finalizeResult(row);
    } on BackendApiException catch (error) {
      throw _safeError(error);
    } on ScheduleRewardException {
      rethrow;
    } catch (_) {
      throw ScheduleRewardException.network();
    }
  }

  @override
  Future<Uint8List> downloadProof(String storagePath) async {
    _validateOwnerPath(storagePath);
    final attemptId = _attemptIdFromPath(storagePath);
    try {
      return await _client.downloadBytes(
        '/api/v1/schedule-rewards/completions/${Uri.encodeComponent(attemptId)}/proof',
      );
    } on BackendApiException catch (error) {
      throw _safeError(error);
    } catch (_) {
      throw ScheduleRewardException.network();
    }
  }

  ScheduleRewardFinalizeResult _finalizeResult(Map<String, Object?> row) {
    final errorCode = _readString(row['error_code']);
    if (errorCode.isNotEmpty || row['success'] == false) {
      throw ScheduleRewardException.fromStableCode(errorCode);
    }
    return ScheduleRewardFinalizeResult(
      rewardStatus: _readString(row['reward_status'], fallback: 'pending'),
      pointsDelta: _readInt(row['points_delta']),
    );
  }

  void _validateOwnerPath(String storagePath) {
    final userId = _client.currentUserId;
    final normalized = storagePath.trim();
    if (userId == null || userId.isEmpty) {
      throw ScheduleRewardException.fromStableCode('auth_required');
    }
    if (!normalized.startsWith('$userId/') ||
        normalized.contains('..') ||
        !normalized.toLowerCase().endsWith('.jpg')) {
      throw ScheduleRewardException.fromStableCode('invalid_storage_path');
    }
    _attemptIdFromPath(normalized);
  }

  String _attemptIdFromPath(String path) {
    final segments = path.split('/');
    if (segments.length != 3 || !segments.last.toLowerCase().endsWith('.jpg')) {
      throw ScheduleRewardException.fromStableCode('invalid_storage_path');
    }
    return segments.last.substring(0, segments.last.length - 4);
  }

  ScheduleRewardException _safeError(BackendApiException error) {
    final code = error.businessCode.toLowerCase();
    if (code.contains('eligibility_not_found')) {
      return const ScheduleRewardException(
        ScheduleRewardErrorCode.networkUnavailable,
        'Điểm chăm sóc đang chờ xác nhận. Nabi sẽ tự thử lại khi dữ liệu lịch được đồng bộ.',
        canContinueWithoutReward: true,
      );
    }
    if (code.contains('manual_reward_daily_limit')) {
      return const ScheduleRewardException(
        ScheduleRewardErrorCode.eligibilityUnavailable,
        'Bạn vẫn hoàn thành nhiệm vụ, nhưng hôm nay đã đạt giới hạn Điểm chăm sóc cho nhiệm vụ tự tạo.',
        canContinueWithoutReward: true,
      );
    }
    if (code.contains('health_action_not_rewardable') ||
        code.contains('health_action_mismatch') ||
        code.contains('manual_health_task_invalid') ||
        code.contains('health_checkin_invalid') ||
        code.contains('photo_proof_required') ||
        code.contains('health_checkin_not_found') ||
        code.contains('eligibility_reward_already_awarded') ||
        code.contains('idempotency_conflict')) {
      return const ScheduleRewardException(
        ScheduleRewardErrorCode.eligibilityUnavailable,
        'Nhiệm vụ đã được lưu nhưng lần ghi nhận này chưa đủ điều kiện nhận Điểm chăm sóc.',
        canContinueWithoutReward: true,
      );
    }
    final mapped = ScheduleRewardException.fromStableCode(code);
    return mapped.code == ScheduleRewardErrorCode.unknown
        ? ScheduleRewardException.network()
        : mapped;
  }
}

String _readString(Object? value, {String fallback = ''}) {
  final normalized = value?.toString().trim() ?? '';
  return normalized.isEmpty ? fallback : normalized;
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _containsAny(String value, List<String> candidates) {
  return candidates.any(value.contains);
}

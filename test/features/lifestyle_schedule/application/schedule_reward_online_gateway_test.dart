import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/application/schedule_reward_online_gateway.dart';

void main() {
  group('ScheduleRewardEligibilityItem', () {
    test('serializes the immutable server registration manifest', () {
      const item = ScheduleRewardEligibilityItem(
        scheduleItemId: 'schedule-1',
        scheduleDate: '2026-07-14',
        startTime: '08:30:15.250',
        title: 'Uống nước buổi sáng',
        sourceType: 'daily_health_task',
        sourceId: 'task-1',
      );

      expect(item.toMap(), {
        'schedule_item_id': 'schedule-1',
        'schedule_date': '2026-07-14',
        'start_time': '08:30:15.250',
        'title': 'Uống nước buổi sáng',
        'source_type': 'daily_health_task',
        'source_id': 'task-1',
      });
    });
  });

  group('ScheduleRewardException stable mapper', () {
    test('maps early and exact-30-minute closure separately', () {
      final notOpen = ScheduleRewardException.fromStableCode(
        'rpc: window_not_open',
      );
      final closed = ScheduleRewardException.fromStableCode('window_expired');

      expect(notOpen.code, ScheduleRewardErrorCode.windowNotOpen);
      expect(closed.code, ScheduleRewardErrorCode.windowClosed);
      expect(notOpen.canContinueWithoutReward, isFalse);
      expect(closed.canContinueWithoutReward, isFalse);
      expect(closed.message, contains('30 phút'));
    });

    test('allows local completion for auth and eligibility failures', () {
      final auth = ScheduleRewardException.fromStableCode('auth_required');

      expect(auth.code, ScheduleRewardErrorCode.authenticationRequired);
      expect(auth.canContinueWithoutReward, isTrue);
      for (final code in const [
        'eligibility_not_found',
        'eligibility_not_available',
        'eligibility_unavailable',
        'schedule_request_not_eligible',
        'schedule_quota_commit_required',
        'health_subject_required',
        'member_account_required',
        'wellness_rewards_disabled',
      ]) {
        final ineligible = ScheduleRewardException.fromStableCode(code);
        expect(
          ineligible.code,
          ScheduleRewardErrorCode.eligibilityUnavailable,
          reason: code,
        );
        expect(ineligible.canContinueWithoutReward, isTrue, reason: code);
      }
    });

    test('maps every backend time-window code without leaking it', () {
      for (final code in const [
        'schedule_window_not_open',
        'window_not_open',
      ]) {
        final exception = ScheduleRewardException.fromStableCode(code);
        expect(exception.code, ScheduleRewardErrorCode.windowNotOpen);
        expect(exception.message, isNot(contains(code)));
      }
      for (final code in const [
        'schedule_window_locked',
        'undo_window_locked',
        'reward_cannot_be_undone',
        'proof_upload_outside_window',
      ]) {
        final exception = ScheduleRewardException.fromStableCode(code);
        expect(exception.code, ScheduleRewardErrorCode.windowClosed);
        expect(exception.message, isNot(contains(code)));
      }
    });

    test('maps every proof validation code to invalidProof', () {
      for (final code in const [
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
      ]) {
        final exception = ScheduleRewardException.fromStableCode(code);
        expect(
          exception.code,
          ScheduleRewardErrorCode.invalidProof,
          reason: code,
        );
        expect(exception.message.trim(), isNotEmpty, reason: code);
        expect(exception.message, isNot(contains(code)), reason: code);
      }
    });

    test('maps idempotent completion responses consistently', () {
      for (final code in const [
        'already_completed',
        'already_finalized',
        'schedule_already_completed',
      ]) {
        expect(
          ScheduleRewardException.fromStableCode(code).code,
          ScheduleRewardErrorCode.alreadyCompleted,
        );
      }
    });

    test('unknown technical content falls back without leaking details', () {
      final exception = ScheduleRewardException.fromStableCode(
        'relation schedule_reward_eligibilities does not exist',
      );

      expect(exception.code, ScheduleRewardErrorCode.unknown);
      expect(exception.message, contains('Nabi'));
      expect(
        exception.message,
        isNot(contains('schedule_reward_eligibilities')),
      );
    });

    test('network failure explicitly allows a no-reward local path', () {
      final exception = ScheduleRewardException.network();

      expect(exception.code, ScheduleRewardErrorCode.networkUnavailable);
      expect(exception.canContinueWithoutReward, isTrue);
      expect(exception.toString(), exception.message);
    });
  });

  group('SupabaseScheduleRewardOnlineGateway input guards', () {
    test('rejects an empty eligibility registration before any RPC', () async {
      const gateway = SupabaseScheduleRewardOnlineGateway();

      await expectLater(
        gateway.registerEligibilities(
          requestId: '',
          items: const [],
          idempotencyKey: '',
        ),
        throwsA(
          isA<ScheduleRewardException>().having(
            (error) => error.code,
            'code',
            ScheduleRewardErrorCode.eligibilityUnavailable,
          ),
        ),
      );
    });

    test('exposes fixed private bucket and five-megabyte limit', () {
      expect(
        SupabaseScheduleRewardOnlineGateway.bucketName,
        'schedule-completion-proofs',
      );
      expect(
        SupabaseScheduleRewardOnlineGateway.maxProofBytes,
        5 * 1024 * 1024,
      );
    });
  });
}

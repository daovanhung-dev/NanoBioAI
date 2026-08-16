import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/application/schedule_proof_image_service.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/application/schedule_reward_eligibility_projection_store.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/application/schedule_reward_eligibility_reconciler.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/application/schedule_reward_online_gateway.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_item_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/lifestyle_schedule_summary_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/entities/schedule_completion_proof_entity.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/repositories/lifestyle_schedule_repository.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/services/schedule_completion_exception.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/presentation/controllers/lifestyle_schedule_controller.dart';
import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/providers/lifestyle_schedule_provider.dart';
import 'package:nano_app/services/image_picker/image_picker_service.dart';

void main() {
  final now = DateTime(2026, 8, 16, 11, 10);

  test('reward network failure still opens camera and commits local completion', () async {
    final item = _item();
    final repository = _FakeRepository(item);
    final proofService = _FakeProofImageService();
    final gateway = _FakeRewardGateway(
      authenticated: true,
      beginError: ScheduleRewardException.network(),
    );
    final container = _container(
      now: now,
      repository: repository,
      proofService: proofService,
      gateway: gateway,
    );
    addTearDown(container.dispose);

    await container.read(lifestyleScheduleControllerProvider.future);
    final result = await container
        .read(lifestyleScheduleControllerProvider.notifier)
        .toggleItem(item);

    expect(result, LifestyleScheduleToggleResult.completed);
    expect(proofService.captureCalls, 1);
    expect(repository.lastCompletedValue, isTrue);
    expect(repository.lastRewardEligibilityId, isNull);
    expect(repository.proofs.single.rewardStatus, ScheduleProofRewardStatuses.notEligible);

    final state = container.read(lifestyleScheduleControllerProvider).requireValue;
    expect(state.summary.items.single.isCompleted, isTrue);
    expect(state.lastEncouragement, contains('chưa có Điểm chăm sóc'));
  });

  test('authenticated completion uploads proof and confirms +10 reward', () async {
    final item = _item();
    final repository = _FakeRepository(item);
    final proofService = _FakeProofImageService();
    final gateway = _FakeRewardGateway(authenticated: true);
    final container = _container(
      now: now,
      repository: repository,
      proofService: proofService,
      gateway: gateway,
    );
    addTearDown(container.dispose);

    await container.read(lifestyleScheduleControllerProvider.future);
    final result = await container
        .read(lifestyleScheduleControllerProvider.notifier)
        .toggleItem(item);

    expect(result, LifestyleScheduleToggleResult.completed);
    expect(gateway.beginCalls, 1);
    expect(gateway.uploadCalls, 1);
    expect(gateway.finalizeCalls, 1);
    expect(repository.lastRewardEligibilityId, 'eligibility-1');
    expect(repository.proofs.single.rewardStatus, ScheduleProofRewardStatuses.confirmed);

    final state = container.read(lifestyleScheduleControllerProvider).requireValue;
    expect(state.lastEncouragement, contains('+10 Điểm chăm sóc'));
  });

  test('non-continuable reward rejection happens after camera and does not commit', () async {
    final item = _item();
    final repository = _FakeRepository(item);
    final proofService = _FakeProofImageService();
    final gateway = _FakeRewardGateway(
      authenticated: true,
      beginError: ScheduleRewardException.fromStableCode('window_closed'),
    );
    final container = _container(
      now: now,
      repository: repository,
      proofService: proofService,
      gateway: gateway,
    );
    addTearDown(container.dispose);

    await container.read(lifestyleScheduleControllerProvider.future);
    final result = await container
        .read(lifestyleScheduleControllerProvider.notifier)
        .toggleItem(item);

    expect(result, LifestyleScheduleToggleResult.blocked);
    expect(proofService.captureCalls, 1);
    expect(proofService.deleteCalls, 1);
    expect(repository.lastCompletedValue, isNull);
  });

  test('camera cancellation leaves the task pending', () async {
    final item = _item();
    final repository = _FakeRepository(item);
    final proofService = _FakeProofImageService(captureResult: null);
    final gateway = _FakeRewardGateway(authenticated: false);
    final container = _container(
      now: now,
      repository: repository,
      proofService: proofService,
      gateway: gateway,
    );
    addTearDown(container.dispose);

    await container.read(lifestyleScheduleControllerProvider.future);
    final result = await container
        .read(lifestyleScheduleControllerProvider.notifier)
        .toggleItem(item);

    expect(result, LifestyleScheduleToggleResult.cancelled);
    expect(proofService.captureCalls, 1);
    expect(repository.lastCompletedValue, isNull);
    expect(repository.proofs, isEmpty);
  });

  test('camera permission error is visible and keeps the task pending', () async {
    final item = _item();
    final repository = _FakeRepository(item);
    final proofService = _FakeProofImageService(
      captureError: const ImagePickerServiceException(
        kind: ImagePickerFailureKind.permission,
        userMessage:
            'Bạn cần cho phép NanoBio sử dụng máy ảnh để chụp minh chứng hoàn thành nhiệm vụ.',
      ),
    );
    final gateway = _FakeRewardGateway(authenticated: false);
    final container = _container(
      now: now,
      repository: repository,
      proofService: proofService,
      gateway: gateway,
    );
    addTearDown(container.dispose);

    await container.read(lifestyleScheduleControllerProvider.future);
    final result = await container
        .read(lifestyleScheduleControllerProvider.notifier)
        .toggleItem(item);

    expect(result, LifestyleScheduleToggleResult.blocked);
    expect(proofService.captureCalls, 1);
    expect(repository.lastCompletedValue, isNull);
    final state = container.read(lifestyleScheduleControllerProvider).requireValue;
    expect(state.lastErrorMessage, contains('cho phép NanoBio sử dụng máy ảnh'));
  });

  test('task at exact start time opens camera immediately', () async {
    final exactNow = DateTime(2026, 8, 16, 12, 30);
    final item = _item(startTime: '12:30');
    final repository = _FakeRepository(item);
    final proofService = _FakeProofImageService();
    final gateway = _FakeRewardGateway(authenticated: false);
    final container = _container(
      now: exactNow,
      repository: repository,
      proofService: proofService,
      gateway: gateway,
    );
    addTearDown(container.dispose);

    await container.read(lifestyleScheduleControllerProvider.future);
    final result = await container
        .read(lifestyleScheduleControllerProvider.notifier)
        .toggleItem(item);

    expect(result, LifestyleScheduleToggleResult.completed);
    expect(proofService.captureCalls, 1);
    expect(repository.lastCompletedValue, isTrue);
  });

  test('double tap is single-flight while camera flow is active', () async {
    final item = _item();
    final repository = _FakeRepository(item);
    final captureGate = Completer<void>();
    final proofService = _FakeProofImageService(captureGate: captureGate);
    final gateway = _FakeRewardGateway(authenticated: false);
    final container = _container(
      now: now,
      repository: repository,
      proofService: proofService,
      gateway: gateway,
    );
    addTearDown(container.dispose);

    await container.read(lifestyleScheduleControllerProvider.future);
    final controller = container.read(
      lifestyleScheduleControllerProvider.notifier,
    );
    final first = controller.toggleItem(item);
    await Future<void>.delayed(Duration.zero);
    final second = await controller.toggleItem(item);

    expect(second, LifestyleScheduleToggleResult.ignored);
    expect(proofService.captureCalls, 1);

    captureGate.complete();
    expect(await first, LifestyleScheduleToggleResult.completed);
    expect(repository.lastCompletedValue, isTrue);
  });

  test(
    'refresh is ignored while camera flow is active and completion reloads SQLite',
    () async {
      final item = _item();
      final repository = _FakeRepository(
        item,
        additionalItems: List.generate(
          10,
          (index) => item.copyWith(
            id: 'schedule-${index + 2}',
            sourceId: 'routine-${index + 2}',
            startTime: '${12 + (index ~/ 2)}:${index.isEven ? '00' : '30'}',
            title: 'Nhiệm vụ ${index + 2}',
          ),
        ),
      );
      final captureGate = Completer<void>();
      final proofService = _FakeProofImageService(captureGate: captureGate);
      final gateway = _FakeRewardGateway(authenticated: false);
      final container = _container(
        now: now,
        repository: repository,
        proofService: proofService,
        gateway: gateway,
      );
      addTearDown(container.dispose);

      await container.read(lifestyleScheduleControllerProvider.future);
      expect(repository.getWeekScheduleCalls, 1);

      final controller = container.read(
        lifestyleScheduleControllerProvider.notifier,
      );
      final completion = controller.toggleItem(item);
      await Future<void>.delayed(Duration.zero);

      expect(controller.hasActiveCompletionFlow, isTrue);
      await controller.refresh();
      expect(repository.getWeekScheduleCalls, 1);

      captureGate.complete();
      expect(await completion, LifestyleScheduleToggleResult.completed);

      final state = container
          .read(lifestyleScheduleControllerProvider)
          .requireValue;
      expect(state.totalItems, 11);
      expect(state.completedItems, 1);
      expect(state.lastErrorMessage, isNull);
      expect(repository.getWeekScheduleCalls, 2);
    },
  );

  test(
    'already completed SQLite row is idempotent success and clears stale 0/11 UI',
    () async {
      final item = _item();
      final repository = _FakeRepository(
        item,
        additionalItems: List.generate(
          10,
          (index) => item.copyWith(
            id: 'schedule-${index + 2}',
            sourceId: 'routine-${index + 2}',
            startTime: '${12 + (index ~/ 2)}:${index.isEven ? '00' : '30'}',
            title: 'Nhiệm vụ ${index + 2}',
          ),
        ),
      );
      final proofService = _FakeProofImageService();
      final gateway = _FakeRewardGateway(authenticated: false);
      final container = _container(
        now: now,
        repository: repository,
        proofService: proofService,
        gateway: gateway,
      );
      addTearDown(container.dispose);

      await container.read(lifestyleScheduleControllerProvider.future);

      // Simulate the database having been committed by the previous attempt
      // while Riverpod still holds the pre-camera pending snapshot.
      repository.item = item.copyWith(
        isCompleted: true,
        currentValue: item.targetValue,
        completionProofPath: 'schedule_proofs/existing.jpg',
        completionProofCapturedAt: '2026-08-16T11:09:59',
        completedAt: '2026-08-16T11:09:59',
      );
      repository.proofs.add(_existingProof(item));

      final result = await container
          .read(lifestyleScheduleControllerProvider.notifier)
          .toggleItem(item);

      expect(result, LifestyleScheduleToggleResult.completed);
      expect(proofService.captureCalls, 1);
      expect(proofService.deleteCalls, 1);

      final state = container
          .read(lifestyleScheduleControllerProvider)
          .requireValue;
      expect(state.totalItems, 11);
      expect(state.completedItems, 1);
      expect(state.lastErrorMessage, isNull);
      expect(state.lastEncouragement, contains('đã được ghi nhận hoàn thành'));
      expect(state.completionProofs, hasLength(1));
    },
  );

  test('guest completion remains local-only and never calls reward begin', () async {
    final item = _item();
    final repository = _FakeRepository(item);
    final proofService = _FakeProofImageService();
    final gateway = _FakeRewardGateway(authenticated: false);
    final container = _container(
      now: now,
      repository: repository,
      proofService: proofService,
      gateway: gateway,
    );
    addTearDown(container.dispose);

    await container.read(lifestyleScheduleControllerProvider.future);
    final result = await container
        .read(lifestyleScheduleControllerProvider.notifier)
        .toggleItem(item);

    expect(result, LifestyleScheduleToggleResult.completed);
    expect(gateway.beginCalls, 0);
    expect(proofService.captureCalls, 1);
    expect(repository.lastRewardEligibilityId, isNull);
  });
}

ProviderContainer _container({
  required DateTime now,
  required _FakeRepository repository,
  required _FakeProofImageService proofService,
  required _FakeRewardGateway gateway,
}) {
  return ProviderContainer(
    overrides: [
      lifestyleScheduleClockProvider.overrideWithValue(() => now),
      lifestyleScheduleRepositoryProvider.overrideWithValue(repository),
      scheduleProofImageServiceProvider.overrideWithValue(proofService),
      scheduleRewardOnlineGatewayProvider.overrideWithValue(gateway),
      scheduleRewardEligibilityReconcilerProvider.overrideWithValue(
        _NoopEligibilityReconciler(gateway),
      ),
    ],
  );
}

LifestyleScheduleItemEntity _item({String startTime = '11:00'}) {
  return LifestyleScheduleItemEntity(
    id: 'schedule-1',
    userId: 'user-1',
    scheduleDate: '2026-08-16',
    startTime: startTime,
    title: 'Đi bộ 10 phút',
    category: LifestyleScheduleCategories.body,
    sourceType: LifestyleScheduleSourceTypes.aiSchedule,
    sourceId: 'routine-walk',
    targetValue: 1,
    encouragement: 'Bạn đã hoàn thành nhiệm vụ.',
  );
}

ScheduleCompletionProofEntity _existingProof(
  LifestyleScheduleItemEntity item,
) {
  return ScheduleCompletionProofEntity(
    id: 'proof-existing',
    userId: item.userId,
    scheduleItemId: item.id,
    scheduleDate: item.scheduleDate,
    startTime: item.startTime,
    scheduleTitle: item.title,
    localPath: 'schedule_proofs/existing.jpg',
    capturedAt: '2026-08-16T11:09:59',
    completedAt: '2026-08-16T11:09:59',
    uploadStatus: ScheduleProofUploadStatuses.localOnly,
    rewardStatus: ScheduleProofRewardStatuses.notEligible,
    createdAt: '2026-08-16T11:09:59',
    updatedAt: '2026-08-16T11:09:59',
  );
}

class _FakeRepository implements LifestyleScheduleRepository {
  _FakeRepository(this.item, {this.additionalItems = const []});

  LifestyleScheduleItemEntity item;
  final List<LifestyleScheduleItemEntity> additionalItems;
  final List<ScheduleCompletionProofEntity> proofs = [];
  int getWeekScheduleCalls = 0;
  bool? lastCompletedValue;
  String? lastRewardEligibilityId;

  @override
  Future<LifestyleScheduleSummaryEntity> getWeekSchedule({DateTime? anchorDate}) async {
    getWeekScheduleCalls++;
    return LifestyleScheduleSummaryEntity(
      userId: 'user-1',
      fullName: 'Người dùng thử',
      items: [item, ...additionalItems],
    );
  }

  @override
  Future<LifestyleScheduleItemEntity> updateItemCompletion({
    required LifestyleScheduleItemEntity item,
    required bool isCompleted,
    String? completionProofPath,
    String? completionProofCapturedAt,
    String? rewardEligibilityId,
    String? completionAttemptId,
    String? completionProofCloudObjectPath,
  }) async {
    if (isCompleted && this.item.isCompleted) {
      throw const ScheduleCompletionException(
        ScheduleCompletionErrorCode.alreadyCompleted,
        'Nhiệm vụ này đã được hoàn thành rồi.',
      );
    }
    lastCompletedValue = isCompleted;
    lastRewardEligibilityId = rewardEligibilityId;
    this.item = item.copyWith(
      isCompleted: isCompleted,
      currentValue: isCompleted ? item.targetValue : 0,
      completionProofPath: completionProofPath,
      completionProofCapturedAt: isCompleted
          ? completionProofCapturedAt ?? '2026-08-16T11:10:00'
          : null,
      completedAt: isCompleted ? '2026-08-16T11:10:00' : null,
      clearCompletionProof: !isCompleted,
    );

    if (isCompleted) {
      proofs
        ..clear()
        ..add(
          ScheduleCompletionProofEntity(
            id: 'proof-1',
            userId: item.userId,
            scheduleItemId: item.id,
            rewardEligibilityId: rewardEligibilityId,
            completionAttemptId: completionAttemptId,
            scheduleDate: item.scheduleDate,
            startTime: item.startTime,
            scheduleTitle: item.title,
            localPath: completionProofPath!,
            capturedAt: '2026-08-16T11:10:00',
            completedAt: '2026-08-16T11:10:00',
            cloudObjectPath: completionProofCloudObjectPath,
            uploadStatus: rewardEligibilityId == null
                ? ScheduleProofUploadStatuses.localOnly
                : ScheduleProofUploadStatuses.pending,
            rewardStatus: rewardEligibilityId == null
                ? ScheduleProofRewardStatuses.notEligible
                : ScheduleProofRewardStatuses.pending,
            createdAt: '2026-08-16T11:10:00',
            updatedAt: '2026-08-16T11:10:00',
          ),
        );
    }
    return this.item;
  }

  @override
  Future<LifestyleScheduleItemEntity> completeItemById(
    String id, {
    String? completionProofPath,
    String? rewardEligibilityId,
    String? completionAttemptId,
    String? completionProofCloudObjectPath,
  }) {
    return updateItemCompletion(
      item: item,
      isCompleted: true,
      completionProofPath: completionProofPath,
      rewardEligibilityId: rewardEligibilityId,
      completionAttemptId: completionAttemptId,
      completionProofCloudObjectPath: completionProofCloudObjectPath,
    );
  }

  @override
  Future<List<ScheduleCompletionProofEntity>> getCompletionProofs() async {
    return List.unmodifiable(proofs);
  }

  @override
  Future<void> updateCompletionProofRemoteState({
    required String proofId,
    String? rewardEligibilityId,
    String? completionAttemptId,
    String? cloudObjectPath,
    String? uploadStatus,
    String? rewardStatus,
  }) async {
    final index = proofs.indexWhere((proof) => proof.id == proofId);
    if (index < 0) return;
    final current = proofs[index];
    proofs[index] = ScheduleCompletionProofEntity(
      id: current.id,
      userId: current.userId,
      scheduleItemId: current.scheduleItemId,
      rewardEligibilityId: rewardEligibilityId ?? current.rewardEligibilityId,
      completionAttemptId: completionAttemptId ?? current.completionAttemptId,
      scheduleDate: current.scheduleDate,
      startTime: current.startTime,
      scheduleTitle: current.scheduleTitle,
      localPath: current.localPath,
      pathKind: current.pathKind,
      capturedAt: current.capturedAt,
      completedAt: current.completedAt,
      status: current.status,
      cloudObjectPath: cloudObjectPath ?? current.cloudObjectPath,
      uploadStatus: uploadStatus ?? current.uploadStatus,
      rewardStatus: rewardStatus ?? current.rewardStatus,
      reversedAt: current.reversedAt,
      createdAt: current.createdAt,
      updatedAt: '2026-08-16T11:10:01',
    );
  }
}

class _FakeProofImageService extends ScheduleProofImageService {
  _FakeProofImageService({
    this.captureResult = 'schedule_proofs/schedule-1.jpg',
    this.captureGate,
    this.captureError,
  }) : super(imagePickerService: ImagePickerService());

  final String? captureResult;
  final Completer<void>? captureGate;
  final Object? captureError;
  int captureCalls = 0;
  int deleteCalls = 0;

  @override
  Future<String?> captureProofForItem(String itemId) async {
    captureCalls++;
    final gate = captureGate;
    if (gate != null) await gate.future;
    final error = captureError;
    if (error != null) throw error;
    return captureResult;
  }

  @override
  Future<File> resolveProofFile(String storedPath) async {
    return File('/tmp/nanobio-schedule-proof.jpg');
  }

  @override
  Future<void> deleteProof(String storedPath) async {
    deleteCalls++;
  }
}

class _FakeRewardGateway implements ScheduleRewardOnlineGateway {
  _FakeRewardGateway({
    required this.authenticated,
    this.beginError,
  });

  final bool authenticated;
  final ScheduleRewardException? beginError;
  int beginCalls = 0;
  int uploadCalls = 0;
  int finalizeCalls = 0;

  @override
  bool get hasAuthenticatedUser => authenticated;

  @override
  Future<ScheduleRewardRegistrationResult> registerEligibilities({
    required String requestId,
    required List<ScheduleRewardEligibilityItem> items,
    required String idempotencyKey,
  }) async {
    return ScheduleRewardRegistrationResult(
      registeredCount: items.length,
      existingCount: 0,
    );
  }

  @override
  Future<ScheduleRewardCompletionAttempt> beginCompletion({
    required String scheduleItemId,
    required String idempotencyKey,
  }) async {
    beginCalls++;
    final error = beginError;
    if (error != null) throw error;
    return const ScheduleRewardCompletionAttempt(
      eligibilityId: 'eligibility-1',
      attemptId: 'attempt-1',
      storagePath: 'user-1/eligibility-1/attempt-1.jpg',
    );
  }

  @override
  Future<void> uploadProof({
    required ScheduleRewardCompletionAttempt attempt,
    required File file,
  }) async {
    uploadCalls++;
  }

  @override
  Future<ScheduleRewardFinalizeResult> finalizeCompletion({
    required ScheduleRewardCompletionAttempt attempt,
    required String idempotencyKey,
  }) async {
    finalizeCalls++;
    return const ScheduleRewardFinalizeResult(
      rewardStatus: ScheduleProofRewardStatuses.confirmed,
      pointsDelta: 10,
    );
  }

  @override
  Future<ScheduleRewardFinalizeResult> undoCompletion({
    required String scheduleItemId,
    required String idempotencyKey,
  }) async {
    return const ScheduleRewardFinalizeResult(
      rewardStatus: ScheduleProofRewardStatuses.reversed,
      pointsDelta: -10,
    );
  }

  @override
  Future<Uint8List> downloadProof(String storagePath) async => Uint8List(0);
}

class _NoopProjectionStore implements ScheduleRewardEligibilityProjectionStore {
  @override
  Future<void> markRegistered({
    required String userId,
    required String requestId,
    required List<ScheduleRewardEligibilityItem> items,
  }) async {}
}

class _NoopEligibilityReconciler extends ScheduleRewardEligibilityReconciler {
  _NoopEligibilityReconciler(ScheduleRewardOnlineGateway gateway)
    : super(
        gateway: gateway,
        projectionStore: _NoopProjectionStore(),
        currentUserId: () => 'user-1',
      );

  @override
  Future<ScheduleRewardEligibilityReconcileResult>
  registerPendingFutureSchedules() async {
    return const ScheduleRewardEligibilityReconcileResult(
      requestsProcessed: 0,
      futureItemsProjected: 0,
    );
  }
}

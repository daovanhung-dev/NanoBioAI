import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/providers/dashboard_provider.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/cloud_sync.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/providers/membership_entitlement_providers.dart';

import '../application/cancel_membership_payment_request.dart';
import '../application/confirm_membership_payment_transfer.dart';
import '../application/create_membership_payment_request.dart';
import '../application/load_current_membership_payment_request.dart';
import '../application/read_membership_payment_payer_name.dart';
import '../data/datasources/membership_payment_payer_profile_local_datasource.dart';
import '../data/datasources/membership_payment_remote_datasource.dart';
import '../data/repositories/sqlite_membership_payment_payer_profile_repository.dart';
import '../data/repositories/supabase_membership_payment_repository.dart';
import '../domain/entities/membership_payment_models.dart';
import '../domain/repositories/membership_payment_payer_profile_repository.dart';
import '../domain/repositories/membership_payment_repository.dart';

final membershipPaymentCurrentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentAuthUserIdProvider);
});

final membershipPaymentRemoteDatasourceProvider =
    Provider<MembershipPaymentRemoteDatasource>((ref) {
      return const SupabaseMembershipPaymentRemoteDatasource();
    });

final membershipPaymentRepositoryProvider =
    Provider<MembershipPaymentRepository>((ref) {
      return SupabaseMembershipPaymentRepository(
        datasource: ref.watch(membershipPaymentRemoteDatasourceProvider),
      );
    });

final membershipPaymentPayerProfileLocalDatasourceProvider =
    Provider<MembershipPaymentPayerProfileLocalDatasource>((ref) {
      return const SqliteMembershipPaymentPayerProfileLocalDatasource();
    });

final membershipPaymentPayerProfileRepositoryProvider =
    Provider<MembershipPaymentPayerProfileRepository>((ref) {
      return SqliteMembershipPaymentPayerProfileRepository(
        datasource: ref.watch(
          membershipPaymentPayerProfileLocalDatasourceProvider,
        ),
      );
    });

final createMembershipPaymentRequestProvider =
    Provider<CreateMembershipPaymentRequest>((ref) {
      return CreateMembershipPaymentRequest(
        repository: ref.watch(membershipPaymentRepositoryProvider),
      );
    });

final loadCurrentMembershipPaymentRequestProvider =
    Provider<LoadCurrentMembershipPaymentRequest>((ref) {
      return LoadCurrentMembershipPaymentRequest(
        repository: ref.watch(membershipPaymentRepositoryProvider),
      );
    });

final confirmMembershipPaymentTransferProvider =
    Provider<ConfirmMembershipPaymentTransfer>((ref) {
      return ConfirmMembershipPaymentTransfer(
        repository: ref.watch(membershipPaymentRepositoryProvider),
      );
    });

final cancelMembershipPaymentRequestProvider =
    Provider<CancelMembershipPaymentRequest>((ref) {
      return CancelMembershipPaymentRequest(
        repository: ref.watch(membershipPaymentRepositoryProvider),
      );
    });

final readMembershipPaymentPayerNameProvider =
    Provider<ReadMembershipPaymentPayerName>((ref) {
      return ReadMembershipPaymentPayerName(
        repository: ref.watch(membershipPaymentPayerProfileRepositoryProvider),
      );
    });

/// Reconciles the local read-model after the trusted backend reports that a
/// payment succeeded. Effective access is invalidated separately and remains
/// authoritative even if this local projection refresh cannot complete.
final membershipPaymentApprovedProjectionRefreshProvider =
    Provider<Future<void> Function()>((ref) {
      return () async {
        final outcome = await ref
            .read(userDataSyncControllerProvider.notifier)
            .sync(AuthSyncReason.authGateRefresh);
        if (outcome.isSuccess) {
          ref.invalidate(dashboardProvider);
        }
      };
    });

final membershipPaymentIdempotencyKeyFactoryProvider =
    Provider<String Function(String planCode, String billingCycle)>((ref) {
      return (planCode, billingCycle) =>
          'membership-${planCode.trim()}-${billingCycle.trim()}-'
          '${DateTime.now().microsecondsSinceEpoch}';
    });

class MembershipPaymentViewState {
  final MembershipPaymentRequest? request;
  final String? payerFullName;

  const MembershipPaymentViewState({this.request, this.payerFullName});

  bool get hasPayerFullName => payerFullName?.trim().isNotEmpty == true;

  /// Prefer the server-snapshotted name attached to an existing payment while
  /// retaining the local profile value for the create-request prerequisite.
  String? get payerFullNameForDisplay {
    final snapshot = request?.payerFullName?.trim();
    if (snapshot != null && snapshot.isNotEmpty) return snapshot;
    return payerFullName;
  }
}

final membershipPaymentControllerProvider =
    AsyncNotifierProvider<
      MembershipPaymentController,
      MembershipPaymentViewState
    >(MembershipPaymentController.new);

class MembershipPaymentController
    extends AsyncNotifier<MembershipPaymentViewState> {
  String? _idempotencyKey;
  String? _idempotencyPlanCode;
  String? _idempotencyBillingCycle;
  String? _accessInvalidatedForPaymentId;

  @override
  Future<MembershipPaymentViewState> build() {
    return _load(ref.watch(membershipPaymentCurrentUserIdProvider));
  }

  Future<void> refresh({bool preserveVisibleStateOnError = false}) async {
    final userId = ref.read(membershipPaymentCurrentUserIdProvider);
    final previousState = state;
    if (!preserveVisibleStateOnError || previousState.value == null) {
      state = const AsyncLoading();
    }

    try {
      state = AsyncData(await _load(userId));
    } catch (error, stackTrace) {
      if (!preserveVisibleStateOnError || previousState.value == null) {
        state = AsyncError(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<MembershipPaymentRequest> createRequest({
    required String planCode,
    required String billingCycle,
  }) async {
    final existingRequest = state.value?.request;
    if (existingRequest != null && existingRequest.isActive) {
      return existingRequest;
    }
    if (existingRequest?.isTerminal == true) {
      _clearIdempotencyKey();
    }

    final userId = ref.read(membershipPaymentCurrentUserIdProvider)?.trim();
    if (userId == null || userId.isEmpty) {
      throw const MembershipPaymentException.authRequired();
    }

    final payerFullName = await ref
        .read(readMembershipPaymentPayerNameProvider)
        .execute(userId);
    if (payerFullName == null || payerFullName.trim().isEmpty) {
      throw const MembershipPaymentException.missingPayerName();
    }

    final idempotencyKey = _idempotencyKeyFor(planCode, billingCycle);
    MembershipPaymentRequest request;
    try {
      request = await ref
          .read(createMembershipPaymentRequestProvider)
          .execute(
            CreateMembershipPaymentRequestCommand(
              planCode: planCode,
              billingCycle: billingCycle,
              idempotencyKey: idempotencyKey,
              payerFullName: payerFullName,
            ),
          );
    } catch (error, stackTrace) {
      request = await _loadExistingOpenRequestOrRethrow(
        error: error,
        stackTrace: stackTrace,
      );
    }
    state = AsyncData(
      MembershipPaymentViewState(
        request: request,
        payerFullName: request.payerFullName ?? payerFullName,
      ),
    );
    _invalidateEffectiveAccessIfSucceeded(request);
    return request;
  }

  Future<MembershipPaymentRequest> confirmTransfer() async {
    final current = state.value?.request;
    if (current == null || !current.canConfirmTransfer) {
      throw const MembershipPaymentException.invalidTransferConfirmation();
    }

    final request = await ref
        .read(confirmMembershipPaymentTransferProvider)
        .execute(current.id);
    state = AsyncData(
      MembershipPaymentViewState(
        request: request,
        payerFullName: request.payerFullName ?? state.value?.payerFullName,
      ),
    );
    _invalidateEffectiveAccessIfSucceeded(request);
    return request;
  }

  Future<MembershipPaymentRequest> cancelRequest() async {
    final current = state.value?.request;
    if (current == null || !current.canCancel) {
      throw const MembershipPaymentException.invalidCancellation();
    }

    final payerFullName = state.value?.payerFullName;
    final request = await ref
        .read(cancelMembershipPaymentRequestProvider)
        .execute(current.id);
    state = AsyncData(
      MembershipPaymentViewState(
        request: request,
        payerFullName: request.payerFullName ?? payerFullName,
      ),
    );
    if (request.isTerminal) {
      _clearIdempotencyKey();
    }
    return request;
  }

  Future<MembershipPaymentViewState> _load(String? userId) async {
    final normalizedUserId = userId?.trim();
    if (normalizedUserId == null || normalizedUserId.isEmpty) {
      _clearIdempotencyKey();
      return const MembershipPaymentViewState();
    }

    final payerFullName = await ref
        .read(readMembershipPaymentPayerNameProvider)
        .execute(normalizedUserId);
    final request = await ref
        .read(loadCurrentMembershipPaymentRequestProvider)
        .execute();
    if (request?.isTerminal == true) {
      _clearIdempotencyKey();
    }
    _invalidateEffectiveAccessIfSucceeded(request);
    return MembershipPaymentViewState(
      request: request,
      payerFullName: request?.payerFullName ?? payerFullName,
    );
  }

  String _idempotencyKeyFor(String planCode, String billingCycle) {
    final normalizedPlanCode = planCode.trim();
    final normalizedBillingCycle = billingCycle.trim();
    final canReuse =
        _idempotencyKey != null &&
        _idempotencyPlanCode == normalizedPlanCode &&
        _idempotencyBillingCycle == normalizedBillingCycle;
    if (canReuse) return _idempotencyKey!;

    _idempotencyPlanCode = normalizedPlanCode;
    _idempotencyBillingCycle = normalizedBillingCycle;
    return _idempotencyKey = ref.read(
      membershipPaymentIdempotencyKeyFactoryProvider,
    )(normalizedPlanCode, normalizedBillingCycle);
  }

  void _clearIdempotencyKey() {
    _idempotencyKey = null;
    _idempotencyPlanCode = null;
    _idempotencyBillingCycle = null;
  }

  Future<MembershipPaymentRequest> _loadExistingOpenRequestOrRethrow({
    required Object error,
    required StackTrace stackTrace,
  }) async {
    if (!_isOpenMembershipPaymentRequestError(error)) {
      Error.throwWithStackTrace(error, stackTrace);
    }

    final request = await ref
        .read(loadCurrentMembershipPaymentRequestProvider)
        .execute();
    if (request != null && request.isActive) return request;

    Error.throwWithStackTrace(error, stackTrace);
  }

  void _invalidateEffectiveAccessIfSucceeded(
    MembershipPaymentRequest? request,
  ) {
    if (request?.isSucceeded != true) return;
    final paymentId = request?.id.trim();
    if (paymentId == null ||
        paymentId.isEmpty ||
        _accessInvalidatedForPaymentId == paymentId) {
      return;
    }

    _accessInvalidatedForPaymentId = paymentId;
    ref.invalidate(effectiveAccessProvider);
    unawaited(_refreshApprovedMembershipProjectionSafely());
  }

  Future<void> _refreshApprovedMembershipProjectionSafely() async {
    try {
      await ref.read(membershipPaymentApprovedProjectionRefreshProvider)();
    } catch (_) {
      // Effective access was already invalidated above. Local projection sync
      // remains retryable through the normal authenticated cloud-sync flow.
    }
  }
}

bool _isOpenMembershipPaymentRequestError(Object error) {
  return error.toString().toUpperCase().contains(
    'MEMBERSHIP_PAYMENT_REQUEST_ALREADY_OPEN',
  );
}

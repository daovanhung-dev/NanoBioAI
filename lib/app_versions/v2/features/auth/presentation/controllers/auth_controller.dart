import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/settings/providers/settings_provider.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_callback_result.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_commands.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_failure.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_route_state.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/entities/auth_sign_out_result.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/repositories/auth_repository.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_dependencies.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/cloud_sync.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/services/supabase/cloud_sync/user_data_sync_outbox.dart';

class AuthController extends AsyncNotifier<AuthRouteState> {
  AuthRepository get _repository => ref.read(v2AuthRepositoryProvider);

  Future<RegistrationResult>? _signUpInFlight;
  Future<void>? _signInInFlight;
  Future<void>? _authEventRefreshInFlight;

  @override
  Future<AuthRouteState> build() async {
    final availability = ref.watch(authBackendAvailabilityProvider);
    if (!availability.isReady) {
      return const AuthRouteState.unauthenticated();
    }

    // Auth events are invalidation signals, not the owner of route state. Using
    // ref.watch here makes Riverpod rebuild this notifier in the middle of a
    // successful sign-in, which can temporarily restore an unauthenticated
    // snapshot and bounce the first login back to the login page.
    ref.listen(v2AuthChangesProvider, (previous, next) {
      if (previous == null) return;
      final previousUserId = previous.value;
      final nextUserId = next.value;
      if (previousUserId == nextUserId ||
          _signInInFlight != null ||
          _signUpInFlight != null) {
        return;
      }
      unawaited(_refreshFromAuthEvent());
    });

    await _trySyncAfterAuth(
      AuthSyncReason.authGateRefresh,
      updateSyncState: false,
    );
    final next = await ref
        .watch(v2AuthRepositoryProvider)
        .resolveAuthRouteState();
    if (next.status == AuthRouteStatus.unauthenticated) {
      _invalidateLocalUserData();
    }
    return next;
  }

  Future<AuthRouteState> refresh() async {
    final availability = ref.read(authBackendAvailabilityProvider);
    if (!availability.isReady) {
      const nextState = AuthRouteState.unauthenticated();
      state = const AsyncData(nextState);
      return nextState;
    }

    try {
      await _trySyncAfterAuth(AuthSyncReason.authGateRefresh);
      final nextState = await _repository.resolveAuthRouteState();
      if (nextState.status == AuthRouteStatus.unauthenticated) {
        _invalidateLocalUserData();
      }
      state = AsyncData(nextState);
      return nextState;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<RegistrationResult> signUpWithEmail(RegisterCommand command) async {
    final active = _signUpInFlight;
    if (active != null) return active;

    final operation = _runAccountMutation(
      (repository) => repository.signUpWithEmail(command),
      syncReasonForResult: (result) => result == RegistrationResult.sessionReady
          ? AuthSyncReason.signUpSessionReady
          : null,
    );
    _signUpInFlight = operation;
    try {
      return await operation;
    } finally {
      if (identical(_signUpInFlight, operation)) _signUpInFlight = null;
    }
  }

  Future<void> signInWithEmail(LoginCommand command) async {
    final active = _signInInFlight;
    if (active != null) return active;

    final operation = _runAccountMutation(
      (repository) => repository.signInWithEmail(command),
      syncReason: AuthSyncReason.signIn,
    );
    _signInInFlight = operation;
    try {
      await operation;
    } finally {
      if (identical(_signInInFlight, operation)) _signInInFlight = null;
    }
  }

  Future<void> resendEmailConfirmation(String email) async {
    _ensureAuthBackendReady();
    await _repository.resendEmailConfirmation(email);
  }

  Future<void> sendPasswordRecovery(String email) async {
    _ensureAuthBackendReady();
    await _repository.sendPasswordRecovery(email);
  }

  Future<void> updatePassword(UpdatePasswordCommand command) {
    return _runAccountMutation(
      (repository) => repository.updatePassword(command),
    );
  }

  Future<AuthCallbackResult> recoverSessionFromUri(Uri uri) {
    return _runAccountMutation(
      (repository) => repository.recoverSessionFromUri(uri),
      syncReason: AuthSyncReason.authCallback,
    );
  }

  Future<AuthSignOutResult> signOut({
    bool force = false,
    Duration flushTimeout = const Duration(seconds: 8),
  }) async {
    _ensureAuthBackendReady();
    try {
      await ref
          .read(userDataSyncControllerProvider.notifier)
          .sync(AuthSyncReason.signOutPreflight)
          .timeout(flushTimeout);
    } catch (_) {}
    final pending = await UserDataSyncOutbox.shared
        .pendingCountForCurrentUser();

    if (pending > 0 && !force) {
      return AuthSignOutResult.confirmForce(
        pendingCount: pending,
        message:
            'Còn $pending thay đổi chưa gửi lên tài khoản. Bạn có thể thử lại '
            'hoặc vẫn đăng xuất; dữ liệu sẽ được giữ để đồng bộ ở lần đăng nhập sau.',
      );
    }

    try {
      await NotificationBootstrap.clearGeneratedReminders();
    } catch (error, stackTrace) {
      AppLogger.warning(
        'AUTH_CONTROLLER',
        'Notification cleanup skipped before sign-out: $error',
      );
      AppLogger.error(
        'AUTH_CONTROLLER',
        'Notification cleanup failed before sign-out',
        error,
        stackTrace,
      );
    }
    await _repository.signOut();
    _invalidateLocalUserData();
    ref.invalidate(userDataSyncControllerProvider);
    const next = AuthRouteState.unauthenticated();
    state = const AsyncData(next);
    return const AuthSignOutResult.completed();
  }

  Future<void> requestAccountDeletion() {
    return _runAccountMutation(
      (repository) => repository.requestAccountDeletion(),
    );
  }

  Future<T> _runAccountMutation<T>(
    Future<T> Function(AuthRepository repository) action, {
    AuthSyncReason? syncReason,
    AuthSyncReason? Function(T result)? syncReasonForResult,
  }) async {
    _ensureAuthBackendReady();
    final previousState = state;

    try {
      final result = await action(_repository);
      final resolvedSyncReason =
          syncReasonForResult?.call(result) ?? syncReason;
      if (resolvedSyncReason != null) {
        await _trySyncAfterAuth(resolvedSyncReason);
      }
      final nextState = await _repository.resolveAuthRouteState();
      state = AsyncData(nextState);
      return result;
    } catch (_) {
      state = previousState;
      rethrow;
    }
  }

  Future<void> _refreshFromAuthEvent() async {
    final active = _authEventRefreshInFlight;
    if (active != null) return active;

    final operation = _refreshFromAuthEventInternal();
    _authEventRefreshInFlight = operation;
    try {
      await operation;
    } finally {
      if (identical(_authEventRefreshInFlight, operation)) {
        _authEventRefreshInFlight = null;
      }
    }
  }

  Future<void> _refreshFromAuthEventInternal() async {
    try {
      await refresh();
    } catch (error, stackTrace) {
      AppLogger.warning('AUTH_CONTROLLER', 'Auth event refresh deferred: $error');
      AppLogger.error(
        'AUTH_CONTROLLER',
        'Auth event refresh failed',
        error,
        stackTrace,
      );
    }
  }

  void _ensureAuthBackendReady() {
    final availability = ref.read(authBackendAvailabilityProvider);
    if (!availability.isReady) {
      throw authBackendUnavailableFailure(availability);
    }
  }

  Future<void> _syncAfterAuth(
    AuthSyncReason reason, {
    bool updateSyncState = true,
  }) async {
    final result = updateSyncState
        ? await ref.read(userDataSyncControllerProvider.notifier).sync(reason)
        : await ref
              .read(authenticatedUserDataSyncRepositoryProvider)
              .syncAfterAuthenticatedSession(reason);

    if (result.pulledAnyData) {
      _invalidateLocalUserData();
    }
  }

  Future<void> _refreshRemindersAfterAuth() async {
    try {
      await NotificationBootstrap.scheduleGeneratedReminders();
    } catch (error, stackTrace) {
      AppLogger.warning(
        'AUTH_CONTROLLER',
        'Notification refresh skipped after cloud sync: $error',
      );
      AppLogger.error(
        'AUTH_CONTROLLER',
        'Notification refresh failed after cloud sync',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _trySyncAfterAuth(
    AuthSyncReason reason, {
    bool updateSyncState = true,
  }) async {
    try {
      await _syncAfterAuth(reason, updateSyncState: updateSyncState);
    } catch (error, stackTrace) {
      AppLogger.warning(
        'AUTH_CONTROLLER',
        'Cloud sync deferred after ${reason.name}',
      );
      AppLogger.error(
        'AUTH_CONTROLLER',
        'Cloud sync failed after authenticated session',
        error,
        stackTrace,
      );
    } finally {
      await _refreshRemindersAfterAuth();
    }
  }

  void _invalidateLocalUserData() {
    invalidateUserScopedContainerProviders(ref);
  }
}

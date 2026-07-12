import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/domain/entities/cloud_sync_result.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';

import 'authenticated_sync_trigger_registry.dart';
import 'user_data_sync_outbox.dart';

class UserDataSyncOutboxRefresher with WidgetsBindingObserver {
  static const _tag = 'SYNC_OUTBOX_REFRESHER';

  static final shared = UserDataSyncOutboxRefresher();

  final UserDataSyncOutbox outbox;
  final Connectivity connectivity;
  final Duration minRefreshInterval;
  final Duration pollingInterval;
  final DateTime Function() _now;

  bool _started = false;
  bool _refreshing = false;
  DateTime? _lastRefreshAttemptAt;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _pollingTimer;

  UserDataSyncOutboxRefresher({
    UserDataSyncOutbox? outbox,
    Connectivity? connectivity,
    this.minRefreshInterval = const Duration(milliseconds: 500),
    this.pollingInterval = const Duration(seconds: 1),
    DateTime Function()? now,
  }) : outbox = outbox ?? UserDataSyncOutbox.shared,
       connectivity = connectivity ?? Connectivity(),
       _now = now ?? DateTime.now;

  void start({bool refreshImmediately = true}) {
    if (_started) return;

    WidgetsBinding.instance.addObserver(this);
    _connectivitySubscription = connectivity.onConnectivityChanged.listen(
      _handleConnectivityResults,
    );
    _pollingTimer = Timer.periodic(pollingInterval, (_) {
      unawaited(_refreshPendingIfNeeded());
    });
    _started = true;

    if (refreshImmediately) {
      unawaited(refreshIfDue(force: true));
    }
  }

  Future<void> dispose() async {
    if (!_started) return;

    WidgetsBinding.instance.removeObserver(this);
    await _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _started = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(refreshIfDue());
  }

  void _handleConnectivityResults(List<ConnectivityResult> results) {
    final online = results.any((result) => result != ConnectivityResult.none);
    if (!online) return;

    unawaited(refreshIfDue(force: true));
  }


  Future<void> _refreshPendingIfNeeded() async {
    final hasPendingUpload = await outbox.pendingCountForCurrentUser() > 0;
    final hasPendingPull = await AppPrefs.isCloudPullRetryPending();
    if (!hasPendingUpload && !hasPendingPull) return;
    await refreshIfDue(force: true);
  }

  Future<void> refreshIfDue({bool force = false}) async {
    if (_refreshing) return;

    final current = _now();
    final lastRefreshAttemptAt = _lastRefreshAttemptAt;
    if (!force &&
        lastRefreshAttemptAt != null &&
        current.difference(lastRefreshAttemptAt) < minRefreshInterval) {
      AppLogger.info(_tag, 'Skip outbox drain due to throttle');
      return;
    }

    _refreshing = true;
    _lastRefreshAttemptAt = current;

    try {
      final reason = force
          ? AuthSyncReason.connectivity
          : AuthSyncReason.resume;
      final handled = await AuthenticatedSyncTriggerRegistry.request(reason);
      if (!handled) await outbox.drainPending();
    } finally {
      _refreshing = false;
    }
  }
}

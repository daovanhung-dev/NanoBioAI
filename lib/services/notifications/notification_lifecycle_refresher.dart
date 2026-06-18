import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:nano_app/core/utils/logger/app_logger.dart';

import 'notification_startup_scheduler.dart';

class NotificationLifecycleRefresher with WidgetsBindingObserver {
  static const _tag = 'NOTIFICATION_LIFECYCLE';

  final NotificationStartupScheduler startupScheduler;
  final Duration minRefreshInterval;
  final DateTime Function() _now;

  bool _started = false;
  bool _refreshing = false;
  DateTime? _lastRefreshAttemptAt;

  NotificationLifecycleRefresher({
    required this.startupScheduler,
    this.minRefreshInterval = const Duration(minutes: 15),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  void start({bool refreshImmediately = true}) {
    if (_started) return;

    WidgetsBinding.instance.addObserver(this);
    _started = true;

    if (refreshImmediately) {
      unawaited(refreshIfDue(force: true));
    }
  }

  void dispose() {
    if (!_started) return;

    WidgetsBinding.instance.removeObserver(this);
    _started = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(handleLifecycleState(state));
  }

  Future<void> handleLifecycleState(AppLifecycleState state) async {
    if (state != AppLifecycleState.resumed) return;
    await refreshIfDue();
  }

  Future<void> refreshIfDue({bool force = false}) async {
    if (_refreshing) return;

    final now = _now();
    final lastRefreshAttemptAt = _lastRefreshAttemptAt;
    if (!force &&
        lastRefreshAttemptAt != null &&
        now.difference(lastRefreshAttemptAt) < minRefreshInterval) {
      AppLogger.info(_tag, 'Skip reminder refresh due to throttle');
      return;
    }

    _refreshing = true;
    _lastRefreshAttemptAt = now;

    try {
      await startupScheduler.refreshGeneratedReminders();
    } finally {
      _refreshing = false;
    }
  }
}

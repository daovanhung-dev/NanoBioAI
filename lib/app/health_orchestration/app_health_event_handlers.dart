import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/services/notifications/active_notification_subject.dart';
import 'package:nano_app/app_versions/v1/services/notifications/notification_bootstrap.dart';
import 'package:nano_app/core/health_events/health_domain_event.dart';
import 'package:nano_app/core/health_events/health_event_impact.dart';
import 'package:nano_app/core/health_events/health_event_priority.dart';
import 'package:nano_app/core/health_events/health_event_type.dart';
import 'package:nano_app/features/nabi/application/care/nabi_care_controller.dart';
import 'package:nano_app/features/nabi/domain/care/nabi_care_models.dart';
import 'package:nano_app/services/health_orchestration/health_event_handler.dart';

import 'riverpod_health_projection_invalidator.dart';

class AppProjectionRefreshHandler implements HealthEventHandler {
  final RiverpodHealthProjectionInvalidator invalidator;

  const AppProjectionRefreshHandler(this.invalidator);

  @override
  Future<void> handle(HealthDomainEvent event, HealthEventImpact impact) async {
    if (!await _isActiveSubject(event.subjectId)) return;
    invalidator.invalidateAll(impact.targets, subjectId: event.subjectId);
  }
}

class AppNotificationReconciliationHandler implements HealthEventHandler {
  const AppNotificationReconciliationHandler();

  @override
  Future<void> handle(HealthDomainEvent event, HealthEventImpact impact) async {
    if (!impact.reconcileNotifications ||
        !await _isActiveSubject(event.subjectId)) {
      return;
    }

    switch (event.type) {
      case HealthEventType.healthCheckInRecorded:
      case HealthEventType.profileUpdated:
      case HealthEventType.goalUpdated:
      case HealthEventType.goalCompleted:
        await NotificationBootstrap.refreshHealthCareReminders(
          subjectUserId: event.subjectId,
        );
        return;
      case HealthEventType.mealPlanUpdated:
      case HealthEventType.scheduleUpdated:
      case HealthEventType.taskRescheduled:
        await NotificationBootstrap.scheduleGeneratedReminders();
        return;
      case HealthEventType.sleepRiskDetected:
        // Sleep Safety owns its urgent native alert path. Do not create a
        // second generic local notification here.
        return;
      default:
        return;
    }
  }
}

class AppNabiCareEventHandler implements HealthEventHandler {
  final Ref ref;
  final Duration debounce;
  final Map<String, Timer> _timers = <String, Timer>{};
  final Map<String, HealthDomainEvent> _latest = <String, HealthDomainEvent>{};

  AppNabiCareEventHandler(
    this.ref, {
    this.debounce = const Duration(milliseconds: 750),
  });

  @override
  Future<void> handle(HealthDomainEvent event, HealthEventImpact impact) async {
    if (!impact.evaluateNabi || !await _isActiveSubject(event.subjectId)) return;

    if (event.priority == HealthEventPriority.safety) {
      _timers.remove(event.subjectId)?.cancel();
      _latest.remove(event.subjectId);
      unawaited(_refresh(event));
      return;
    }

    _latest[event.subjectId] = event;
    _timers.remove(event.subjectId)?.cancel();
    _timers[event.subjectId] = Timer(debounce, () {
      final latest = _latest.remove(event.subjectId);
      _timers.remove(event.subjectId);
      if (latest != null) unawaited(_refresh(latest));
    });
  }

  Future<void> _refresh(HealthDomainEvent event) async {
    if (!await _isActiveSubject(event.subjectId)) return;
    await ref.read(nabiCareControllerProvider.notifier).refresh(
          trigger: _triggerFor(event.type),
          subjectId: event.subjectId,
        );
  }

  NabiCareTrigger _triggerFor(HealthEventType type) {
    return switch (type) {
      HealthEventType.taskCompleted ||
      HealthEventType.taskSkipped ||
      HealthEventType.taskRescheduled ||
      HealthEventType.scheduleUpdated => NabiCareTrigger.taskChanged,
      _ => NabiCareTrigger.healthTrackingChanged,
    };
  }
}

Future<bool> _isActiveSubject(String subjectId) async {
  final active = (await resolveActiveNotificationSubject())?.trim();
  return active != null && active == subjectId.trim();
}

import 'package:nano_app/app_versions/v1/features/lifestyle_schedule/domain/services/lifestyle_schedule_window_policy.dart';
import 'package:nano_app/app_versions/v1/services/ai/generated_plan_request_store.dart';
import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/core/storage/localdb/tables/personal_schedule_ai_requests_table.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';
import 'package:sqflite/sqflite.dart';

import 'schedule_reward_eligibility_projection_store.dart';
import 'schedule_reward_online_gateway.dart';

class ScheduleRewardEligibilityReconcileResult {
  final int requestsProcessed;
  final int futureItemsProjected;

  const ScheduleRewardEligibilityReconcileResult({
    required this.requestsProcessed,
    required this.futureItemsProjected,
  });
}

class ScheduleRewardEligibilityReconciler {
  final ScheduleRewardOnlineGateway gateway;
  final ScheduleRewardEligibilityProjectionStore projectionStore;
  final Database? databaseOverride;
  final String? Function() currentUserId;
  final DateTime Function() now;

  ScheduleRewardEligibilityReconciler({
    required this.gateway,
    required this.projectionStore,
    this.databaseOverride,
    String? Function()? currentUserId,
    DateTime Function()? now,
  }) : currentUserId = currentUserId ?? currentSupabaseUserIdOrNull,
       now = now ?? LifestyleScheduleWindowPolicy.vietnamNow;

  Future<Database> _db() async => databaseOverride ?? DatabaseService.database;

  Future<ScheduleRewardEligibilityReconcileResult>
  registerPendingFutureSchedules() async {
    final userId = currentUserId()?.trim();
    if (userId == null || userId.isEmpty || !gateway.hasAuthenticatedUser) {
      return const ScheduleRewardEligibilityReconcileResult(
        requestsProcessed: 0,
        futureItemsProjected: 0,
      );
    }
    final db = await _db();
    final requestRows = await db.query(
      PersonalScheduleAiRequestsTable.tableName,
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, GeneratedPlanRequestStatuses.succeeded],
      orderBy: 'start_date ASC',
    );
    var requestsProcessed = 0;
    var futureItemsProjected = 0;
    final vietnamNow = LifestyleScheduleWindowPolicy.toVietnamWallClock(now());

    for (final row in requestRows) {
      final request = PersonalScheduleAiRequestRecord.fromMap(row);
      if (!request.isSucceeded ||
          (request.actorMode != GeneratedPlanActorModes.memberNew &&
              request.actorMode != GeneratedPlanActorModes.initialGuest) ||
          request.scheduleItemCount != request.days * 10 ||
          request.startDate == null) {
        continue;
      }
      final endDate = request.startDate!.add(Duration(days: request.days - 1));
      final scheduleRows = await db.query(
        'lifestyle_schedule_items',
        where: 'user_id = ? AND schedule_date >= ? AND schedule_date <= ?',
        whereArgs: [userId, _dateKey(request.startDate!), _dateKey(endDate)],
        orderBy: 'schedule_date ASC, sort_order ASC, start_time ASC',
      );
      if (scheduleRows.length != request.scheduleItemCount) continue;
      final items = scheduleRows
          .map(
            (item) => ScheduleRewardEligibilityItem(
              scheduleItemId: item['id']?.toString() ?? '',
              scheduleDate: item['schedule_date']?.toString() ?? '',
              startTime: item['start_time']?.toString() ?? '',
              title: item['title']?.toString() ?? 'Nhiệm vụ hằng ngày',
              sourceType: item['source_type']?.toString() ?? 'ai_schedule',
              sourceId: item['source_id']?.toString(),
            ),
          )
          .where((item) => item.scheduleItemId.isNotEmpty)
          .toList(growable: false);
      if (items.length != request.scheduleItemCount) continue;

      final futureItems = items
          .where((item) {
            final scheduledAt = LifestyleScheduleWindowPolicy.parseScheduledAt(
              scheduleDate: item.scheduleDate,
              startTime: item.startTime,
            );
            return scheduledAt != null && scheduledAt.isAfter(vietnamNow);
          })
          .toList(growable: false);
      final registrationItems =
          request.actorMode == GeneratedPlanActorModes.initialGuest
          ? futureItems
          : items;
      if (registrationItems.isEmpty) continue;

      try {
        await gateway.registerEligibilities(
          requestId: request.requestId,
          items: registrationItems,
          idempotencyKey: 'eligibility:${request.requestId}:v1',
        );
        await projectionStore.markRegistered(
          userId: userId,
          requestId: request.requestId,
          items: futureItems,
        );
        requestsProcessed++;
        futureItemsProjected += futureItems.length;
      } on ScheduleRewardException {
        // Retry ở lần đồng bộ/resume sau; không biến cloud sync thành thất bại.
      }
    }

    return ScheduleRewardEligibilityReconcileResult(
      requestsProcessed: requestsProcessed,
      futureItemsProjected: futureItemsProjected,
    );
  }

  String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

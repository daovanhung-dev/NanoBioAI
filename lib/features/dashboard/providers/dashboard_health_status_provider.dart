import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/features/dashboard/domain/entities/dashboard_health_status.dart';
import 'package:nano_app/features/dashboard/presentation/mappers/dashboard_health_status_mapper.dart';
import 'package:nano_app/features/dashboard/providers/dashboard_provider.dart';

/// Computed health status provider for the dashboard.
///
/// It keeps calculation logic outside the UI and derives health models from
/// the existing dashboardProvider data that already comes from local database.
final dashboardHealthStatusProvider =
    Provider<AsyncValue<DashboardHealthStatus>>((ref) {
  final dashboardAsync = ref.watch(dashboardProvider);

  return dashboardAsync.whenData(
    (dashboard) => DashboardHealthStatusMapper.fromDashboard(
      fullName: dashboard.fullName,
      heightCm: dashboard.heightCm,
      weightKg: dashboard.weightKg,
      bmi: dashboard.bmi,
      sleepQuality: dashboard.sleepQuality,
      activityLevel: dashboard.activityLevel,
      waterPerDay: dashboard.waterPerDay,
      conditions: dashboard.conditions,
      goals: dashboard.goals,
      concernText: dashboard.concernText,
    ),
  );
});

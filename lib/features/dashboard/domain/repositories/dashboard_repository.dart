// lib/features/dashboard/domain/repositories/dashboard_repository.dart
import '../entities/dashboard_entity.dart';

abstract class DashboardRepository {
  Future<DashboardEntity> fetchDashboard();
}
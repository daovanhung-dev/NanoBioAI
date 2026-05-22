// lib/features/dashboard/data/repositories/dashboard_repository_impl.dart
import 'package:nano_app/features/dashboard/data/datasources/dashboard_local_datasource.dart';
import '../../domain/entities/dashboard_entity.dart';
import '../../domain/repositories/dashboard_repository.dart';


class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardLocalDatasource datasource;

  DashboardRepositoryImpl({
    required this.datasource,
  });

  @override
  Future<DashboardEntity> fetchDashboard() {
    return datasource.fetchDashboard();
  }
}
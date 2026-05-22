// lib/features/dashboard/providers/dashboard_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/features/dashboard/data/datasources/dashboard_local_datasource.dart';
import 'package:nano_app/features/dashboard/domain/repositories/dashboard_repository_impl.dart';


import '../domain/entities/dashboard_entity.dart';
import '../domain/repositories/dashboard_repository.dart';

final dashboardDatasourceProvider = Provider<DashboardLocalDatasource>((ref) {
  return const DashboardLocalDatasource();
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    datasource: ref.read(dashboardDatasourceProvider),
  );
});

final dashboardProvider = FutureProvider<DashboardEntity>((ref) async {
  final repository = ref.read(dashboardRepositoryProvider);
  return repository.fetchDashboard();
});
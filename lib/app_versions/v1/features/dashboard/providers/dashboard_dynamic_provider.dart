import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nano_app/core/storage/localdb/database_service.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/data/datasources/dashboard_dynamic_local_datasource.dart';
import 'package:nano_app/app_versions/v1/features/dashboard/domain/entities/dashboard_dynamic_entity.dart';

final dashboardDynamicLocalDatasourceProvider =
    FutureProvider<DashboardDynamicLocalDatasource>((ref) async {
      final db = await DatabaseService.database;
      return DashboardDynamicLocalDatasource(db);
    });

final dashboardDynamicProvider = FutureProvider<DashboardDynamicEntity>((
  ref,
) async {
  final datasource = await ref.watch(
    dashboardDynamicLocalDatasourceProvider.future,
  );
  return datasource.fetch();
});

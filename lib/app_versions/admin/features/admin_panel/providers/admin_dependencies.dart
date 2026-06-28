import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/data/datasources/admin_supabase_datasource.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/data/repositories/admin_repository_impl.dart';
import 'package:nano_app/app_versions/admin/features/admin_panel/domain/repositories/admin_repository.dart';

final adminSupabaseDatasourceProvider = Provider<AdminSupabaseDatasource>((
  ref,
) {
  return const AdminSupabaseDatasource();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(
    datasource: ref.watch(adminSupabaseDatasourceProvider),
  );
});

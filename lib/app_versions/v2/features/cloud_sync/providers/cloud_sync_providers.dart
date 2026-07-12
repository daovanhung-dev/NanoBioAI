import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/sqlite_user_data_sync_local_datasource.dart';
import '../data/datasources/supabase_user_data_sync_remote_datasource.dart';
import '../data/repositories/authenticated_user_data_sync_repository_impl.dart';
import '../domain/entities/cloud_sync_result.dart';
import '../domain/repositories/authenticated_user_data_sync_repository.dart';
import '../presentation/controllers/user_data_sync_controller.dart';

final userDataSyncRemoteDatasourceProvider =
    Provider<SupabaseUserDataSyncRemoteDatasource>((ref) {
      return const SupabaseUserDataSyncRemoteDatasource();
    });

final userDataSyncLocalDatasourceProvider =
    Provider<SqliteUserDataSyncLocalDatasource>((ref) {
      return const SqliteUserDataSyncLocalDatasource();
    });

final authenticatedUserDataSyncRepositoryProvider =
    Provider<AuthenticatedUserDataSyncRepository>((ref) {
      return AuthenticatedUserDataSyncRepositoryImpl(
        remoteDatasource: ref.watch(userDataSyncRemoteDatasourceProvider),
        localDatasource: ref.watch(userDataSyncLocalDatasourceProvider),
      );
    });

final userDataSyncControllerProvider =
    NotifierProvider<UserDataSyncController, UserDataSyncState>(
      UserDataSyncController.new,
    );

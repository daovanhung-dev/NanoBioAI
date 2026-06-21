import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v2/features/auth/data/datasources/supabase_auth_remote_datasource.dart';
import 'package:nano_app/app_versions/v2/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:nano_app/app_versions/v2/features/auth/domain/repositories/auth_repository.dart';

final authEmailConfirmationRequiredProvider = Provider<bool>((ref) {
  if (!dotenv.isInitialized) return true;
  final value = dotenv.env['AUTH_CONFIRM_EMAIL_REQUIRED'];
  return value?.trim().toLowerCase() != 'false';
});

final v2AuthRemoteDatasourceProvider = Provider<SupabaseAuthRemoteDatasource>((
  ref,
) {
  return SupabaseAuthRemoteDatasource();
});

final v2AuthRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(
    datasource: ref.watch(v2AuthRemoteDatasourceProvider),
    requiresEmailConfirmation: ref.watch(authEmailConfirmationRequiredProvider),
  );
});

final v2AuthChangesProvider = StreamProvider<void>((ref) {
  return ref.watch(v2AuthRepositoryProvider).watchAuthChanges();
});

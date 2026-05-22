import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:nano_app/features/auth/data/datasource/auth_remote_datasource.dart';
import 'package:nano_app/features/auth/domain/repositories/auth_repository_impl.dart';


import '../domain/repositories/auth_repository.dart';
import '../presentation/controllers/login_controller.dart';

final authRemoteDatasourceProvider =
    Provider<AuthRemoteDatasource>((ref) {

  return AuthRemoteDatasource();

});

final authRepositoryProvider =
    Provider<AuthRepository>((ref) {

  return AuthRepositoryImpl(
    remoteDatasource:
        ref.read(authRemoteDatasourceProvider),
  );

});

final loginControllerProvider =
    StateNotifierProvider<
        LoginController,
        AsyncValue<void>>((ref) {

  return LoginController(
    ref.read(authRepositoryProvider),
  );

});
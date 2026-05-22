import 'package:nano_app/features/auth/data/datasource/auth_remote_datasource.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl
    implements AuthRepository {

  final AuthRemoteDatasource remoteDatasource;

  AuthRepositoryImpl({
    required this.remoteDatasource,
  });

  @override
  Future<void> login({
    required String email,
    required String password,
  }) async {

    await remoteDatasource.login(
      email: email,
      password: password,
    );
  }
}
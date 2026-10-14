import '../entities/auth_callback_result.dart';
import '../entities/auth_commands.dart';
import '../entities/auth_route_state.dart';

abstract class AuthRepository {
  Stream<String?> watchAuthChanges();

  Future<AuthRouteState> resolveAuthRouteState();

  Future<RegistrationResult> signUpWithPhone(RegisterCommand command);

  Future<void> signInWithPhone(LoginCommand command);

  Future<void> updatePassword(UpdatePasswordCommand command);

  Future<AuthCallbackResult> recoverSessionFromUri(Uri uri);

  Future<void> signOut();

  Future<void> requestAccountDeletion();
}

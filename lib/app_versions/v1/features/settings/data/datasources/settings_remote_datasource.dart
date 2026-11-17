import 'package:nano_app/core/network/backend_api_client.dart';
import 'package:nano_app/core/storage/nabi_esp_credential_vault.dart';

/// SettingsRemoteDatasource handles remote sign out for settings.
class SettingsRemoteDatasource {
  const SettingsRemoteDatasource({this.client});
  final BackendApiClient? client;

  /// Signs out the current user from the self-hosted backend.
  ///
  /// This method clears the backend session but does NOT clear local data.
  /// Local data clearing should be handled by the repository layer.
  ///
  Future<void> signOut() async {
    try {
      await (client ?? BackendApiClient.shared).signOut();
    } finally {
      try {
        await NabiEspCredentialVault.instance.clear();
      } catch (_) {
        // Do not prevent logout if local credential cleanup fails.
      }
    }
  }
}

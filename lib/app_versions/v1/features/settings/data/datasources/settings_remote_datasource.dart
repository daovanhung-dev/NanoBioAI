import 'package:nano_app/core/network/backend_api_client.dart';

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
    await (client ?? BackendApiClient.shared).signOut();
  }
}

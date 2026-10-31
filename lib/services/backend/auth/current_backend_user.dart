import 'package:nano_app/core/network/backend_api_client.dart';

String? currentBackendUserIdOrNull() {
  return BackendApiClient.shared.currentUserId;
}

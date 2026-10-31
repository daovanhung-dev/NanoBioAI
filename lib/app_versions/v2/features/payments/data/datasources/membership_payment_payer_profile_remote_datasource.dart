import 'package:nano_app/core/network/backend_api_client.dart';

abstract interface class MembershipPaymentPayerProfileRemoteDatasource {
  Future<String?> readFullName(String userId);
}

class BackendMembershipPaymentPayerProfileRemoteDatasource
    implements MembershipPaymentPayerProfileRemoteDatasource {
  final BackendApiClient? clientOverride;

  const BackendMembershipPaymentPayerProfileRemoteDatasource({
    this.clientOverride,
  });

  @override
  Future<String?> readFullName(String userId) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return null;
    final client = clientOverride ?? BackendApiClient.shared;
    if (client.currentUserId != normalizedUserId) return null;
    try {
      final profile = await client.requestMap('GET', '/api/v1/profile/me');
      return _readText(profile['full_name']);
    } on BackendApiException {
      rethrow;
    }
  }
}

String? _readText(Object? value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

import 'package:nano_app/core/network/backend_api_client.dart';

import 'nabi_esp_cloud_contract.g.dart';

class NabiEspPairingSession {
  const NabiEspPairingSession({
    required this.id,
    required this.token,
    required this.expiresIn,
  });

  final String id;
  final String token;
  final int expiresIn;
}

class NabiEspPairingStatus {
  const NabiEspPairingStatus({
    required this.status,
    this.deviceId,
    this.deviceName,
  });

  final String status;
  final String? deviceId;
  final String? deviceName;
}

class NabiEspDeviceConsent {
  const NabiEspDeviceConsent({
    this.identity = false,
    this.profileGoals = false,
    this.sensitiveHealth = false,
    this.recentTracking = false,
  });

  final bool identity;
  final bool profileGoals;
  final bool sensitiveHealth;
  final bool recentTracking;

  Map<String, Object?> toJson() => {
    'identity': identity,
    'profile_goals': profileGoals,
    'sensitive_health': sensitiveHealth,
    'recent_tracking': recentTracking,
  };

  factory NabiEspDeviceConsent.fromJson(Object? value) {
    final json = value is Map ? Map<String, Object?>.from(value) : const {};
    return NabiEspDeviceConsent(
      identity: json['identity'] == true,
      profileGoals: json['profile_goals'] == true,
      sensitiveHealth: json['sensitive_health'] == true,
      recentTracking: json['recent_tracking'] == true,
    );
  }
}

class NabiEspDevice {
  const NabiEspDevice({
    required this.id,
    required this.name,
    required this.connected,
    required this.createdAt,
    required this.consent,
  });

  final String id;
  final String name;
  final bool connected;
  final DateTime? createdAt;
  final NabiEspDeviceConsent consent;

  factory NabiEspDevice.fromJson(Map<String, Object?> json) => NabiEspDevice(
    id: json['device_id']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Nabi',
    connected: json['connected'] == true,
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    consent: NabiEspDeviceConsent.fromJson(json['consent']),
  );
}

/// Authenticated app operations for claiming and managing owner-bound ESPs.
/// Device access and refresh credentials are deliberately never returned to
/// this service; the ESP receives them after its local-AP claim reaches the server.
class NabiEspDeviceService {
  NabiEspDeviceService({BackendApiClient? client})
    : _client = client ?? BackendApiClient.shared;

  final BackendApiClient _client;

  Future<NabiEspPairingSession> createPairingSession() async {
    final json = await _client.requestMap(
      'POST',
      NabiEspCloudContract.pairingSessionPath,
    );
    final id = json['pairing_session_id']?.toString() ?? '';
    final token = json['pairing_token']?.toString() ?? '';
    final expiresIn = _asInt(json['expires_in']) ?? 0;
    if (id.isEmpty || token.length < 32 || expiresIn <= 0) {
      throw const FormatException('Invalid Nabi pairing response.');
    }
    return NabiEspPairingSession(id: id, token: token, expiresIn: expiresIn);
  }

  Future<NabiEspPairingStatus> getPairingStatus(String id) async {
    final json = await _client.requestMap(
      'GET',
      '/api/v1/iot/pairing-sessions/$id',
    );
    return NabiEspPairingStatus(
      status: json['status']?.toString() ?? 'unknown',
      deviceId: json['device_id']?.toString(),
      deviceName: json['device_name']?.toString(),
    );
  }

  Future<List<NabiEspDevice>> listDevices() async {
    final value = await _client.request('GET', '/api/v1/iot/devices');
    if (value is! List) {
      throw const FormatException('Invalid Nabi device list.');
    }
    return value
        .whereType<Map>()
        .map((row) => NabiEspDevice.fromJson(Map<String, Object?>.from(row)))
        .where((device) => device.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> updateConsent(
    String deviceId,
    NabiEspDeviceConsent consent,
  ) async {
    await _client.requestMap(
      'PUT',
      '/api/v1/iot/devices/$deviceId/consents',
      body: consent.toJson(),
    );
  }

  Future<void> rename(String deviceId, String name) async {
    await _client.requestMap(
      'PATCH',
      '/api/v1/iot/devices/$deviceId',
      body: {'name': name.trim()},
    );
  }

  Future<void> unlockSensitiveContext(String deviceId) async {
    await _client.requestMap(
      'POST',
      '/api/v1/iot/devices/$deviceId/sensitive-unlock',
      body: const {'confirm': true},
    );
  }

  Future<void> unbind(String deviceId) async {
    await _client.requestMap('DELETE', '/api/v1/iot/devices/$deviceId');
  }
}

int? _asInt(Object? value) => switch (value) {
  int number => number,
  num number => number.toInt(),
  String text => int.tryParse(text),
  _ => null,
};

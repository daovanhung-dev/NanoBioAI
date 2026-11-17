import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nano_app/app_versions/v1/features/nabi_esp_assistant/data/services/nabi_esp_device_service.dart';
import 'package:nano_app/core/network/backend_api_client.dart';

void main() {
  late BackendApiClient client;
  late NabiEspDeviceService devices;
  late List<http.Request> requests;

  setUp(() async {
    requests = [];
    client = BackendApiClient(
      baseUrl: 'https://api.example.test',
      sessionStore: _MemorySessionStore(),
      httpClient: MockClient((request) async {
        requests.add(request);
        final path = request.url.path;
        final data = switch (path) {
          '/api/v1/iot/pairing-sessions' => {
            'pairing_session_id': 'pair-1',
            'pairing_token': 'one-time-pair-token-0123456789abcdef',
            'expires_in': 120,
          },
          '/api/v1/iot/pairing-sessions/pair-1' => {
            'pairing_session_id': 'pair-1',
            'status': 'claimed',
            'device_id': '0123456789abcdef0123456789abcdef',
            'device_name': 'Nabi phòng khách',
          },
          '/api/v1/iot/devices' => [
            {
              'device_id': '0123456789abcdef0123456789abcdef',
              'name': 'Nabi phòng khách',
              'connected': true,
              'created_at': '2026-11-17T02:30:00Z',
              'consent': {
                'identity': false,
                'profile_goals': true,
                'sensitive_health': false,
                'recent_tracking': false,
              },
            },
          ],
          _ => {'ok': true},
        };
        return http.Response(
          jsonEncode({'success': true, 'data': data}),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    await client.establishSession({
      'access_token': 'test-access-token',
      'refresh_token': 'test-refresh-token',
      'expires_in': 900,
      'user': {'id': 'user-1'},
    });
    devices = NabiEspDeviceService(client: client);
  });

  tearDown(() => client.close());

  test(
    'creates a short-lived pairing session and polls claim status',
    () async {
      final pairing = await devices.createPairingSession();
      expect(pairing.id, 'pair-1');
      expect(pairing.token, 'one-time-pair-token-0123456789abcdef');
      expect(pairing.expiresIn, 120);

      final status = await devices.getPairingStatus(pairing.id);
      expect(status.status, 'claimed');
      expect(status.deviceId, '0123456789abcdef0123456789abcdef');
      expect(requests.map((request) => request.url.path), [
        '/api/v1/iot/pairing-sessions',
        '/api/v1/iot/pairing-sessions/pair-1',
      ]);
      expect(
        requests.every(
          (request) =>
              request.headers['authorization'] == 'Bearer test-access-token',
        ),
        isTrue,
      );
    },
  );

  test(
    'maps owner devices and sends management actions to scoped endpoints',
    () async {
      final listed = await devices.listDevices();
      expect(listed, hasLength(1));
      expect(listed.single.connected, isTrue);
      expect(listed.single.consent.profileGoals, isTrue);
      expect(listed.single.consent.sensitiveHealth, isFalse);

      const id = '0123456789abcdef0123456789abcdef';
      await devices.updateConsent(
        id,
        const NabiEspDeviceConsent(identity: true, recentTracking: true),
      );
      await devices.rename(id, '  Nabi bếp  ');
      await devices.unlockSensitiveContext(id);
      await devices.unbind(id);

      expect(
        requests.map((request) => '${request.method} ${request.url.path}'),
        [
          'GET /api/v1/iot/devices',
          'PUT /api/v1/iot/devices/$id/consents',
          'PATCH /api/v1/iot/devices/$id',
          'POST /api/v1/iot/devices/$id/sensitive-unlock',
          'DELETE /api/v1/iot/devices/$id',
        ],
      );
      expect(jsonDecode(requests[1].body), {
        'identity': true,
        'profile_goals': false,
        'sensitive_health': false,
        'recent_tracking': true,
      });
      expect(jsonDecode(requests[2].body), {'name': 'Nabi bếp'});
      expect(jsonDecode(requests[3].body), {'confirm': true});
    },
  );

  test('rejects incomplete pairing responses', () async {
    final invalidClient = BackendApiClient(
      baseUrl: 'https://api.example.test',
      sessionStore: _MemorySessionStore(),
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'pairing_session_id': 'pair-1',
              'pairing_token': 'too-short',
              'expires_in': 120,
            },
          }),
          200,
        ),
      ),
    );
    addTearDown(invalidClient.close);
    await invalidClient.establishSession({
      'access_token': 'test-access-token',
      'refresh_token': 'test-refresh-token',
      'expires_in': 900,
      'user': {'id': 'user-1'},
    });

    await expectLater(
      NabiEspDeviceService(client: invalidClient).createPairingSession(),
      throwsFormatException,
    );
  });
}

class _MemorySessionStore implements BackendSessionStore {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String value) async {}

  @override
  Future<void> clear() async {}
}

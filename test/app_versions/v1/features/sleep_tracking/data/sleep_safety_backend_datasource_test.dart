import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/data/datasources/sleep_safety_cloud_datasource.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/sleep_safety_dispatch_result.dart';
import 'package:nano_app/core/network/backend_api_client.dart';

void main() {
  test(
    'sleep safety cloud datasource uses authenticated backend routes',
    () async {
      const userId = '10000000-0000-4000-8000-000000000201';
      final calls = <String>[];
      final client = BackendApiClient(
        baseUrl: 'https://backend.test',
        sessionStore: _MemorySessionStore(),
        httpClient: MockClient((request) async {
          calls.add('${request.method} ${request.url.path}');
          final data = switch (request.url.path) {
            '/api/v1/sleep-safety/runtime-config' => {
              'enabled': true,
              'max_dispatches_per_hour': 3,
              'event_freshness_seconds': 600,
            },
            '/api/v1/sleep-safety/contacts' =>
              request.method == 'GET' ? [_contact(userId)] : _contact(userId),
            '/api/v1/sleep-safety/dispatch' => {'accepted': true},
            _ => {'saved': true, 'deleted': true},
          };
          return http.Response(
            jsonEncode({'success': true, 'data': data}),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.close);
      await client.establishSession({
        'access_token': 'test-access-token',
        'refresh_token': 'test-refresh-token',
        'expires_in': 3600,
        'user': {'id': userId},
      });

      final datasource = SleepSafetyCloudDatasource(clientOverride: client);
      final config = await datasource.fetchRuntimeConfig();
      expect(config.enabled, isTrue);
      final contacts = await datasource.fetchContacts();
      expect(contacts.single.phoneE164, '+84912345678');
      final saved = await datasource.upsertContact(
        id: null,
        name: 'Người thân',
        relationship: 'family',
        phoneE164: '+84912345678',
        priority: 1,
      );
      expect(saved.userId, userId);
      await datasource.deleteContact(saved.id);
      await datasource.requestVerification(saved.id);
      await datasource.confirmVerification(saved.id, '123456');
      await datasource.syncRow('sleep_safety_preferences', {'enabled': true});
      await datasource.syncRow('sleep_safety_sessions', {
        'id': 'session-local-1',
      });
      await datasource.syncRow('sleep_safety_events', {'id': 'event-local-1'});
      final dispatch = await datasource.dispatchEvent(
        eventId: 'event-local-1',
        idempotencyKey: 'sleep-dispatch-local-1',
      );
      expect(dispatch.route, SleepSafetyDispatchRoute.cloudAccepted);
      expect(
        calls,
        containsAll([
          'GET /api/v1/sleep-safety/runtime-config',
          'GET /api/v1/sleep-safety/contacts',
          'POST /api/v1/sleep-safety/contacts',
          'DELETE /api/v1/sleep-safety/contacts/${saved.id}',
          'POST /api/v1/sleep-safety/contacts/verification',
          'PUT /api/v1/sleep-safety/preferences',
          'PUT /api/v1/sleep-safety/sessions/session-local-1',
          'PUT /api/v1/sleep-safety/events/event-local-1',
          'POST /api/v1/sleep-safety/dispatch',
        ]),
      );
    },
  );
}

Map<String, Object?> _contact(String userId) => {
  'id': '20000000-0000-4000-8000-000000000201',
  'user_id': userId,
  'name': 'Người thân',
  'relationship': 'family',
  'phone_e164': '+84912345678',
  'priority': 1,
  'active': true,
  'allow_phone_fallback': true,
  'verification_status': 'pending',
  'allow_unverified_voice_alert': false,
  'created_at': '2026-10-30T10:00:00Z',
  'updated_at': '2026-10-30T10:00:00Z',
};

class _MemorySessionStore implements BackendSessionStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;

  @override
  Future<void> clear() async => value = null;
}

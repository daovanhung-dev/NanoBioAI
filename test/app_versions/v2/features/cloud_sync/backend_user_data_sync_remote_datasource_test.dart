import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/data/datasources/backend_user_data_sync_remote_datasource.dart';
import 'package:nano_app/core/network/backend_api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'pulls backend revision and leaves omitted optional tables untouched',
    () async {
      SharedPreferences.setMockInitialValues({});
      final client = BackendApiClient(
        baseUrl: 'https://backend.test',
        sessionStore: _MemorySessionStore(),
        httpClient: MockClient((request) async {
          expect(request.url.path, '/api/v1/cloud-sync/snapshot');
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'revision': 7,
                'user': {'id': _userId, 'full_name': 'QA User'},
                'tables': {
                  'health_profiles': [
                    {'id': 'profile-1', 'user_id': _userId},
                  ],
                },
              },
            }),
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
        'user': {'id': _userId},
      });

      final snapshot = await BackendUserDataSyncRemoteDatasource(
        clientOverride: client,
      ).pullCurrentUserSnapshot();

      expect(snapshot?.revision, 7);
      expect(snapshot?.hasUser, isTrue);
      expect(snapshot!.tables['health_profiles'], hasLength(1));
      expect(snapshot.tables, isNot(contains('fitness_training_programs')));
    },
  );
}

class _MemorySessionStore implements BackendSessionStore {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async => this.value = value;

  @override
  Future<void> clear() async => value = null;
}

const _userId = '10000000-0000-4000-8000-000000000101';

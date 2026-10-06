import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nano_app/app_versions/v2/features/cloud_sync/data/datasources/supabase_user_data_sync_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'missing optional fitness table does not abort cloud snapshot pull',
    () async {
      final requests = <String>[];
      final client = SupabaseClient(
        'https://sync-test.supabase.co',
        'test-anon-key',
        httpClient: MockClient((request) async {
          requests.add(request.url.path);
          if (request.url.path.endsWith('/auth/v1/user')) {
            return http.Response(
              jsonEncode(_authUser),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path.endsWith('/rest/v1/users')) {
            return http.Response(
              jsonEncode([
                {'id': _userId, 'full_name': 'QA User'},
              ]),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
          if (request.url.path.endsWith('/rest/v1/fitness_training_programs')) {
            return http.Response(
              jsonEncode({
                'code': 'PGRST205',
                'details': null,
                'hint': null,
                'message':
                    "Could not find the table 'public.fitness_training_programs' in the schema cache",
              }),
              404,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('[]', 200, request: request);
        }),
      );
      addTearDown(client.dispose);
      await client.auth.setSession(
        'test-refresh-token',
        accessToken: _accessToken(),
      );

      final snapshot = await SupabaseUserDataSyncRemoteDatasource(
        clientOverride: client,
      ).pullCurrentUserSnapshot();

      expect(snapshot?.hasUser, isTrue);
      expect(snapshot!.tables['health_profiles'], isEmpty);
      expect(snapshot.tables, isNot(contains('fitness_training_programs')));
      expect(requests, contains('/rest/v1/fitness_training_programs'));
    },
  );
}

const _userId = '10000000-0000-4000-8000-000000000101';

const _authUser = {
  'id': _userId,
  'aud': 'authenticated',
  'role': 'authenticated',
  'email': 'qa@example.test',
  'app_metadata': {
    'provider': 'email',
    'providers': ['email'],
  },
  'user_metadata': {},
  'created_at': '2026-01-01T00:00:00.000Z',
};

String _accessToken() {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  String encode(Map<String, Object?> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

  return '${encode({'alg': 'HS256', 'typ': 'JWT'})}.'
      '${encode({'sub': _userId, 'aud': 'authenticated', 'role': 'authenticated', 'iat': now, 'exp': now + 3600})}.'
      '${base64Url.encode(utf8.encode('signature')).replaceAll('=', '')}';
}

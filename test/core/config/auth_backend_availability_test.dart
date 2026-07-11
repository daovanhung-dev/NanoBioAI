import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/config/auth_backend_availability.dart';

void main() {
  group('initializeAuthBackendAvailability', () {
    test(
      'reports missing configuration without invoking initializer',
      () async {
        var initializerCalled = false;

        final availability = await initializeAuthBackendAvailability(
          config: null,
          initialize: (_, __) async {
            initializerCalled = true;
          },
        );

        expect(availability, AuthBackendAvailability.missingConfiguration);
        expect(initializerCalled, isFalse);
      },
    );

    test('reports ready after successful initialization', () async {
      var initializerCalled = false;

      final availability = await initializeAuthBackendAvailability(
        config: (url: 'https://example.test', anonKey: 'test-key'),
        initialize: (_, __) async {
          initializerCalled = true;
        },
      );

      expect(availability, AuthBackendAvailability.ready);
      expect(initializerCalled, isTrue);
    });

    test(
      'reports initialization failure and forwards safe diagnostics',
      () async {
        Object? reportedError;

        final availability = await initializeAuthBackendAvailability(
          config: (url: 'https://example.test', anonKey: 'test-key'),
          initialize: (_, __) async {
            throw StateError('initialization failed');
          },
          onInitializationError: (error, _) {
            reportedError = error;
          },
        );

        expect(availability, AuthBackendAvailability.initializationFailed);
        expect(reportedError, isA<StateError>());
      },
    );
  });
}

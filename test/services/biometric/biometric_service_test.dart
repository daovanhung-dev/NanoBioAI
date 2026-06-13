import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/services/biometric/biometric_service.dart';

void main() {
  group('BiometricService', () {
    late BiometricService biometricService;

    setUp(() {
      biometricService = BiometricService();
    });

    test('BiometricService can be instantiated', () {
      expect(biometricService, isNotNull);
      expect(biometricService, isA<BiometricService>());
    });

    group('BiometricException', () {
      test('creates exception with message only', () {
        final exception = BiometricException('Test message');
        expect(exception.message, equals('Test message'));
        expect(exception.code, isNull);
        expect(exception.toString(), contains('BiometricException'));
        expect(exception.toString(), contains('Test message'));
      });

      test('creates exception with message and code', () {
        final exception =
            BiometricException('Test message', code: 'TEST_CODE');
        expect(exception.message, equals('Test message'));
        expect(exception.code, equals('TEST_CODE'));
      });

      test('toString() includes both class name and message', () {
        final exception = BiometricException('Error occurred');
        final stringRepresentation = exception.toString();
        expect(stringRepresentation, contains('BiometricException'));
        expect(stringRepresentation, contains('Error occurred'));
      });

      test('implements Exception interface', () {
        final exception = BiometricException('Test');
        expect(exception, isA<Exception>());
      });
    });

    group('API Contract', () {
      test('has isAvailable method', () {
        expect(biometricService.isAvailable, isA<Function>());
      });

      test('has authenticate method', () {
        expect(biometricService.authenticate, isA<Function>());
      });

      test('has getAvailableBiometrics method', () {
        expect(biometricService.getAvailableBiometrics, isA<Function>());
      });
    });
  });
}

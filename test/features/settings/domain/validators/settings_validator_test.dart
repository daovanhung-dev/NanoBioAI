import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/features/settings/domain/validators/settings_validator.dart';

void main() {
  group('SettingsValidator - validateMealReminderTime', () {
    test('should return null for valid time format 09:30', () {
      final result = SettingsValidator.validateMealReminderTime('09:30');
      expect(result, isNull);
    });

    test('should return null for valid time format 23:59', () {
      final result = SettingsValidator.validateMealReminderTime('23:59');
      expect(result, isNull);
    });

    test('should return null for valid time format 00:00', () {
      final result = SettingsValidator.validateMealReminderTime('00:00');
      expect(result, isNull);
    });

    test('should return null for valid time format 12:00', () {
      final result = SettingsValidator.validateMealReminderTime('12:00');
      expect(result, isNull);
    });

    test('should return error for null time', () {
      final result = SettingsValidator.validateMealReminderTime(null);
      expect(result, isNotNull);
      expect(result, contains('không được để trống'));
    });

    test('should return error for empty time', () {
      final result = SettingsValidator.validateMealReminderTime('');
      expect(result, isNotNull);
      expect(result, contains('không được để trống'));
    });

    test('should return error for invalid hour 24:00', () {
      final result = SettingsValidator.validateMealReminderTime('24:00');
      expect(result, isNotNull);
      expect(result, contains('HH:mm'));
    });

    test('should return error for invalid hour 25:30', () {
      final result = SettingsValidator.validateMealReminderTime('25:30');
      expect(result, isNotNull);
      expect(result, contains('HH:mm'));
    });

    test('should return error for invalid minute 12:60', () {
      final result = SettingsValidator.validateMealReminderTime('12:60');
      expect(result, isNotNull);
      expect(result, contains('HH:mm'));
    });

    test('should return error for missing leading zero 9:30', () {
      final result = SettingsValidator.validateMealReminderTime('9:30');
      expect(result, isNotNull);
      expect(result, contains('HH:mm'));
    });

    test('should return error for missing leading zero 12:5', () {
      final result = SettingsValidator.validateMealReminderTime('12:5');
      expect(result, isNotNull);
      expect(result, contains('HH:mm'));
    });

    test('should return error for wrong separator 12-30', () {
      final result = SettingsValidator.validateMealReminderTime('12-30');
      expect(result, isNotNull);
      expect(result, contains('HH:mm'));
    });

    test('should return error for wrong separator 12.30', () {
      final result = SettingsValidator.validateMealReminderTime('12.30');
      expect(result, isNotNull);
      expect(result, contains('HH:mm'));
    });

    test('should return error for too short time 12:3', () {
      final result = SettingsValidator.validateMealReminderTime('12:3');
      expect(result, isNotNull);
      expect(result, contains('HH:mm'));
    });

    test('should return error for too long time 012:30', () {
      final result = SettingsValidator.validateMealReminderTime('012:30');
      expect(result, isNotNull);
      expect(result, contains('HH:mm'));
    });

    test('should return error for non-numeric characters AB:CD', () {
      final result = SettingsValidator.validateMealReminderTime('AB:CD');
      expect(result, isNotNull);
      expect(result, contains('HH:mm'));
    });

    test('should return error for random string', () {
      final result = SettingsValidator.validateMealReminderTime('invalid');
      expect(result, isNotNull);
      expect(result, contains('HH:mm'));
    });
  });

  group('SettingsValidator - validateLanguageCode', () {
    test('should return null for valid Vietnamese code "vi"', () {
      final result = SettingsValidator.validateLanguageCode('vi');
      expect(result, isNull);
    });

    test('should return null for valid English code "en"', () {
      final result = SettingsValidator.validateLanguageCode('en');
      expect(result, isNull);
    });

    test('should return error for null language code', () {
      final result = SettingsValidator.validateLanguageCode(null);
      expect(result, isNotNull);
      expect(result, contains('không được để trống'));
    });

    test('should return error for empty language code', () {
      final result = SettingsValidator.validateLanguageCode('');
      expect(result, isNotNull);
      expect(result, contains('không được để trống'));
    });

    test('should return error for unsupported language code "fr"', () {
      final result = SettingsValidator.validateLanguageCode('fr');
      expect(result, isNotNull);
      expect(result, contains('"vi"'));
      expect(result, contains('"en"'));
    });

    test('should return error for unsupported language code "es"', () {
      final result = SettingsValidator.validateLanguageCode('es');
      expect(result, isNotNull);
      expect(result, contains('"vi"'));
      expect(result, contains('"en"'));
    });

    test('should return error for unsupported language code "ja"', () {
      final result = SettingsValidator.validateLanguageCode('ja');
      expect(result, isNotNull);
      expect(result, contains('"vi"'));
      expect(result, contains('"en"'));
    });

    test('should return error for invalid uppercase code "VI"', () {
      final result = SettingsValidator.validateLanguageCode('VI');
      expect(result, isNotNull);
      expect(result, contains('"vi"'));
      expect(result, contains('"en"'));
    });

    test('should return error for invalid uppercase code "EN"', () {
      final result = SettingsValidator.validateLanguageCode('EN');
      expect(result, isNotNull);
      expect(result, contains('"vi"'));
      expect(result, contains('"en"'));
    });

    test('should return error for random string', () {
      final result = SettingsValidator.validateLanguageCode('invalid');
      expect(result, isNotNull);
      expect(result, contains('"vi"'));
      expect(result, contains('"en"'));
    });
  });

  group('SettingsValidator - validateMealReminderSettings', () {
    test('should return empty map for valid time', () {
      final result = SettingsValidator.validateMealReminderSettings(
        time: '09:30',
      );
      expect(result, isEmpty);
    });

    test('should return error map for invalid time', () {
      final result = SettingsValidator.validateMealReminderSettings(
        time: '25:00',
      );
      expect(result, isNotEmpty);
      expect(result['meal_reminder_time'], isNotNull);
      expect(result['meal_reminder_time'], contains('HH:mm'));
    });

    test('should return error map for null time', () {
      final result = SettingsValidator.validateMealReminderSettings(
        time: null,
      );
      expect(result, isNotEmpty);
      expect(result['meal_reminder_time'], isNotNull);
      expect(result['meal_reminder_time'], contains('không được để trống'));
    });
  });

  group('SettingsValidator - validateLanguageSettings', () {
    test('should return empty map for valid language code "vi"', () {
      final result = SettingsValidator.validateLanguageSettings(
        languageCode: 'vi',
      );
      expect(result, isEmpty);
    });

    test('should return empty map for valid language code "en"', () {
      final result = SettingsValidator.validateLanguageSettings(
        languageCode: 'en',
      );
      expect(result, isEmpty);
    });

    test('should return error map for invalid language code', () {
      final result = SettingsValidator.validateLanguageSettings(
        languageCode: 'fr',
      );
      expect(result, isNotEmpty);
      expect(result['language_code'], isNotNull);
      expect(result['language_code'], contains('"vi"'));
      expect(result['language_code'], contains('"en"'));
    });

    test('should return error map for null language code', () {
      final result = SettingsValidator.validateLanguageSettings(
        languageCode: null,
      );
      expect(result, isNotEmpty);
      expect(result['language_code'], isNotNull);
      expect(result['language_code'], contains('không được để trống'));
    });
  });
}

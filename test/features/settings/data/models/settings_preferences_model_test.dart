import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/settings/data/models/settings_preferences_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsPreferencesModel language migration', () {
    test('migrates the legacy English preference to Vietnamese', () async {
      SharedPreferences.setMockInitialValues({
        SettingsPreferencesModel.keyLanguageCode: 'en',
      });
      final preferences = await SharedPreferences.getInstance();

      final model = SettingsPreferencesModel.fromPreferences(preferences);

      expect(model.languageCode, 'vi');
    });

    test('persists only the Vietnamese language code', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final model = SettingsPreferencesModel.defaults().copyWith(
        languageCode: 'en',
      );

      await model.saveToPreferences(preferences);

      expect(model.languageCode, 'vi');
      expect(
        preferences.getString(SettingsPreferencesModel.keyLanguageCode),
        'vi',
      );
    });
  });
}

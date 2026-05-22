import 'package:shared_preferences/shared_preferences.dart';

class AppPrefs {
  static const String _onboardingKey = 'onboarding_completed';

  static Future<void> setOnboardingCompleted(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_onboardingKey, value);
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_onboardingKey) ?? false;
  }
}

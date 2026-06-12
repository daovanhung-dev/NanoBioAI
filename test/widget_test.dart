import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('OnboardingState', () {
    const validProfile = OnboardingState(
      fullName: 'Nguyen Van A',
      gender: 'Nam',
      birthYear: 1995,
      occupation: 'Nhan vien van phong',
    );

    test('không cho lưu khi người dùng chưa đồng ý điều khoản', () {
      expect(validProfile.canSave, isFalse);
    });

    test('cho lưu khi đủ thông tin và đã đồng ý điều khoản', () {
      expect(validProfile.copyWith(agreed: true).canSave, isTrue);
    });
  });

  test('lưu trạng thái onboarding hoàn tất để dùng cho lần mở sau', () async {
    SharedPreferences.setMockInitialValues({});

    expect(await AppPrefs.isOnboardingCompleted(), isFalse);

    await AppPrefs.setOnboardingCompleted(true);

    expect(await AppPrefs.isOnboardingCompleted(), isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/data/models/sleep_safety_models.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/safety_contact.dart';

void main() {
  test('unverified voice consent survives local contact mapping', () {
    final now = DateTime.utc(2026, 10, 6);
    final contact = SafetyContact(
      id: 'contact-1',
      userId: 'user-1',
      name: 'Người thân',
      relationship: 'Gia đình',
      phoneE164: '+84901234567',
      priority: 1,
      verificationStatus: SafetyContactVerificationStatus.pending,
      active: true,
      createdAt: now,
      updatedAt: now,
      allowUnverifiedVoiceAlert: true,
    );

    final mapped = SleepSafetyModelMapper.contactToMap(contact);
    final restored = SleepSafetyModelMapper.contactFromMap(mapped);

    expect(mapped['allow_unverified_voice_alert'], 1);
    expect(restored.allowUnverifiedVoiceAlert, isTrue);
    expect(restored.canReceiveSafetyCall, isTrue);
  });

  test('legacy contact rows default unverified voice consent off', () {
    final now = DateTime.utc(2026, 10, 6).toIso8601String();
    final contact = SleepSafetyModelMapper.contactFromMap({
      'id': 'contact-1',
      'user_id': 'user-1',
      'name': 'Người thân',
      'relationship': 'Gia đình',
      'phone_e164': '+84901234567',
      'priority': 1,
      'verification_status': 'pending',
      'active': 1,
      'created_at': now,
      'updated_at': now,
    });

    expect(contact.allowUnverifiedVoiceAlert, isFalse);
    expect(contact.canReceiveSafetyCall, isFalse);
  });
}

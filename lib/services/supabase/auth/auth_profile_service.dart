import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CloudOnboardingPayload {
  final String? email;
  final String phone;
  final String fullName;
  final String gender;
  final int birthYear;
  final String occupation;
  final double heightCm;
  final double weightKg;
  final double bmi;
  final List<CloudCodeLabel> goals;
  final List<CloudCodeLabel> conditions;
  final List<String> habits;
  final String sleepQuality;
  final String activityLevel;
  final String waterPerDay;
  final String allergyName;
  final String allergyNote;
  final String treatmentName;
  final String medicationName;
  final String treatmentNote;
  final String concernText;

  const CloudOnboardingPayload({
    required this.email,
    required this.phone,
    required this.fullName,
    required this.gender,
    required this.birthYear,
    required this.occupation,
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
    required this.goals,
    required this.conditions,
    required this.habits,
    required this.sleepQuality,
    required this.activityLevel,
    required this.waterPerDay,
    required this.allergyName,
    required this.allergyNote,
    required this.treatmentName,
    required this.medicationName,
    required this.treatmentNote,
    required this.concernText,
  });

  bool get hasAllergy => allergyName.trim().isNotEmpty;

  bool get hasTreatment =>
      treatmentName.trim().isNotEmpty ||
      medicationName.trim().isNotEmpty ||
      treatmentNote.trim().isNotEmpty;
}

class CloudCodeLabel {
  final String code;
  final String label;

  const CloudCodeLabel({required this.code, required this.label});
}

class CloudProfileUpdatePayload {
  final String fullName;
  final String phone;
  final String gender;
  final int birthYear;
  final String occupation;
  final double heightCm;
  final double weightKg;
  final double bmi;

  const CloudProfileUpdatePayload({
    required this.fullName,
    required this.phone,
    required this.gender,
    required this.birthYear,
    required this.occupation,
    required this.heightCm,
    required this.weightKg,
    required this.bmi,
  });
}

class AuthProfileService {
  static const _tag = 'AUTH_PROFILE';

  final SupabaseClient? clientOverride;

  const AuthProfileService({this.clientOverride});

  SupabaseClient? get _client {
    if (clientOverride != null) return clientOverride;
    try {
      return Supabase.instance.client;
    } on AssertionError {
      return null;
    }
  }

  String? get currentUserId {
    return _client?.auth.currentUser?.id;
  }

  bool get hasAuthenticatedUser {
    return currentUserId != null;
  }

  Future<void> markOnboardingInProgress() async {
    final client = _client;
    final userId = currentUserId;
    if (client == null || userId == null) return;

    await client
        .from('users')
        .update({'onboarding_status': 'in_progress'})
        .eq('id', userId)
        .neq('onboarding_status', 'completed');
  }

  Future<void> saveCompletedOnboarding(CloudOnboardingPayload payload) async {
    final client = _client;
    final userId = currentUserId;
    if (client == null || userId == null) {
      throw const AuthException('Missing authenticated user for onboarding.');
    }

    AppLogger.supabase(_tag, 'Saving onboarding profile for current user');

    await client
        .from('users')
        .update({
          'phone': _nullable(payload.phone),
          'full_name': payload.fullName.trim(),
          'gender': payload.gender.trim(),
          'birth_year': payload.birthYear,
          'onboarding_status': 'in_progress',
        })
        .eq('id', userId);

    await client
        .from('health_profiles')
        .update({
          'occupation': payload.occupation.trim(),
          'height_cm': payload.heightCm,
          'weight_kg': payload.weightKg,
          'bmi': payload.bmi,
        })
        .eq('user_id', userId);

    await client
        .from('lifestyle_habits')
        .update(_lifestyleRow(payload))
        .eq('user_id', userId);

    await _replaceGoals(client, userId, payload);
    await _replaceConditions(client, userId, payload);
    await _replaceAllergies(client, userId, payload);
    await _replaceTreatments(client, userId, payload);
    await _upsertSurveyAnswers(client, userId, payload);

    await client
        .from('users')
        .update({
          'onboarding_status': 'completed',
          'onboarding_completed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', userId);

    AppLogger.success(_tag, 'Cloud onboarding lifecycle completed');
  }

  Future<void> updateProfile(CloudProfileUpdatePayload payload) async {
    final client = _client;
    final userId = currentUserId;
    if (client == null || userId == null) {
      throw const AuthException(
        'Missing authenticated user for profile update.',
      );
    }

    AppLogger.supabase(_tag, 'Updating profile for current user');

    await client
        .from('users')
        .update({
          'phone': _nullable(payload.phone),
          'full_name': payload.fullName.trim(),
          'gender': payload.gender.trim(),
          'birth_year': payload.birthYear,
        })
        .eq('id', userId);

    await client
        .from('health_profiles')
        .update({
          'occupation': payload.occupation.trim(),
          'height_cm': payload.heightCm,
          'weight_kg': payload.weightKg,
          'bmi': payload.bmi,
        })
        .eq('user_id', userId);

    AppLogger.success(_tag, 'Cloud profile updated');
  }

  Future<void> _replaceGoals(
    SupabaseClient client,
    String userId,
    CloudOnboardingPayload payload,
  ) async {
    await client.from('health_goals').delete().eq('user_id', userId);
    if (payload.goals.isEmpty) return;

    await client
        .from('health_goals')
        .insert(
          payload.goals
              .map(
                (goal) => {
                  'user_id': userId,
                  'goal_code': goal.code,
                  'goal_name': goal.label,
                  'is_active': true,
                },
              )
              .toList(),
        );
  }

  Future<void> _replaceConditions(
    SupabaseClient client,
    String userId,
    CloudOnboardingPayload payload,
  ) async {
    await client.from('health_conditions').delete().eq('user_id', userId);
    if (payload.conditions.isEmpty) return;

    await client
        .from('health_conditions')
        .insert(
          payload.conditions
              .map(
                (condition) => {
                  'user_id': userId,
                  'condition_code': condition.code,
                  'condition_name': condition.label,
                  'severity_level': 1,
                },
              )
              .toList(),
        );
  }

  Future<void> _replaceAllergies(
    SupabaseClient client,
    String userId,
    CloudOnboardingPayload payload,
  ) async {
    await client.from('food_allergies').delete().eq('user_id', userId);
    if (!payload.hasAllergy) return;

    await client.from('food_allergies').insert({
      'user_id': userId,
      'allergy_name': payload.allergyName.trim(),
      'note': _nullable(payload.allergyNote),
    });
  }

  Future<void> _replaceTreatments(
    SupabaseClient client,
    String userId,
    CloudOnboardingPayload payload,
  ) async {
    await client.from('medical_treatments').delete().eq('user_id', userId);
    if (!payload.hasTreatment) return;

    await client.from('medical_treatments').insert({
      'user_id': userId,
      'treatment_name': _nullable(payload.treatmentName) ?? 'Đang điều trị',
      'medication_name': _nullable(payload.medicationName),
      'note': _nullable(
        [
          payload.treatmentNote.trim(),
          if (payload.medicationName.trim().isNotEmpty)
            'Thuốc: ${payload.medicationName.trim()}',
        ].where((item) => item.isNotEmpty).join(' | '),
      ),
    });
  }

  Future<void> _upsertSurveyAnswers(
    SupabaseClient client,
    String userId,
    CloudOnboardingPayload payload,
  ) async {
    final rows = <Map<String, Object?>>[
      _surveyRow(userId, 'full_name', payload.fullName),
      _surveyRow(userId, 'email', payload.email ?? ''),
      _surveyRow(userId, 'phone', payload.phone),
      _surveyRow(userId, 'gender', payload.gender),
      _surveyRow(userId, 'birth_year', payload.birthYear.toString()),
      _surveyRow(userId, 'concern_text', payload.concernText),
    ];

    await client
        .from('survey_answers')
        .upsert(rows, onConflict: 'user_id,question_code');
  }

  Map<String, Object?> _surveyRow(
    String userId,
    String questionCode,
    String answerValue,
  ) {
    return {
      'user_id': userId,
      'question_code': questionCode,
      'answer_value': answerValue.trim(),
    };
  }

  Map<String, Object?> _lifestyleRow(CloudOnboardingPayload payload) {
    bool has(String code) => payload.habits.contains(code);

    return {
      'skip_breakfast': has('skip_breakfast'),
      'eat_late': has('eat_late'),
      'eat_sweet': has('eat_sweet'),
      'eat_oily': has('eat_oily'),
      'low_vegetable': has('low_vegetable'),
      'low_water': has('low_water'),
      'fast_food': has('fast_food'),
      'alcohol': has('alcohol'),
      'coffee_high': has('coffee_high'),
      'sleep_quality': payload.sleepQuality,
      'activity_level': payload.activityLevel,
      'water_per_day': payload.waterPerDay,
    };
  }

  String? _nullable(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

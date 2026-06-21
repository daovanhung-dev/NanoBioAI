import 'package:nano_app/core/utils/logger/app_logger.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';
import 'package:nano_app/services/supabase/auth/auth_profile_service.dart';

import '../../data/datasource/onboarding_local_datasource.dart';
import '../entities/onboarding_entity.dart';
import 'onboarding_repository.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  static const _tag = 'ONBOARDING_REPO';

  final OnboardingLocalDatasource localDatasource;
  final AuthProfileService authProfileService;

  OnboardingRepositoryImpl({
    required this.localDatasource,
    this.authProfileService = const AuthProfileService(),
  });

  @override
  Future<void> save(OnboardingEntity entity) async {
    try {
      final authUserId = authProfileService.currentUserId;
      if (authUserId != null) {
        AppLogger.info(_tag, 'Saving onboarding to Supabase profile rows');
        await authProfileService.saveCompletedOnboarding(
          _toCloudPayload(entity),
        );
      }

      AppLogger.info(_tag, 'Mirroring onboarding to local datasource');
      final localUserId = await localDatasource.saveOnboarding(
        entity,
        userIdOverride: authUserId,
      );

      if (authUserId == null) {
        await AppPrefs.setPendingGuestUserId(localUserId);
      } else {
        await AppPrefs.clearPendingGuestUserId();
      }
      AppLogger.success(_tag, 'Save completed successfully');
    } catch (e, st) {
      AppLogger.error(_tag, 'Repository save failed', e, st);
      rethrow;
    }
  }

  CloudOnboardingPayload _toCloudPayload(OnboardingEntity entity) {
    return CloudOnboardingPayload(
      email: entity.email,
      phone: entity.phone,
      fullName: entity.fullName,
      gender: entity.gender,
      birthYear: entity.birthYear,
      occupation: entity.occupation,
      heightCm: entity.heightCm,
      weightKg: entity.weightKg,
      bmi: entity.bmi,
      goals: [
        ...entity.goals.map(
          (code) => CloudCodeLabel(code: code, label: _goalLabel(code)),
        ),
        if (entity.otherGoal.trim().isNotEmpty)
          CloudCodeLabel(code: 'other_goal', label: entity.otherGoal.trim()),
      ],
      conditions: [
        ...entity.conditions.map(
          (code) => CloudCodeLabel(code: code, label: _conditionLabel(code)),
        ),
        if (entity.otherCondition.trim().isNotEmpty)
          CloudCodeLabel(
            code: 'other_condition',
            label: entity.otherCondition.trim(),
          ),
      ],
      habits: entity.habits,
      sleepQuality: entity.sleepQuality,
      activityLevel: entity.activityLevel,
      waterPerDay: entity.waterPerDay,
      allergyName: entity.allergyName,
      allergyNote: entity.allergyNote,
      treatmentName: entity.treatmentName,
      medicationName: entity.medicationName,
      treatmentNote: entity.treatmentNote,
      concernText: entity.concernText,
    );
  }

  String _goalLabel(String code) {
    const labels = {
      'lose_weight': 'Giảm cân',
      'gain_weight': 'Tăng cân',
      'lose_belly_fat': 'Giảm mỡ bụng',
      'gain_muscle': 'Tăng cơ',
      'improve_digestion': 'Cải thiện tiêu hóa',
      'sleep_better': 'Ngủ ngon hơn',
      'reduce_fatigue': 'Giảm mệt mỏi',
      'increase_energy': 'Tăng năng lượng',
      'beautify_skin': 'Làm đẹp da',
      'immune_boost': 'Tăng đề kháng',
      'stable_blood_sugar': 'Ổn định đường huyết',
      'stable_blood_pressure': 'Ổn định huyết áp',
      'joint_health': 'Cải thiện xương khớp',
      'detox_body': 'Thanh lọc cơ thể',
      'overall_health': 'Cải thiện sức khỏe tổng thể',
    };

    return labels[code] ?? code;
  }

  String _conditionLabel(String code) {
    const labels = {
      'stomach_pain': 'Đau dạ dày',
      'constipation': 'Táo bón',
      'bloating': 'Đầy hơi, khó tiêu',
      'insomnia': 'Mất ngủ',
      'stress': 'Stress, căng thẳng',
      'joint_pain': 'Đau nhức xương khớp',
      'high_blood_sugar': 'Đường huyết cao',
      'blood_pressure_issue': 'Huyết áp cao/thấp',
      'high_cholesterol': 'Mỡ máu cao',
      'fatty_liver': 'Gan nhiễm mỡ',
      'tired_always': 'Hay mệt mỏi',
      'overweight': 'Thừa cân/béo phì',
      'underweight': 'Gầy yếu, khó hấp thu',
      'no_special_issue': 'Không có vấn đề đặc biệt',
    };

    return labels[code] ?? code;
  }
}

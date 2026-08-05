import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/domain/entities/nutrition_profile_entity.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/domain/repositories/nutrition_profile_repository.dart';
import 'package:nano_app/app_versions/v1/features/nutrition/providers/nutrition_profile_providers.dart';

class NutritionProfileController
    extends AsyncNotifier<NutritionProfileEntity> {
  late NutritionProfileRepository _repository;
  late String _userId;

  @override
  Future<NutritionProfileEntity> build() async {
    _repository = ref.read(nutritionProfileRepositoryProvider);
    _userId = ref.watch(activeNutritionProfileUserIdProvider);
    if (_userId.isEmpty) {
      return NutritionProfileEntity.empty('');
    }
    return _repository.load(_userId);
  }

  Future<void> save(NutritionProfileEntity profile) async {
    if (_userId.isEmpty) {
      state = AsyncError(
        const FormatException('Bạn cần đăng nhập để lưu hồ sơ dinh dưỡng.'),
        StackTrace.current,
      );
      return;
    }
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final normalized = profile.copyWith(userId: _userId);
      await _repository.save(normalized);
      return _repository.load(_userId);
    });
  }

  Future<void> refresh() async {
    if (_userId.isEmpty) return;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.load(_userId));
  }
}

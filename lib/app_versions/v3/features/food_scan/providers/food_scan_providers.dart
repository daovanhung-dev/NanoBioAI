import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/app_versions/v2/features/membership_entitlement/providers/membership_entitlement_providers.dart';
import 'package:nano_app/services/supabase/auth/current_auth_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/food_scan_service.dart';
import '../data/services/food_scan_image_service.dart';
import '../domain/entities/food_scan_models.dart';
import '../domain/food_scan_exception.dart';

final foodScanAccessProvider = FutureProvider<FoodScanAccess>((ref) async {
  final userId = currentSupabaseUserIdOrNull();
  if (userId == null || userId.trim().isEmpty) {
    return const FoodScanAccess(
      userId: null,
      status: FoodScanAccessStatus.authRequired,
    );
  }
  final access = await ref.watch(effectiveAccessProvider.future);
  if (access == null || !access.isPlus) {
    return FoodScanAccess(
      userId: userId,
      status: FoodScanAccessStatus.plusRequired,
    );
  }
  return FoodScanAccess(userId: userId, status: FoodScanAccessStatus.allowed);
});

final foodScanServiceProvider = Provider<FoodScanService>((ref) {
  return FoodScanService();
});

final foodScanImageServiceProvider = Provider<FoodScanImageService>((ref) {
  return FoodScanImageService();
});

final foodScanConsentProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('food_scan_ai_consent_v1_$userId') ?? false;
});

final foodScanGrantConsentProvider = Provider<Future<void> Function(String)>((ref) {
  return (userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('food_scan_ai_consent_v1_$userId', true);
    ref.invalidate(foodScanConsentProvider(userId));
  };
});

final foodScanHistoryProvider =
    FutureProvider.family<List<FoodScanResult>, String>((ref, userId) {
  return ref.watch(foodScanServiceProvider).history(userId);
});

final foodScanControllerProvider =
    NotifierProvider<FoodScanController, FoodScanState>(FoodScanController.new);

class FoodScanState {
  final FoodScanPhase phase;
  final String? imagePath;
  final FoodScanResult? result;
  final String? errorMessage;
  final bool healthNeedsRefresh;

  const FoodScanState({
    this.phase = FoodScanPhase.idle,
    this.imagePath,
    this.result,
    this.errorMessage,
    this.healthNeedsRefresh = false,
  });

  bool get busy => const <FoodScanPhase>{
    FoodScanPhase.selectingImage,
    FoodScanPhase.analyzingVision,
    FoodScanPhase.resolvingNutrition,
    FoodScanPhase.evaluatingHealth,
    FoodScanPhase.saving,
  }.contains(phase);

  FoodScanState copyWith({
    FoodScanPhase? phase,
    Object? imagePath = _unset,
    Object? result = _unset,
    Object? errorMessage = _unset,
    bool? healthNeedsRefresh,
  }) {
    return FoodScanState(
      phase: phase ?? this.phase,
      imagePath: identical(imagePath, _unset) ? this.imagePath : imagePath as String?,
      result: identical(result, _unset) ? this.result : result as FoodScanResult?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      healthNeedsRefresh: healthNeedsRefresh ?? this.healthNeedsRefresh,
    );
  }
}

const Object _unset = Object();

class FoodScanController extends Notifier<FoodScanState> {
  @override
  FoodScanState build() => const FoodScanState();

  FoodScanService get _service => ref.read(foodScanServiceProvider);
  FoodScanImageService get _images => ref.read(foodScanImageServiceProvider);

  void reset() => state = const FoodScanState();

  Future<void> pickCamera(String userId) => _pick(userId, camera: true);

  Future<void> pickGallery(String userId) => _pick(userId, camera: false);

  Future<void> _pick(String userId, {required bool camera}) async {
    if (state.busy) return;
    state = state.copyWith(
      phase: FoodScanPhase.selectingImage,
      errorMessage: null,
    );
    try {
      final prepared = camera
          ? await _images.pickCamera(userId: userId)
          : await _images.pickGallery(userId: userId);
      if (prepared == null) {
        state = state.copyWith(phase: FoodScanPhase.idle);
        return;
      }
      state = FoodScanState(
        phase: FoodScanPhase.readyToAnalyze,
        imagePath: prepared.path,
      );
    } on FoodScanException catch (error) {
      _fail(error.userMessage);
    } catch (_) {
      _fail('Nabi chưa thể chọn ảnh lúc này. Bạn thử lại nhé.');
    }
  }

  Future<void> analyze(String userId) async {
    if (state.busy) return;
    final imagePath = state.imagePath;
    if (imagePath == null || imagePath.isEmpty) {
      _fail('Bạn cần chụp hoặc chọn một ảnh món ăn trước.');
      return;
    }
    state = state.copyWith(
      phase: FoodScanPhase.analyzingVision,
      errorMessage: null,
      result: null,
    );
    try {
      final result = await _service.analyze(userId: userId, imagePath: imagePath);
      state = FoodScanState(
        phase: FoodScanPhase.ready,
        imagePath: imagePath,
        result: result,
      );
      ref.invalidate(foodScanHistoryProvider(userId));
    } on FoodScanException catch (error) {
      _fail(error.userMessage);
    } catch (_) {
      _fail('Nabi chưa thể phân tích món ăn lúc này. Bạn thử lại nhé.');
    }
  }

  Future<void> updateItem({
    required String userId,
    required String itemId,
    required String name,
    required double weightGrams,
    required String portionDescription,
  }) async {
    final current = state.result;
    if (current == null || state.busy) return;
    try {
      final updated = _service.updateItem(
        result: current,
        itemId: itemId,
        name: name,
        weightGrams: weightGrams,
        portionDescription: portionDescription,
      );
      state = state.copyWith(
        result: updated,
        phase: FoodScanPhase.ready,
        healthNeedsRefresh: true,
        errorMessage: null,
      );
      await _service.persistEditedAnalysis(userId: userId, result: updated);
      ref.invalidate(foodScanHistoryProvider(userId));
    } on FoodScanException catch (error) {
      _fail(error.userMessage);
    }
  }

  Future<void> removeItem({
    required String userId,
    required String itemId,
  }) async {
    final current = state.result;
    if (current == null || state.busy) return;
    final updated = _service.removeItem(result: current, itemId: itemId);
    state = state.copyWith(
      result: updated,
      phase: FoodScanPhase.ready,
      healthNeedsRefresh: true,
    );
    await _service.persistEditedAnalysis(userId: userId, result: updated);
    ref.invalidate(foodScanHistoryProvider(userId));
  }

  Future<void> reevaluateHealth(String userId) async {
    final current = state.result;
    if (current == null || state.busy) return;
    state = state.copyWith(
      phase: FoodScanPhase.evaluatingHealth,
      errorMessage: null,
    );
    try {
      final updated = await _service.reevaluateHealth(
        userId: userId,
        result: current,
      );
      state = state.copyWith(
        phase: FoodScanPhase.ready,
        result: updated,
        healthNeedsRefresh: false,
      );
      ref.invalidate(foodScanHistoryProvider(userId));
    } on FoodScanException catch (error) {
      state = state.copyWith(
        phase: FoodScanPhase.ready,
        errorMessage: error.userMessage,
        healthNeedsRefresh: true,
      );
    }
  }

  Future<FoodScanResult?> confirmConsumed(String userId) async {
    final current = state.result;
    if (current == null || current.items.isEmpty || state.busy) return null;
    state = state.copyWith(phase: FoodScanPhase.saving, errorMessage: null);
    try {
      final saved = await _service.confirmConsumed(
        userId: userId,
        result: current,
      );
      state = state.copyWith(
        phase: FoodScanPhase.saved,
        result: saved,
        healthNeedsRefresh: false,
      );
      ref.invalidate(foodScanHistoryProvider(userId));
      return saved;
    } on FoodScanException catch (error) {
      state = state.copyWith(
        phase: FoodScanPhase.ready,
        errorMessage: error.userMessage,
      );
      return null;
    }
  }

  void loadHistoryResult(FoodScanResult result) {
    state = FoodScanState(
      phase: FoodScanPhase.ready,
      imagePath: result.imageLocalPath,
      result: result,
    );
  }

  void _fail(String message) {
    state = state.copyWith(
      phase: FoodScanPhase.error,
      errorMessage: message,
    );
  }
}

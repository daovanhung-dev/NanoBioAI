import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v3/features/food_scan/data/services/food_scan_image_service.dart';
import 'package:nano_app/app_versions/v3/features/food_scan/domain/entities/food_scan_models.dart';
import 'package:nano_app/app_versions/v3/features/food_scan/providers/food_scan_providers.dart';

void main() {
  test('keeps the local model unloaded through image picker completion', () async {
    final calls = <String>[];
    final container = ProviderContainer(
      overrides: [
        foodScanImageServiceProvider.overrideWith(
          (ref) => _FakeFoodScanImageService(calls),
        ),
        foodScanWithLocalModelUnloadedProvider.overrideWith(
          (ref) => <T>(action) async {
            calls.add('unload');
            final value = await action();
            calls.add('release');
            return value;
          },
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(foodScanControllerProvider.notifier);
    await controller.pickGallery('test-user');

    expect(calls, ['unload', 'gallery', 'release']);
    expect(
      container.read(foodScanControllerProvider).imagePath,
      '/picked/meal.jpg',
    );
  });

  test('restores a recovered picker image into the analysis state', () async {
    final calls = <String>[];
    final container = ProviderContainer(
      overrides: [
        foodScanImageServiceProvider.overrideWith(
          (ref) => _FakeFoodScanImageService(calls),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container
        .read(foodScanControllerProvider.notifier)
        .recoverLostPickerImage('test-user');

    final state = container.read(foodScanControllerProvider);
    expect(state.phase, FoodScanPhase.readyToAnalyze);
    expect(state.imagePath, '/recovered/meal.jpg');
  });
}

class _FakeFoodScanImageService extends FoodScanImageService {
  final List<String> calls;

  _FakeFoodScanImageService(this.calls);

  @override
  Future<PreparedFoodScanImage?> pickGallery({required String userId}) async {
    calls.add('gallery');
    return const PreparedFoodScanImage(path: '/picked/meal.jpg');
  }

  @override
  Future<PreparedFoodScanImage?> retrieveLostImage({
    required String userId,
  }) async {
    calls.add('retrieve');
    return const PreparedFoodScanImage(path: '/recovered/meal.jpg');
  }
}

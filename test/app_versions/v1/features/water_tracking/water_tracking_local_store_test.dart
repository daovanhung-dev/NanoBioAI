import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/water_tracking/data/water_tracking_local_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late String? currentUserId;
  late SharedPreferencesWaterTrackingLocalStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
    currentUserId = null;
    store = SharedPreferencesWaterTrackingLocalStore(
      currentUserId: () => currentUserId,
    );
  });

  test('isolates target and daily amount between member namespaces', () async {
    final day = DateTime(2026, 8, 8);

    currentUserId = 'member-a';
    await store.saveTargetMl(1800);
    await store.saveAmountMl(day, 600);

    currentUserId = 'member-b';
    expect(
      await store.load(day),
      isA<WaterTrackingSnapshot>()
          .having((snapshot) => snapshot.targetMl, 'targetMl', isNull)
          .having((snapshot) => snapshot.amountMl, 'amountMl', 0),
    );
    await store.saveTargetMl(2200);
    await store.saveAmountMl(day, 900);

    currentUserId = 'member-a';
    expect(
      await store.load(day),
      isA<WaterTrackingSnapshot>()
          .having((snapshot) => snapshot.targetMl, 'targetMl', 1800)
          .having((snapshot) => snapshot.amountMl, 'amountMl', 600),
    );

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getKeys(),
      containsAll(<String>{
        'wellness.water.v2.member:member-a.target_ml',
        'wellness.water.v2.member:member-a.amount_ml.2026-08-08',
        'wellness.water.v2.member:member-b.target_ml',
        'wellness.water.v2.member:member-b.amount_ml.2026-08-08',
      }),
    );
  });

  test(
    'uses one install guest namespace without exposing member data',
    () async {
      final day = DateTime(2026, 8, 8);

      await store.saveTargetMl(1500);
      await store.saveAmountMl(day, 350);

      currentUserId = 'member-a';
      expect(
        await store.load(day),
        isA<WaterTrackingSnapshot>()
            .having((snapshot) => snapshot.targetMl, 'targetMl', isNull)
            .having((snapshot) => snapshot.amountMl, 'amountMl', 0),
      );

      currentUserId = '   ';
      expect(
        await store.load(day),
        isA<WaterTrackingSnapshot>()
            .having((snapshot) => snapshot.targetMl, 'targetMl', 1500)
            .having((snapshot) => snapshot.amountMl, 'amountMl', 350),
      );

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getKeys(),
        containsAll(<String>{
          'wellness.water.v2.guest:install.target_ml',
          'wellness.water.v2.guest:install.amount_ml.2026-08-08',
        }),
      );
    },
  );
}

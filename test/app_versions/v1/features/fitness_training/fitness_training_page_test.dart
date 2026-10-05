import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/application/fitness_training_controller.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/application/fitness_training_service.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/entities/fitness_training_profile.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/entities/fitness_schedule_conflict.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/entities/fitness_training_program.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/repositories/fitness_training_profile_repository.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/repositories/fitness_training_repository.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/presentation/pages/fitness_training_page.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/providers/fitness_training_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profile review proceeds to gym/home setup with pilot disclosure', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final controller = FitnessTrainingController(
      service: FitnessTrainingService(repository: _EmptyRepository()),
      profileRepository: _ProfileRepository(_adultProfile),
      currentUserId: () => 'user-1',
      now: () => DateTime(2026, 10, 5),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fitnessTrainingControllerProvider.overrideWithValue(controller),
        ],
        child: const MaterialApp(home: FitnessTrainingPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Bản thử nghiệm: nội dung bài tập và minh họa đang chờ rà soát chuyên môn. Đây là gợi ý wellness, không thay thế tư vấn y tế hoặc huấn luyện viên.',
      ),
      findsOneWidget,
    );
    expect(find.text('Đủ 18 tuổi'), findsOneWidget);
    expect(find.text('Rà soát hồ sơ'), findsOneWidget);

    final reviewConfirmation = find.text(
      'Tôi đã rà soát và xác nhận hồ sơ bên trên.',
    );
    await tester.scrollUntilVisible(
      reviewConfirmation,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.ancestor(
        of: reviewConfirmation,
        matching: find.byType(CheckboxListTile),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Tiếp tục thiết lập'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Tiếp tục thiết lập'));
    await tester.pumpAndSettle();

    expect(find.text('Bạn thường tập ở đâu?'), findsOneWidget);
    expect(find.text('Chọn thiết bị bạn có thể dùng'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Máy chạy bộ')), findsWidgets);

    await tester.tap(find.text('Tại nhà'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn thiết bị bạn có thể dùng'), findsNothing);
    expect(find.text('Vùng vận động cần tránh'), findsOneWidget);
    expect(find.text('Dị ứng cần loại trừ'), findsNothing);
    expect(find.text('Giờ ngủ'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Đồng ý tạo gợi ý bằng AI'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Đồng ý tạo gợi ý bằng AI'));
    await tester.pumpAndSettle();
    final generateButton = find.widgetWithText(
      FilledButton,
      'Tạo bản xem trước 4 tuần',
    );
    await tester.scrollUntilVisible(
      generateButton,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(generateButton).onPressed, isNotNull);
    debugDefaultTargetPlatformOverride = null;
  });
}

final _adultProfile = FitnessTrainingProfileSnapshot(
  userId: 'user-1',
  fullName: 'Người tập',
  birthDate: DateTime(1990, 4, 12),
  goals: const ['Vận động đều'],
  conditions: const [],
  foodRestrictions: const ['động vật có vỏ'],
  heightCm: 170,
  weightKg: 68,
  gender: 'female',
  activityLevel: 'light',
  sleepTime: '22:00',
  wakeTime: '06:00',
  mealTimes: const ['07:30', '10:00', '12:30', '15:30', '19:00'],
  workoutTime: '17:30',
);

class _ProfileRepository implements FitnessTrainingProfileRepository {
  const _ProfileRepository(this.profile);

  final FitnessTrainingProfileSnapshot profile;

  @override
  Future<FitnessTrainingProfileSnapshot> load(
    String? authenticatedUserId,
  ) async => profile;

  @override
  Future<void> saveBirthDate({
    required String userId,
    required DateTime birthDate,
  }) async {}
}

class _EmptyRepository implements FitnessTrainingRepository {
  @override
  Future<bool> guestInitialPlanAvailable(String userId) async => true;

  @override
  Future<List<FitnessTrainingProgram>> loadPrograms(String userId) async =>
      const [];

  @override
  Future<FitnessTrainingProgram?> findByRequestId(
    String userId,
    String requestId,
  ) async => null;

  @override
  Future<FitnessTrainingProgram> savePreview(
    FitnessTrainingProgram program, {
    required bool guest,
  }) => Future.error(UnimplementedError());

  @override
  Future<void> markQuotaCommitted({
    required String userId,
    required String programId,
  }) => Future.error(UnimplementedError());

  @override
  Future<FitnessTrainingProgram> saveCheckIn({
    required String userId,
    required String programId,
    required FitnessWeeklyCheckIn checkIn,
  }) => Future.error(UnimplementedError());

  @override
  Future<List<FitnessScheduleConflict>> findScheduleConflicts({
    required String userId,
    required List<FitnessWorkoutScheduleSlot> slots,
    required DateTime now,
  }) async => const [];

  @override
  Future<FitnessTrainingProgram> applyWeek({
    required String userId,
    required String programId,
    required int week,
    required DateTime today,
    required catalog,
    String? workoutTimeOverride,
  }) => Future.error(UnimplementedError());
}

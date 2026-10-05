import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/application/fitness_training_controller.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/application/fitness_training_service.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/entities/fitness_training_catalog.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/entities/fitness_training_profile.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/entities/fitness_schedule_conflict.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/entities/fitness_training_program.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/repositories/fitness_training_profile_repository.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/repositories/fitness_training_repository.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/domain/services/fitness_program_validator.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/presentation/pages/fitness_training_page.dart';
import 'package:nano_app/app_versions/v1/features/fitness_training/providers/fitness_training_providers.dart';
import 'package:nano_app/app_versions/v1/services/ai/gemini_rest_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('profile review proceeds to gym/home setup with pilot disclosure', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final repository = _EmptyRepository(
      conflictsByTime: {
        '17:30': [_conflict()],
      },
    );
    var aiCalls = 0;
    final controller = FitnessTrainingController(
      service: FitnessTrainingService(
        repository: repository,
        currentUserId: () => null,
        now: () => DateTime(2026, 10, 5, 8),
        validator: _PageAcceptingValidator(),
        aiClientFactory: (_) => _FakeAiClient(() {
          aiCalls++;
          return '{}';
        }),
      ),
      profileRepository: _ProfileRepository(_adultProfile),
      currentUserId: () => null,
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
    await tester.tap(generateButton);
    await _pumpUntilVisible(tester, find.text('Giờ tập đang bị trùng'));
    expect(find.textContaining('sang 16:30'), findsOneWidget);
    expect(find.textContaining('1 xung đột lịch'), findsOneWidget);
    expect(find.textContaining('lịch hiện có được giữ nguyên'), findsOneWidget);
    await tester.tap(find.text('Giữ giờ đã chọn'));
    await tester.pumpAndSettle();

    expect(aiCalls, 0);
    expect(repository.saveCalls, 0);
    expect(repository.program, isNull);
    expect(
      find.textContaining('Giờ tập bị trùng với lịch hiện có.'),
      findsOneWidget,
    );
    expect(find.text('Giờ tập đang bị trùng'), findsNothing);

    await _tapCreateAndWaitForTimeConsent(tester);
    await tester.tap(find.text('Đồng ý đổi giờ'));
    await _pumpUntilVisible(tester, find.text('Xác nhận và áp dụng tuần 1'));
    expect(aiCalls, 1);
    expect(repository.saveCalls, 1);
    expect(repository.program!.intake.workoutTime, '16:30');
    expect(repository.program!.intake.mealTimes, isEmpty);
    expect(find.textContaining('Giờ tập 16:30'), findsOneWidget);

    final applyButton = find.text('Xác nhận và áp dụng tuần 1');
    await tester.scrollUntilVisible(
      applyButton,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(applyButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
    await _pumpUntilVisible(tester, find.text('Giờ tập đang bị trùng'));
    expect(find.textContaining('sang 17:30'), findsOneWidget);
    await tester.tap(find.text('Đồng ý đổi giờ'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Giờ tập 17:30'), findsOneWidget);

    await tester.scrollUntilVisible(
      applyButton,
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(applyButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
    await _pumpUntilVisible(
      tester,
      find.text('Đã áp dụng lịch luyện tập của bạn.'),
    );
    expect(aiCalls, 1);
    expect(repository.applyCalls, 2);
    expect(repository.appliedTimes, ['16:30', '17:30']);
    debugDefaultTargetPlatformOverride = null;
  });
}

Future<void> _tapCreateAndWaitForTimeConsent(WidgetTester tester) async {
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
  await tester.tap(generateButton);
  await _pumpUntilVisible(tester, find.text('Giờ tập đang bị trùng'));
}

Future<void> _pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  int attempts = 60,
}) async {
  for (var attempt = 0; attempt < attempts; attempt++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data ?? widget.textSpan?.toPlainText() ?? '')
      .join(' | ');
  fail('Timed out waiting for $finder. Current text: $visibleText');
}

FitnessScheduleConflict _conflict() => FitnessScheduleConflict(
  workoutStartAt: DateTime(2026, 10, 5, 17, 30),
  workoutEndAt: DateTime(2026, 10, 5, 18, 15),
  itemTitle: 'Lịch khác',
  itemStartAt: DateTime(2026, 10, 5, 17, 30),
  itemEndAt: DateTime(2026, 10, 5, 18),
);

FitnessScheduleConflict _conflictAt(DateTime startAt) =>
    FitnessScheduleConflict(
      workoutStartAt: startAt,
      workoutEndAt: startAt.add(const Duration(minutes: 45)),
      itemTitle: 'Lịch khác',
      itemStartAt: startAt,
      itemEndAt: startAt.add(const Duration(minutes: 30)),
    );

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
  _EmptyRepository({this.conflictsByTime = const {}});

  final Map<String, List<FitnessScheduleConflict>> conflictsByTime;
  FitnessTrainingProgram? program;
  int saveCalls = 0;
  int applyCalls = 0;
  bool staleConflictAfterApply = false;
  final List<String?> appliedTimes = [];

  @override
  Future<bool> guestInitialPlanAvailable(String userId) async => true;

  @override
  Future<List<FitnessTrainingProgram>> loadPrograms(String userId) async =>
      program == null ? const [] : [program!];

  @override
  Future<FitnessTrainingProgram?> findByRequestId(
    String userId,
    String requestId,
  ) async => program?.requestId == requestId ? program : null;

  @override
  Future<FitnessTrainingProgram> savePreview(
    FitnessTrainingProgram program, {
    required bool guest,
  }) async {
    saveCalls++;
    this.program = program.copyWith(quotaCommitted: guest);
    return this.program!;
  }

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
  Future<Map<String, List<FitnessScheduleConflict>>>
  findScheduleConflictsByWorkoutTime({
    required String userId,
    required Map<String, List<FitnessWorkoutScheduleSlot>> slotsByTime,
    required DateTime now,
  }) async => {
    for (final time in slotsByTime.keys)
      time: staleConflictAfterApply
          ? (time == '16:30'
                ? [_conflictAt(DateTime(2026, 10, 5, 16, 30))]
                : const [])
          : (conflictsByTime[time] ?? const []),
  };

  @override
  Future<FitnessTrainingProgram> applyWeek({
    required String userId,
    required String programId,
    required int week,
    required DateTime today,
    required catalog,
    String? workoutTimeOverride,
  }) async {
    applyCalls++;
    appliedTimes.add(workoutTimeOverride ?? program?.intake.workoutTime);
    if (applyCalls == 1) {
      staleConflictAfterApply = true;
      throw FitnessScheduleConflictException([
        _conflictAt(DateTime(2026, 10, 5, 16, 30)),
      ]);
    }
    return program!.copyWith(
      status: FitnessProgramStatus.active,
      activeWeek: week,
      updatedAt: today,
    );
  }
}

class _FakeAiClient implements AiTextClient {
  const _FakeAiClient(this.respond);

  final String Function() respond;

  @override
  Future<String> generateText({
    required String model,
    required List<GeminiContent> contents,
    required GeminiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async => respond();

  @override
  Stream<String> streamText({
    required String model,
    required List<GeminiContent> contents,
    required GeminiGenerationConfig generationConfig,
    String? systemInstruction,
  }) async* {}
}

class _PageAcceptingValidator extends FitnessProgramValidator {
  @override
  FitnessTrainingProgram parse({
    required String response,
    required String userId,
    required String requestId,
    required String programId,
    required String status,
    required bool quotaCommitted,
    required FitnessTrainingIntake intake,
    required FitnessTrainingCatalog catalog,
    required DateTime startDate,
    required DateTime now,
    int firstDayIndex = 0,
    List<FitnessProgramDay> preservedDays = const [],
    List<FitnessWeeklyCheckIn> checkIns = const [],
    String? parentProgramId,
  }) => FitnessTrainingProgram(
    id: programId,
    userId: userId,
    requestId: requestId,
    status: status,
    activeWeek: 1,
    quotaCommitted: quotaCommitted,
    startDate: startDate,
    intake: intake,
    days: [
      for (var index = 0; index < 28; index++)
        () {
          final date = startDate.add(Duration(days: index));
          final hasWorkout = intake.trainingWeekdays.contains(date.weekday);
          return FitnessProgramDay(
            dayIndex: index,
            date: date,
            isRestDay: !hasWorkout,
            exercises: hasWorkout
                ? [
                    FitnessWorkoutExercise(
                      exerciseId: catalog.exercises.first.id,
                      sets: 3,
                      reps: 10,
                      durationMinutes: null,
                      restSeconds: 60,
                    ),
                  ]
                : const [],
            meals: const [],
            sleepTime: '',
            wakeTime: '',
          );
        }(),
    ],
    checkIns: checkIns,
    createdAt: now,
    updatedAt: now,
    parentProgramId: parentProgramId,
  );
}

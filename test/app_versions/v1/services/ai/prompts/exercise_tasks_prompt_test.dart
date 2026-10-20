import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/services/ai/prompts/exercise_tasks_prompt.dart';

void main() {
  test('exercise prompt includes the requested day and prior use counts', () {
    final prompt = ExerciseTasksPrompt.generate(
      startDate: DateTime(2026, 10, 13),
      startDay: 6,
      days: 1,
      catalog: const [],
      usedExerciseCodeCounts: const {
        'ex_walk_relaxed': 2,
        'ex_mobility_easy': 1,
      },
    );

    expect(prompt, contains('"day": 6'));
    expect(prompt, isNot(contains('"day": 1')));
    expect(prompt, contains('ex_walk_relaxed: 2 lần'));
    expect(prompt, contains('ex_mobility_easy: 1 lần'));
    expect(prompt, contains('2 different codes'));
    expect(prompt, contains('Avoid codes used at least twice'));
  });
}

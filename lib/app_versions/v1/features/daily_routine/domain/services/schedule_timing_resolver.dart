import '../entities/daily_routine_preferences.dart';

class ResolvedDayTiming {
  final RoutineDayTemplate template;

  const ResolvedDayTiming(this.template);

  RoutineTimeRange mealRange(int mealOrder) {
    const durations = [30, 15, 45, 15, 45];
    if (mealOrder < 1 || mealOrder > 5) {
      throw RangeError.range(mealOrder, 1, 5, 'mealOrder');
    }
    final start = template.mealTimes[mealOrder - 1];
    return RoutineTimeRange(
      start: start,
      end: _shift(start, durations[mealOrder - 1]),
    );
  }

  RoutineTimeRange workoutRange(int index) => template.workoutRanges[index];

  RoutineTimeRange get wakeRange => RoutineTimeRange(
    start: template.wakeTime,
    end: _shift(template.wakeTime, 15),
  );

  RoutineTimeRange get morningWaterRange => RoutineTimeRange(
    start: _shift(template.wakeTime, 15),
    end: _shift(template.wakeTime, 20),
  );

  RoutineTimeRange get sleepPreparationRange => RoutineTimeRange(
    start: _shift(template.sleepTime, -15),
    end: template.sleepTime,
  );

  RoutineTimeRange? get napRange =>
      template.napEnabled ? template.napRange : null;
}

class ScheduleTimingResolver {
  const ScheduleTimingResolver();

  ResolvedDayTiming resolve(
    DailyRoutinePreferences preferences,
    DateTime date,
  ) {
    final errors = preferences.validate();
    if (errors.isNotEmpty) throw FormatException(errors.first);
    return ResolvedDayTiming(preferences.templateFor(date));
  }
}

String _shift(String value, int deltaMinutes) {
  final hour = int.parse(value.substring(0, 2));
  final minute = int.parse(value.substring(3, 5));
  final shifted = (hour * 60 + minute + deltaMinutes) % 1440;
  final normalized = shifted < 0 ? shifted + 1440 : shifted;
  return '${(normalized ~/ 60).toString().padLeft(2, '0')}:'
      '${(normalized % 60).toString().padLeft(2, '0')}';
}

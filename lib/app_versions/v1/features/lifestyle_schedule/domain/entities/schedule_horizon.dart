class ScheduleHorizon {
  final DateTime? lastScheduledDate;
  final int remainingDays;
  final DateTime nextStartDate;

  const ScheduleHorizon({
    required this.lastScheduledDate,
    required this.remainingDays,
    required this.nextStartDate,
  });

  bool get canGenerate => remainingDays <= 1;
}

class ScheduleHorizonDataException implements Exception {
  static const userMessage =
      'Nabi chưa đọc được ngày lịch. Hãy thử lại sau khi dữ liệu được kiểm tra.';

  const ScheduleHorizonDataException();

  @override
  String toString() => userMessage;
}

class PersonalScheduleStillActiveException implements Exception {
  static const userMessage =
      'Lịch hiện tại còn ít nhất 2 ngày. Hãy quay lại khi còn 1 ngày.';

  final int remainingDays;

  const PersonalScheduleStillActiveException(this.remainingDays);

  @override
  String toString() => userMessage;
}

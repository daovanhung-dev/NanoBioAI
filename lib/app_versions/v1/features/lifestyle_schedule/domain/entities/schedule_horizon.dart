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
      'Nabi chưa đọc được ngày trong lịch hiện tại. Bạn chưa nên tạo lịch mới cho đến khi dữ liệu được kiểm tra lại nhé.';

  const ScheduleHorizonDataException();

  @override
  String toString() => userMessage;
}

class PersonalScheduleStillActiveException implements Exception {
  static const userMessage =
      'Lịch trình hiện tại vẫn còn ít nhất 2 ngày. Bạn tiếp tục theo lịch này rồi quay lại khi còn 1 ngày nhé.';

  final int remainingDays;

  const PersonalScheduleStillActiveException(this.remainingDays);

  @override
  String toString() => userMessage;
}

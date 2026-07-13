class VietnamTime {
  static const offset = Duration(hours: 7);

  const VietnamTime._();

  /// Chuyển một instant thành đồng hồ tường Asia/Ho_Chi_Minh (UTC+7, không DST).
  static DateTime wallClock(DateTime value) {
    final shifted = value.toUtc().add(offset);
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
      shifted.microsecond,
    );
  }
}

enum ScheduleHealthActionType {
  photoProof,
  quickComplete,
  hydration,
  moodStress,
  sleepCheckIn,
  weightCheckIn,
}

extension ScheduleHealthActionTypeX on ScheduleHealthActionType {
  String get stableCode => switch (this) {
    ScheduleHealthActionType.photoProof => 'photo_proof',
    ScheduleHealthActionType.quickComplete => 'quick_complete',
    ScheduleHealthActionType.hydration => 'hydration',
    ScheduleHealthActionType.moodStress => 'mood_stress',
    ScheduleHealthActionType.sleepCheckIn => 'sleep_checkin',
    ScheduleHealthActionType.weightCheckIn => 'weight_checkin',
  };

  String get label => switch (this) {
    ScheduleHealthActionType.photoProof => 'Chụp ảnh minh chứng',
    ScheduleHealthActionType.quickComplete => 'Xác nhận nhanh',
    ScheduleHealthActionType.hydration => 'Ghi nhận nước',
    ScheduleHealthActionType.moodStress => 'Check-in cảm xúc',
    ScheduleHealthActionType.sleepCheckIn => 'Ghi nhận giấc ngủ',
    ScheduleHealthActionType.weightCheckIn => 'Ghi nhận cân nặng',
  };

  static ScheduleHealthActionType? fromStableCode(String? value) {
    final normalized = value?.trim().toLowerCase();
    for (final action in ScheduleHealthActionType.values) {
      if (action.stableCode == normalized) return action;
    }
    return null;
  }
}

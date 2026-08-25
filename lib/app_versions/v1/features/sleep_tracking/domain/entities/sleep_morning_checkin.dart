class SleepMorningCheckin {
  const SleepMorningCheckin({
    required this.timeInBedMinutes,
    required this.sleepLatencyMinutes,
    required this.rememberedAwakenings,
    required this.awakeDuringNightMinutes,
    required this.restfulness,
  });

  final int timeInBedMinutes;
  final int sleepLatencyMinutes;
  final int rememberedAwakenings;
  final int awakeDuringNightMinutes;
  final int restfulness;

  int get estimatedSleepMinutes => (timeInBedMinutes -
          sleepLatencyMinutes -
          awakeDuringNightMinutes)
      .clamp(0, timeInBedMinutes).toInt();

  Map<String, Object?> toJson() => {
        'time_in_bed_minutes': timeInBedMinutes,
        'sleep_latency_minutes': sleepLatencyMinutes,
        'remembered_awakenings': rememberedAwakenings,
        'awake_during_night_minutes': awakeDuringNightMinutes,
        'restfulness': restfulness,
      };

  factory SleepMorningCheckin.fromJson(Map<String, Object?> json) {
    int readInt(String key, {int fallback = 0}) =>
        (json[key] as num?)?.toInt() ?? fallback;

    return SleepMorningCheckin(
      timeInBedMinutes: readInt('time_in_bed_minutes'),
      sleepLatencyMinutes: readInt('sleep_latency_minutes'),
      rememberedAwakenings: readInt('remembered_awakenings'),
      awakeDuringNightMinutes: readInt('awake_during_night_minutes'),
      restfulness: readInt('restfulness', fallback: 3).clamp(1, 5).toInt(),
    );
  }
}

import '../entities/daily_health_profile_entity.dart';
import '../entities/daily_health_task_entity.dart';

class DailyHealthTaskGenerator {
  const DailyHealthTaskGenerator();

  List<DailyHealthTaskEntity> generate({
    required DailyHealthProfileEntity profile,
    required String taskDate,
    required String createdAt,
  }) {
    final tasks = <DailyHealthTaskEntity>[
      _task(
        profile: profile,
        taskDate: taskDate,
        createdAt: createdAt,
        code: 'water_daily',
        category: 'water',
        title: 'Uống đủ nước',
        description: 'Chia đều trong ngày, mỗi lần một cốc nhỏ.',
        targetValue: _waterTarget(profile.waterPerDay),
        unit: 'ml',
        sortOrder: 1,
        encouragement: 'Tuyệt vời, cơ thể của bạn đang được tiếp nước đều đặn.',
      ),
      _task(
        profile: profile,
        taskDate: taskDate,
        createdAt: createdAt,
        code: 'body_steps',
        category: 'body',
        title: 'Vận động cơ thể',
        description: 'Đi bộ nhẹ hoặc vận động ngắt quãng trong ngày.',
        targetValue: _stepsTarget(profile.activityLevel).toDouble(),
        unit: 'bước',
        sortOrder: 2,
        encouragement:
            'Cơ thể đã được đánh thức, cứ giữ nhịp nhẹ nhàng như vậy.',
      ),
      _task(
        profile: profile,
        taskDate: taskDate,
        createdAt: createdAt,
        code: 'mind_breathing',
        category: 'mind',
        title: _hasStressSignal(profile)
            ? 'Thở chậm để hạ căng thẳng'
            : 'Dừng lại và thở sâu',
        description: 'Dành 3 phút hít thở chậm, thả lỏng vai và mắt.',
        targetValue: 1,
        unit: 'lần',
        sortOrder: 3,
        encouragement: 'Tâm trí vừa có một khoảng nghỉ tử tế.',
      ),
      _task(
        profile: profile,
        taskDate: taskDate,
        createdAt: createdAt,
        code: 'brain_health_note',
        category: 'brain',
        title: 'Ghi nhớ một điều tốt cho sức khỏe',
        description: 'Đọc lại gợi ý hôm nay hoặc review nhanh thực đơn.',
        targetValue: 1,
        unit: 'lần',
        sortOrder: 4,
        encouragement:
            'Một chút hiểu biết hôm nay sẽ thành thói quen ngày mai.',
      ),
    ];

    for (final extra in _extraTasks(profile, taskDate, createdAt)) {
      if (tasks.length >= 6) break;
      if (!tasks.any((task) => task.taskCode == extra.taskCode)) {
        tasks.add(extra);
      }
    }

    return tasks;
  }

  List<DailyHealthTaskEntity> _extraTasks(
    DailyHealthProfileEntity profile,
    String taskDate,
    String createdAt,
  ) {
    final extras = <DailyHealthTaskEntity>[];
    final habits = profile.habits.map(_normalize).toList();

    if (habits.any((item) => item.contains('low_water')) ||
        _waterTarget(profile.waterPerDay) < 2000) {
      extras.add(
        _task(
          profile: profile,
          taskDate: taskDate,
          createdAt: createdAt,
          code: 'water_morning',
          category: 'water',
          title: 'Bắt đầu bằng một cốc nước',
          description: 'Uống 250ml nước trước bữa đầu tiên trong ngày.',
          targetValue: 250,
          unit: 'ml',
          sortOrder: 5,
          encouragement: 'Một khởi đầu rất gọn cho nhịp nước hôm nay.',
        ),
      );
    }

    if (_sleepNeedsCare(profile.sleepQuality) || _hasInsomniaSignal(profile)) {
      extras.add(
        _task(
          profile: profile,
          taskDate: taskDate,
          createdAt: createdAt,
          code: 'mind_sleep_reset',
          category: 'mind',
          title: 'Chuẩn bị ngủ dễ hơn',
          description: 'Giảm màn hình và chọn một việc nhẹ trước giờ ngủ.',
          targetValue: 1,
          unit: 'lần',
          sortOrder: 6,
          encouragement: 'Bạn vừa đặt một viên gạch nhỏ cho giấc ngủ tối nay.',
        ),
      );
    }

    if (habits.any(
      (item) =>
          item.contains('eat_late') ||
          item.contains('late_meals') ||
          item.contains('skip_breakfast') ||
          item.contains('skip_meals') ||
          item.contains('fast_food'),
    )) {
      extras.add(
        _task(
          profile: profile,
          taskDate: taskDate,
          createdAt: createdAt,
          code: 'body_meal_rhythm',
          category: 'body',
          title: 'Giữ nhịp ăn ổn định',
          description: 'Ăn đúng bữa hơn hôm qua, ưu tiên món nhẹ và đủ rau.',
          targetValue: 1,
          unit: 'lần',
          sortOrder: 7,
          encouragement: 'Nhịp ăn ổn hơn là một tín hiệu rất đáng mừng.',
        ),
      );
    }

    if (_hasStressSignal(profile)) {
      extras.add(
        _task(
          profile: profile,
          taskDate: taskDate,
          createdAt: createdAt,
          code: 'mind_mood_check',
          category: 'mind',
          title: 'Chấm nhanh cảm xúc',
          description:
              'Gọi tên cảm xúc hiện tại và chọn một việc nhỏ để dịu lại.',
          targetValue: 1,
          unit: 'lần',
          sortOrder: 8,
          encouragement: 'Bạn vừa lắng nghe mình rõ hơn một chút.',
        ),
      );
    }

    return extras;
  }

  DailyHealthTaskEntity _task({
    required DailyHealthProfileEntity profile,
    required String taskDate,
    required String createdAt,
    required String code,
    required String category,
    required String title,
    required String description,
    required double targetValue,
    required String unit,
    required int sortOrder,
    required String encouragement,
  }) {
    return DailyHealthTaskEntity(
      id: 'daily_${profile.userId}_${taskDate}_$code',
      userId: profile.userId,
      taskDate: taskDate,
      taskCode: code,
      category: category,
      title: title,
      description: description,
      targetValue: targetValue,
      currentValue: 0,
      unit: unit,
      isCompleted: false,
      sortOrder: sortOrder,
      source: 'profile',
      encouragement: encouragement,
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  double _waterTarget(String waterPerDay) {
    final text = _normalize(waterPerDay);
    if (text.contains('less_1') ||
        text.contains('duoi 1') ||
        text.contains('duoi_1')) {
      return 1500;
    }
    if (text.contains('1_to_1_5') || text.contains('1-1.5')) {
      return 1800;
    }
    if (text.contains('1_5_to_2') || text.contains('1.5-2')) {
      return 2000;
    }
    if (text.contains('2_to_3') || text.contains('2-3')) {
      return 2500;
    }
    if (text.contains('more_3') || text.contains('tren 3')) {
      return 3000;
    }
    return 2000;
  }

  int _stepsTarget(String activityLevel) {
    final text = _normalize(activityLevel);
    if (text.contains('sedentary') || text.contains('it van dong')) return 3000;
    if (text.contains('light') || text.contains('nhe')) return 5000;
    if (text.contains('moderate') || text.contains('trung binh')) return 7000;
    if (text.contains('very_active') || text.contains('rat nang dong'))
      return 10000;
    if (text.contains('active') || text.contains('nang dong')) return 9000;
    return 5000;
  }

  bool _sleepNeedsCare(String sleepQuality) {
    final text = _normalize(sleepQuality);
    return text.contains('poor') ||
        text.contains('very_poor') ||
        text.contains('mat ngu') ||
        text.contains('kem');
  }

  bool _hasInsomniaSignal(DailyHealthProfileEntity profile) {
    return profile.conditions.any(
      (item) => _normalize(item).contains('mat ngu'),
    );
  }

  bool _hasStressSignal(DailyHealthProfileEntity profile) {
    final values = [
      ...profile.goals,
      ...profile.conditions,
      profile.sleepQuality,
    ].map(_normalize);
    return values.any(
      (item) => item.contains('stress') || item.contains('cang thang'),
    );
  }

  String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('đ', 'd')
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ả', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('ạ', 'a')
        .replaceAll('ă', 'a')
        .replaceAll('ắ', 'a')
        .replaceAll('ằ', 'a')
        .replaceAll('ẳ', 'a')
        .replaceAll('ẵ', 'a')
        .replaceAll('ặ', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ấ', 'a')
        .replaceAll('ầ', 'a')
        .replaceAll('ẩ', 'a')
        .replaceAll('ẫ', 'a')
        .replaceAll('ậ', 'a')
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ẻ', 'e')
        .replaceAll('ẽ', 'e')
        .replaceAll('ẹ', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ế', 'e')
        .replaceAll('ề', 'e')
        .replaceAll('ể', 'e')
        .replaceAll('ễ', 'e')
        .replaceAll('ệ', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ì', 'i')
        .replaceAll('ỉ', 'i')
        .replaceAll('ĩ', 'i')
        .replaceAll('ị', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ỏ', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ọ', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ố', 'o')
        .replaceAll('ồ', 'o')
        .replaceAll('ổ', 'o')
        .replaceAll('ỗ', 'o')
        .replaceAll('ộ', 'o')
        .replaceAll('ơ', 'o')
        .replaceAll('ớ', 'o')
        .replaceAll('ờ', 'o')
        .replaceAll('ở', 'o')
        .replaceAll('ỡ', 'o')
        .replaceAll('ợ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ù', 'u')
        .replaceAll('ủ', 'u')
        .replaceAll('ũ', 'u')
        .replaceAll('ụ', 'u')
        .replaceAll('ư', 'u')
        .replaceAll('ứ', 'u')
        .replaceAll('ừ', 'u')
        .replaceAll('ử', 'u')
        .replaceAll('ữ', 'u')
        .replaceAll('ự', 'u')
        .replaceAll('ý', 'y')
        .replaceAll('ỳ', 'y')
        .replaceAll('ỷ', 'y')
        .replaceAll('ỹ', 'y')
        .replaceAll('ỵ', 'y');
  }
}

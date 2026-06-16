import '../../domain/entities/daily_health_profile_entity.dart';
import 'daily_health_task_model.dart';

class DailyHealthAiTaskNormalizer {
  static const categories = ['water', 'body', 'mind', 'brain'];

  const DailyHealthAiTaskNormalizer();

  List<DailyHealthTaskModel> normalize({
    required List<dynamic> items,
    required DailyHealthProfileEntity profile,
    required DateTime startDate,
    int days = 7,
    required String createdAt,
  }) {
    final expectedCount = days * categories.length;
    if (items.length != expectedCount) {
      throw FormatException(
        'Daily health AI response must contain exactly $expectedCount tasks',
      );
    }

    final byDateAndCategory = <String, Map<String, Map<String, dynamic>>>{};

    for (final item in items) {
      if (item is! Map) {
        throw const FormatException('Daily health AI task must be an object');
      }

      final map = Map<String, dynamic>.from(item);
      final taskDate = _readString(map['task_date']);
      final category = _readString(map['category']).toLowerCase();

      if (!categories.contains(category)) {
        throw FormatException('Invalid daily health category: $category');
      }

      final categoryMap = byDateAndCategory.putIfAbsent(taskDate, () => {});
      if (categoryMap.containsKey(category)) {
        throw FormatException('Duplicate task for $taskDate/$category');
      }
      categoryMap[category] = map;
    }

    final normalized = <DailyHealthTaskModel>[];
    for (var dayIndex = 0; dayIndex < days; dayIndex++) {
      final date = _dateKey(startDate.add(Duration(days: dayIndex)));
      final categoryMap = byDateAndCategory[date];
      if (categoryMap == null) {
        throw FormatException('Missing daily health tasks for $date');
      }

      for (
        var categoryIndex = 0;
        categoryIndex < categories.length;
        categoryIndex++
      ) {
        final category = categories[categoryIndex];
        final map = categoryMap[category];
        if (map == null) {
          throw FormatException('Missing $category task for $date');
        }

        normalized.add(
          DailyHealthTaskModel(
            id: 'daily_${profile.userId}_${date}_ai_$category',
            userId: profile.userId,
            taskDate: date,
            taskCode: 'ai_$category',
            category: category,
            title: _readString(
              map['title'],
              fallback: _fallbackTitle(category),
            ),
            description: _readString(map['description']),
            targetValue: _readPositiveDouble(map['target_value']),
            currentValue: 0,
            unit: _readString(map['unit'], fallback: 'lan'),
            isCompleted: false,
            sortOrder: categoryIndex + 1,
            source: 'ai',
            encouragement: _readString(map['encouragement']),
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
      }
    }

    return normalized;
  }

  static String _readString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static double _readPositiveDouble(Object? value) {
    final parsed = switch (value) {
      final num n => n.toDouble(),
      final String s => double.tryParse(s.trim()) ?? 1,
      _ => 1.0,
    };
    return parsed > 0 ? parsed : 1;
  }

  static String _fallbackTitle(String category) {
    switch (category) {
      case 'water':
        return 'Uong nuoc';
      case 'body':
        return 'Van dong';
      case 'mind':
        return 'Cham soc tam tri';
      case 'brain':
        return 'Kien thuc suc khoe';
      default:
        return 'Nhiem vu suc khoe';
    }
  }

  static String _dateKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

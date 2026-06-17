import 'package:nano_app/features/dashboard/domain/entities/dashboard_health_input.dart';
import 'package:nano_app/features/dashboard/domain/entities/dashboard_health_status.dart';
import 'package:nano_app/features/dashboard/domain/services/dashboard_health_calculator.dart';

class DashboardHealthStatusMapper {
  const DashboardHealthStatusMapper._();

  static DashboardHealthStatus fromDashboard({
    required Object? fullName,
    required Object? heightCm,
    required Object? weightKg,
    required Object? bmi,
    required Object? sleepQuality,
    required Object? activityLevel,
    required Object? waterPerDay,
    required Object? conditions,
    required Object? goals,
    Object? concernText,
  }) {
    final input = DashboardHealthInput(
      fullName: _resolveName(fullName),
      heightCm: _toNum(heightCm),
      weightKg: _toNum(weightKg),
      bmi: _toNum(bmi),
      sleepQuality: _toText(sleepQuality),
      activityLevel: _toText(activityLevel),
      waterPerDay: _toText(waterPerDay),
      conditions: _toCleanStringList(conditions),
      goals: _toCleanStringList(goals),
      concernText: _toText(concernText),
    );

    return DashboardHealthCalculator.calculate(input);
  }

  static String _resolveName(Object? fullName) {
    final name = fullName?.toString().trim();
    if (name == null || name.isEmpty) return 'Bạn';
    return name;
  }

  static num? _toNum(Object? value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString().replaceAll(',', '.'));
  }

  static String? _toText(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static List<String> _toCleanStringList(Object? value) {
    if (value == null) return const <String>[];

    if (value is String) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    if (value is Iterable) {
      return value
          .map((item) => item?.toString().trim())
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    final text = value.toString().trim();
    return text.isEmpty ? const <String>[] : <String>[text];
  }
}

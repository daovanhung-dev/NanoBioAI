import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nano_app/core/router/router.dart';
import 'package:nano_app/core/storage/localdb/app_prefs.dart';

import '../controllers/onboarding_controller.dart';

class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key});

  String _genderLabel(String value) {
    switch (value) {
      case 'male':
        return 'Nam';

      case 'female':
        return 'Nữ';

      default:
        return 'Khác';
    }
  }

  String _goalLabel(String code) {
    const labels = {
      'lose_weight': 'Giảm cân',
      'gain_weight': 'Tăng cân',
      'lose_belly_fat': 'Giảm mỡ bụng',
      'gain_muscle': 'Tăng cơ',
      'improve_digestion': 'Cải thiện tiêu hóa',
      'sleep_better': 'Ngủ ngon hơn',
      'reduce_fatigue': 'Giảm mệt mỏi',
      'increase_energy': 'Tăng năng lượng',
      'beautify_skin': 'Làm đẹp da',
      'immune_boost': 'Tăng đề kháng',
      'stable_blood_sugar': 'Ổn định đường huyết',
      'stable_blood_pressure': 'Ổn định huyết áp',
      'joint_health': 'Cải thiện xương khớp',
      'detox_body': 'Thanh lọc cơ thể',
      'overall_health': 'Cải thiện sức khỏe tổng thể',
    };

    return labels[code] ?? code;
  }

  String _conditionLabel(String code) {
    const labels = {
      'stomach_pain': 'Đau dạ dày',
      'constipation': 'Táo bón',
      'bloating': 'Đầy hơi, khó tiêu',
      'insomnia': 'Mất ngủ',
      'stress': 'Stress, căng thẳng',
      'joint_pain': 'Đau nhức xương khớp',
      'high_blood_sugar': 'Đường huyết cao',
      'blood_pressure_issue': 'Huyết áp cao/thấp',
      'high_cholesterol': 'Mỡ máu cao',
      'fatty_liver': 'Gan nhiễm mỡ',
      'tired_always': 'Hay mệt mỏi',
      'overweight': 'Thừa cân / béo phì',
      'underweight': 'Gầy yếu / khó hấp thu',
      'no_special_issue': 'Không có vấn đề đặc biệt',
    };

    return labels[code] ?? code;
  }

  String _habitLabel(String code) {
    const labels = {
      'skip_breakfast': 'Thường xuyên bỏ bữa sáng',
      'eat_late': 'Ăn khuya',
      'eat_sweet': 'Ăn nhiều đồ ngọt',
      'eat_oily': 'Ăn nhiều dầu mỡ',
      'low_vegetable': 'Ít ăn rau',
      'low_water': 'Uống ít nước',
      'fast_food': 'Ăn nhiều đồ ăn nhanh',
      'alcohol': 'Uống rượu bia',
      'coffee_high': 'Uống nhiều cà phê',
    };

    return labels[code] ?? code;
  }

  String _sleepLabel(String value) {
    switch (value) {
      case 'good':
        return 'Ngủ tốt';

      case 'normal':
        return 'Bình thường';

      case 'bad':
        return 'Khó ngủ / ngủ kém';

      default:
        return value;
    }
  }

  String _activityLabel(String value) {
    switch (value) {
      case 'low':
        return 'Ít vận động';

      case 'medium':
        return 'Vận động vừa';

      case 'high':
        return 'Vận động nhiều';

      default:
        return value;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);

    final controller = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            'Xem lại thông tin',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 24),

          _section(
            title: 'Thông tin cá nhân',
            children: [
              _item('Họ và tên', state.fullName),

              _item('Email', state.email),

              _item('Số điện thoại', state.phone),

              _item('Giới tính', _genderLabel(state.gender)),

              _item('Năm sinh', state.birthYear.toString()),

              _item('Nghề nghiệp', state.occupation),
            ],
          ),

          const SizedBox(height: 20),

          _section(
            title: 'Thông tin cơ thể',
            children: [
              _item('Chiều cao', '${state.heightCm.toStringAsFixed(1)} cm'),

              _item('Cân nặng', '${state.weightKg.toStringAsFixed(1)} kg'),

              _item('BMI', state.bmi.toStringAsFixed(1)),
            ],
          ),

          const SizedBox(height: 20),

          _section(
            title: 'Mục tiêu sức khỏe',
            children: [
              ...state.goals.map((goal) => _bullet(_goalLabel(goal))),

              if (state.otherGoal.trim().isNotEmpty) _bullet(state.otherGoal),
            ],
          ),

          const SizedBox(height: 20),

          _section(
            title: 'Tình trạng sức khỏe',
            children: [
              ...state.conditions.map(
                (condition) => _bullet(_conditionLabel(condition)),
              ),

              if (state.otherCondition.trim().isNotEmpty)
                _bullet(state.otherCondition),
            ],
          ),

          const SizedBox(height: 20),

          _section(
            title: 'Lối sống',
            children: [
              ...state.habits.map((habit) => _bullet(_habitLabel(habit))),

              _item('Chất lượng giấc ngủ', _sleepLabel(state.sleepQuality)),

              _item('Mức vận động', _activityLabel(state.activityLevel)),

              _item('Lượng nước / ngày', state.waterPerDay),
            ],
          ),

          if (state.treatmentName.trim().isNotEmpty ||
              state.medicationName.trim().isNotEmpty) ...[
            const SizedBox(height: 20),

            _section(
              title: 'Dị ứng thực phẩm',
              children: [
                _item('Tên dị ứng', state.allergyName),

                _item('Ghi chú', state.allergyNote),
              ],
            ),
          ],

          if (state.treatmentName.trim().isNotEmpty ||
              state.medicationName.trim().isNotEmpty) ...[
            const SizedBox(height: 20),

            _section(
              title: 'Điều trị hiện tại',
              children: [
                _item('Điều trị', state.treatmentName),

                _item('Thuốc đang dùng', state.medicationName),

                _item('Ghi chú', state.treatmentNote),
              ],
            ),
          ],

          const SizedBox(height: 20),

          _section(
            title: 'Mối quan tâm sức khỏe',
            children: [
              Text(state.concernText, style: const TextStyle(fontSize: 15)),
            ],
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,

            child: ElevatedButton(
              onPressed: () async {
                await controller.saveOnboarding();
                await AppPrefs.setOnboardingCompleted(true);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Đã lưu thông tin sức khỏe thành công'),
                    ),
                  );
                  AppNavigator.goDashboard(context);
                }
              },

              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),

                child: Text('Hoàn tất khảo sát'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.grey.shade300),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          ...children,
        ],
      ),
    );
  }

  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Expanded(
            flex: 4,

            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          Expanded(flex: 6, child: Text(value)),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text('• '),

          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import 'package:nano_app/core/theme/theme.dart';

class SleepTrackingPage extends StatelessWidget {
  const SleepTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MedicalComingSoonPage(
      eyebrow: 'NHỊP NGHỈ NGƠI',
      title: 'Hiểu giấc ngủ của bạn',
      message:
          'Theo dõi giờ ngủ, chất lượng nghỉ ngơi và những điều giúp cơ thể dịu xuống trước khi ngủ.',
      icon: Icons.bedtime_rounded,
      color: AppColors.tertiary,
      previewItems: [
        'Ghi nhận giờ ngủ và giờ thức thật nhanh',
        'Nhìn lại xu hướng nghỉ ngơi theo tuần',
        'Gợi ý thư giãn nhẹ trước giờ ngủ',
      ],
    );
  }
}

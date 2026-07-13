import 'package:flutter/material.dart';

import 'package:nano_app/core/theme/theme.dart';

class StressTrackingPage extends StatelessWidget {
  const StressTrackingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MedicalComingSoonPage(
      eyebrow: 'SỨC KHỎE TINH THẦN',
      title: 'Lắng nghe cảm xúc mỗi ngày',
      message:
          'Một góc riêng tư để ghi nhận mức căng thẳng, nhịp thở và những điều giúp bạn bình tĩnh hơn.',
      icon: Icons.self_improvement_rounded,
      color: AppColors.secondary,
      previewItems: [
        'Check-in cảm xúc trong vài giây',
        'Bài thở ngắn, dễ làm ở bất kỳ đâu',
        'Xu hướng cảm xúc được trình bày rõ ràng',
      ],
    );
  }
}

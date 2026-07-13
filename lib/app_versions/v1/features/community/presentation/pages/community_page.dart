import 'package:flutter/material.dart';

import 'package:nano_app/core/theme/theme.dart';

class CommunityPage extends StatelessWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MedicalComingSoonPage(
      eyebrow: 'CỘNG ĐỒNG AN TOÀN',
      title: 'Kết nối để cùng khỏe hơn',
      message:
          'Một không gian tích cực để chia sẻ thói quen, động lực và những tiến bộ nhỏ mỗi ngày.',
      icon: Icons.groups_rounded,
      color: AppColors.primary,
      previewItems: [
        'Chia sẻ theo chủ đề với quyền riêng tư rõ ràng',
        'Nội dung tích cực, không phán xét và có kiểm duyệt',
        'Theo dõi thử thách sức khỏe cùng bạn bè',
      ],
    );
  }
}

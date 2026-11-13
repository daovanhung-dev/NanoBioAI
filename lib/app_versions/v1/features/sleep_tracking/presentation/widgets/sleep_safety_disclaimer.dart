import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SleepSafetyDisclaimer extends StatelessWidget {
  const SleepSafetyDisclaimer({super.key});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              kIsWeb
                  ? 'Trên web, micro chỉ được theo dõi khi màn hình này đang mở và ở trước màn hình. Phiên sẽ tự dừng khi bạn chuyển tab, khóa màn hình hoặc rời màn hình giám sát; hãy bắt đầu lại khi quay về. Cảnh báo cần trang còn hoạt động và tính năng không thay thế thiết bị y tế hoặc hệ thống cấp cứu.'
                  : 'Giám sát giấc ngủ của NanoBio hỗ trợ phát hiện tín hiệu âm thanh cần chú ý và gửi cảnh báo sớm. Tính năng không phải thiết bị y tế và không thay thế hệ thống cấp cứu hoặc đánh giá của chuyên gia.',
            ),
          ),
        ],
      ),
    ),
  );
}

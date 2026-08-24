import 'package:flutter/material.dart';

class SleepSafetyDisclaimer extends StatelessWidget {
  const SleepSafetyDisclaimer({super.key});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Icon(Icons.info_outline_rounded,color:Theme.of(context).colorScheme.primary),
        const SizedBox(width:12),
        const Expanded(child:Text('Giám sát giấc ngủ của NanoBio hỗ trợ phát hiện tín hiệu âm thanh cần chú ý và gửi cảnh báo sớm. Tính năng không phải thiết bị y tế và không thay thế hệ thống cấp cứu hoặc đánh giá của chuyên gia.')),
      ]),
    ),
  );
}

import 'package:flutter/material.dart';
import '../../domain/services/sleep_safety_state_machine.dart';

class SleepSafetyStatusCard extends StatelessWidget {
  const SleepSafetyStatusCard({super.key,required this.phase,required this.sensitivity,required this.verifiedContacts,required this.onStart,required this.onStop,required this.busy});
  final SleepSafetyPhase phase;
  final String sensitivity;
  final int verifiedContacts;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final bool busy;
  @override
  Widget build(BuildContext context){
    final active=phase!=SleepSafetyPhase.idle&&phase!=SleepSafetyPhase.failed;
    final title=switch(phase){
      SleepSafetyPhase.idle=>'Giám sát đang tắt',SleepSafetyPhase.arming=>'Đang chuẩn bị giám sát',SleepSafetyPhase.calibrating=>'Nabi đang làm quen với âm thanh phòng',SleepSafetyPhase.monitoring=>'Giám sát giấc ngủ đang bật',SleepSafetyPhase.awaitingResponse=>'Đang chờ bạn xác nhận',SleepSafetyPhase.reminder=>'Nabi đang hỏi lại bạn',SleepSafetyPhase.escalating=>'Đang liên hệ người hỗ trợ',SleepSafetyPhase.cooldown=>'Đã ghi nhận bạn ổn',SleepSafetyPhase.failed=>'Giám sát vừa bị gián đoạn'};
    return Card(child:Padding(padding:const EdgeInsets.all(20),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      Row(children:[Icon(active?Icons.hearing_rounded:Icons.bedtime_outlined,size:34,color:Theme.of(context).colorScheme.primary),const SizedBox(width:12),Expanded(child:Text(title,style:Theme.of(context).textTheme.titleLarge))]),
      const SizedBox(height:16),
      Wrap(spacing:12,runSpacing:8,children:[Chip(label:Text('Độ nhạy: $sensitivity')),Chip(label:Text('Liên hệ đã xác minh: $verifiedContacts'))]),
      const SizedBox(height:16),
      SizedBox(width:double.infinity,child:active?OutlinedButton.icon(onPressed:busy?null:onStop,icon:const Icon(Icons.stop_circle_outlined),label:const Text('Dừng giám sát')):FilledButton.icon(onPressed:busy?null:onStart,icon:const Icon(Icons.nightlight_round),label:const Text('Bắt đầu giám sát đêm nay'))),
    ])));
  }
}

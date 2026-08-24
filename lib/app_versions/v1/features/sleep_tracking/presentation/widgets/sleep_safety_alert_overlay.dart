import 'dart:async';
import 'package:flutter/material.dart';
import 'sleep_safety_countdown.dart';

class SleepSafetyAlertOverlay extends StatefulWidget{
  const SleepSafetyAlertOverlay({super.key,required this.startedAt,required this.onOk,required this.onNeedHelp,required this.dispatching});
  final DateTime startedAt;
  final VoidCallback onOk;
  final VoidCallback onNeedHelp;
  final bool dispatching;
  @override State<SleepSafetyAlertOverlay> createState()=>_SleepSafetyAlertOverlayState();
}
class _SleepSafetyAlertOverlayState extends State<SleepSafetyAlertOverlay>{
  Timer? _timer; int _seconds=60;
  @override void initState(){super.initState();_update();_timer=Timer.periodic(const Duration(seconds:1),(_)=>_update());}
  void _update(){final value=60-DateTime.now().difference(widget.startedAt).inSeconds;if(mounted)setState(()=>_seconds=value.clamp(0,60));}
  @override void dispose(){_timer?.cancel();super.dispose();}
  @override Widget build(BuildContext context)=>Material(color:Colors.black54,child:Center(child:ConstrainedBox(constraints:const BoxConstraints(maxWidth:480),child:Card(margin:const EdgeInsets.all(24),child:Padding(padding:const EdgeInsets.all(24),child:Column(mainAxisSize:MainAxisSize.min,children:[
    Icon(Icons.health_and_safety_rounded,size:58,color:Theme.of(context).colorScheme.error),const SizedBox(height:14),
    Text('Bạn có ổn không?',style:Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight:FontWeight.w700)),const SizedBox(height:8),
    const Text('Nabi vừa nhận thấy một âm thanh bất thường cần được chú ý.',textAlign:TextAlign.center),const SizedBox(height:16),
    if(widget.dispatching) const Column(children:[CircularProgressIndicator(),SizedBox(height:12),Text('Nabi đang liên hệ người hỗ trợ đã xác minh…')]) else ...[
      SleepSafetyCountdown(seconds:_seconds),const SizedBox(height:8),
      const Text('Nếu bạn không phản hồi, Nabi sẽ liên hệ người hỗ trợ đã thiết lập.',textAlign:TextAlign.center),const SizedBox(height:20),
      Row(children:[Expanded(child:OutlinedButton(onPressed:widget.onOk,child:const Text('Tôi ổn'))),const SizedBox(width:12),Expanded(child:FilledButton(onPressed:widget.onNeedHelp,child:const Text('Tôi cần hỗ trợ')))]),
    ],
  ]))))));
}

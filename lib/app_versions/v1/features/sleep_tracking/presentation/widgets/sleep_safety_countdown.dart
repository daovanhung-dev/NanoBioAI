import 'package:flutter/material.dart';
class SleepSafetyCountdown extends StatelessWidget{
  const SleepSafetyCountdown({super.key,required this.seconds});
  final int seconds;
  @override Widget build(BuildContext context)=>Semantics(label:'Còn $seconds giây trước khi liên hệ người hỗ trợ',child:Text('$seconds giây',style:Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight:FontWeight.w700)));
}

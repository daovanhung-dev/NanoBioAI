import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/sleep_safety_providers.dart';

class SleepSafetySchedulePage extends ConsumerStatefulWidget{const SleepSafetySchedulePage({super.key});@override ConsumerState<SleepSafetySchedulePage> createState()=>_State();}
class _State extends ConsumerState<SleepSafetySchedulePage>{
  bool? enabled; TimeOfDay? start; TimeOfDay? end; Set<int>? days;
  @override Widget build(BuildContext context){final s=ref.watch(sleepSafetyControllerProvider);final p=s.preference;if(p==null)return const Scaffold(body:Center(child:CircularProgressIndicator()));enabled??=p.scheduleEnabled;start??=TimeOfDay(hour:p.scheduleStartMinutes~/60,minute:p.scheduleStartMinutes%60);end??=TimeOfDay(hour:p.scheduleEndMinutes~/60,minute:p.scheduleEndMinutes%60);days??={...p.selectedWeekdays};return Scaffold(appBar:AppBar(title:const Text('Lịch giám sát')),body:ListView(padding:const EdgeInsets.all(16),children:[
    SwitchListTile(value:enabled!,onChanged:(v)=>setState(()=>enabled=v),title:const Text('Nhắc bật giám sát theo lịch'),subtitle:const Text('Hệ điều hành không cho NanoBio âm thầm bật micro khi app đang đóng. Đến giờ, Nabi sẽ nhắc bạn mở app và xác nhận Bắt đầu giám sát.')),
    ListTile(title:const Text('Giờ bắt đầu'),trailing:Text(start!.format(context)),onTap:()async{final v=await showTimePicker(context:context,initialTime:start!);if(v!=null)setState(()=>start=v);}),
    ListTile(title:const Text('Giờ kết thúc'),trailing:Text(end!.format(context)),onTap:()async{final v=await showTimePicker(context:context,initialTime:end!);if(v!=null)setState(()=>end=v);}),
    const SizedBox(height:12),const Text('Ngày áp dụng'),Wrap(spacing:8,children:List.generate(7,(i){final d=i+1;final labels=['T2','T3','T4','T5','T6','T7','CN'];return FilterChip(label:Text(labels[i]),selected:days!.contains(d),onSelected:(v)=>setState(()=>v?days!.add(d):days!.remove(d)));})),
    const SizedBox(height:24),FilledButton(onPressed:()async{final updated=p.copyWith(scheduleEnabled:enabled,scheduleStartMinutes:start!.hour*60+start!.minute,scheduleEndMinutes:end!.hour*60+end!.minute,selectedWeekdays:days);await ref.read(sleepSafetyControllerProvider.notifier).savePreference(updated);if(context.mounted)Navigator.pop(context);},child:const Text('Lưu lịch')),
  ]));}
}

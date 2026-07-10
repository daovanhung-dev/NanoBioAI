import 'dart:async';
import 'package:flutter/material.dart';

class NabiFrameAnimation extends StatefulWidget {
  const NabiFrameAnimation({super.key, required this.basePath, required this.filePrefix, required this.frameCount, this.fps = 30, this.width = 160, this.height = 160, this.loop = true});
  final String basePath, filePrefix;
  final int frameCount, fps;
  final double width, height;
  final bool loop;
  @override
  State<NabiFrameAnimation> createState() => _NabiFrameAnimationState();
}
class _NabiFrameAnimationState extends State<NabiFrameAnimation> {
  Timer? _timer; int _index = 1;
  @override void initState(){ super.initState(); WidgetsBinding.instance.addPostFrameCallback((_){ for(var i=1;i<=widget.frameCount;i++){ precacheImage(AssetImage(_path(i)), context); }}); _timer=Timer.periodic(Duration(milliseconds:(1000/widget.fps).round()),(_){ if(!mounted)return; setState(()=>_index=_index>=widget.frameCount?(widget.loop?1:widget.frameCount):_index+1);});}
  String _path(int i)=>'${widget.basePath}/${widget.filePrefix}_F${i.toString().padLeft(4,'0')}.png';
  @override void dispose(){_timer?.cancel(); super.dispose();}
  @override Widget build(BuildContext context)=>Image.asset(_path(_index),width:widget.width,height:widget.height,fit:BoxFit.contain,gaplessPlayback:true,filterQuality:FilterQuality.high);
}

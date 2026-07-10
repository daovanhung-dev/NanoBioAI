import 'package:flutter/material.dart';
import 'nabi_frame_animation.dart';

class NabiViewMascot extends StatelessWidget {
  const NabiViewMascot({super.key, required this.animationId, required this.module, this.size = 180});
  final String animationId, module;
  final double size;
  @override Widget build(BuildContext context) => NabiFrameAnimation(basePath:'assets/nabi/01_character/02_30fps_frames/$module/$animationId', filePrefix:animationId, frameCount:30, fps:30, width:size, height:size);
}

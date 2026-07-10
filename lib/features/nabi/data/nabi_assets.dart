import 'package:flutter/widgets.dart';

import '../domain/nabi_animation_type.dart';

class NabiAnimationSpec {
  const NabiAnimationSpec({
    required this.type,
    required this.id,
    required this.module,
    required this.staticFallbackAsset,
    this.frameCount = NabiAssets.defaultFrameCount,
    this.fps = NabiAssets.defaultFps,
    this.loop = true,
    this.root = NabiAssets.root,
  });

  final NabiAnimationType type;
  final String id;
  final String module;
  final String staticFallbackAsset;
  final int frameCount;
  final int fps;
  final bool loop;
  final String root;

  Duration get duration =>
      Duration(milliseconds: (frameCount * 1000 / fps).round());

  String get framesDirectory =>
      '$root/01_character/02_30fps_frames/$module/$id';

  String framePath(int frameNumber) {
    final normalized = frameNumber.clamp(1, frameCount).toInt();
    final suffix = normalized.toString().padLeft(4, '0');
    return '$framesDirectory/${id}_F$suffix.png';
  }

  String get firstFramePath => framePath(1);
}

abstract final class NabiAssets {
  const NabiAssets._();

  static const root = 'assets/nabi';
  static const defaultFps = 30;
  static const defaultFrameCount = 30;

  static const idle = NabiAnimationSpec(
    type: NabiAnimationType.idle,
    id: 'NABI_ANIM_001_happy_idle_breathing',
    module: '01_core',
    staticFallbackAsset:
        '$root/01_character/01_static_expressions/NABI_EXP_001_happy.png',
  );

  static const happy = NabiAnimationSpec(
    type: NabiAnimationType.happy,
    id: 'NABI_ANIM_003_happy_jump_pop',
    module: '01_core',
    loop: false,
    staticFallbackAsset:
        '$root/01_character/01_static_expressions/NABI_EXP_002_happy_closed.png',
  );

  static const sad = NabiAnimationSpec(
    type: NabiAnimationType.sad,
    id: 'NABI_ANIM_006_sad_sigh_slow',
    module: '02_emotion',
    staticFallbackAsset:
        '$root/01_character/01_static_expressions/NABI_EXP_003_sad.png',
  );

  static const angry = NabiAnimationSpec(
    type: NabiAnimationType.angry,
    id: 'NABI_ANIM_010_angry_small_stomp',
    module: '02_emotion',
    loop: false,
    staticFallbackAsset:
        '$root/01_character/01_static_expressions/NABI_EXP_005_angry.png',
  );

  static const sulk = NabiAnimationSpec(
    type: NabiAnimationType.sulk,
    id: 'NABI_ANIM_008_pout_cheek_turn',
    module: '02_emotion',
    loop: false,
    staticFallbackAsset:
        '$root/01_character/01_static_expressions/NABI_EXP_004_pout.png',
  );

  static const crying = NabiAnimationSpec(
    type: NabiAnimationType.crying,
    id: 'NABI_ANIM_012_cry_big_tears',
    module: '02_emotion',
    staticFallbackAsset:
        '$root/01_character/01_static_expressions/NABI_EXP_006_cry.png',
  );

  static const listening = NabiAnimationSpec(
    type: NabiAnimationType.listening,
    id: 'NABI_ANIM_018_listening_ear_bounce',
    module: '03_daily',
    staticFallbackAsset:
        '$root/01_character/01_static_expressions/NABI_EXP_009_surprised.png',
  );

  static const talking = NabiAnimationSpec(
    type: NabiAnimationType.talking,
    id: 'NABI_ANIM_017_talking_soft',
    module: '03_daily',
    staticFallbackAsset:
        '$root/01_character/01_static_expressions/NABI_EXP_010_talking.png',
  );

  static const thinking = NabiAnimationSpec(
    type: NabiAnimationType.thinking,
    id: 'NABI_ANIM_016_thinking_bubble',
    module: '03_daily',
    staticFallbackAsset:
        '$root/01_character/01_static_expressions/NABI_EXP_008_thinking.png',
  );

  static const greeting = NabiAnimationSpec(
    type: NabiAnimationType.greeting,
    id: 'NABI_ANIM_002_happy_wave_right',
    module: '01_core',
    loop: false,
    staticFallbackAsset:
        '$root/01_character/01_static_expressions/NABI_EXP_001_happy.png',
  );

  static const loading = NabiAnimationSpec(
    type: NabiAnimationType.loading,
    id: 'NABI_ANIM_021_loading_leaf_spin',
    module: '04_system',
    staticFallbackAsset:
        '$root/01_character/01_static_expressions/NABI_EXP_008_thinking.png',
  );

  static const error = NabiAnimationSpec(
    type: NabiAnimationType.error,
    id: 'NABI_ANIM_022_error_dizzy',
    module: '04_system',
    staticFallbackAsset:
        '$root/01_character/01_static_expressions/NABI_EXP_009_surprised.png',
  );

  static const cheering = NabiAnimationSpec(
    type: NabiAnimationType.cheering,
    id: 'NABI_ANIM_024_exercise_cheer',
    module: '05_views',
    staticFallbackAsset:
        '$root/01_character/01_static_expressions/NABI_EXP_002_happy_closed.png',
  );

  static const reminder = NabiAnimationSpec(
    type: NabiAnimationType.reminder,
    id: 'NABI_ANIM_015_sleepy_reminder_nod',
    module: '03_daily',
    staticFallbackAsset:
        '$root/01_character/01_static_expressions/NABI_EXP_007_sleepy.png',
  );

  static const membership = NabiAnimationSpec(
    type: NabiAnimationType.membership,
    id: 'NABI_ANIM_026_membership_vip_sparkle',
    module: '05_views',
    staticFallbackAsset:
        '$root/01_character/01_static_expressions/NABI_EXP_001_happy.png',
  );

  static const Map<NabiAnimationType, NabiAnimationSpec> specs = {
    NabiAnimationType.idle: idle,
    NabiAnimationType.happy: happy,
    NabiAnimationType.sad: sad,
    NabiAnimationType.angry: angry,
    NabiAnimationType.sulk: sulk,
    NabiAnimationType.crying: crying,
    NabiAnimationType.listening: listening,
    NabiAnimationType.talking: talking,
    NabiAnimationType.thinking: thinking,
    NabiAnimationType.greeting: greeting,
    NabiAnimationType.loading: loading,
    NabiAnimationType.error: error,
    NabiAnimationType.cheering: cheering,
    NabiAnimationType.reminder: reminder,
    NabiAnimationType.membership: membership,
  };

  static NabiAnimationSpec specFor(NabiAnimationType type) {
    return specs[type] ?? idle;
  }

  static Future<void> precacheCoreAnimations(BuildContext context) async {
    for (final type in const [
      NabiAnimationType.idle,
      NabiAnimationType.happy,
      NabiAnimationType.loading,
      NabiAnimationType.talking,
    ]) {
      await precacheAnimation(context, type);
    }
  }

  static Future<void> precacheAnimation(
    BuildContext context,
    NabiAnimationType type,
  ) async {
    final spec = specFor(type);
    await Future.wait<void>([
      _safePrecache(context, spec.staticFallbackAsset),
      for (var i = 1; i <= spec.frameCount; i++)
        _safePrecache(context, spec.framePath(i)),
    ]);
  }

  static Future<void> precacheFirstFrame(
    BuildContext context,
    NabiAnimationSpec spec,
  ) async {
    await Future.wait<void>([
      _safePrecache(context, spec.staticFallbackAsset),
      _safePrecache(context, spec.firstFramePath),
    ]);
  }

  static Future<void> _safePrecache(
    BuildContext context,
    String assetPath,
  ) async {
    try {
      await precacheImage(AssetImage(assetPath), context, onError: (_, _) {});
    } catch (_) {
      // Missing optional mascot frames must not break app startup.
    }
  }
}

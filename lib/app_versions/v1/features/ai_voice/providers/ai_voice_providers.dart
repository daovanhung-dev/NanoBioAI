import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/ai_voice_state.dart';
import '../presentation/controllers/ai_voice_controller.dart';

export 'voice_dependencies.dart';

final aiVoiceControllerProvider =
    NotifierProvider<AiVoiceController, AiVoiceState>(AiVoiceController.new);

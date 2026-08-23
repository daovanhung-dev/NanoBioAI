import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/entities/ai_voice_state.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/gateways/voice_gateways.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/domain/repositories/ai_voice_repository.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/presentation/pages/ai_voice_page.dart';
import 'package:nano_app/app_versions/v1/features/ai_voice/providers/ai_voice_providers.dart';
import 'package:nano_app/core/theme/theme.dart';

void main() {
  testWidgets('does not open microphone until Start is pressed', (
    tester,
  ) async {
    final speech = _PageSpeech();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          speechRecognitionGatewayProvider.overrideWithValue(speech),
          textToSpeechGatewayProvider.overrideWithValue(_PageTts()),
          aiVoiceRepositoryProvider.overrideWithValue(_PageRepository()),
          aiVoiceTurnDelayProvider.overrideWithValue(Duration.zero),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AiVoicePage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Bắt đầu'), findsOneWidget);
    expect(find.text('Bình thường 1 giây'), findsOneWidget);
    expect(speech.listenCount, 0);

    await tester.tap(find.byKey(const Key('ai_voice_reaction_speed')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Siêu nhanh 0,2 giây').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('ai_voice_primary_action')));
    await tester.pump();
    expect(speech.listenCount, 1);
    expect(speech.pauseDurations, [const Duration(milliseconds: 200)]);
    expect(find.text('Dừng'), findsOneWidget);
    final dropdown = tester.widget<DropdownButton<AiVoiceReactionSpeed>>(
      find.byType(DropdownButton<AiVoiceReactionSpeed>),
    );
    expect(dropdown.onChanged, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

class _PageSpeech implements SpeechRecognitionGateway {
  Completer<String>? _active;
  int listenCount = 0;
  final List<Duration> pauseDurations = [];

  @override
  Future<bool> initialize() async => true;

  @override
  Future<String> listenOnce({
    String localeId = 'vi_VN',
    Duration listenFor = const Duration(minutes: 3),
    Duration pauseFor = const Duration(seconds: 1),
  }) {
    listenCount++;
    pauseDurations.add(pauseFor);
    _active = Completer<String>();
    return _active!.future;
  }

  @override
  Future<void> cancel() async {
    final active = _active;
    if (active != null && !active.isCompleted) active.complete('');
  }

  @override
  Future<void> stop() async {}
}

class _PageTts implements TextToSpeechGateway {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}
}

class _PageRepository implements AiVoiceRepository {
  @override
  void resetSession() {}

  @override
  Future<String> sendTurn(String message) async => 'Nabi trả lời';
}

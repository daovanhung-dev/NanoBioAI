import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/core/ai_local/presentation/local_ai_setup_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('native first run requires choosing a local model', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(home: LocalAiSetupGate(child: Text('user app'))),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chuẩn bị Nabi trên thiết bị'), findsOneWidget);
    expect(find.text('Tải model và tiếp tục'), findsOneWidget);
    expect(find.text('Gemma 3 270M'), findsOneWidget);
    expect(find.text('Qwen3 0.6B'), findsOneWidget);
    expect(find.text('user app'), findsNothing);
  });
}

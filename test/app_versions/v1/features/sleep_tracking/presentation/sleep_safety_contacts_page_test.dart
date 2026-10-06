import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/entities/safety_contact.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/domain/services/sleep_safety_state_machine.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_safety_contacts_page.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/providers/sleep_safety_controller.dart';
import 'package:nano_app/app_versions/v1/features/sleep_tracking/providers/sleep_safety_providers.dart';

void main() {
  for (final dismissal in _editorDismissals) {
    testWidgets(
      'canceling contact edit with ${dismissal.name} preserves monitoring and contact',
      (tester) async {
        final controller = _ContactPageTestController();
        await tester.pumpWidget(_app(controller));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Mở danh bạ'));
        await tester.pumpAndSettle();
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chỉnh sửa'));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        await dismissal.close(tester);
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsNothing);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(find.text('Đang giám sát'), findsOneWidget);
        expect(find.text('Bạn có ổn không?'), findsOneWidget);
        expect(controller.saveContactCalls, 0);
        expect(controller.state.contacts, [testContact]);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('saving the contact edit submits its draft once', (tester) async {
    final controller = _ContactPageTestController();
    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mở danh bạ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Chỉnh sửa'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Tên mới');
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();

    expect(controller.saveContactCalls, 1);
    expect(controller.savedName, 'Tên mới');
    expect(tester.takeException(), isNull);
  });
}

Widget _app(_ContactPageTestController controller) => ProviderScope(
  overrides: [sleepSafetyControllerProvider.overrideWith(() => controller)],
  child: const MaterialApp(home: _SleepMonitoringTestPage()),
);

class _SleepMonitoringTestPage extends ConsumerWidget {
  const _SleepMonitoringTestPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sleepSafetyControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Giám sát giấc ngủ')),
      body: Column(
        children: [
          Text(state.monitoringActive ? 'Đang giám sát' : 'Đã dừng'),
          if (state.machine.phase == SleepSafetyPhase.awaitingResponse)
            const Text('Bạn có ổn không?'),
          FilledButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const SleepSafetyContactsPage(),
              ),
            ),
            child: const Text('Mở danh bạ'),
          ),
        ],
      ),
    );
  }
}

class _ContactPageTestController extends SleepSafetyController {
  int saveContactCalls = 0;
  String? savedName;

  @override
  SleepSafetyViewState build() => SleepSafetyViewState(
    machine: SleepSafetyMachineState(
      phase: SleepSafetyPhase.awaitingResponse,
      eventId: 'event-test',
      alertStartedAt: DateTime(2026, 10, 6),
    ),
    contacts: [testContact],
    contactsLoaded: true,
    history: const [],
  );

  @override
  Future<void> saveContact({
    String? id,
    required String name,
    required String relationship,
    required String phoneE164,
    required int priority,
    bool allowPhoneFallback = true,
    bool allowUnverifiedVoiceAlert = false,
  }) async {
    saveContactCalls += 1;
    savedName = name;
  }
}

final testContact = SafetyContact(
  id: 'contact-test',
  userId: 'user-test',
  name: 'Người liên hệ QA',
  relationship: 'Gia đình',
  phoneE164: '+10000000000',
  priority: 1,
  verificationStatus: SafetyContactVerificationStatus.verified,
  active: true,
  createdAt: DateTime(2026, 10, 6),
  updatedAt: DateTime(2026, 10, 6),
);

final _editorDismissals = <_EditorDismissal>[
  _EditorDismissal('Hủy', (tester) async => tester.tap(find.text('Hủy'))),
  _EditorDismissal('Back', (tester) async {
    await tester.binding.handlePopRoute();
  }),
  _EditorDismissal('barrier', (tester) async {
    await tester.tapAt(const Offset(12, 12));
  }),
];

class _EditorDismissal {
  const _EditorDismissal(this.name, this.close);

  final String name;
  final Future<void> Function(WidgetTester tester) close;
}

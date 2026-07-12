import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v1/features/settings/presentation/widgets/guest_account_access_card.dart';

void main() {
  testWidgets('guest account card exposes login and registration actions', (
    tester,
  ) async {
    var loginPressed = false;
    var registerPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuestAccountAccessCard(
            onLogin: () => loginPressed = true,
            onRegister: () => registerPressed = true,
          ),
        ),
      ),
    );

    expect(find.text('Đăng nhập để giữ hành trình lâu dài'), findsOneWidget);
    expect(
      find.byKey(const Key('settings_guest_login_button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('settings_guest_register_button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('settings_guest_login_button')));
    await tester.pump();
    expect(loginPressed, isTrue);

    await tester.tap(find.byKey(const Key('settings_guest_register_button')));
    await tester.pump();
    expect(registerPressed, isTrue);
  });
}

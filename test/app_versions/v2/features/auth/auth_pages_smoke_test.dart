import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/auth/presentation/pages/auth_pages.dart';
import 'package:nano_app/app_versions/v2/features/auth/providers/auth_providers.dart';
import 'package:nano_app/core/config/auth_backend_availability.dart';

void main() {
  testWidgets('login page renders core fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: V2LoginPage())),
    );

    expect(find.text('Mừng bạn quay lại'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('register page renders core fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: V2RegisterPage())),
    );

    expect(find.text('Tạo tài khoản NanoBio'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(6));
  });

  testWidgets('login form accepts valid credentials', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: V2LoginPage())),
    );

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));

    await tester.enterText(fields.at(0), 'nabi@example.com');
    await tester.enterText(fields.at(1), '12345678');
    await tester.pump();

    final formState = tester.state<FormState>(find.byType(Form));
    expect(formState.validate(), isTrue);
  });

  testWidgets('login is disabled when account access is not configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authBackendAvailabilityProvider.overrideWithValue(
            AuthBackendAvailability.missingConfiguration,
          ),
        ],
        child: const MaterialApp(home: V2LoginPage()),
      ),
    );

    expect(find.text('Đăng nhập chưa sẵn sàng'), findsOneWidget);
    expect(find.textContaining('chế độ khách'), findsOneWidget);
    expect(_loginSubmitInkWell(tester).onTap, isNull);
  });

  testWidgets('login is disabled when account access failed to start', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authBackendAvailabilityProvider.overrideWithValue(
            AuthBackendAvailability.initializationFailed,
          ),
        ],
        child: const MaterialApp(home: V2LoginPage()),
      ),
    );

    expect(find.textContaining('thử lại sau'), findsOneWidget);
    expect(_loginSubmitInkWell(tester).onTap, isNull);
  });

  testWidgets('login submit stays enabled when account access is ready', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authBackendAvailabilityProvider.overrideWithValue(
            AuthBackendAvailability.ready,
          ),
        ],
        child: const MaterialApp(home: V2LoginPage()),
      ),
    );

    expect(find.text('Đăng nhập chưa sẵn sàng'), findsNothing);
    expect(_loginSubmitInkWell(tester).onTap, isNotNull);
  });

  testWidgets('register form accepts valid account details', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: V2RegisterPage())),
    );

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(6));

    await tester.enterText(fields.at(0), 'Test User');
    await tester.enterText(fields.at(2), 'nabi@example.com');
    await tester.enterText(fields.at(3), '12345678');
    await tester.enterText(fields.at(4), '12345678');
    await tester.pump();

    final formState = tester.state<FormState>(find.byType(Form));
    expect(formState.validate(), isTrue);
  });
}

InkWell _loginSubmitInkWell(WidgetTester tester) {
  final finder = find.descendant(
    of: find.byKey(const Key('login_submit_button')),
    matching: find.byType(InkWell),
  );
  expect(finder, findsOneWidget);
  return tester.widget<InkWell>(finder);
}

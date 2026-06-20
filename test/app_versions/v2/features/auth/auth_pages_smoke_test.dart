import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_app/app_versions/v2/features/auth/presentation/pages/auth_pages.dart';

void main() {
  testWidgets('login page renders core fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: V2LoginPage())),
    );

    expect(find.text('Mừng bạn quay lại'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
  });

  testWidgets('register page renders core fields', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: V2RegisterPage())),
    );

    expect(find.text('Tạo tài khoản NanoBio'), findsOneWidget);
    expect(find.text('Họ và tên'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
  });
}

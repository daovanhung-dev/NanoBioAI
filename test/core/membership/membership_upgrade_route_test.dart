import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/core/membership/membership_upgrade_route.dart';
import 'package:nano_app/shared/membership/presentation/membership_upgrade_navigation.dart';

void main() {
  test('builds only canonical payment-plan routes', () {
    expect(
      buildMembershipUpgradeRoute(MembershipUpgradePlan.plus),
      '/v2/payments?plan=plus',
    );
    expect(
      buildMembershipUpgradeRoute(MembershipUpgradePlan.familyPlus),
      '/v2/payments?plan=family_plus',
    );
    expect(buildMembershipUpgradeRoute('familyplus'), '/v2/payments?plan=plus');
    expect(buildMembershipUpgradeRoute(null), '/v2/payments?plan=plus');
  });

  testWidgets('upgrade prompt opens payment with its canonical plan', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/gate',
      routes: [
        GoRoute(
          path: '/gate',
          builder: (context, state) => Scaffold(
            body: FilledButton(
              onPressed: () {
                showMembershipUpgradePrompt(
                  context,
                  title: 'Đã dùng hết lượt',
                  message: 'Nâng cấp để tiếp tục sử dụng.',
                  planCode: MembershipUpgradePlan.familyPlus,
                );
              },
              child: const Text('Mở gợi ý'),
            ),
          ),
        ),
        GoRoute(
          path: membershipPaymentRoutePath,
          builder: (context, state) => Scaffold(
            body: Text(
              'PAYMENT_DESTINATION:${state.uri.queryParameters['plan']}',
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Mở gợi ý'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Nâng cấp FamilyPlus'));
    await tester.pumpAndSettle();

    expect(find.text('PAYMENT_DESTINATION:family_plus'), findsOneWidget);
  });
}

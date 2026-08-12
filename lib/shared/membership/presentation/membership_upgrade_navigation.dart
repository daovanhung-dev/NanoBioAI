import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_app/core/membership/membership_upgrade_route.dart';

void openMembershipUpgrade(BuildContext context, {String? planCode}) {
  context.push(buildMembershipUpgradeRoute(planCode));
}

Future<void> showMembershipUpgradePrompt(
  BuildContext context, {
  required String title,
  required String message,
  String? planCode,
}) async {
  final normalizedPlan = normalizeMembershipUpgradePlan(planCode);
  final shouldOpenPayment = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(membershipUpgradeActionLabel(normalizedPlan)),
          ),
        ],
      );
    },
  );

  if (shouldOpenPayment == true && context.mounted) {
    openMembershipUpgrade(context, planCode: normalizedPlan);
  }
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('M13 VietQR hardening executable acceptance source', () {
    late String migration;
    late String rebuild;
    late String smoke;

    setUpAll(() {
      migration = File(
        'docs/supabase/23-membership-payment-hardening.sql',
      ).readAsStringSync();
      rebuild = File('docs/supabase/config.sql').readAsStringSync();
      smoke = File(
        'test/docs/fixtures/supabase_membership_payment_hardening_smoke.sql',
      ).readAsStringSync();
    });

    test('keeps the canonical reference-only VietQR contract', () {
      for (final source in [migration, rebuild]) {
        expect(source, contains(r"'^NB[0-9A-F]{12}$'"));
        expect(source, contains('v_transfer_memo := v_transfer_reference'));
        expect(
          source,
          contains("'transfer_memo_contract', 'reference_only_v2'"),
        );
        expect(source, contains('"bank_code": "VCB"'));
        expect(source, contains('"bank_bin": "970436"'));
        expect(source, contains('"bank_account_number": "1026806174"'));
        expect(source, contains('"bank_account_name": "LE PHU THACH"'));
      }
    });

    test('keeps cancellation, one-open-request, and reviewer hardening', () {
      for (final token in [
        'cancel_my_membership_payment_request',
        'uq_payment_events_one_open_manual_membership',
        'MEMBERSHIP_PAYMENT_REQUEST_ALREADY_OPEN',
        'admin_has_payment_reviewer_role',
        "aur.role_code in ('finance_admin', 'super_admin')",
        'PAYMENT_TRANSFER_RECONCILIATION_REQUIRED',
      ]) {
        expect(migration, contains(token), reason: 'migration: $token');
        expect(rebuild, contains(token), reason: 'config.sql: $token');
      }
    });

    test('keeps finite subscription transition and audit policy', () {
      for (final token in [
        'LEGACY_PAID_SUBSCRIPTION_MISSING_ENDS_AT',
        'same_plan_renewal',
        'plan_switch',
        "interval '1 month'",
        "interval '1 year'",
        "at time zone 'Asia/Ho_Chi_Minh'",
        'current_period_start',
        'current_period_end',
        'superseded_subscription_ids',
        'public.admin_write_audit',
      ]) {
        expect(migration, contains(token), reason: token);
        expect(rebuild, contains(token), reason: 'config.sql: $token');
      }
    });

    test('provides a rollback-only executable smoke covering the plan', () {
      expect(smoke, startsWith('-- M13 VietQR hardening executable smoke.'));
      expect(smoke, contains('\nbegin;'));
      expect(smoke.trimRight(), endsWith('rollback;'));

      for (final token in [
        'M13_REFERENCE_NOT_CANONICAL',
        'M13_MEMO_NOT_REFERENCE_ONLY',
        'M13_OPEN_REQUEST_CONFLICT_NOT_BLOCKED',
        'M13_DIRECT_PAYMENT_WRITE_ALLOWED',
        'M13_DIRECT_SUBSCRIPTION_WRITE_ALLOWED',
        'M13_DIRECT_QUOTA_WRITE_ALLOWED',
        'M13_CROSS_OWNER_CANCEL_ALLOWED',
        'M13_CANCEL_AFTER_CONFIRM_ALLOWED',
        'M13_NON_FINANCE_ALERT_ALLOWED_',
        'M13_NON_FINANCE_REVIEW_ALLOWED_',
        'M13_UNVERIFIED_APPROVE_ALLOWED',
        'M13_APPROVE_DID_NOT_ENABLE_PLUS',
        'M13_APPROVAL_AUDIT_MISSING',
        'M13_SAME_PLAN_RENEWAL_DID_NOT_EXTEND',
        'M13_PLAN_SWITCH_DID_NOT_ENABLE_FAMILYPLUS',
        'M13_REJECT_GRANTED_ACCESS',
        'M13_PAYMENT_RLS_CROSS_USER_LEAK',
        'M13_LEGACY_MISSING_END_APPROVED',
      ]) {
        expect(smoke, contains(token), reason: token);
      }
    });

    test('documents the only acceptance case that needs two SQL sessions', () {
      expect(smoke, contains('True two-session concurrency'));
      expect(
        smoke,
        contains('docs/supabase/08-acceptance-checks.md'),
      );
    });
  });
}

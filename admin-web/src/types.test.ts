import { describe, expect, it } from 'vitest';
import {
  canAccessSection,
  canAdjustPoints,
  canCreateAccount,
  canBulkProvisionAccounts,
  canAdjustMembership,
  canGrantMembership,
  canManageUserDetails,
  canReviewPayments,
  normalizeMap,
  parseUserPlanCode,
  toAdminSession,
  toUserWorkItems,
  toWellnessWorkItems,
  type AdminSession,
} from './types';
import { dateTimeLocalToIso, formatMembershipPeriod, planLabel, toDateTimeLocal } from './lib/labels';
import { bulkConfirmationText, parseBulkAccountLines } from './lib/bulk-accounts';

function session(roles: AdminSession['roles'], permissions: string[]): AdminSession {
  return { userId: 'admin-1', roles, permissions, active: true, canUseUserApp: false };
}

describe('NanoBio Admin permission matrix', () => {
  it('gives Super Admin access to operational sections and mutations', () => {
    const value = session(['super_admin'], ['*']);
    expect(canAccessSection(value, 'dashboard')).toBe(true);
    expect(canAccessSection(value, 'payments')).toBe(true);
    expect(canAccessSection(value, 'wellness-rewards')).toBe(true);
    expect(canCreateAccount(value)).toBe(true);
    expect(canGrantMembership(value)).toBe(true);
    expect(canAdjustMembership(value)).toBe(true);
    expect(canBulkProvisionAccounts(value)).toBe(true);
    expect(canAdjustPoints(value)).toBe(true);
    expect(canManageUserDetails(value)).toBe(true);
  });

  it('limits Finance Admin to payment review when payment permission is present', () => {
    const value = session(['finance_admin'], ['dashboard.read', 'payments.write']);
    expect(canReviewPayments(value)).toBe(true);
    expect(canAccessSection(value, 'payments')).toBe(true);
    expect(canAccessSection(value, 'users')).toBe(false);
    expect(canGrantMembership(value)).toBe(false);
    expect(canAdjustMembership(value)).toBe(false);
  });

  it('maps Support, Content and Operations Admin to their scoped work', () => {
    const support = session(['support_admin'], ['dashboard.read', 'users.write']);
    const content = session(['content_admin'], ['dashboard.read', 'wellness_rewards.read', 'wellness_rewards.write']);
    const operations = session(['operations_admin'], ['dashboard.read', 'reconciliation.write', 'plans.write']);
    expect(canCreateAccount(support)).toBe(true);
    expect(canBulkProvisionAccounts(support)).toBe(false);
    expect(canManageUserDetails(support)).toBe(false);
    expect(canAccessSection(support, 'users')).toBe(true);
    expect(canAccessSection(support, 'wellness-rewards')).toBe(false);
    expect(canAccessSection(content, 'wellness-rewards')).toBe(true);
    expect(canAccessSection(content, 'config')).toBe(false);
    expect(canAccessSection(operations, 'reconciliation')).toBe(true);
    expect(canAccessSection(operations, 'plans')).toBe(true);
    expect(canAccessSection(operations, 'payments')).toBe(false);
  });

  it('denies inactive or role-less sessions', () => {
    const value = session([], ['*']);
    expect(canAccessSection(value, 'dashboard')).toBe(false);
    expect(canReviewPayments({ ...value, roles: ['finance_admin'], active: false })).toBe(false);
  });
});

describe('Supabase response normalization', () => {
  it('normalizes a session row and ignores unknown roles', () => {
    expect(toAdminSession([{ user_id: 'admin-1', roles: ['finance_admin', 'owner'], permissions: ['payments.write'], is_active: true }])).toEqual({
      userId: 'admin-1', roles: ['finance_admin'], permissions: ['payments.write'], active: true, canUseUserApp: true,
    });
    expect(normalizeMap(null)).toEqual({});
  });

  it('keeps wellness work items safe and masks code data', () => {
    const [offer, redemption] = toWellnessWorkItems([
      { item_type: 'offer', id: 'offer-1', offer_id: 'offer-1', title: 'Khám sức khỏe', provider_name: 'NanoBio', cost_points: 500, status: 'active', is_active: true, eligible_plan_codes: ['plus'], available_codes: 4, issued_codes: 1, retired_codes: 0, created_at: '2026-09-13T00:00:00Z' },
      { item_type: 'redemption', id: 'redemption-1', offer_id: 'offer-1', redemption_id: 'redemption-1', title: 'Khám sức khỏe', provider_name: 'NanoBio', points_spent: 500, status: 'issued', user_label: 'N***@example.com', masked_code: '••••••', created_at: '2026-09-13T00:00:00Z' },
    ]);
    expect(offer.id).toBe('offer-1');
    expect(offer.metadata.available_codes).toBe(4);
    expect(redemption.id).toBe('redemption-1');
    expect(redemption.metadata.masked_code).toBe('••••••');
    expect(redemption.metadata.raw_code).toBeUndefined();
  });

  it('maps the canonical user subtitle plan into structured metadata', () => {
    const [plus, familyPlus, free, guest, malformed] = toUserWorkItems([
      { id: 'plus', plan_code: 'plus', subscription_id: 'subscription-1', membership_status: 'active', membership_source: 'manual', membership_starts_at: '2026-09-13T00:00:00.000Z', membership_ends_at: '2026-10-13T00:00:00.000Z', subtitle: 'plus@example.com - plus - none' },
      { id: 'family', subtitle: 'family@example.com - family_plus - none' },
      { id: 'free', subtitle: 'free@example.com - free - none' },
      { id: 'guest', subtitle: 'guest@example.com - guest - none' },
      { id: 'bad', subtitle: 'plus customer account' },
    ]);

    expect(plus.metadata.plan_code).toBe('plus');
    expect(plus.membership).toEqual({ subscriptionId: 'subscription-1', planCode: 'plus', status: 'active', source: 'manual', startsAt: '2026-09-13T00:00:00.000Z', endsAt: '2026-10-13T00:00:00.000Z' });
    expect(familyPlus.metadata.plan_code).toBe('family_plus');
    expect(free.metadata.plan_code).toBe('free');
    expect(guest.metadata.plan_code).toBe('guest');
    expect(malformed.metadata.plan_code).toBeUndefined();
  });

  it('prefers a valid structured plan over the subtitle fallback', () => {
    const [item] = toUserWorkItems([{
      id: 'structured',
      plan_code: 'family_plus',
      subtitle: 'user@example.com - plus - none',
      metadata: { plan_code: 'free' },
    }]);

    expect(item.metadata.plan_code).toBe('free');
  });

  it('normalizes the legacy FamilyPlus display name from structured metadata', () => {
    const [item] = toUserWorkItems([{
      id: 'legacy-name',
      metadata: { plan_name: 'FamilyPlus' },
      subtitle: 'user@example.com - free - none',
    }]);

    expect(item.metadata.plan_code).toBe('family_plus');
    expect(planLabel('FamilyPlus')).toBe('FamilyPlus');
  });

  it('uses current product access before a stale subscription tier', () => {
    const [item] = toUserWorkItems([{
      id: 'current-access',
      product_access_status: 'plus',
      subscription_tier: 'free',
      subtitle: 'user@example.com - free - none',
    }]);

    expect(item.metadata.plan_code).toBe('plus');
  });

  it('rejects unsupported plan text and labels only known plan codes', () => {
    expect(parseUserPlanCode('user@example.com - premium_plus - none')).toBeUndefined();
    expect(parseUserPlanCode('plus customer account')).toBeUndefined();
    expect(planLabel('free')).toBe('Miễn phí');
    expect(planLabel('plus')).toBe('Plus');
    expect(planLabel('family_plus')).toBe('FamilyPlus');
    expect(planLabel('guest')).toBe('Khách');
    expect(planLabel(undefined)).toBe('Chưa xác định');
  });

  it('round-trips Vietnam datetime-local values and renders membership periods', () => {
    const iso = dateTimeLocalToIso('2026-09-13T15:30');
    expect(iso).toBe('2026-09-13T08:30:00.000Z');
    expect(toDateTimeLocal(iso)).toBe('2026-09-13T15:30');
    expect(dateTimeLocalToIso('2026-02-30T15:30')).toBeUndefined();
    expect(formatMembershipPeriod('2026-09-13T00:00:00.000Z', '2026-10-13T00:00:00.000Z')).toContain('–');
    expect(formatMembershipPeriod('2026-09-13T00:00:00.000Z')).toContain('Không thời hạn');
  });
});

describe('bulk account input', () => {
  it('accepts strict Gmail rows and normalizes email casing', () => {
    const result = parseBulkAccountLines('  User.Name@GMAIL.COM | Nguyễn Văn A  ');
    expect(result.issues).toEqual([]);
    expect(result.accounts).toEqual([{ email: 'user.name@gmail.com', fullName: 'Nguyễn Văn A' }]);
  });

  it('rejects malformed, non-Gmail and duplicate rows', () => {
    const result = parseBulkAccountLines([
      'user@example.com | User',
      'missing-name@gmail.com',
      'USER@gmail.com | User One',
      'user@gmail.com | User Two',
    ].join('\n'));
    expect(result.accounts).toEqual([{ email: 'user@gmail.com', fullName: 'User One' }]);
    expect(result.issues.map((issue) => issue.message)).toEqual([
      'Chỉ chấp nhận địa chỉ kết thúc bằng @gmail.com.',
      'Cần nhập theo dạng email | họ tên.',
      'Email bị trùng trong danh sách.',
    ]);
  });

  it('rejects rows containing more than one separator', () => {
    const result = parseBulkAccountLines('user@gmail.com | User | Extra');
    expect(result.accounts).toEqual([]);
    expect(result.issues[0]?.message).toBe('Cần nhập theo dạng email | họ tên.');
  });

  it('enforces the 100-account limit and deterministic confirmation text', () => {
    const lines = Array.from({ length: 101 }, (_, index) => `user${index}@gmail.com | User ${index}`).join('\n');
    const result = parseBulkAccountLines(lines);
    expect(result.accounts).toHaveLength(101);
    expect(result.issues.at(-1)?.message).toBe('Mỗi lần chỉ được xử lý tối đa 100 tài khoản.');
    expect(bulkConfirmationText(3)).toBe('TAO TAI KHOAN 3');
  });
});

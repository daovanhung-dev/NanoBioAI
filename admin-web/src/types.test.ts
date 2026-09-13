import { describe, expect, it } from 'vitest';
import {
  canAccessSection,
  canAdjustPoints,
  canCreateAccount,
  canGrantMembership,
  canReviewPayments,
  normalizeMap,
  toAdminSession,
  toWellnessWorkItems,
  type AdminSession,
} from './types';

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
    expect(canAdjustPoints(value)).toBe(true);
  });

  it('limits Finance Admin to payment review when payment permission is present', () => {
    const value = session(['finance_admin'], ['dashboard.read', 'payments.write']);
    expect(canReviewPayments(value)).toBe(true);
    expect(canAccessSection(value, 'payments')).toBe(true);
    expect(canAccessSection(value, 'users')).toBe(false);
    expect(canGrantMembership(value)).toBe(false);
  });

  it('maps Support, Content and Operations Admin to their scoped work', () => {
    const support = session(['support_admin'], ['dashboard.read', 'users.write']);
    const content = session(['content_admin'], ['dashboard.read', 'wellness_rewards.read', 'wellness_rewards.write']);
    const operations = session(['operations_admin'], ['dashboard.read', 'reconciliation.write', 'plans.write']);
    expect(canCreateAccount(support)).toBe(true);
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
});

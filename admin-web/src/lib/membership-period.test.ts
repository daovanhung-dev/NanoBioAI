import { describe, expect, it } from 'vitest';
import {
  buildMembershipAdjustmentInput,
  previewMembershipEnd,
} from './membership-period';

const finiteMembership = {
  subscriptionId: 'subscription-1',
  planCode: 'plus' as const,
  status: 'active',
  source: 'manual',
  startsAt: '2026-09-13T00:00:00.000Z',
  endsAt: '2026-10-13T00:00:00.000Z',
};

describe('membership period form validation', () => {
  it('sends only days for add/subtract operations', () => {
    const result = buildMembershipAdjustmentInput(
      'user-1',
      finiteMembership,
      'add_days',
      '7',
      '',
      'Gia hạn theo phê duyệt.',
    );
    expect(result).toEqual({
      userId: 'user-1',
      subscriptionId: 'subscription-1',
      operation: 'add_days',
      days: 7,
      endsAt: null,
      expectedEndsAt: '2026-10-13T00:00:00.000Z',
      reason: 'Gia hạn theo phê duyệt.',
    });
    expect(previewMembershipEnd(finiteMembership, 'add_days', '7', '')).toBe(
      '2026-10-20T00:00:00.000Z',
    );
  });

  it('requires a reason and rejects reducing through the start', () => {
    expect(
      buildMembershipAdjustmentInput(
        'user-1',
        finiteMembership,
        'add_days',
        '7',
        '',
        ' ',
      ),
    ).toEqual({ error: 'Cần nhập lý do điều chỉnh.' });
    expect(
      buildMembershipAdjustmentInput(
        'user-1',
        finiteMembership,
        'subtract_days',
        '31',
        '',
        'Điều chỉnh.',
      ),
    ).toEqual({ error: 'Ngày kết thúc phải sau ngày bắt đầu.' });
  });

  it('only allows an absolute end date for permanent packages', () => {
    const permanent = { ...finiteMembership, endsAt: undefined };
    expect(
      buildMembershipAdjustmentInput(
        'user-1',
        permanent,
        'add_days',
        '7',
        '',
        'Gia hạn.',
      ),
    ).toEqual({ error: 'Gói không thời hạn chỉ hỗ trợ chọn ngày kết thúc.' });
    expect(
      buildMembershipAdjustmentInput(
        'user-1',
        permanent,
        'set_end_at',
        '',
        '2026-10-13T15:30',
        'Đặt thời hạn.',
      ),
    ).toMatchObject({
      operation: 'set_end_at',
      days: null,
      endsAt: '2026-10-13T08:30:00.000Z',
      expectedEndsAt: null,
    });
  });
});

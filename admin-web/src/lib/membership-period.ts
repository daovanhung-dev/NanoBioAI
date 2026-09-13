import { dateTimeLocalToIso } from './labels';
import type {
  AdminMembershipSummary,
  MembershipPeriodAdjustmentInput,
  MembershipPeriodAdjustmentOperation,
} from '../types';

export function buildMembershipAdjustmentInput(
  userId: string,
  membership: AdminMembershipSummary,
  operation: MembershipPeriodAdjustmentOperation,
  daysText: string,
  customEndsAt: string,
  reason: string,
): Omit<MembershipPeriodAdjustmentInput, 'idempotencyKey'> | { error: string } {
  if (!reason.trim()) return { error: 'Cần nhập lý do điều chỉnh.' };
  const startsAt = membership.startsAt ? new Date(membership.startsAt) : null;
  if (!startsAt || Number.isNaN(startsAt.getTime())) {
    return { error: 'Thời điểm bắt đầu của gói chưa hợp lệ.' };
  }

  let endsAt: string | null = null;
  let days: number | null = null;
  if (operation === 'set_end_at') {
    endsAt = dateTimeLocalToIso(customEndsAt) ?? null;
    if (!endsAt) return { error: 'Ngày kết thúc mới chưa hợp lệ.' };
  } else {
    if (!membership.endsAt) {
      return { error: 'Gói không thời hạn chỉ hỗ trợ chọn ngày kết thúc.' };
    }
    const parsedDays = Number(daysText);
    if (!Number.isInteger(parsedDays) || parsedDays <= 0) {
      return { error: 'Số ngày phải là số nguyên lớn hơn 0.' };
    }
    days = parsedDays;
    const currentEnd = new Date(membership.endsAt);
    if (Number.isNaN(currentEnd.getTime())) {
      return { error: 'Thời hạn hiện tại của gói chưa hợp lệ.' };
    }
    currentEnd.setUTCDate(
      currentEnd.getUTCDate() +
        (operation === 'add_days' ? parsedDays : -parsedDays),
    );
    if (currentEnd.getTime() <= startsAt.getTime()) {
      return { error: 'Ngày kết thúc phải sau ngày bắt đầu.' };
    }
  }

  if (endsAt && new Date(endsAt).getTime() <= startsAt.getTime()) {
    return { error: 'Ngày kết thúc phải sau ngày bắt đầu.' };
  }
  return {
    userId,
    subscriptionId: membership.subscriptionId,
    operation,
    days,
    endsAt,
    expectedEndsAt: membership.endsAt ?? null,
    reason,
  };
}

export function previewMembershipEnd(
  membership: AdminMembershipSummary,
  operation: MembershipPeriodAdjustmentOperation,
  daysText: string,
  customEndsAt: string,
): string | undefined {
  if (operation === 'set_end_at') return dateTimeLocalToIso(customEndsAt);
  if (!membership.endsAt) return undefined;
  const days = Number(daysText);
  if (!Number.isInteger(days) || days <= 0) return undefined;
  const end = new Date(membership.endsAt);
  if (Number.isNaN(end.getTime())) return undefined;
  end.setUTCDate(
    end.getUTCDate() + (operation === 'add_days' ? days : -days),
  );
  return end.toISOString();
}

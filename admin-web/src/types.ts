export const ADMIN_ROLES = [
  'super_admin',
  'finance_admin',
  'support_admin',
  'content_admin',
  'operations_admin',
] as const;

export type AdminRole = (typeof ADMIN_ROLES)[number];

export const PERMISSIONS = {
  dashboardRead: 'dashboard.read',
  usersWrite: 'users.write',
  paymentsWrite: 'payments.write',
  salesWrite: 'sales.write',
  reconciliationWrite: 'reconciliation.write',
  pointsWrite: 'points.write',
  wellnessRewardsRead: 'wellness_rewards.read',
  wellnessRewardsWrite: 'wellness_rewards.write',
  plansWrite: 'plans.write',
  reportsWrite: 'reports.write',
  auditRead: 'audit.read',
  configWrite: 'config.write',
  wildcard: '*',
} as const;

export type AdminPermission = (typeof PERMISSIONS)[keyof typeof PERMISSIONS];

export const SECTIONS = [
  'dashboard',
  'users',
  'payments',
  'sales',
  'sale-conversions',
  'wellness-rewards',
  'reconciliation',
  'plans',
  'reports',
  'audit',
  'config',
] as const;

export type AdminSection = (typeof SECTIONS)[number];

export type AdminSession = {
  userId: string;
  roles: AdminRole[];
  permissions: string[];
  active: boolean;
  canUseUserApp: boolean;
};

export type DashboardMetric = {
  key: string;
  label: string;
  value: number;
  status: string;
  targetSection?: AdminSection;
};

export type PaymentReconciliation = {
  transferReference?: string;
  transferMemo?: string;
  payerFullName?: string;
  billingCycle?: string;
  amountCents?: number;
  currency?: string;
  transferConfirmedAt?: string;
};

export type AdminWorkItem = {
  id: string;
  title: string;
  subtitle: string;
  status: string;
  section: string;
  createdAt?: string;
  metadata: Record<string, unknown>;
  membership?: AdminMembershipSummary;
  paymentReconciliation?: PaymentReconciliation;
};

export const ADMIN_PLAN_CODES = ['guest', 'free', 'plus', 'family_plus'] as const;

export type AdminPlanCode = (typeof ADMIN_PLAN_CODES)[number];

export type AdminMembershipSummary = {
  subscriptionId: string;
  planCode: AdminPlanCode;
  status: string;
  source?: string;
  startsAt?: string;
  endsAt?: string;
};

export type AdminAuditEvent = {
  id: string;
  action: string;
  actorId: string;
  target: string;
  reason: string;
  createdAt?: string;
};

export type AdminMutation = {
  section: AdminSection;
  action: string;
  targetId: string;
  reason: string;
  idempotencyKey?: string;
  payload?: Record<string, unknown>;
};

export type MutationResult = {
  success: boolean;
  message: string;
};

export type AccountCreateInput = {
  fullName: string;
  email: string;
  password: string;
  phone?: string;
  reason: string;
  idempotencyKey: string;
};

export type MembershipGrantInput = {
  userId: string;
  planCode: 'plus' | 'family_plus';
  startsAt: string;
  endsAt: string;
  reason: string;
  idempotencyKey: string;
};

export type MembershipPeriodAdjustmentOperation = 'add_days' | 'subtract_days' | 'set_end_at';

export type MembershipPeriodAdjustmentInput = {
  userId: string;
  subscriptionId: string;
  operation: MembershipPeriodAdjustmentOperation;
  days: number | null;
  endsAt: string | null;
  expectedEndsAt: string | null;
  reason: string;
  idempotencyKey: string;
};

export type MembershipPeriodAdjustmentResult = {
  subscriptionId: string;
  planCode: AdminPlanCode;
  status: string;
  startsAt: string;
  previousEndsAt: string | null;
  endsAt: string | null;
  operation: MembershipPeriodAdjustmentOperation;
  deltaDays: number | null;
};

export type BulkProvisionPlanCode = 'plus' | 'family_plus';

export type BulkProvisionAccount = {
  email: string;
  fullName: string;
};

export type BulkProvisionPreviewRow = {
  index: number;
  status: 'new' | 'existing' | 'paid_preserved';
  currentPlan?: string;
};

export type BulkProvisionPreview = {
  fingerprint: string;
  candidateCount: number;
  rows: BulkProvisionPreviewRow[];
};

export type BulkProvisionInput = {
  accounts: BulkProvisionAccount[];
  password: string;
  planCode: BulkProvisionPlanCode;
  durationMonths: 1 | 3 | 6 | 12;
  reason: string;
  idempotencyKey: string;
};

export type BulkProvisionResult = {
  success: boolean;
  message: string;
  batchId: string;
  processedCount: number;
  createdCount: number;
  grantedCount: number;
  skippedCount: number;
  failedIndex?: number;
};

export type AdminUserDetails = {
  user: {
    id: string;
    email?: string;
    fullName?: string;
    phone?: string;
    gender?: string;
    birthYear?: number;
    avatarUrl?: string;
    adminStatus?: string;
    createdAt?: string;
    updatedAt?: string;
  };
  health: {
    subject?: Record<string, unknown>;
    profile?: Record<string, unknown>;
    lifestyle?: Record<string, unknown>;
    goals: Array<Record<string, unknown>>;
    conditions: Array<Record<string, unknown>>;
    allergies: Array<Record<string, unknown>>;
    treatments: Array<Record<string, unknown>>;
    surveyAnswers: Array<Record<string, unknown>>;
  };
  membership: {
    subscriptionId?: string;
    planCode: AdminPlanCode;
    status: string;
    source?: string;
    startsAt?: string;
    endsAt?: string;
  };
};

export type AdminUserProfileUpdateInput = {
  userId: string;
  fullName: string;
  phone: string;
  gender: string;
  birthYear?: number;
  reason: string;
  idempotencyKey: string;
};

export type AdminPasswordResetResult = {
  success: boolean;
  message: string;
  status: 'password_reset' | 'already_processed';
  temporaryPassword?: string;
  passwordVisibleOnce: boolean;
};

export type RewardOfferInput = {
  offerId?: string;
  title: string;
  description: string;
  providerName: string;
  costPoints: number;
  eligiblePlanCodes: string[];
  availableFrom?: string;
  availableUntil?: string;
  voucherExpiresAt?: string;
  isActive: boolean;
  reason: string;
  idempotencyKey: string;
};

export type SectionConfig = {
  label: string;
  description: string;
  permission: string;
  group: string;
};

export const SECTION_CONFIG: Record<AdminSection, SectionConfig> = {
  dashboard: {
    label: 'Tổng quan',
    description: 'Theo dõi tình hình vận hành và các việc cần ưu tiên.',
    permission: PERMISSIONS.dashboardRead,
    group: 'Tổng quan',
  },
  users: {
    label: 'Người dùng',
    description: 'Tìm kiếm và quản lý trạng thái tài khoản người dùng.',
    permission: PERMISSIONS.usersWrite,
    group: 'Tài khoản',
  },
  payments: {
    label: 'Thanh toán',
    description: 'Đối chiếu giao dịch trước khi duyệt hoặc từ chối.',
    permission: PERMISSIONS.paymentsWrite,
    group: 'Tài chính',
  },
  sales: {
    label: 'Cộng tác viên',
    description: 'Xử lý hồ sơ và trạng thái hoạt động của cộng tác viên.',
    permission: PERMISSIONS.salesWrite,
    group: 'Sale',
  },
  'sale-conversions': {
    label: 'Chi trả cộng tác viên',
    description: 'Kiểm tra yêu cầu quy đổi và xác nhận việc chi trả.',
    permission: PERMISSIONS.salesWrite,
    group: 'Sale',
  },
  'wellness-rewards': {
    label: 'Điểm chăm sóc',
    description: 'Quản lý ưu đãi và kho mã dành cho người dùng.',
    permission: PERMISSIONS.wellnessRewardsRead,
    group: 'Vận hành',
  },
  reconciliation: {
    label: 'Đối soát',
    description: 'Theo dõi sai lệch và ghi nhận kết quả đối soát.',
    permission: PERMISSIONS.reconciliationWrite,
    group: 'Vận hành',
  },
  plans: {
    label: 'Gói dịch vụ',
    description: 'Quản lý các gói dịch vụ đang áp dụng.',
    permission: PERMISSIONS.plansWrite,
    group: 'Vận hành',
  },
  reports: {
    label: 'Báo cáo',
    description: 'Tạo và theo dõi yêu cầu xuất báo cáo.',
    permission: PERMISSIONS.reportsWrite,
    group: 'Kiểm tra',
  },
  audit: {
    label: 'Lịch sử thao tác',
    description: 'Xem lại các thao tác quan trọng đã được ghi nhận.',
    permission: PERMISSIONS.auditRead,
    group: 'Kiểm tra',
  },
  config: {
    label: 'Thiết lập',
    description: 'Cập nhật thiết lập vận hành theo phạm vi được cấp.',
    permission: PERMISSIONS.configWrite,
    group: 'Kiểm tra',
  },
};

export function canReviewPayments(session: AdminSession): boolean {
  const reviewer = session.roles.includes('super_admin') || session.roles.includes('finance_admin');
  return session.active && reviewer && (session.permissions.includes(PERMISSIONS.wildcard) || session.permissions.includes(PERMISSIONS.paymentsWrite));
}

export function hasPermission(session: AdminSession, permission: string): boolean {
  if (!session.active || session.roles.length === 0) return false;
  if (permission === PERMISSIONS.paymentsWrite) return canReviewPayments(session);
  return session.permissions.includes(PERMISSIONS.wildcard) || session.permissions.includes(permission);
}

export function canAccessSection(session: AdminSession, section: AdminSection): boolean {
  return hasPermission(session, SECTION_CONFIG[section].permission);
}

export function canCreateAccount(session: AdminSession): boolean {
  return session.active && (session.roles.includes('super_admin') || session.roles.includes('support_admin'));
}

export function canGrantMembership(session: AdminSession): boolean {
  return session.active && session.roles.includes('super_admin');
}

export function canAdjustMembership(session: AdminSession): boolean {
  return session.active && session.roles.includes('super_admin');
}

export function canBulkProvisionAccounts(session: AdminSession): boolean {
  return session.active && session.roles.includes('super_admin');
}

export function canManageUserDetails(session: AdminSession): boolean {
  return session.active && session.roles.includes('super_admin');
}

export function canAdjustPoints(session: AdminSession): boolean {
  return session.roles.includes('super_admin') && hasPermission(session, PERMISSIONS.pointsWrite);
}

export function normalizeArray<T>(value: unknown): T[] {
  if (!Array.isArray(value)) return [];
  return value as T[];
}

export function normalizeMap(value: unknown): Record<string, unknown> {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return {};
  return value as Record<string, unknown>;
}

export function toAdminSession(value: unknown): AdminSession {
  const map = normalizeMap(Array.isArray(value) ? value[0] : value);
  return {
    userId: String(map.user_id ?? ''),
    roles: normalizeArray<unknown>(map.roles).filter((role): role is AdminRole => ADMIN_ROLES.includes(role as AdminRole)),
    permissions: normalizeArray<unknown>(map.permissions).map(String),
    active: map.is_active === true,
    canUseUserApp: map.can_use_user_app !== false,
  };
}

export function toWorkItems(value: unknown): AdminWorkItem[] {
  return normalizeArray<Record<string, unknown>>(value).map(toWorkItem);
}

export function toUserWorkItems(value: unknown): AdminWorkItem[] {
  return normalizeArray<Record<string, unknown>>(value).map((row) => {
    const item = toWorkItem(row);
    const metadata = normalizeMap(row.metadata);
    const planCode = firstPlanCode(
      metadata.plan_code,
      row.plan_code,
      row.product_access_status,
      row.subscription_tier,
      metadata.plan_name,
      parseUserPlanCode(item.subtitle),
    );

    const membershipId = optionalString(row.membership_id);
    const membershipPlan = normalizePlanCode(row.plan_code) ?? planCode;
    const membership = membershipId && membershipPlan
      ? {
          subscriptionId: membershipId,
          planCode: membershipPlan,
          status: String(row.membership_status ?? 'active'),
          source: optionalString(row.membership_source),
          startsAt: optionalString(row.membership_starts_at),
          endsAt: optionalString(row.membership_ends_at),
        } satisfies AdminMembershipSummary
      : undefined;

    return planCode || membership
      ? {
          ...item,
          metadata: planCode ? { ...metadata, plan_code: planCode } : metadata,
          ...(membership ? { membership } : {}),
        }
      : item;
  });
}

export function parseUserPlanCode(subtitle: string): AdminPlanCode | undefined {
  const match = subtitle.match(/(?:^| - )(guest|free|plus|family_plus) - [^-]+$/i);
  return match ? normalizePlanCode(match[1]) : undefined;
}

export function normalizePlanCode(value: unknown): AdminPlanCode | undefined {
  const normalized = String(value ?? '').trim().toLowerCase();
  return ADMIN_PLAN_CODES.includes(normalized as AdminPlanCode)
    ? normalized as AdminPlanCode
    : undefined;
}

function firstPlanCode(...values: unknown[]): AdminPlanCode | undefined {
  for (const value of values) {
    const planCode = planCodeFromValue(value);
    if (planCode) return planCode;
  }
  return undefined;
}

function planCodeFromValue(value: unknown): AdminPlanCode | undefined {
  const code = normalizePlanCode(value);
  if (code) return code;
  return String(value ?? '').trim().toLowerCase() === 'familyplus'
    ? 'family_plus'
    : undefined;
}

function toWorkItem(row: Record<string, unknown>): AdminWorkItem {
  return {
    id: String(row.id ?? ''),
    title: String(row.title ?? 'Bản ghi'),
    subtitle: String(row.subtitle ?? ''),
    status: String(row.status ?? 'ready'),
    section: String(row.section ?? ''),
    createdAt: row.created_at ? String(row.created_at) : undefined,
    metadata: normalizeMap(row.metadata),
    paymentReconciliation: toPaymentReconciliation(row),
  };
}

export function toWellnessWorkItems(value: unknown): AdminWorkItem[] {
  return normalizeArray<Record<string, unknown>>(value).map((row) => {
    const redemptionId = optionalString(row.redemption_id);
    const offerId = optionalString(row.offer_id);
    const metadata: Record<string, unknown> = {
      item_type: optionalString(row.item_type),
      offer_id: offerId,
      redemption_id: redemptionId,
      provider_name: optionalString(row.provider_name),
      description: optionalString(row.description),
      cost_points: optionalNumber(row.cost_points),
      points_spent: optionalNumber(row.points_spent),
      eligible_plan_codes: normalizeArray<string>(row.eligible_plan_codes),
      available_codes: optionalNumber(row.available_codes),
      issued_codes: optionalNumber(row.issued_codes),
      retired_codes: optionalNumber(row.retired_codes),
      user_label: optionalString(row.user_label),
      masked_code: optionalString(row.masked_code),
      voucher_expires_at: optionalString(row.voucher_expires_at),
      available_from: optionalString(row.available_from),
      available_until: optionalString(row.available_until),
      cancelled_at: optionalString(row.cancelled_at),
    };
    return {
      id: redemptionId ?? offerId ?? String(row.id ?? ''),
      title: String(row.title ?? 'Ưu đãi Điểm chăm sóc'),
      subtitle: redemptionId
        ? `${optionalString(row.user_label) ?? 'Tài khoản NanoBio'} · ${optionalNumber(row.points_spent) ?? 0} điểm`
        : `${optionalString(row.provider_name) ?? 'Nhà cung cấp chưa cập nhật'} · ${optionalNumber(row.cost_points) ?? 0} điểm`,
      status: String(row.status ?? 'ready'),
      section: 'wellness-rewards',
      createdAt: row.created_at ? String(row.created_at) : undefined,
      metadata,
    };
  });
}

function toPaymentReconciliation(row: Record<string, unknown>): PaymentReconciliation | undefined {
  const metadata = normalizeMap(row.metadata);
  const source = { ...metadata, ...row };
  const details: PaymentReconciliation = {
    transferReference: optionalString(source.transfer_reference),
    transferMemo: optionalString(source.transfer_memo),
    payerFullName: optionalString(source.payer_full_name),
    billingCycle: optionalString(source.billing_cycle),
    amountCents: optionalNumber(source.amount_cents),
    currency: optionalString(source.currency),
    transferConfirmedAt: optionalString(source.transfer_confirmed_at),
  };
  return Object.values(details).some((value) => value !== undefined) ? details : undefined;
}

function optionalString(value: unknown): string | undefined {
  const result = String(value ?? '').trim();
  return result.length > 0 ? result : undefined;
}

function optionalNumber(value: unknown): number | undefined {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : undefined;
}

export function makeIdempotencyKey(prefix: string, target = ''): string {
  const random = typeof crypto !== 'undefined' && 'randomUUID' in crypto
    ? crypto.randomUUID()
    : `${Date.now()}-${Math.random().toString(36).slice(2)}`;
  return `${prefix}-${target}-${random}`.replace(/[^a-zA-Z0-9_-]/g, '_');
}

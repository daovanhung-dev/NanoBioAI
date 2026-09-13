import type { AuthChangeEvent, Session, SupabaseClient } from '@supabase/supabase-js';
import { getSupabaseClient } from './supabase';
import {
  type AccountCreateInput,
  type AdminAuditEvent,
  type AdminMutation,
  type AdminPasswordResetResult,
  type AdminSection,
  type AdminSession,
  type AdminUserDetails,
  type AdminUserProfileUpdateInput,
  type AdminWorkItem,
  type BulkProvisionInput,
  type BulkProvisionPreview,
  type BulkProvisionPreviewRow,
  type BulkProvisionResult,
  type DashboardMetric,
  type MembershipGrantInput,
  type MutationResult,
  type RewardOfferInput,
  normalizeArray,
  normalizeMap,
  normalizePlanCode,
  toAdminSession,
  toUserWorkItems,
  toWellnessWorkItems,
  toWorkItems,
} from '../types';

export class AdminApiError extends Error {
  constructor(message: string, readonly retryable = false) {
    super(message);
    this.name = 'AdminApiError';
  }
}

type AuthListener = (event: AuthChangeEvent, session: Session | null) => void;

export class AdminApi {
  constructor(private readonly getClient: () => SupabaseClient = getSupabaseClient) {}

  async getCurrentSession(): Promise<Session | null> {
    const { data, error } = await this.getClient().auth.getSession();
    if (error) throw toSafeError(error);
    return data.session;
  }

  watchAuth(listener: AuthListener): { unsubscribe: () => void } {
    const { data } = this.getClient().auth.onAuthStateChange(listener);
    return data.subscription;
  }

  async signIn(email: string, password: string): Promise<void> {
    const { error } = await this.getClient().auth.signInWithPassword({
      email: email.trim().toLowerCase(),
      password,
    });
    if (error) throw new AdminApiError('Thông tin đăng nhập chưa đúng hoặc tài khoản chưa thể sử dụng.');
  }

  async signOut(): Promise<void> {
    const { error } = await this.getClient().auth.signOut();
    if (error) throw new AdminApiError('Chưa thể đăng xuất lúc này. Bạn thử lại sau nhé.', true);
  }

  async fetchAdminSession(): Promise<AdminSession> {
    const data = await this.rpc<unknown>('get_my_admin_session');
    return toAdminSession(data);
  }

  async fetchDashboard(from: Date, to: Date): Promise<DashboardMetric[]> {
    const data = await this.rpc<unknown>('get_admin_dashboard_summary', {
      p_from: from.toISOString(),
      p_to: to.toISOString(),
      p_scope: 'global',
      p_time_zone: 'Asia/Ho_Chi_Minh',
    });
    return normalizeArray<Record<string, unknown>>(data).map((row) => ({
      key: String(row.metric_key ?? 'unknown'),
      label: String(row.label ?? 'Chỉ số vận hành'),
      value: numberValue(row.metric_value),
      status: String(row.status ?? 'ready'),
      targetSection: sectionFromTarget(row.target_section),
    }));
  }

  async fetchPaymentReviewAlert(): Promise<number> {
    const data = await this.rpc<unknown>('admin_get_payment_review_alert');
    const row = normalizeMap(Array.isArray(data) ? data[0] : data);
    return Math.max(0, numberValue(row.pending_review_count));
  }

  async listSection(section: AdminSection, query = ''): Promise<AdminWorkItem[]> {
    const rpcBySection: Record<AdminSection, string> = {
      dashboard: 'admin_search_users',
      users: 'admin_search_users',
      payments: 'admin_list_payments',
      sales: 'admin_list_sales',
      'sale-conversions': 'admin_list_sale_point_conversions',
      'wellness-rewards': 'admin_list_wellness_rewards',
      reconciliation: 'admin_list_reconciliation_discrepancies',
      plans: 'admin_list_plan_config_versions',
      reports: 'admin_list_report_catalog',
      audit: 'admin_list_audit_events',
      config: 'admin_list_config_versions',
    };
    if (section === 'audit') return this.listAudit(query).then((events) => events.map(auditAsWorkItem));
    const data = await this.rpc<unknown>(rpcBySection[section], { p_query: query.trim(), p_limit: 100 });
    if (section === 'users') return toUserWorkItems(data);
    return section === 'wellness-rewards' ? toWellnessWorkItems(data) : toWorkItems(data);
  }

  async listReportExports(query = ''): Promise<AdminWorkItem[]> {
    const data = await this.rpc<unknown>('admin_list_report_exports', { p_query: query.trim(), p_limit: 100 });
    return toWorkItems(data);
  }

  async listAudit(query = ''): Promise<AdminAuditEvent[]> {
    const data = await this.rpc<unknown>('admin_list_audit_events', { p_query: query.trim(), p_limit: 100 });
    return normalizeArray<Record<string, unknown>>(data).map((row) => ({
      id: String(row.id ?? ''),
      action: String(row.action ?? ''),
      actorId: String(row.actor_id ?? ''),
      target: String(row.target ?? ''),
      reason: String(row.reason ?? ''),
      createdAt: row.created_at ? String(row.created_at) : undefined,
    }));
  }

  async runMutation(mutation: AdminMutation): Promise<MutationResult> {
    const reason = mutation.reason.trim();
    if (!reason) throw new AdminApiError('Vui lòng nhập lý do cho thao tác này.');
    const idempotencyKey = mutation.idempotencyKey ?? makeKey(mutation.action, mutation.targetId);
    const base = { p_reason: reason, p_idempotency_key: idempotencyKey };
    let functionName: string;
    let params: Record<string, unknown>;

    switch (mutation.section) {
      case 'users':
        functionName = 'admin_update_user_status';
        params = { ...base, p_user_id: mutation.targetId, p_status: mutation.action };
        break;
      case 'payments':
        functionName = ['refund', 'cancel', 'chargeback'].includes(mutation.action)
          ? 'admin_refund_or_cancel_payment'
          : 'admin_review_payment';
        params = {
          ...base,
          p_payment_event_id: mutation.targetId,
          p_decision: mutation.action,
          ...(mutation.action === 'approve' || mutation.action === 'reject'
            ? { p_transfer_verified: mutation.payload?.transferVerified === true }
            : {}),
        };
        break;
      case 'sales':
        functionName = 'admin_review_sale_profile';
        params = { ...base, p_sale_user_id: mutation.targetId, p_decision: mutation.action };
        break;
      case 'sale-conversions':
        if (mutation.action === 'adjust_points') {
          functionName = 'admin_adjust_sale_points';
          params = { ...base, p_sale_user_id: mutation.targetId, p_point_delta_cents: numberValue(mutation.payload?.pointDeltaCents) };
        } else {
          functionName = 'admin_review_sale_point_conversion';
          params = {
            ...base,
            p_conversion_id: mutation.targetId,
            p_decision: mutation.action,
            ...(mutation.payload?.paymentProofPath ? { p_payment_proof_path: mutation.payload.paymentProofPath } : {}),
          };
        }
        break;
      case 'reconciliation':
        if (mutation.action === 'create_run') {
          functionName = 'admin_create_reconciliation_run';
          params = { ...base, p_scope: mutation.targetId || 'payments' };
        } else {
          functionName = 'admin_update_reconciliation_discrepancy_status';
          params = { ...base, p_discrepancy_id: mutation.targetId, p_status: mutation.action };
        }
        break;
      case 'plans':
      case 'config':
        functionName = 'admin_upsert_config_version';
        params = {
          ...base,
          p_config_key: mutation.targetId,
          p_config_value: mutation.payload?.configValue ?? {},
        };
        break;
      case 'reports':
        functionName = 'admin_request_report_export';
        params = {
          ...base,
          p_report_type: mutation.targetId,
          p_filters: { time_zone: 'Asia/Ho_Chi_Minh' },
        };
        break;
      case 'dashboard':
      case 'audit':
        throw new AdminApiError('Khu vực này chỉ cho phép xem thông tin.');
      case 'wellness-rewards':
        throw new AdminApiError('Thao tác phần thưởng cần biểu mẫu chuyên biệt.');
    }

    return toMutationResult(await this.rpc<unknown>(functionName, params));
  }

  async createAccount(input: AccountCreateInput): Promise<MutationResult> {
    assertWriteContext(input.reason, input.idempotencyKey);
    const data = await this.invoke<unknown>('admin-create-account', {
      full_name: input.fullName.trim(),
      email: input.email.trim().toLowerCase(),
      password: input.password,
      phone: input.phone?.trim() || null,
      reason: input.reason.trim(),
      idempotency_key: input.idempotencyKey,
    });
    return toMutationResult(data);
  }

  async grantMembership(input: MembershipGrantInput): Promise<MutationResult> {
    assertWriteContext(input.reason, input.idempotencyKey);
    const data = await this.invoke<unknown>('admin-grant-membership', {
      user_id: input.userId,
      plan_code: input.planCode,
      starts_at: input.startsAt,
      ends_at: input.endsAt,
      reason: input.reason.trim(),
      idempotency_key: input.idempotencyKey,
    });
    return toMutationResult(data);
  }

  async getUserDetails(userId: string, reason: string): Promise<AdminUserDetails> {
    if (!userId.trim()) throw new AdminApiError('Chưa chọn tài khoản cần xem.');
    if (!reason.trim()) throw new AdminApiError('Vui lòng nhập lý do xem thông tin sức khỏe.');
    const data = await this.invoke<unknown>('admin-user-management', {
      operation: 'detail',
      user_id: userId,
      reason: reason.trim(),
    });
    return toAdminUserDetails(data);
  }

  async updateUserProfile(input: AdminUserProfileUpdateInput): Promise<MutationResult> {
    assertWriteContext(input.reason, input.idempotencyKey);
    const data = await this.invoke<unknown>('admin-user-management', {
      operation: 'update_profile',
      user_id: input.userId,
      full_name: input.fullName.trim(),
      phone: input.phone.trim() || null,
      gender: input.gender.trim() || null,
      birth_year: input.birthYear ?? null,
      reason: input.reason.trim(),
      idempotency_key: input.idempotencyKey,
    });
    return toMutationResult(data);
  }

  async resetUserPassword(userId: string, reason: string, idempotencyKey: string): Promise<AdminPasswordResetResult> {
    assertWriteContext(reason, idempotencyKey);
    const data = await this.invoke<unknown>('admin-user-management', {
      operation: 'reset_password',
      user_id: userId,
      reason: reason.trim(),
      idempotency_key: idempotencyKey,
    });
    const map = normalizeMap(data);
    const status = map.status === 'already_processed' ? 'already_processed' : 'password_reset';
    return {
      success: map.success === true,
      message: String(map.message ?? 'Đã xử lý đổi mật khẩu.'),
      status,
      temporaryPassword: typeof map.temporary_password === 'string' ? map.temporary_password : undefined,
      passwordVisibleOnce: map.password_visible_once === true,
    };
  }

  async previewBulkProvision(input: Omit<BulkProvisionInput, 'password'>): Promise<BulkProvisionPreview> {
    assertWriteContext(input.reason, input.idempotencyKey);
    const data = await this.invoke<unknown>('admin-provision-accounts-bulk', {
      mode: 'preview',
      accounts: input.accounts,
      plan_code: input.planCode,
      duration_months: input.durationMonths,
      reason: input.reason.trim(),
      idempotency_key: input.idempotencyKey,
    });
    return toBulkPreview(data);
  }

  async executeBulkProvision(input: BulkProvisionInput, fingerprint: string): Promise<BulkProvisionResult> {
    assertWriteContext(input.reason, input.idempotencyKey);
    const data = await this.invoke<unknown>('admin-provision-accounts-bulk', {
      mode: 'execute',
      accounts: input.accounts,
      password: input.password,
      plan_code: input.planCode,
      duration_months: input.durationMonths,
      reason: input.reason.trim(),
      idempotency_key: input.idempotencyKey,
      preview_fingerprint: fingerprint,
      confirmation: `TAO TAI KHOAN ${input.accounts.length}`,
    });
    return toBulkProvisionResult(data);
  }

  async upsertRewardOffer(input: RewardOfferInput): Promise<MutationResult> {
    assertWriteContext(input.reason, input.idempotencyKey);
    const data = await this.rpc<unknown>('admin_upsert_reward_offer', {
      p_offer_id: input.offerId || null,
      p_title: input.title.trim(),
      p_description: input.description.trim(),
      p_provider_name: input.providerName.trim(),
      p_cost_points: input.costPoints,
      p_eligible_plan_codes: input.eligiblePlanCodes,
      p_available_from: input.availableFrom || null,
      p_available_until: input.availableUntil || null,
      p_voucher_expires_at: input.voucherExpiresAt || null,
      p_is_active: input.isActive,
      p_reason: input.reason.trim(),
      p_idempotency_key: input.idempotencyKey,
    });
    return toMutationResult(data);
  }

  async importRewardCodes(offerId: string, codes: string[], expiresAt: string, reason: string, idempotencyKey = makeKey('reward-import', offerId)): Promise<MutationResult> {
    assertWriteContext(reason, idempotencyKey);
    const data = await this.rpc<unknown>('admin_import_reward_codes', {
      p_offer_id: offerId,
      p_codes: codes,
      p_voucher_expires_at: expiresAt,
      p_reason: reason.trim(),
      p_idempotency_key: idempotencyKey,
    });
    return toMutationResult(data);
  }

  async cancelRewardRedemption(redemptionId: string, reason: string, idempotencyKey = makeKey('reward-cancel', redemptionId)): Promise<MutationResult> {
    assertWriteContext(reason, idempotencyKey);
    const data = await this.rpc<unknown>('admin_cancel_reward_redemption', {
      p_redemption_id: redemptionId,
      p_reason: reason.trim(),
      p_external_revocation_confirmed: true,
      p_idempotency_key: idempotencyKey,
    });
    return toMutationResult(data);
  }

  async uploadPayoutProof(conversionId: string, file: File): Promise<string> {
    if (!['image/jpeg', 'image/png'].includes(file.type)) {
      throw new AdminApiError('Chỉ nhận ảnh JPG hoặc PNG.');
    }
    if (file.size > 5 * 1024 * 1024) {
      throw new AdminApiError('Ảnh cần nhỏ hơn 5 MB.');
    }
    const safeConversion = conversionId.replace(/[^a-zA-Z0-9_-]/g, '_');
    const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_');
    const path = `sale-point-conversions/${safeConversion}/${Date.now()}-${safeName}`;
    const { error } = await this.getClient().storage.from('sale-payout-proofs').upload(path, file, {
      contentType: file.type,
      upsert: false,
    });
    if (error) throw new AdminApiError('Chưa tải được ảnh xác nhận. Hãy thử lại với ảnh khác.', true);
    return path;
  }

  async signedPayoutProof(path: string): Promise<string> {
    const { data, error } = await this.getClient().storage.from('sale-payout-proofs').createSignedUrl(path, 600);
    if (error || !data?.signedUrl) throw new AdminApiError('Chưa mở được ảnh xác nhận.', true);
    return data.signedUrl;
  }

  private async rpc<T>(name: string, params?: Record<string, unknown>): Promise<T> {
    const { data, error } = await this.getClient().rpc(name, params);
    if (error) throw toSafeError(error);
    return data as T;
  }

  private async invoke<T>(name: string, body: Record<string, unknown>): Promise<T> {
    const { data, error } = await this.getClient().functions.invoke(name, { body });
    if (error) {
      const context = (error as { context?: unknown }).context;
      if (context instanceof Response) {
        try {
          const payload = await context.clone().json() as Record<string, unknown>;
          const message = typeof payload.message === 'string' ? payload.message.trim() : '';
          if (message && message.length <= 240) throw new AdminApiError(message, false);
        } catch (nextError) {
          if (nextError instanceof AdminApiError) throw nextError;
        }
      }
      throw new AdminApiError('Thao tác chưa hoàn tất. Bạn thử lại sau nhé.', true);
    }
    return data as T;
  }
}

export function makeKey(action: string, target = ''): string {
  const random = typeof crypto !== 'undefined' && 'randomUUID' in crypto ? crypto.randomUUID() : `${Date.now()}-${Math.random()}`;
  return `${action}-${target}-${random}`.replace(/[^a-zA-Z0-9_-]/g, '_');
}

function numberValue(value: unknown): number {
  const number = typeof value === 'number' ? value : Number(value);
  return Number.isFinite(number) ? number : 0;
}

function assertWriteContext(reason: string, idempotencyKey: string): void {
  if (!reason.trim()) throw new AdminApiError('Vui lòng nhập lý do cho thao tác này.');
  if (!idempotencyKey.trim()) throw new AdminApiError('Thao tác chưa có mã chống gửi trùng.');
}

function sectionFromTarget(value: unknown): AdminSection | undefined {
  const result = String(value ?? '');
  const map: Record<string, AdminSection> = {
    users: 'users',
    payments: 'payments',
    sales: 'sales',
    sale_conversions: 'sale-conversions',
    sale_point_conversions: 'sale-conversions',
    reconciliation: 'reconciliation',
    reports: 'reports',
    plans: 'plans',
  };
  return map[result];
}

function toAdminUserDetails(value: unknown): AdminUserDetails {
  const map = normalizeMap(value);
  const user = normalizeMap(map.user);
  const health = normalizeMap(map.health);
  const membership = normalizeMap(map.membership);
  return {
    user: {
      id: String(user.id ?? ''),
      email: optionalString(user.email),
      fullName: optionalString(user.full_name),
      phone: optionalString(user.phone),
      gender: optionalString(user.gender),
      birthYear: optionalNumber(user.birth_year),
      avatarUrl: optionalString(user.avatar_url),
      adminStatus: optionalString(user.admin_status),
      createdAt: optionalString(user.created_at),
      updatedAt: optionalString(user.updated_at),
    },
    health: {
      subject: optionalRecord(health.subject),
      profile: optionalRecord(health.profile),
      lifestyle: optionalRecord(health.lifestyle),
      goals: recordArray(health.goals),
      conditions: recordArray(health.conditions),
      allergies: recordArray(health.allergies),
      treatments: recordArray(health.treatments),
      surveyAnswers: recordArray(health.survey_answers),
    },
    membership: {
      planCode: normalizePlanCode(membership.plan_code) ?? 'free',
      status: String(membership.status ?? 'none'),
      source: optionalString(membership.source),
      startsAt: optionalString(membership.starts_at),
      endsAt: optionalString(membership.ends_at),
    },
  };
}

function optionalRecord(value: unknown): Record<string, unknown> | undefined {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
    ? value as Record<string, unknown>
    : undefined;
}

function recordArray(value: unknown): Array<Record<string, unknown>> {
  return normalizeArray<unknown>(value)
    .map(optionalRecord)
    .filter((row): row is Record<string, unknown> => row !== undefined);
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

function toMutationResult(value: unknown): MutationResult {
  const row = normalizeMap(Array.isArray(value) ? value[0] : value);
  return {
    success: row.success !== false,
    message: String(row.message ?? 'Thao tác đã được ghi nhận.'),
  };
}

function toBulkPreview(value: unknown): BulkProvisionPreview {
  const row = normalizeMap(value);
  const rows: BulkProvisionPreviewRow[] = normalizeArray<Record<string, unknown>>(row.rows).map((item) => {
    const status: BulkProvisionPreviewRow['status'] = item.status === 'paid_preserved' || item.status === 'existing'
      ? item.status
      : 'new';
    return {
      index: numberValue(item.index),
      status,
      ...(typeof item.current_plan === 'string' ? { currentPlan: item.current_plan } : {}),
    };
  });
  const fingerprint = typeof row.fingerprint === 'string' ? row.fingerprint : '';
  if (!fingerprint || rows.length === 0) {
    throw new AdminApiError('Bản xem trước chưa hợp lệ. Vui lòng thử lại.', true);
  }
  return {
    fingerprint,
    candidateCount: numberValue(row.candidate_count),
    rows,
  };
}

function toBulkProvisionResult(value: unknown): BulkProvisionResult {
  const row = normalizeMap(value);
  const batchId = typeof row.batch_id === 'string' ? row.batch_id : '';
  if (!batchId) {
    throw new AdminApiError('Batch chưa hoàn tất. Vui lòng giữ nguyên mã thao tác khi thử lại.', true);
  }
  return {
    success: row.success !== false,
    message: String(row.message ?? 'Batch đã được ghi nhận.'),
    batchId,
    processedCount: numberValue(row.processed_count),
    createdCount: numberValue(row.created_count),
    grantedCount: numberValue(row.granted_count),
    skippedCount: numberValue(row.skipped_count),
    ...(Number.isFinite(Number(row.failed_index)) ? { failedIndex: numberValue(row.failed_index) } : {}),
  };
}

function auditAsWorkItem(event: AdminAuditEvent): AdminWorkItem {
  return {
    id: event.id,
    title: event.action,
    subtitle: `${event.target} · ${event.reason}`,
    status: 'recorded',
    section: 'audit',
    createdAt: event.createdAt,
    metadata: {},
  };
}

function toSafeError(error: unknown): AdminApiError {
  const source = normalizeMap(error);
  const code = String(source.code ?? '').toLowerCase();
  const rawMessage = error instanceof Error ? error.message : String(source.message ?? '');
  const message = rawMessage.toLowerCase();
  if (code === '42501' || message.includes('permission') || message.includes('forbidden') || message.includes('not authorized') || message.includes('insufficient privilege')) {
    return new AdminApiError('Tài khoản chưa được cấp quyền cho thao tác này.');
  }
  if (code === '401' || code === 'jwt_expired' || message.includes('jwt') || message.includes('session') || message.includes('unauthorized')) {
    return new AdminApiError('Phiên đăng nhập đã hết hạn. Bạn đăng nhập lại nhé.');
  }
  return new AdminApiError('Chưa tải được dữ liệu. Bạn thử lại sau nhé.', true);
}

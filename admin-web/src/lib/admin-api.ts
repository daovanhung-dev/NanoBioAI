import {
  BackendClient,
  BackendRequestError,
  createBackendClient,
  type BackendAuthSession,
} from "./backend-client";
import {
  type AccountCreateInput,
  type AdminAuditEvent,
  type AdminMutation,
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
  EARLY_ACCESS_LEAD_STATUSES,
  type EarlyAccessLead,
  type EarlyAccessLeadPage,
  type EarlyAccessLeadStatus,
  type MembershipGrantInput,
  type MembershipPeriodAdjustmentInput,
  type MembershipPeriodAdjustmentResult,
  type MutationResult,
  normalizeArray,
  normalizeMap,
  normalizePlanCode,
  type RewardOfferInput,
  toAdminSession,
  toUserWorkItems,
  toWellnessWorkItems,
  toWorkItems,
} from "../types";

export class AdminApiError extends Error {
  constructor(
    message: string,
    readonly retryable = false,
    readonly businessCode = 'ADMIN_API_ERROR',
  ) {
    super(message);
    this.name = "AdminApiError";
  }
}

type AuthListener = (session: BackendAuthSession | null) => void;

export class AdminApi {
  constructor(
    private readonly client: BackendClient = createBackendClient(),
  ) {}

  async getCurrentSession(): Promise<BackendAuthSession | null> {
    return this.client.getCurrentSession();
  }

  watchAuth(listener: AuthListener): { unsubscribe: () => void } {
    return this.client.watchAuth(listener);
  }

  async signIn(identifier: string, password: string): Promise<BackendAuthSession> {
    try {
      return await this.client.signIn(identifier, password);
    } catch (error) {
      if (error instanceof BackendRequestError) {
        throw new AdminApiError(error.message, error.statusCode >= 500, error.businessCode);
      }
      throw new AdminApiError("Thông tin đăng nhập chưa đúng hoặc tài khoản chưa thể sử dụng.");
    }
  }

  async changePassword(newPassword: string): Promise<BackendAuthSession> {
    try {
      return await this.client.changePassword(newPassword);
    } catch (error) {
      if (error instanceof BackendRequestError) {
        throw new AdminApiError(error.message, error.statusCode >= 500, error.businessCode);
      }
      throw new AdminApiError("Chưa thể cập nhật mật khẩu lúc này.");
    }
  }

  async signOut(): Promise<void> {
    await this.client.signOut();
  }

  async fetchAdminSession(): Promise<AdminSession> {
    try {
      const data = await this.client.requestData<unknown>("/admin/session");
      return toAdminSession(data);
    } catch (error) {
      if (error instanceof BackendRequestError) {
        throw new AdminApiError(error.message, error.statusCode >= 500, error.businessCode);
      }
      throw error;
    }
  }

  async fetchEarlyAccessLeads(
    query: string,
    page: number,
    pageSize = 25,
  ): Promise<EarlyAccessLeadPage> {
    const data = await this.client.requestData<unknown>("/admin/early-access/leads", {
      query: { q: query.trim(), page, page_size: pageSize },
    });
    const response = normalizeMap(data);
    if (!Array.isArray(response.rows)) {
      throw new AdminApiError(
        "Chưa tải được danh sách thông tin sự kiện.",
        true,
      );
    }
    const rows = normalizeArray<Record<string, unknown>>(response.rows).map((
      row,
    ) => toEarlyAccessLead(row));
    return {
      rows,
      total: integerValue(response.total),
      page: integerValue(response.page),
      pageSize: integerValue(response.page_size),
    };
  }

  async updateEarlyAccessLeadStatus(input: {
    leadId: string;
    status: EarlyAccessLeadStatus;
    reason: string;
    idempotencyKey: string;
  }): Promise<MutationResult> {
    assertWriteContext(input.reason, input.idempotencyKey);
    if (
      !input.leadId.trim() || !EARLY_ACCESS_LEAD_STATUSES.includes(input.status)
    ) {
      throw new AdminApiError("Chưa chọn hồ sơ hoặc trạng thái hợp lệ.");
    }
    return toMutationResult(await this.client.requestData<unknown>(
      `/admin/early-access/leads/${encodeURIComponent(input.leadId)}`,
      {
        method: "PATCH",
        body: {
          status: input.status,
          reason: input.reason.trim(),
          idempotency_key: input.idempotencyKey,
        },
      },
    ));
  }

  async fetchDashboard(from: Date, to: Date): Promise<DashboardMetric[]> {
    const data = await this.client.requestData<unknown>("/admin/dashboard", {
      query: { from: from.toISOString(), to: to.toISOString() },
    });
    return normalizeArray<Record<string, unknown>>(data).map((row) => ({
      key: String(row.metric_key ?? "unknown"),
      label: String(row.label ?? "Chỉ số vận hành"),
      value: numberValue(row.metric_value),
      status: String(row.status ?? "ready"),
      targetSection: sectionFromTarget(row.target_section),
    }));
  }

  async fetchPaymentReviewAlert(): Promise<number> {
    const data = await this.rpc<unknown>("admin_get_payment_review_alert");
    const row = normalizeMap(Array.isArray(data) ? data[0] : data);
    return Math.max(0, numberValue(row.pending_review_count));
  }

  async listSection(
    section: AdminSection,
    query = "",
  ): Promise<AdminWorkItem[]> {
    if (section === "event-info") {
      throw new AdminApiError(
        "Khu vực này cần API thông tin sự kiện chuyên biệt.",
      );
    }
    const rpcBySection: Record<Exclude<AdminSection, "event-info">, string> = {
      dashboard: "admin_search_users",
      users: "admin_search_users",
      payments: "admin_list_payments",
      sales: "admin_list_sales",
      "sale-conversions": "admin_list_sale_point_conversions",
      "wellness-rewards": "admin_list_wellness_rewards",
      reconciliation: "admin_list_reconciliation_discrepancies",
      plans: "admin_list_plan_config_versions",
      reports: "admin_list_report_catalog",
      audit: "admin_list_audit_events",
      config: "admin_list_config_versions",
    };
    if (section === "audit") {
      return this.listAudit(query).then((events) =>
        events.map(auditAsWorkItem)
      );
    }
    const data = await this.rpc<unknown>(rpcBySection[section], {
      p_query: query.trim(),
      p_limit: 100,
    });
    if (section === "users") return toUserWorkItems(data);
    return section === "wellness-rewards"
      ? toWellnessWorkItems(data)
      : toWorkItems(data);
  }

  async listReportExports(query = ""): Promise<AdminWorkItem[]> {
    const data = await this.rpc<unknown>("admin_list_report_exports", {
      p_query: query.trim(),
      p_limit: 100,
    });
    return toWorkItems(data);
  }

  async listAudit(query = ""): Promise<AdminAuditEvent[]> {
    const data = await this.rpc<unknown>("admin_list_audit_events", {
      p_query: query.trim(),
      p_limit: 100,
    });
    return normalizeArray<Record<string, unknown>>(data).map((row) => ({
      id: String(row.id ?? ""),
      action: String(row.action ?? ""),
      actorId: String(row.actor_id ?? ""),
      target: String(row.target ?? ""),
      reason: String(row.reason ?? ""),
      createdAt: row.created_at ? String(row.created_at) : undefined,
    }));
  }

  async runMutation(mutation: AdminMutation): Promise<MutationResult> {
    const reason = mutation.reason.trim();
    if (!reason) {
      throw new AdminApiError("Vui lòng nhập lý do cho thao tác này.");
    }
    const idempotencyKey = mutation.idempotencyKey ??
      makeKey(mutation.action, mutation.targetId);
    const base = { p_reason: reason, p_idempotency_key: idempotencyKey };
    let functionName: string;
    let params: Record<string, unknown>;

    switch (mutation.section) {
      case "users":
        functionName = "admin_update_user_status";
        params = {
          ...base,
          p_user_id: mutation.targetId,
          p_status: mutation.action,
        };
        break;
      case "payments":
        functionName =
          ["refund", "cancel", "chargeback"].includes(mutation.action)
            ? "admin_refund_or_cancel_payment"
            : "admin_review_payment";
        params = {
          ...base,
          p_payment_event_id: mutation.targetId,
          p_decision: mutation.action,
          ...(mutation.action === "approve" || mutation.action === "reject"
            ? {
              p_transfer_verified: mutation.payload?.transferVerified === true,
            }
            : {}),
        };
        break;
      case "sales":
        functionName = "admin_review_sale_profile";
        params = {
          ...base,
          p_sale_user_id: mutation.targetId,
          p_decision: mutation.action,
        };
        break;
      case "sale-conversions":
        if (mutation.action === "adjust_points") {
          functionName = "admin_adjust_sale_points";
          params = {
            ...base,
            p_sale_user_id: mutation.targetId,
            p_point_delta_cents: numberValue(mutation.payload?.pointDeltaCents),
          };
        } else {
          functionName = "admin_review_sale_point_conversion";
          params = {
            ...base,
            p_conversion_id: mutation.targetId,
            p_decision: mutation.action,
            ...(mutation.payload?.paymentProofPath
              ? { p_payment_proof_path: mutation.payload.paymentProofPath }
              : {}),
          };
        }
        break;
      case "reconciliation":
        if (mutation.action === "create_run") {
          functionName = "admin_create_reconciliation_run";
          params = { ...base, p_scope: mutation.targetId || "payments" };
        } else {
          functionName = "admin_update_reconciliation_discrepancy_status";
          params = {
            ...base,
            p_discrepancy_id: mutation.targetId,
            p_status: mutation.action,
          };
        }
        break;
      case "plans":
      case "config":
        functionName = "admin_upsert_config_version";
        params = {
          ...base,
          p_config_key: mutation.targetId,
          p_config_value: mutation.payload?.configValue ?? {},
        };
        break;
      case "reports":
        functionName = "admin_request_report_export";
        params = {
          ...base,
          p_report_type: mutation.targetId,
          p_filters: { time_zone: "Asia/Ho_Chi_Minh" },
        };
        break;
      case "dashboard":
      case "audit":
        throw new AdminApiError("Khu vực này chỉ cho phép xem thông tin.");
      case "event-info":
        throw new AdminApiError(
          "Thao tác thông tin sự kiện cần biểu mẫu chuyên biệt.",
        );
      case "wellness-rewards":
        throw new AdminApiError(
          "Thao tác phần thưởng cần biểu mẫu chuyên biệt.",
        );
    }

    return toMutationResult(await this.rpc<unknown>(functionName, params));
  }

  async createAccount(input: AccountCreateInput): Promise<MutationResult> {
    assertWriteContext(input.reason, input.idempotencyKey);
    const data = await this.invoke<unknown>("admin-create-account", {
      full_name: input.fullName.trim(),
      email: input.email?.trim().toLowerCase() || null,
      password: input.password,
      phone: input.phone.trim(),
      reason: input.reason.trim(),
      idempotency_key: input.idempotencyKey,
    });
    return toMutationResult(data);
  }

  async grantMembership(input: MembershipGrantInput): Promise<MutationResult> {
    assertWriteContext(input.reason, input.idempotencyKey);
    const data = await this.invoke<unknown>("admin-grant-membership", {
      user_id: input.userId,
      plan_code: input.planCode,
      starts_at: input.startsAt,
      ends_at: input.endsAt,
      reason: input.reason.trim(),
      idempotency_key: input.idempotencyKey,
    });
    return toMutationResult(data);
  }

  async adjustMembershipPeriod(
    input: MembershipPeriodAdjustmentInput,
  ): Promise<MembershipPeriodAdjustmentResult> {
    assertWriteContext(input.reason, input.idempotencyKey);
    if (!input.userId.trim() || !input.subscriptionId.trim()) {
      throw new AdminApiError("Chưa chọn gói cần điều chỉnh.");
    }
    const data = await this.invoke<unknown>("admin-adjust-membership-period", {
      user_id: input.userId,
      subscription_id: input.subscriptionId,
      operation: input.operation,
      days: input.days,
      ends_at: input.endsAt,
      expected_ends_at: input.expectedEndsAt,
      reason: input.reason.trim(),
      idempotency_key: input.idempotencyKey,
    });
    return toMembershipPeriodAdjustmentResult(data);
  }

  async getUserDetails(
    userId: string,
    reason: string,
  ): Promise<AdminUserDetails> {
    if (!userId.trim()) throw new AdminApiError("Chưa chọn tài khoản cần xem.");
    if (!reason.trim()) {
      throw new AdminApiError("Vui lòng nhập lý do xem thông tin sức khỏe.");
    }
    const data = await this.invoke<unknown>("admin-user-management", {
      operation: "detail",
      user_id: userId,
      reason: reason.trim(),
    });
    return toAdminUserDetails(data);
  }

  async updateUserProfile(
    input: AdminUserProfileUpdateInput,
  ): Promise<MutationResult> {
    assertWriteContext(input.reason, input.idempotencyKey);
    const data = await this.invoke<unknown>("admin-user-management", {
      operation: "update_profile",
      user_id: input.userId,
      full_name: input.fullName.trim(),
      gender: input.gender.trim() || null,
      birth_year: input.birthYear ?? null,
      reason: input.reason.trim(),
      idempotency_key: input.idempotencyKey,
    });
    return toMutationResult(data);
  }

  async resetMemberPassword(
    userId: string,
    reason: string,
    idempotencyKey: string,
  ): Promise<MutationResult> {
    assertWriteContext(reason, idempotencyKey);
    if (!userId.trim()) {
      throw new AdminApiError("Chưa chọn tài khoản cần đặt lại mật khẩu.");
    }
    return toMutationResult(
      await this.invoke<unknown>("admin-user-management", {
        operation: "reset_member_password",
        user_id: userId,
        reason: reason.trim(),
        idempotency_key: idempotencyKey,
      }),
    );
  }

  async previewBulkProvision(
    input: Omit<BulkProvisionInput, "password">,
  ): Promise<BulkProvisionPreview> {
    assertWriteContext(input.reason, input.idempotencyKey);
    const data = await this.invoke<unknown>("admin-provision-accounts-bulk", {
      mode: "preview",
      accounts: toBulkFunctionAccounts(input.accounts),
      plan_code: input.planCode,
      duration_months: input.durationMonths,
      reason: input.reason.trim(),
      idempotency_key: input.idempotencyKey,
    });
    return toBulkPreview(data);
  }

  async executeBulkProvision(
    input: BulkProvisionInput,
    fingerprint: string,
  ): Promise<BulkProvisionResult> {
    assertWriteContext(input.reason, input.idempotencyKey);
    const data = await this.invoke<unknown>("admin-provision-accounts-bulk", {
      mode: "execute",
      accounts: toBulkFunctionAccounts(input.accounts),
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
    const data = await this.rpc<unknown>("admin_upsert_reward_offer", {
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

  async importRewardCodes(
    offerId: string,
    codes: string[],
    expiresAt: string,
    reason: string,
    idempotencyKey = makeKey("reward-import", offerId),
  ): Promise<MutationResult> {
    assertWriteContext(reason, idempotencyKey);
    const data = await this.rpc<unknown>("admin_import_reward_codes", {
      p_offer_id: offerId,
      p_codes: codes,
      p_voucher_expires_at: expiresAt,
      p_reason: reason.trim(),
      p_idempotency_key: idempotencyKey,
    });
    return toMutationResult(data);
  }

  async cancelRewardRedemption(
    redemptionId: string,
    reason: string,
    idempotencyKey = makeKey("reward-cancel", redemptionId),
  ): Promise<MutationResult> {
    assertWriteContext(reason, idempotencyKey);
    const data = await this.rpc<unknown>("admin_cancel_reward_redemption", {
      p_redemption_id: redemptionId,
      p_reason: reason.trim(),
      p_external_revocation_confirmed: true,
      p_idempotency_key: idempotencyKey,
    });
    return toMutationResult(data);
  }

  async uploadPayoutProof(conversionId: string, file: File): Promise<string> {
    if (!["image/jpeg", "image/png"].includes(file.type)) {
      throw new AdminApiError("Chỉ nhận ảnh JPG hoặc PNG.");
    }
    if (file.size > 5 * 1024 * 1024) {
      throw new AdminApiError("Ảnh cần nhỏ hơn 5 MB.");
    }
    if (!conversionId.trim()) throw new AdminApiError("Chưa chọn giao dịch cần xác nhận.");
    const form = new FormData();
    form.append("file", file, file.name);
    const data = normalizeMap(await this.client.requestData<unknown>(
      "/files/sale-payout-proofs",
      { method: "POST", body: form },
    ));
    const fileId = String(data.id ?? "");
    if (!fileId) throw new AdminApiError("Máy chủ chưa trả về mã tệp.", true);
    return fileId;
  }

  async signedPayoutProof(path: string): Promise<string> {
    const fileId = path.trim().split("/").at(-1) ?? "";
    if (!/^[0-9a-f-]{36}$/i.test(fileId)) {
      throw new AdminApiError("Mã tệp chưa hợp lệ.");
    }
    const blob = await this.client.requestBlob(
      `/admin/files/sale-payout-proofs/${encodeURIComponent(fileId)}`,
    );
    return URL.createObjectURL(blob);
  }

  private async rpc<T>(
    name: string,
    params?: Record<string, unknown>,
  ): Promise<T> {
    const p = params ?? {};
    try {
      switch (name) {
        case "get_admin_dashboard_summary":
          return await this.client.requestData<T>("/admin/dashboard", {
            query: {
              from: String(p.p_from ?? ""),
              to: String(p.p_to ?? ""),
            },
          });
        case "get_my_admin_session":
          return await this.client.requestData<T>("/admin/session");
        case "admin_search_users":
          return await this.client.requestData<T>("/admin/users/search", {
            query: {
              q: typeof p.p_query === "string" ? p.p_query : "",
              limit: typeof p.p_limit === "number" ? p.p_limit : 50,
            },
          });
        case "admin_list_payments":
          return await this.client.requestData<T>("/admin/payments", {
            query: {
              q: typeof p.p_query === "string" ? p.p_query : "",
              limit: typeof p.p_limit === "number" ? p.p_limit : 50,
            },
          });
        case "admin_get_payment_review_alert":
          return await this.client.requestData<T>("/admin/payments/review-alert");
        case "admin_list_audit_events":
          return await this.client.requestData<T>("/admin/audit-events", {
            query: { limit: typeof p.p_limit === "number" ? p.p_limit : 100 },
          });
        case "admin_review_payment":
          return await this.client.requestData<T>(
            `/admin/payments/${encodeURIComponent(String(p.p_payment_event_id ?? ""))}/review`,
            {
              method: "POST",
              body: {
                decision: p.p_decision,
                reason: p.p_reason,
                idempotency_key: p.p_idempotency_key,
                transfer_verified: p.p_transfer_verified === true,
              },
            },
          );
        case "admin_refund_or_cancel_payment":
          return await this.client.requestData<T>(
            `/admin/payments/${encodeURIComponent(String(p.p_payment_event_id ?? ""))}/reversal`,
            {
              method: "POST",
              body: {
                decision: p.p_decision,
                reason: p.p_reason,
                idempotency_key: p.p_idempotency_key,
              },
            },
          );
        case "admin_update_user_status":
          return await this.client.requestData<T>(
            `/admin/users/${encodeURIComponent(String(p.p_user_id ?? ""))}/status`,
            {
              method: "PATCH",
              body: {
                status: p.p_status,
                reason: p.p_reason,
                idempotency_key: p.p_idempotency_key,
              },
            },
          );
        case "admin_list_sales":
        case "admin_list_sale_point_conversions":
        case "admin_list_wellness_rewards":
        case "admin_list_reconciliation_discrepancies":
        case "admin_list_plan_config_versions":
        case "admin_list_report_catalog":
        case "admin_list_config_versions":
        case "admin_list_report_exports": {
          const sectionByName: Record<string, string> = {
            admin_list_sales: "sales",
            admin_list_sale_point_conversions: "sale-conversions",
            admin_list_wellness_rewards: "wellness-rewards",
            admin_list_reconciliation_discrepancies: "reconciliation",
            admin_list_plan_config_versions: "plans",
            admin_list_report_catalog: "reports",
            admin_list_config_versions: "config",
            admin_list_report_exports: "report-exports",
          };
          return await this.client.requestData<T>(
            `/admin/business/${sectionByName[name]}`,
            {
              query: {
                q: typeof p.p_query === "string" ? p.p_query : "",
                limit: typeof p.p_limit === "number" ? p.p_limit : 100,
              },
            },
          );
        }
        case "admin_review_sale_profile":
          return await this.adminBusinessMutation<T>("sales", {
            action: p.p_decision,
            target_id: p.p_sale_user_id,
            reason: p.p_reason,
            idempotency_key: p.p_idempotency_key,
          });
        case "admin_adjust_sale_points":
          return await this.adminBusinessMutation<T>("sale-conversions", {
            action: "adjust_points",
            target_id: p.p_sale_user_id,
            reason: p.p_reason,
            idempotency_key: p.p_idempotency_key,
            payload: { point_delta_cents: p.p_point_delta_cents },
          });
        case "admin_review_sale_point_conversion":
          return await this.adminBusinessMutation<T>("sale-conversions", {
            action: p.p_decision,
            target_id: p.p_conversion_id,
            reason: p.p_reason,
            idempotency_key: p.p_idempotency_key,
            payload: { payment_proof_path: p.p_payment_proof_path },
          });
        case "admin_create_reconciliation_run":
          return await this.adminBusinessMutation<T>("reconciliation", {
            action: "create_run",
            target_id: p.p_scope,
            reason: p.p_reason,
            idempotency_key: p.p_idempotency_key,
          });
        case "admin_update_reconciliation_discrepancy_status":
          return await this.adminBusinessMutation<T>("reconciliation", {
            action: p.p_status,
            target_id: p.p_discrepancy_id,
            reason: p.p_reason,
            idempotency_key: p.p_idempotency_key,
          });
        case "admin_upsert_config_version":
          return await this.adminBusinessMutation<T>("config", {
            action: "upsert_config",
            target_id: p.p_config_key,
            reason: p.p_reason,
            idempotency_key: p.p_idempotency_key,
            payload: { config_value: p.p_config_value },
          });
        case "admin_request_report_export":
          return await this.adminBusinessMutation<T>("reports", {
            action: "request_export",
            target_id: p.p_report_type,
            reason: p.p_reason,
            idempotency_key: p.p_idempotency_key,
            payload: { filters: p.p_filters },
          });
        case "admin_upsert_reward_offer":
        case "admin_upsert_reward_offer_v2":
          return await this.adminBusinessMutation<T>("wellness-rewards", {
            action: "upsert_offer",
            target_id: p.p_offer_id,
            reason: p.p_reason,
            idempotency_key: p.p_idempotency_key,
            payload: {
              reward_type: p.p_reward_type ?? "voucher",
              title: p.p_title,
              description: p.p_description,
              provider_name: p.p_provider_name,
              cost_points: p.p_cost_points,
              stock_count: p.p_stock_count ?? 0,
              eligible_plan_codes: p.p_eligible_plan_codes,
              available_from: p.p_available_from,
              available_until: p.p_available_until,
              voucher_expires_at: p.p_voucher_expires_at,
              is_active: p.p_is_active,
            },
          });
        case "admin_import_reward_codes":
          return await this.adminBusinessMutation<T>("wellness-rewards", {
            action: "import_codes",
            target_id: p.p_offer_id,
            reason: p.p_reason,
            idempotency_key: p.p_idempotency_key,
            payload: {
              codes: p.p_codes,
              voucher_expires_at: p.p_voucher_expires_at,
            },
          });
        case "admin_cancel_reward_redemption":
          return await this.adminBusinessMutation<T>("wellness-rewards", {
            action: "cancel",
            target_id: p.p_redemption_id,
            reason: p.p_reason,
            idempotency_key: p.p_idempotency_key,
            payload: { external_revocation_confirmed: true },
          });
        case "admin_mark_reward_redemption_received":
          return await this.adminBusinessMutation<T>("wellness-rewards", {
            action: "mark_received",
            target_id: p.p_redemption_id,
            reason: p.p_reason,
            idempotency_key: p.p_idempotency_key,
          });
        default:
          throw new AdminApiError(`Nghiệp vụ ${name} chưa được cung cấp trên backend tự host.`);
      }
    } catch (error) {
      throw safeBackendError(error);
    }
  }

  private async adminBusinessMutation<T>(
    section: string,
    body: Record<string, unknown>,
  ): Promise<T> {
    return this.client.requestData<T>(`/admin/business/${section}`, {
      method: "POST",
      body,
    });
  }

  private async invoke<T>(
    name: string,
    body: Record<string, unknown>,
  ): Promise<T> {
    try {
      switch (name) {
        case "admin-create-account":
          return await this.client.requestData<T>("/admin/accounts", {
            method: "POST",
            body,
          });
        case "admin-grant-membership":
          return await this.client.requestData<T>("/admin/memberships/grant", {
            method: "POST",
            body,
          });
        case "admin-adjust-membership-period":
          return await this.client.requestData<T>("/admin/memberships/adjust-period", {
            method: "POST",
            body,
          });
        case "admin-provision-accounts-bulk":
          return await this.client.requestData<T>(
            body.mode === "preview"
              ? "/admin/accounts/bulk-provision/preview"
              : "/admin/accounts/bulk-provision",
            { method: "POST", body },
          );
        case "admin-user-management": {
          const userId = encodeURIComponent(String(body.user_id ?? ""));
          if (body.operation === "detail") {
            return await this.client.requestData<T>(`/admin/users/${userId}`, {
              query: { reason: body.reason as string },
            });
          }
          if (body.operation === "update_profile") {
            return await this.client.requestData<T>(`/admin/users/${userId}/profile`, {
              method: "PATCH",
              body: {
                full_name: body.full_name,
                gender: body.gender,
                birth_year: body.birth_year,
                reason: body.reason,
                idempotency_key: body.idempotency_key,
              },
            });
          }
          if (body.operation === "reset_member_password") {
            return await this.client.requestData<T>(`/admin/users/${userId}/password-reset`, {
              method: "POST",
              query: {
                reason: body.reason as string,
                idempotency_key: body.idempotency_key as string,
              },
            });
          }
          throw new AdminApiError("Thao tác tài khoản này chưa được cung cấp.");
        }
        default:
          throw new AdminApiError(`Nghiệp vụ ${name} chưa được cung cấp trên backend tự host.`);
      }
    } catch (error) {
      throw safeBackendError(error);
    }
  }
}

function safeBackendError(error: unknown): AdminApiError {
  if (error instanceof AdminApiError) return error;
  if (error instanceof BackendRequestError) {
    return new AdminApiError(error.message, error.statusCode >= 500 || error.statusCode === 0);
  }
  return new AdminApiError("Máy chủ chưa thể hoàn tất thao tác này. Bạn thử lại sau nhé.", true);
}

export function makeKey(action: string, target = ""): string {
  const random = typeof crypto !== "undefined" && "randomUUID" in crypto
    ? crypto.randomUUID()
    : `${Date.now()}-${Math.random()}`;
  return `${action}-${target}-${random}`.replace(/[^a-zA-Z0-9_-]/g, "_");
}

function numberValue(value: unknown): number {
  const number = typeof value === "number" ? value : Number(value);
  return Number.isFinite(number) ? number : 0;
}

function assertWriteContext(reason: string, idempotencyKey: string): void {
  if (!reason.trim()) {
    throw new AdminApiError("Vui lòng nhập lý do cho thao tác này.");
  }
  if (!idempotencyKey.trim()) {
    throw new AdminApiError("Thao tác chưa có mã chống gửi trùng.");
  }
}

function toBulkFunctionAccounts(
  accounts: BulkProvisionInput["accounts"],
): Array<{ phone: string; full_name: string; email?: string }> {
  return accounts.map((account) => ({
    phone: account.phone,
    full_name: account.fullName,
    ...(account.email ? { email: account.email } : {}),
  }));
}

function sectionFromTarget(value: unknown): AdminSection | undefined {
  const result = String(value ?? "");
  const map: Record<string, AdminSection> = {
    users: "users",
    payments: "payments",
    sales: "sales",
    sale_conversions: "sale-conversions",
    sale_point_conversions: "sale-conversions",
    reconciliation: "reconciliation",
    reports: "reports",
    plans: "plans",
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
      id: String(user.id ?? ""),
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
      subscriptionId: optionalString(membership.subscription_id),
      planCode: normalizePlanCode(membership.plan_code) ?? "free",
      status: String(membership.status ?? "none"),
      source: optionalString(membership.source),
      startsAt: optionalString(membership.starts_at),
      endsAt: optionalString(membership.ends_at),
    },
  };
}

function optionalRecord(value: unknown): Record<string, unknown> | undefined {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : undefined;
}

function toEarlyAccessLead(value: Record<string, unknown>): EarlyAccessLead {
  const statusValue = String(value.status ?? "new");
  const status =
    EARLY_ACCESS_LEAD_STATUSES.includes(statusValue as EarlyAccessLeadStatus)
      ? statusValue as EarlyAccessLeadStatus
      : "new";
  return {
    id: String(value.id ?? ""),
    phoneE164: String(value.phone_e164 ?? value.phone_masked ?? ""),
    phoneDisplay: nullableString(value.phone_display ?? value.phone_masked),
    fullName: nullableString(value.full_name),
    age: nullableNumber(value.age),
    gender: nullableString(value.gender),
    address: nullableString(value.address),
    status,
    createdAt: String(value.created_at ?? ""),
  };
}

function nullableString(value: unknown): string | null {
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

function nullableNumber(value: unknown): number | null {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  return null;
}

function integerValue(value: unknown): number {
  const number = numberValue(value);
  return Number.isInteger(number) && number >= 0 ? number : 0;
}

function recordArray(value: unknown): Array<Record<string, unknown>> {
  return normalizeArray<unknown>(value)
    .map(optionalRecord)
    .filter((row): row is Record<string, unknown> => row !== undefined);
}

function optionalString(value: unknown): string | undefined {
  const result = String(value ?? "").trim();
  return result.length > 0 ? result : undefined;
}

function optionalNumber(value: unknown): number | undefined {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : undefined;
}

function toMutationResult(value: unknown): MutationResult {
  const row = normalizeMap(Array.isArray(value) ? value[0] : value);
  return {
    success: row.success !== false,
    message: String(row.message ?? "Thao tác đã được ghi nhận."),
  };
}

function toMembershipPeriodAdjustmentResult(
  value: unknown,
): MembershipPeriodAdjustmentResult {
  const row = normalizeMap(value);
  const operation =
    row.operation === "subtract_days" || row.operation === "set_end_at"
      ? row.operation
      : "add_days";
  return {
    subscriptionId: String(row.subscription_id ?? ""),
    planCode: normalizePlanCode(row.plan_code) ?? "free",
    status: String(row.status ?? "active"),
    startsAt: String(row.starts_at ?? ""),
    previousEndsAt: typeof row.previous_ends_at === "string"
      ? row.previous_ends_at
      : null,
    endsAt: typeof row.ends_at === "string" ? row.ends_at : null,
    operation,
    deltaDays: typeof row.delta_days === "number" ? row.delta_days : null,
  };
}

function toBulkPreview(value: unknown): BulkProvisionPreview {
  const row = normalizeMap(value);
  const rows: BulkProvisionPreviewRow[] = normalizeArray<
    Record<string, unknown>
  >(row.rows).map((item) => {
    const status: BulkProvisionPreviewRow["status"] =
      item.status === "paid_preserved" || item.status === "existing"
        ? item.status
        : "new";
    return {
      index: numberValue(item.index),
      status,
      ...(typeof item.current_plan === "string"
        ? { currentPlan: item.current_plan }
        : {}),
    };
  });
  const fingerprint = typeof row.fingerprint === "string"
    ? row.fingerprint
    : "";
  if (!fingerprint || rows.length === 0) {
    throw new AdminApiError(
      "Bản xem trước chưa hợp lệ. Vui lòng thử lại.",
      true,
    );
  }
  return {
    fingerprint,
    candidateCount: numberValue(row.candidate_count),
    rows,
  };
}

function toBulkProvisionResult(value: unknown): BulkProvisionResult {
  const row = normalizeMap(value);
  const batchId = typeof row.batch_id === "string" ? row.batch_id : "";
  if (!batchId) {
    throw new AdminApiError(
      "Batch chưa hoàn tất. Vui lòng giữ nguyên mã thao tác khi thử lại.",
      true,
    );
  }
  return {
    success: row.success !== false,
    message: String(row.message ?? "Batch đã được ghi nhận."),
    batchId,
    processedCount: numberValue(row.processed_count),
    createdCount: numberValue(row.created_count),
    grantedCount: numberValue(row.granted_count),
    skippedCount: numberValue(row.skipped_count),
    ...(Number.isFinite(Number(row.failed_index))
      ? { failedIndex: numberValue(row.failed_index) }
      : {}),
  };
}

function auditAsWorkItem(event: AdminAuditEvent): AdminWorkItem {
  return {
    id: event.id,
    title: event.action,
    subtitle: `${event.target} · ${event.reason}`,
    status: "recorded",
    section: "audit",
    createdAt: event.createdAt,
    metadata: {},
  };
}

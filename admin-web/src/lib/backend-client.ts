import { readRuntimeConfig } from "./config";

export type BackendAuthSession = {
  accessToken: string;
  refreshToken: string;
  expiresAt: number;
  user: { id: string; email: string | null; roles: string[] };
  mustChangePassword: boolean;
};

export type ApiEnvelope<T> = {
  success: boolean;
  businessCode?: string;
  message?: string;
  data: T;
  meta?: Record<string, unknown>;
};

export type Readiness = { ready: boolean; message: string; checkedAt: string };

export type AdminUserSummary = {
  id: string;
  title: string;
  subtitle: string;
  phone: string | null;
  email: string | null;
  status: string;
  is_active: boolean;
  created_at: string;
  plan_code: string;
  subscription_id: string | null;
  membership_status: string | null;
  membership_source: string | null;
  membership_starts_at: string | null;
  membership_ends_at: string | null;
};

export type UserDataSection =
  | "profile"
  | "health"
  | "schedule"
  | "membership"
  | "family"
  | "sleep_safety"
  | "sale_rewards"
  | "activity"
  | "related";

export type UserDetail = { user: Record<string, unknown> };

export type UserDataPage = {
  section: UserDataSection;
  page: number;
  page_size: number;
  tables: Record<
    string,
    { rows: Array<Record<string, unknown>>; total: number; page: number; page_size: number; pages: number }
  >;
};

export class BackendRequestError extends Error {
  constructor(
    message: string,
    readonly statusCode: number,
    readonly businessCode: string,
  ) {
    super(message);
    this.name = "BackendRequestError";
  }
}

type StorageLike = Pick<Storage, "getItem" | "setItem" | "removeItem">;
type FetchLike = typeof fetch;

export class BackendClient {
  private static readonly storageKey = "nanobio_admin_session_v1";
  private current: BackendAuthSession | null = null;
  private refreshInFlight: Promise<BackendAuthSession | null> | null = null;

  constructor(
    readonly baseUrl = readRuntimeConfig().apiBaseUrl,
    private readonly storage: StorageLike = window.sessionStorage,
    private readonly fetcher: FetchLike = globalThis.fetch.bind(globalThis),
  ) {}

  get session(): BackendAuthSession | null {
    return this.current ?? this.readStoredSession();
  }

  async getCurrentSession(): Promise<BackendAuthSession | null> {
    const session = this.session;
    if (!session) return null;
    this.current = session;
    if (session.expiresAt <= Date.now() + 20_000) return this.refreshSession();
    return session;
  }

  async checkReadiness(): Promise<Readiness> {
    const checkedAt = new Date().toISOString();
    try {
      const response = await this.fetcher(new URL("/health/ready", this.baseUrl), {
        headers: { Accept: "application/json" },
        signal: AbortSignal.timeout(6000),
      });
      const body = await response.json().catch(() => null) as Record<string, unknown> | null;
      if (response.ok && body?.status === "ready" && body.database === "ready") {
        return { ready: true, message: "API và cơ sở dữ liệu đã sẵn sàng.", checkedAt };
      }
      return {
        ready: false,
        message: typeof body?.message === "string"
          ? body.message
          : "API chưa sẵn sàng. Các thao tác ghi đang tạm khóa.",
        checkedAt,
      };
    } catch {
      return {
        ready: false,
        message: "Không kết nối được API.",
        checkedAt,
      };
    }
  }

  async signIn(identifier: string, password: string): Promise<BackendAuthSession> {
    const normalized = identifier.trim();
    const credentials = normalized.includes("@")
      ? { email: normalized.toLowerCase(), password }
      : /^[+\d(]/.test(normalized)
      ? { phone: normalized, password }
      : { username: normalized.toLowerCase(), password };
    const data = await this.requestData<unknown>("/auth/login", {
      method: "POST",
      body: credentials,
      authenticated: false,
    });
    return this.saveSession(parseSession(data));
  }

  async changePassword(newPassword: string): Promise<BackendAuthSession> {
    const data = await this.requestData<unknown>("/auth/change-password", {
      method: "POST",
      body: { new_password: newPassword },
    });
    return this.saveSession(parseSession(data, this.session ?? undefined));
  }

  async signOut(): Promise<void> {
    const current = this.session;
    try {
      if (current) {
        await this.requestData("/auth/logout", {
          method: "POST",
          body: { refresh_token: current.refreshToken },
        });
      }
    } finally {
      this.clearSession();
    }
  }

  async requestData<T>(
    path: string,
    options: {
      method?: string;
      body?: unknown;
      query?: Record<string, string | number | boolean | undefined>;
      authenticated?: boolean;
    } = {},
  ): Promise<T> {
    if (!path.startsWith("/")) throw new TypeError("API path must be absolute.");
    const url = new URL(`/api/v1${path}`, this.baseUrl);
    const params = new URLSearchParams();
    for (const [key, value] of Object.entries(options.query ?? {})) {
      if (value !== undefined) params.set(key, String(value));
    }
    url.search = params.toString();
    const send = async (): Promise<Response> => {
      const headers = new Headers({ Accept: "application/json" });
      if (options.body !== undefined) headers.set("Content-Type", "application/json");
      const session = this.session;
      if (options.authenticated !== false && session) {
        headers.set("Authorization", `Bearer ${session.accessToken}`);
      }
      return this.fetcher(url, {
        method: options.method ?? "GET",
        headers,
        body: options.body === undefined ? undefined : JSON.stringify(options.body),
      });
    };

    let response = await send();
    if (response.status === 401 && options.authenticated !== false && this.session) {
      if (await this.refreshSession()) response = await send();
    }
    const envelope = await response.json().catch(() => null) as Partial<ApiEnvelope<T>> | null;
    if (!response.ok || envelope?.success !== true) {
      throw new BackendRequestError(
        typeof envelope?.message === "string"
          ? envelope.message
          : "Máy chủ chưa thể xử lý yêu cầu này. Bạn thử lại sau nhé.",
        response.status,
        typeof envelope?.businessCode === "string" ? envelope.businessCode : "BACKEND_ERROR",
      );
    }
    return envelope.data as T;
  }

  async fetchAdminSession(): Promise<{ user_id: string; roles: string[]; permissions: string[] }> {
    return this.requestData("/admin/session");
  }

  async searchUsers(term: string): Promise<AdminUserSummary[]> {
    const rows = await this.requestData<unknown>("/admin/users/search", {
      query: { q: term.trim(), limit: 100 },
    });
    return Array.isArray(rows) ? rows as AdminUserSummary[] : [];
  }

  getUserDetails(userId: string, reason: string): Promise<UserDetail> {
    return this.requestData(`/admin/users/${encodeURIComponent(userId)}`, { query: { reason } });
  }

  getUserData(
    userId: string,
    section: UserDataSection,
    page: number,
    reason: string,
  ): Promise<UserDataPage> {
    return this.requestData(`/admin/users/${encodeURIComponent(userId)}/data`, {
      query: { section, page, page_size: 20, reason },
    });
  }

  createAccount(input: {
    phone: string;
    full_name: string;
    email?: string;
    reason: string;
    idempotency_key: string;
  }): Promise<Record<string, unknown>> {
    return this.requestData("/admin/accounts", { method: "POST", body: input });
  }

  updateProfile(userId: string, input: Record<string, unknown>): Promise<unknown> {
    return this.requestData(`/admin/users/${encodeURIComponent(userId)}/profile`, {
      method: "PATCH",
      body: input,
    });
  }

  updateStatus(userId: string, input: Record<string, unknown>): Promise<unknown> {
    return this.requestData(`/admin/users/${encodeURIComponent(userId)}/status`, {
      method: "PATCH",
      body: input,
    });
  }

  resetPassword(userId: string, reason: string, idempotencyKey: string): Promise<Record<string, unknown>> {
    return this.requestData(`/admin/users/${encodeURIComponent(userId)}/password-reset`, {
      method: "POST",
      query: { reason, idempotency_key: idempotencyKey },
    });
  }

  grantMembership(input: Record<string, unknown>): Promise<Record<string, unknown>> {
    return this.requestData("/admin/memberships/grant", { method: "POST", body: input });
  }

  adjustMembership(input: Record<string, unknown>): Promise<Record<string, unknown>> {
    return this.requestData("/admin/memberships/adjust-period", { method: "POST", body: input });
  }

  revokeMembership(input: Record<string, unknown>): Promise<Record<string, unknown>> {
    return this.requestData("/admin/memberships/revoke", { method: "POST", body: input });
  }

  private async refreshSession(): Promise<BackendAuthSession | null> {
    if (this.refreshInFlight) return this.refreshInFlight;
    const current = this.session;
    if (!current) return null;
    this.refreshInFlight = (async () => {
      try {
        const data = await this.requestData<unknown>("/auth/refresh", {
          method: "POST",
          body: { refresh_token: current.refreshToken },
          authenticated: false,
        });
        return this.saveSession(parseSession(data, current));
      } catch {
        this.clearSession();
        return null;
      }
    })();
    try {
      return await this.refreshInFlight;
    } finally {
      this.refreshInFlight = null;
    }
  }

  private saveSession(session: BackendAuthSession): BackendAuthSession {
    this.current = session;
    this.storage.setItem(BackendClient.storageKey, JSON.stringify(session));
    return session;
  }

  private clearSession(): void {
    this.current = null;
    this.storage.removeItem(BackendClient.storageKey);
  }

  private readStoredSession(): BackendAuthSession | null {
    try {
      const value = this.storage.getItem(BackendClient.storageKey);
      if (!value) return null;
      return parseSession(JSON.parse(value));
    } catch {
      this.storage.removeItem(BackendClient.storageKey);
      return null;
    }
  }
}

export function createBackendClient(): BackendClient {
  return new BackendClient();
}

function parseSession(value: unknown, previous?: BackendAuthSession): BackendAuthSession {
  const data = asRecord(value);
  const user = asRecord(data.user);
  const accessToken = String(data.access_token ?? data.accessToken ?? "").trim();
  const refreshToken = String(data.refresh_token ?? data.refreshToken ?? "").trim();
  const userId = String(user.id ?? previous?.user.id ?? "").trim();
  const expiresIn = Number(data.expires_in ?? 900);
  if (!accessToken || !refreshToken || !userId || !Number.isFinite(expiresIn)) {
    throw new BackendRequestError("Phiên đăng nhập chưa hợp lệ.", 401, "INVALID_SESSION");
  }
  const roles = Array.isArray(user.roles) ? user.roles.map(String) : previous?.user.roles ?? [];
  return {
    accessToken,
    refreshToken,
    expiresAt: data.expires_at ? Date.parse(String(data.expires_at)) : Date.now() + expiresIn * 1000,
    user: {
      id: userId,
      email: typeof user.email === "string" ? user.email : previous?.user.email ?? null,
      roles,
    },
    mustChangePassword: typeof data.must_change_password === "boolean"
      ? data.must_change_password
      : previous?.mustChangePassword ?? false,
  };
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {};
}

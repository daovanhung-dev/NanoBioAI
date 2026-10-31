import { readRuntimeConfig } from './config';

export type BackendAuthSession = {
  accessToken: string;
  refreshToken: string;
  expiresAt: number;
  user: { id: string; email: string | null; roles: string[] };
  mustChangePassword: boolean;
};

export class BackendRequestError extends Error {
  constructor(
    message: string,
    readonly statusCode: number,
    readonly businessCode: string,
  ) {
    super(message);
    this.name = 'BackendRequestError';
  }
}

type StorageLike = Pick<Storage, 'getItem' | 'setItem' | 'removeItem'>;
type FetchLike = typeof fetch;
type AuthListener = (session: BackendAuthSession | null) => void;

export class BackendClient {
  private static readonly storageKey = 'nanobio_admin_backend_session_v1';
  private current: BackendAuthSession | null = null;
  private listeners = new Set<AuthListener>();
  private refreshInFlight: Promise<BackendAuthSession | null> | null = null;

  constructor(
    readonly baseUrl = readRuntimeConfig().apiBaseUrl,
    private readonly storage: StorageLike = window.sessionStorage,
    private readonly fetcher: FetchLike = fetch,
  ) {}

  get session(): BackendAuthSession | null {
    return this.current ?? this.readStoredSession();
  }

  async getCurrentSession(): Promise<BackendAuthSession | null> {
    const session = this.session;
    if (!session) return null;
    this.current = session;
    if (session.expiresAt <= Date.now() + 20_000) {
      return this.refreshSession();
    }
    return session;
  }

  watchAuth(listener: AuthListener): { unsubscribe: () => void } {
    this.listeners.add(listener);
    return { unsubscribe: () => this.listeners.delete(listener) };
  }

  async signIn(email: string, password: string): Promise<BackendAuthSession> {
    const data = await this.requestData('/auth/login', {
      method: 'POST',
      body: { email: email.trim().toLowerCase(), password },
      authenticated: false,
    });
    return this.saveSession(parseSession(data));
  }

  async signOut(): Promise<void> {
    const session = this.session;
    try {
      if (session) {
        await this.requestData('/auth/logout', {
          method: 'POST',
          body: { refresh_token: session.refreshToken },
        });
      }
    } finally {
      this.clearSession();
    }
  }

  async requestData<T = unknown>(
    path: string,
    options: {
      method?: string;
      body?: unknown;
      query?: Record<string, string | number | boolean | undefined>;
      authenticated?: boolean;
      headers?: HeadersInit;
    } = {},
  ): Promise<T> {
    if (!path.startsWith('/')) throw new TypeError('API path must be absolute.');
    const query = new URLSearchParams();
    for (const [key, value] of Object.entries(options.query ?? {})) {
      if (value !== undefined) query.set(key, String(value));
    }
    const url = new URL(`/api/v1${path}`, this.baseUrl);
    url.search = query.toString();
    const send = async (): Promise<Response> => {
      const headers = new Headers(options.headers);
      headers.set('Accept', 'application/json');
      const body = options.body;
      if (body !== undefined && !(body instanceof FormData)) {
        headers.set('Content-Type', 'application/json');
      }
      const session = this.session;
      if (options.authenticated !== false && session) {
        headers.set('Authorization', `Bearer ${session.accessToken}`);
      }
      return this.fetcher(url, {
        method: options.method ?? 'GET',
        headers,
        body: body === undefined
          ? undefined
          : body instanceof FormData
          ? body
          : JSON.stringify(body),
      });
    };

    let response = await send();
    if (response.status === 401 && options.authenticated !== false && this.session) {
      if (await this.refreshSession()) response = await send();
    }
    const payload = await response.json().catch(() => null) as Record<string, unknown> | null;
    if (!response.ok || payload?.success !== true) {
      throw new BackendRequestError(
        typeof payload?.message === 'string'
          ? payload.message
          : 'Máy chủ chưa thể xử lý yêu cầu này. Bạn thử lại sau nhé.',
        response.status,
        typeof payload?.businessCode === 'string' ? payload.businessCode : 'BACKEND_ERROR',
      );
    }
    return payload.data as T;
  }

  async requestBlob(path: string): Promise<Blob> {
    const send = async () => {
      const headers = new Headers();
      const session = this.session;
      if (session) headers.set('Authorization', `Bearer ${session.accessToken}`);
      return this.fetcher(new URL(`/api/v1${path}`, this.baseUrl), { headers });
    };
    let response = await send();
    if (response.status === 401 && this.session && await this.refreshSession()) {
      response = await send();
    }
    if (!response.ok) {
      throw new BackendRequestError('Chưa mở được tệp.', response.status, 'FILE_READ_FAILED');
    }
    return response.blob();
  }

  private async refreshSession(): Promise<BackendAuthSession | null> {
    if (this.refreshInFlight) return this.refreshInFlight;
    const current = this.session;
    if (!current) return null;
    this.refreshInFlight = (async () => {
      try {
        const data = await this.requestData('/auth/refresh', {
          method: 'POST',
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
    for (const listener of this.listeners) listener(session);
    return session;
  }

  private clearSession(): void {
    this.current = null;
    this.storage.removeItem(BackendClient.storageKey);
    for (const listener of this.listeners) listener(null);
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
  const data = record(value);
  const user = record(data.user);
  const accessToken = String(data.access_token ?? data.accessToken ?? '').trim();
  const refreshToken = String(data.refresh_token ?? data.refreshToken ?? '').trim();
  const userId = String(user.id ?? previous?.user.id ?? '').trim();
  const expiresIn = Number(data.expires_in ?? 900);
  if (!accessToken || !refreshToken || !userId || !Number.isFinite(expiresIn)) {
    throw new BackendRequestError('Phiên đăng nhập chưa hợp lệ.', 401, 'INVALID_SESSION');
  }
  const roles = Array.isArray(user.roles)
    ? user.roles.map(String)
    : previous?.user.roles ?? [];
  return {
    accessToken,
    refreshToken,
    expiresAt: data.expires_at
      ? Date.parse(String(data.expires_at))
      : Date.now() + expiresIn * 1000,
    user: {
      id: userId,
      email: typeof user.email === 'string' ? user.email : previous?.user.email ?? null,
      roles,
    },
    mustChangePassword: data.must_change_password === true || previous?.mustChangePassword === true,
  };
}

function record(value: unknown): Record<string, unknown> {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? value as Record<string, unknown>
    : {};
}

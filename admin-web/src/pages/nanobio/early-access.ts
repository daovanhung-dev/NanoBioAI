import { readRuntimeConfig } from '../../lib/config';

export type EarlyAccessPayload = {
  phone: string;
  full_name: string;
  age: number;
  gender: 'male' | 'female' | 'other' | 'prefer_not_to_say';
  address: string;
  privacy_consent: true;
  utm_source?: string;
  utm_medium?: string;
  utm_campaign?: string;
  landing_path: string;
};

export type EarlyAccessResult = {
  success: true;
  message: string;
  downloadUrl: string | null;
  downloadAvailable: boolean;
  expiresAt: string | null;
  appVersion: string;
};

export type EarlyAccessErrorCode = 'rate_limited' | 'invalid_phone' | 'consent_required' | 'not_configured' | 'network' | 'server';

export class EarlyAccessError extends Error {
  constructor(readonly code: EarlyAccessErrorCode) {
    super(code);
    this.name = 'EarlyAccessError';
  }
}

type ApiResponse = {
  success?: unknown;
  businessCode?: unknown;
  message?: unknown;
  data?: Record<string, unknown>;
};

type EarlyAccessData = {
  download_url?: unknown;
  download_available?: unknown;
  expires_at?: unknown;
  app_version?: unknown;
};

export type SubmitOptions = {
  apiBaseUrl: string;
  fetcher?: typeof fetch;
  timeoutMs?: number;
};

export async function submitEarlyAccess(
  payload: EarlyAccessPayload,
  options?: SubmitOptions,
): Promise<EarlyAccessResult> {
  let config: SubmitOptions;
  try {
    if (options) {
      config = options;
    } else {
      const runtime = readRuntimeConfig();
      config = { apiBaseUrl: runtime.apiBaseUrl };
    }
  } catch {
    throw new EarlyAccessError('not_configured');
  }

  const controller = new AbortController();
  const timeout = globalThis.setTimeout(() => controller.abort(), config.timeoutMs ?? 12_000);
  let response: Response;
  try {
    response = await (config.fetcher ?? fetch)(
      `${config.apiBaseUrl.replace(/\/$/, '')}/api/v1/early-access`,
      {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
        },
        body: JSON.stringify(payload),
        signal: controller.signal,
      },
    );
  } catch {
    throw new EarlyAccessError('network');
  } finally {
    globalThis.clearTimeout(timeout);
  }

  let envelope: ApiResponse;
  try {
    envelope = await response.json() as ApiResponse;
  } catch {
    throw new EarlyAccessError(response.status === 429 ? 'rate_limited' : 'server');
  }

  const code = String(envelope.businessCode ?? '');
  if (response.status === 429 || code === 'RATE_LIMITED') throw new EarlyAccessError('rate_limited');
  if (!response.ok || envelope.success !== true) {
    if (code === 'INVALID_PHONE') throw new EarlyAccessError('invalid_phone');
    if (code === 'CONSENT_REQUIRED') throw new EarlyAccessError('consent_required');
    throw new EarlyAccessError('server');
  }

  const body = (envelope.data ?? {}) as EarlyAccessData;
  const downloadUrl = typeof body.download_url === 'string' && body.download_available === true
    ? safeDownloadUrl(body.download_url)
    : null;

  return {
    success: true,
    message: typeof envelope.message === 'string' ? envelope.message : 'Đã ghi nhận đăng ký của bạn.',
    downloadUrl,
    downloadAvailable: downloadUrl !== null,
    expiresAt: typeof body.expires_at === 'string' ? body.expires_at : null,
    appVersion: typeof body.app_version === 'string' ? body.app_version : '1.0.1+4',
  };
}

export function safeDownloadUrl(value: string): string | null {
  try {
    const url = new URL(value);
    const expectedPath = '/daovanhung-dev/NanoBioAI/releases/download/nanobio-early-access-v1.0.1-build4/app-release.apk';
    return url.protocol === 'https:' && url.origin === 'https://github.com' && url.pathname === expectedPath && !url.search && !url.hash
      ? url.toString()
      : null;
  } catch {
    return null;
  }
}

export function sanitizeCampaignValue(value: string | null): string | undefined {
  if (!value) return undefined;
  const sanitized = value.trim().replace(/[^a-zA-Z0-9._~-]/g, '').slice(0, 100);
  return sanitized || undefined;
}

export function readCampaignValue(name: string, location: Pick<Location, 'search' | 'hash'> = window.location): string | undefined {
  const search = new URLSearchParams(location.search).get(name);
  const hashQuery = location.hash.includes('?') ? location.hash.slice(location.hash.indexOf('?') + 1) : '';
  const hashValue = new URLSearchParams(hashQuery).get(name);
  return sanitizeCampaignValue(search ?? hashValue);
}

import { readRuntimeConfig } from '../../lib/config';

export type EarlyAccessPayload = {
  phone: string;
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

type FunctionResponse = {
  success?: unknown;
  code?: unknown;
  message?: unknown;
  download_url?: unknown;
  download_available?: unknown;
  expires_at?: unknown;
  app_version?: unknown;
};

export type SubmitOptions = {
  supabaseUrl: string;
  anonKey: string;
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
      config = { supabaseUrl: runtime.supabaseUrl, anonKey: runtime.supabaseAnonKey };
    }
  } catch {
    throw new EarlyAccessError('not_configured');
  }

  const controller = new AbortController();
  const timeout = globalThis.setTimeout(() => controller.abort(), config.timeoutMs ?? 12_000);
  let response: Response;
  try {
    response = await (config.fetcher ?? fetch)(
      `${config.supabaseUrl.replace(/\/$/, '')}/functions/v1/register-early-access`,
      {
        method: 'POST',
        headers: {
          apikey: config.anonKey,
          authorization: `Bearer ${config.anonKey}`,
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

  let body: FunctionResponse;
  try {
    body = await response.json() as FunctionResponse;
  } catch {
    throw new EarlyAccessError(response.status === 429 ? 'rate_limited' : 'server');
  }

  if (response.status === 429 || body.code === 'RATE_LIMITED') throw new EarlyAccessError('rate_limited');
  if (!response.ok || body.success !== true) {
    if (body.code === 'INVALID_PHONE') throw new EarlyAccessError('invalid_phone');
    if (body.code === 'CONSENT_REQUIRED') throw new EarlyAccessError('consent_required');
    throw new EarlyAccessError('server');
  }

  const downloadUrl = typeof body.download_url === 'string' && body.download_available === true
    ? safeDownloadUrl(body.download_url, config.supabaseUrl)
    : null;

  return {
    success: true,
    message: typeof body.message === 'string' ? body.message : 'Đã ghi nhận đăng ký của bạn.',
    downloadUrl,
    downloadAvailable: downloadUrl !== null,
    expiresAt: typeof body.expires_at === 'string' ? body.expires_at : null,
    appVersion: typeof body.app_version === 'string' ? body.app_version : '1.0.1+4',
  };
}

function safeDownloadUrl(value: string, supabaseUrl: string): string | null {
  try {
    const url = new URL(value);
    const service = new URL(supabaseUrl);
    return url.protocol === 'https:' && url.origin === service.origin ? url.toString() : null;
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

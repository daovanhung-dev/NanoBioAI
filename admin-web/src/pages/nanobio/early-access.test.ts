import { describe, expect, it, vi } from 'vitest';
import { EarlyAccessError, readCampaignValue, sanitizeCampaignValue, submitEarlyAccess, type EarlyAccessPayload } from './early-access';

const payload: EarlyAccessPayload = {
  phone: '0912 345 678',
  privacy_consent: true,
  landing_path: '/nanobio',
};

function response(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });
}

describe('Early Access function client', () => {
  it('posts only the consented form data with the publishable key', async () => {
    const fetcher = vi.fn(async (_input: RequestInfo | URL, _init?: RequestInit) => response({ success: true, message: 'Đã ghi nhận.', download_available: false }));
    const result = await submitEarlyAccess(payload, { supabaseUrl: 'https://nano.example', anonKey: 'publishable-test', fetcher });

    expect(result.success).toBe(true);
    expect(result.downloadUrl).toBeNull();
    expect(fetcher).toHaveBeenCalledWith('https://nano.example/functions/v1/register-early-access', expect.objectContaining({
      method: 'POST',
      headers: expect.objectContaining({ apikey: 'publishable-test', authorization: 'Bearer publishable-test' }),
    }));
    const request = fetcher.mock.calls[0]?.[1];
    expect(JSON.parse(String(request?.body))).toEqual(payload);
  });

  it('accepts only signed URLs from the configured Supabase origin', async () => {
    const accepted = await submitEarlyAccess(payload, {
      supabaseUrl: 'https://nano.example', anonKey: 'public',
      fetcher: async () => response({ success: true, download_available: true, download_url: 'https://nano.example/storage/v1/object/sign/apk?token=x' }),
    });
    const rejected = await submitEarlyAccess(payload, {
      supabaseUrl: 'https://nano.example', anonKey: 'public',
      fetcher: async () => response({ success: true, download_available: true, download_url: 'https://attacker.example/apk' }),
    });
    expect(accepted.downloadAvailable).toBe(true);
    expect(rejected.downloadAvailable).toBe(false);
  });

  it('maps rate limits and backend failures to safe typed errors', async () => {
    await expect(submitEarlyAccess(payload, {
      supabaseUrl: 'https://nano.example', anonKey: 'public', fetcher: async () => response({ code: 'RATE_LIMITED' }, 429),
    })).rejects.toMatchObject({ code: 'rate_limited' });
    await expect(submitEarlyAccess(payload, {
      supabaseUrl: 'https://nano.example', anonKey: 'public', fetcher: async () => response({ message: 'raw database detail' }, 500),
    })).rejects.toBeInstanceOf(EarlyAccessError);
    await expect(submitEarlyAccess(payload, {
      supabaseUrl: 'https://nano.example', anonKey: 'public', fetcher: async () => { throw new Error('private network detail'); },
    })).rejects.toMatchObject({ code: 'network' });
  });

  it('sanitizes campaign attribution and never includes query values in the page path', () => {
    expect(sanitizeCampaignValue('spring_sale 2026')).toBe('spring_sale2026');
    expect(readCampaignValue('utm_source', { search: '', hash: '#/nanobio?utm_source=campaign' })).toBe('campaign');
    expect(readCampaignValue('utm_source', { search: '?utm_source=outer', hash: '#/nanobio?utm_source=inner' })).toBe('outer');
  });
});

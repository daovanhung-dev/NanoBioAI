import { describe, expect, it, vi } from 'vitest';
import { AdminApi, AdminApiError, makeKey } from './admin-api';
import { BackendClient } from './backend-client';

type Call = { url: URL; init: RequestInit };

function envelope(data: unknown, status = 200, businessCode = 'OK'): Response {
  return new Response(JSON.stringify({
    success: status >= 200 && status < 300,
    businessCode,
    message: 'Đã xử lý.',
    data,
  }), { status, headers: { 'content-type': 'application/json' } });
}

function harness(respond: (url: URL, init: RequestInit) => Response | Promise<Response>) {
  const calls: Call[] = [];
  const values = new Map<string, string>();
  const storage = {
    getItem: (key: string) => values.get(key) ?? null,
    setItem: (key: string, value: string) => values.set(key, value),
    removeItem: (key: string) => values.delete(key),
  };
  const fetcher: typeof fetch = async (input, init = {}) => {
    const url = new URL(String(input));
    calls.push({ url, init });
    return respond(url, init);
  };
  const api = new AdminApi(new BackendClient('https://backend.example.test', storage, fetcher));
  return { api, calls, values };
}

describe('Admin API backend transport', () => {
  it('authenticates by email and loads the backend role and permission projection', async () => {
    const { api, calls } = harness((url) => {
      if (url.pathname.endsWith('/auth/login')) {
        return envelope({
          access_token: 'access',
          refresh_token: 'refresh-token-value-that-is-long-enough',
          expires_in: 900,
          user: { id: 'admin-1', email: 'admin@example.test', roles: ['super_admin'] },
        });
      }
      return envelope({
        user_id: 'admin-1',
        roles: ['super_admin'],
        permissions: ['*'],
        is_active: true,
        can_use_user_app: false,
      });
    });

    await api.signIn(' Admin@Example.Test ', 'AdminPass123');
    const session = await api.fetchAdminSession();

    expect(session).toEqual({
      userId: 'admin-1', roles: ['super_admin'], permissions: ['*'],
      active: true, canUseUserApp: false,
    });
    expect(calls[0]?.url.pathname).toBe('/api/v1/auth/login');
    expect(JSON.parse(String(calls[0]?.init.body))).toEqual({
      email: 'admin@example.test', password: 'AdminPass123',
    });
    expect(new Headers(calls[1]?.init.headers).get('authorization')).toBe('Bearer access');
  });

  it('loads a bounded early access page and sends an audited status update', async () => {
    const { api, calls } = harness((url) => url.pathname.endsWith('/early-access/leads')
      ? envelope({
        rows: [{
          id: 'lead-1', phone_e164: '+84912345678', phone_display: '0912 345 678',
          full_name: 'Nguyễn An', age: 24, gender: 'female', address: 'Quận 1',
          status: 'new', created_at: '2026-10-07T00:00:00.000Z',
        }], total: 51, page: 2, page_size: 25,
      })
      : envelope({ success: true, message: 'Đã cập nhật.' }));
    const page = await api.fetchEarlyAccessLeads(' Nguyen An ', 2, 25);

    expect(page.total).toBe(51);
    expect(page.rows[0]?.phoneE164).toBe('+84912345678');
    expect(calls[0]?.url.searchParams.get('q')).toBe('Nguyen An');
    await api.updateEarlyAccessLeadStatus({
      leadId: 'lead-1', status: 'contacted', reason: 'Đã gọi khách hàng.',
      idempotencyKey: 'status-change-1',
    });
    expect(calls[1]?.url.pathname).toBe('/api/v1/admin/early-access/leads/lead-1');
    expect(JSON.parse(String(calls[1]?.init.body))).toEqual({
      status: 'contacted', reason: 'Đã gọi khách hàng.', idempotency_key: 'status-change-1',
    });
  });

  it('rejects a write without an audit reason before making a request', async () => {
    const { api, calls } = harness(() => envelope({}));
    await expect(api.runMutation({
      section: 'users', action: 'suspended', targetId: 'user-1', reason: ' ',
    })).rejects.toBeInstanceOf(AdminApiError);
    expect(calls).toHaveLength(0);
  });

  it('sends account management through the versioned backend routes', async () => {
    const { api, calls } = harness(() => envelope({ success: true, message: 'ok' }));
    await api.createAccount({
      fullName: 'User One', email: 'USER@example.test', password: 'TempPass123',
      phone: '0912345678', reason: 'Được phê duyệt.', idempotencyKey: 'create-user-1',
    });
    expect(calls[0]?.url.pathname).toBe('/api/v1/admin/accounts');
    expect(JSON.parse(String(calls[0]?.init.body))).toMatchObject({
      email: 'user@example.test', phone: '0912345678', idempotency_key: 'create-user-1',
    });
  });

  it('uploads proof as multipart data without sending server credentials', async () => {
    const { api, calls } = harness(() => envelope({ id: 'f2b6ab88-37f6-48af-a7da-436b01bdf29f' }, 201));
    const file = new File([new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a])], 'proof.png', { type: 'image/png' });
    const id = await api.uploadPayoutProof('conversion-1', file);
    expect(id).toBe('f2b6ab88-37f6-48af-a7da-436b01bdf29f');
    expect(calls[0]?.url.pathname).toBe('/api/v1/files/sale-payout-proofs');
    expect(calls[0]?.init.body).toBeInstanceOf(FormData);
    expect(new Headers(calls[0]?.init.headers).has('apikey')).toBe(false);
  });

  it('downloads a payout proof through the protected Admin route', async () => {
    const fileId = 'f2b6ab88-37f6-48af-a7da-436b01bdf29f';
    const { api, calls } = harness(() => new Response('proof bytes'));
    const original = Object.getOwnPropertyDescriptor(URL, 'createObjectURL');
    const createObjectUrl = vi.fn(() => 'blob:proof');
    Object.defineProperty(URL, 'createObjectURL', { configurable: true, value: createObjectUrl });
    try {
      await expect(api.signedPayoutProof(`sale-payout-proofs/${fileId}`)).resolves.toBe('blob:proof');
      expect(calls[0]?.url.pathname).toBe(`/api/v1/admin/files/sale-payout-proofs/${fileId}`);
    } finally {
      if (original) Object.defineProperty(URL, 'createObjectURL', original);
      else Reflect.deleteProperty(URL, 'createObjectURL');
    }
  });
});

describe('idempotency key generation', () => {
  it('uses a scoped, transport-safe key', () => {
    expect(makeKey('approve payment', 'a/b')).toMatch(/^approve_payment-a_b-.+/);
  });
});

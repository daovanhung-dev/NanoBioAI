import { describe, expect, it } from 'vitest';
import type { SupabaseClient } from '@supabase/supabase-js';
import { AdminApi, AdminApiError, makeKey } from './admin-api';

type RpcCall = { name: string; params?: Record<string, unknown> };

function fakeClient(rpcCalls: RpcCall[], storageCalls: Array<Record<string, unknown>> = []) {
  return {
    rpc: async (name: string, params?: Record<string, unknown>) => {
      rpcCalls.push({ name, params });
      return { data: [{ success: true, message: 'ok' }], error: null };
    },
    auth: {
      getSession: async () => ({ data: { session: null }, error: null }),
      onAuthStateChange: () => ({ data: { subscription: { unsubscribe: () => undefined } } }),
      signInWithPassword: async () => ({ error: null }),
      signOut: async () => ({ error: null }),
    },
    functions: { invoke: async () => ({ data: { success: true, message: 'ok' }, error: null }) },
    storage: {
      from: () => ({
        upload: async (path: string, file: File, options: Record<string, unknown>) => { storageCalls.push({ path, file, options }); return { data: { path }, error: null }; },
        createSignedUrl: async () => ({ data: { signedUrl: 'https://example.test/signed' }, error: null }),
      }),
    },
  } as unknown as SupabaseClient;
}

describe('AdminApi mutation contract', () => {
  it('sends payment review reason, idempotency and transfer verification', async () => {
    const calls: RpcCall[] = [];
    const api = new AdminApi(() => fakeClient(calls));
    await api.runMutation({ section: 'payments', action: 'approve', targetId: 'payment-1', reason: 'Đã kiểm tra sao kê.', idempotencyKey: 'payment-1-approve-1', payload: { transferVerified: true } });
    expect(calls[0]).toEqual({
      name: 'admin_review_payment',
      params: { p_reason: 'Đã kiểm tra sao kê.', p_idempotency_key: 'payment-1-approve-1', p_payment_event_id: 'payment-1', p_decision: 'approve', p_transfer_verified: true },
    });
  });

  it('rejects a write without reason before calling Supabase', async () => {
    const calls: RpcCall[] = [];
    const api = new AdminApi(() => fakeClient(calls));
    await expect(api.runMutation({ section: 'users', action: 'suspended', targetId: 'user-1', reason: ' ' })).rejects.toBeInstanceOf(AdminApiError);
    expect(calls).toHaveLength(0);
  });

  it('uploads payout proof only to the constrained bucket path', async () => {
    const calls: RpcCall[] = []; const storageCalls: Array<Record<string, unknown>> = [];
    const api = new AdminApi(() => fakeClient(calls, storageCalls));
    const file = new File(['proof'], 'transfer receipt.png', { type: 'image/png' });
    const path = await api.uploadPayoutProof('conversion/unsafe', file);
    expect(path).toMatch(/^sale-point-conversions\/conversion_unsafe\/\d+-transfer_receipt.png$/);
    expect(storageCalls[0].options).toEqual({ contentType: 'image/png', upsert: false });
  });

  it('rejects unsupported payout proof files', async () => {
    const api = new AdminApi(() => fakeClient([]));
    const file = new File(['not an image'], 'receipt.pdf', { type: 'application/pdf' });
    await expect(api.uploadPayoutProof('conversion-1', file)).rejects.toThrow('Chỉ nhận ảnh JPG hoặc PNG.');
  });
});

describe('idempotency key generation', () => {
  it('uses a scoped, transport-safe key', () => {
    expect(makeKey('approve payment', 'a/b')).toMatch(/^approve_payment-a_b-.+/);
  });
});

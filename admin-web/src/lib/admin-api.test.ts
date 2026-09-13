import { describe, expect, it } from 'vitest';
import type { SupabaseClient } from '@supabase/supabase-js';
import { AdminApi, AdminApiError, makeKey } from './admin-api';

type RpcCall = { name: string; params?: Record<string, unknown> };
type FunctionCall = { name: string; body?: Record<string, unknown> };

function fakeClient(rpcCalls: RpcCall[], storageCalls: Array<Record<string, unknown>> = [], functionCalls: FunctionCall[] = []) {
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
    functions: { invoke: async (name: string, options: { body?: Record<string, unknown> }) => { functionCalls.push({ name, body: options.body }); return { data: { success: true, message: 'ok' }, error: null }; } },
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

  it('previews and executes bulk provisioning through the protected Edge Function', async () => {
    const calls: RpcCall[] = [];
    const functionCalls: FunctionCall[] = [];
    const api = new AdminApi(() => fakeClient(calls, [], functionCalls));
    const accounts = [{ email: 'user@gmail.com', fullName: 'User One' }];

    await expect(api.previewBulkProvision({
      accounts,
      planCode: 'plus',
      durationMonths: 1,
      reason: 'Được phê duyệt.',
      idempotencyKey: 'bulk-1',
    })).rejects.toThrow('Bản xem trước chưa hợp lệ');
    expect(functionCalls[0]).toEqual({
      name: 'admin-provision-accounts-bulk',
      body: {
        mode: 'preview',
        accounts: [{ email: 'user@gmail.com', full_name: 'User One' }],
        plan_code: 'plus',
        duration_months: 1,
        reason: 'Được phê duyệt.',
        idempotency_key: 'bulk-1',
      },
    });
    expect(JSON.stringify(functionCalls[0])).not.toContain('password');
  });

  it('uses the protected user-management Function for detail, profile update and password reset', async () => {
    const functionCalls: FunctionCall[] = [];
    const api = new AdminApi(() => fakeClient([], [], functionCalls));
    await api.getUserDetails('user-1', 'Hỗ trợ người dùng.');
    await api.updateUserProfile({ userId: 'user-1', fullName: 'User One', phone: '', gender: '', birthYear: 1990, reason: 'Cập nhật hồ sơ.', idempotencyKey: 'profile-1' });
    await api.resetUserPassword('user-1', 'Cấp lại quyền truy cập.', 'reset-1');

    expect(functionCalls.map((call) => call.name)).toEqual([
      'admin-user-management',
      'admin-user-management',
      'admin-user-management',
    ]);
    expect(functionCalls[0]?.body).toEqual({ operation: 'detail', user_id: 'user-1', reason: 'Hỗ trợ người dùng.' });
    expect(functionCalls[1]?.body).toEqual({ operation: 'update_profile', user_id: 'user-1', full_name: 'User One', phone: null, gender: null, birth_year: 1990, reason: 'Cập nhật hồ sơ.', idempotency_key: 'profile-1' });
    expect(functionCalls[2]?.body).toEqual({ operation: 'reset_password', user_id: 'user-1', reason: 'Cấp lại quyền truy cập.', idempotency_key: 'reset-1' });
    expect(JSON.stringify(functionCalls)).not.toContain('service_role');
  });
});

describe('idempotency key generation', () => {
  it('uses a scoped, transport-safe key', () => {
    expect(makeKey('approve payment', 'a/b')).toMatch(/^approve_payment-a_b-.+/);
  });
});

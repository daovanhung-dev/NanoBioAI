import { act } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { AuthProvider, useAdminAuth } from './AuthProvider';

const mocks = vi.hoisted(() => ({
  getCurrentSession: vi.fn(),
  watchAuth: vi.fn(),
  signIn: vi.fn(),
  changePassword: vi.fn(),
  signOut: vi.fn(),
  fetchAdminSession: vi.fn(),
}));

vi.mock('../lib/admin-api', () => ({
  AdminApi: vi.fn().mockImplementation(() => ({
    getCurrentSession: mocks.getCurrentSession,
    watchAuth: mocks.watchAuth,
    signIn: mocks.signIn,
    changePassword: mocks.changePassword,
    signOut: mocks.signOut,
    fetchAdminSession: mocks.fetchAdminSession,
  })),
  AdminApiError: class AdminApiError extends Error {},
}));

function AuthProbe() {
  const auth = useAdminAuth();
  return <div>
    <span data-testid="auth-status">{auth.status}</span>
    <button data-testid="sign-in" onClick={() => void auth.signIn('admin', 'InitialPass123')}>Sign in</button>
    <button data-testid="change-password" onClick={() => void auth.changePassword('PersonalPass456')}>Change password</button>
  </div>;
}

describe('Admin AuthProvider password rotation', () => {
  let container: HTMLDivElement;
  let root: Root;

  beforeEach(() => {
    (globalThis as typeof globalThis & { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true;
    mocks.getCurrentSession.mockReset().mockResolvedValue(null);
    mocks.watchAuth.mockReset().mockReturnValue({ unsubscribe: vi.fn() });
    mocks.signIn.mockReset().mockResolvedValue({
      accessToken: 'temporary-access',
      refreshToken: 'temporary-refresh',
      expiresAt: Date.now() + 900_000,
      user: { id: 'admin-1', email: null, roles: ['super_admin'] },
      mustChangePassword: true,
    });
    mocks.changePassword.mockReset().mockResolvedValue({
      accessToken: 'rotated-access',
      refreshToken: 'rotated-refresh',
      expiresAt: Date.now() + 900_000,
      user: { id: 'admin-1', email: null, roles: ['super_admin'] },
      mustChangePassword: false,
    });
    mocks.signOut.mockReset().mockResolvedValue(undefined);
    mocks.fetchAdminSession.mockReset().mockResolvedValue({
      userId: 'admin-1',
      roles: ['super_admin'],
      permissions: ['*'],
      active: true,
      canUseUserApp: false,
    });
    container = document.createElement('div');
    document.body.append(container);
    root = createRoot(container);
  });

  afterEach(async () => {
    await act(async () => root.unmount());
    container.remove();
  });

  it('blocks admin-session lookup until the temporary password is changed', async () => {
    await act(async () => {
      root.render(<AuthProvider><AuthProbe /></AuthProvider>);
      await new Promise((resolve) => setTimeout(resolve, 0));
    });

    await act(async () => {
      container.querySelector<HTMLButtonElement>('[data-testid="sign-in"]')?.click();
      await new Promise((resolve) => setTimeout(resolve, 0));
    });

    expect(container.querySelector('[data-testid="auth-status"]')?.textContent).toBe('password_change_required');
    expect(mocks.fetchAdminSession).not.toHaveBeenCalled();

    await act(async () => {
      container.querySelector<HTMLButtonElement>('[data-testid="change-password"]')?.click();
      await new Promise((resolve) => setTimeout(resolve, 0));
    });

    expect(mocks.fetchAdminSession).toHaveBeenCalledTimes(1);
    expect(container.querySelector('[data-testid="auth-status"]')?.textContent).toBe('signed_in');
  });
});

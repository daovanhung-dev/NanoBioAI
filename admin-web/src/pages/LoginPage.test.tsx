import { act } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import { LoginPage } from './LoginPage';

const auth = vi.hoisted(() => ({ useAdminAuth: vi.fn() }));

vi.mock('../auth/AuthProvider', () => ({ useAdminAuth: auth.useAdminAuth }));

describe('Admin LoginPage forced password change', () => {
  let container: HTMLDivElement;
  let root: Root;

  beforeEach(() => {
    (globalThis as typeof globalThis & { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true;
    auth.useAdminAuth.mockReturnValue({
      status: 'password_change_required',
      session: null,
      message: null,
      signIn: vi.fn(),
      changePassword: vi.fn(),
      signOut: vi.fn(),
      refresh: vi.fn(),
    });
    container = document.createElement('div');
    document.body.append(container);
    root = createRoot(container);
  });

  afterEach(async () => {
    await act(async () => root.unmount());
    container.remove();
  });

  it('shows only the required password rotation form, not the dashboard login form', async () => {
    await act(async () => root.render(<MemoryRouter><LoginPage /></MemoryRouter>));

    expect(container.textContent).toContain('Hãy đổi mật khẩu tạm để tiếp tục vào khu quản trị.');
    expect(container.querySelector('#admin-new-password')).not.toBeNull();
    expect(container.querySelector('#admin-confirm-password')).not.toBeNull();
    expect(container.querySelector('#admin-identifier')).toBeNull();
    expect(container.querySelector('#admin-password')).toBeNull();
    expect(container.textContent).toContain('Lưu mật khẩu mới');
  });
});

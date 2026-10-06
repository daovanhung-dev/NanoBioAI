import { act } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { MemoryRouter, useLocation } from 'react-router-dom';
import { AdminShell } from './AdminShell';

vi.mock('../auth/AuthProvider', () => ({
  useAdminAuth: () => ({
    session: { roles: ['super_admin'] },
    userEmail: 'admin@nanobio.vn',
    signOut: vi.fn(),
    refresh: vi.fn(),
  }),
}));

function CurrentPath() {
  const location = useLocation();
  return <output data-testid="current-path">{location.pathname}</output>;
}

describe('AdminShell website shortcut', () => {
  let container: HTMLDivElement;
  let root: Root;

  beforeEach(() => {
    (globalThis as typeof globalThis & { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true;
    container = document.createElement('div');
    document.body.append(container);
    root = createRoot(container);
  });

  afterEach(async () => {
    await act(async () => root.unmount());
    container.remove();
  });

  it('keeps one website link in the fixed footer and navigates there from the mobile drawer', async () => {
    await act(async () => root.render(
      <MemoryRouter initialEntries={['/admin/dashboard']}>
        <AdminShell><span>Dashboard</span></AdminShell>
        <CurrentPath />
      </MemoryRouter>,
    ));

    const link = container.querySelector<HTMLAnchorElement>('.sidebar-footer a.website-cta');
    expect(link).not.toBeNull();
    expect(link?.textContent).toContain('Website NanoBio');
    expect(link?.getAttribute('href')).toBe('/nanobio');
    expect(container.querySelector('nav a[href="/nanobio"]')).toBeNull();
    expect(container.querySelectorAll('a[href="/nanobio"]')).toHaveLength(1);

    link?.focus();
    expect(document.activeElement).toBe(link);

    await act(async () => container.querySelector<HTMLButtonElement>('.mobile-menu')?.click());
    expect(container.querySelector('.sidebar')?.classList.contains('sidebar-open')).toBe(true);

    await act(async () => link?.click());
    expect(container.querySelector('[data-testid="current-path"]')?.textContent).toBe('/nanobio');
    expect(link?.getAttribute('aria-current')).toBe('page');
    expect(link?.classList.contains('active')).toBe(true);
    expect(container.querySelector('.sidebar')?.classList.contains('sidebar-open')).toBe(false);
  });
});

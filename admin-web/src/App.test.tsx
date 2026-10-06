import { act } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import { EarlyAccessError } from './pages/nanobio/early-access';
import { App } from './App';

const { submitEarlyAccessMock } = vi.hoisted(() => ({ submitEarlyAccessMock: vi.fn() }));

vi.mock('./pages/nanobio/early-access', async (importOriginal) => ({
  ...await importOriginal<typeof import('./pages/nanobio/early-access')>(),
  submitEarlyAccess: submitEarlyAccessMock,
}));

vi.mock('./auth/AuthProvider', () => ({
  AuthProvider: ({ children }: { children: import('react').ReactNode }) => <div data-admin-auth-provider="true">{children}</div>,
  useAdminAuth: () => ({
    status: 'signed_out', session: null, userEmail: null, message: null,
    signIn: vi.fn(), signOut: vi.fn(), refresh: vi.fn(),
  }),
}));

describe('NanoBio public routes', () => {
  let container: HTMLDivElement;
  let root: Root;

  beforeEach(() => {
    (globalThis as typeof globalThis & { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true;
    submitEarlyAccessMock.mockReset();
    container = document.createElement('div');
    document.body.append(container);
    root = createRoot(container);
    vi.spyOn(window, 'scrollTo').mockImplementation(() => undefined);
  });

  afterEach(async () => {
    await act(async () => root.unmount());
    container.remove();
    vi.restoreAllMocks();
  });

  it('renders the NanoBio landing page while signed out', async () => {
    await act(async () => root.render(<MemoryRouter initialEntries={['/nanobio']}><App /></MemoryRouter>));
    const site = container.querySelector('.nanobio-landing-host')?.shadowRoot;
    expect(site?.textContent).toContain('Sống khỏe chủ động hơn mỗi ngày');
    expect(site?.textContent).toContain('Tải ứng dụng hoàn toàn miễn phí');
    expect(site?.textContent).toContain('Đang phát triển mạnh');
    expect(container.querySelector('[data-admin-auth-provider]')).toBeNull();
  });

  it('renders the privacy route while signed out', async () => {
    await act(async () => root.render(<MemoryRouter initialEntries={['/nanobio/privacy']}><App /></MemoryRouter>));
    expect(container.textContent).toContain('Dữ liệu được ghi nhận');
    expect(container.textContent).toContain('thông tin trình duyệt');
    expect(container.textContent).toContain('24 giờ');
  });

  it('continues to route protected Admin pages to login while signed out', async () => {
    await act(async () => root.render(<MemoryRouter initialEntries={['/admin/dashboard']}><App /></MemoryRouter>));
    expect(container.querySelector('[data-admin-auth-provider]')).not.toBeNull();
    expect(container.textContent).toContain('Đăng nhập');
  });

  it('validates phone and consent before sending the public form', async () => {
    await renderLanding();
    const site = getLandingShadow();
    await act(async () => site.querySelector<HTMLButtonElement>('[data-open-vip-modal]')?.click());
    const phone = site.querySelector<HTMLInputElement>('#phone')!;
    const consent = site.querySelector<HTMLInputElement>('#consent')!;
    const form = site.querySelector<HTMLFormElement>('#earlyAccessForm')!;

    await submitWith(phone, form, '0123 456 789');
    expect(site.querySelector('#formError')?.textContent).toContain('chưa đúng định dạng');
    expect(submitEarlyAccessMock).not.toHaveBeenCalled();

    await submitWith(phone, form, '0912 345 678');
    expect(site.querySelector('#formError')?.textContent).toContain('cần đồng ý');
    expect(consent.checked).toBe(false);
    expect(submitEarlyAccessMock).not.toHaveBeenCalled();
  });

  it('allows retry after a network error and does not invent an APK link', async () => {
    submitEarlyAccessMock
      .mockRejectedValueOnce(new EarlyAccessError('network'))
      .mockResolvedValueOnce({
        success: true,
        message: 'Đã ghi nhận yêu cầu của bạn.',
        downloadUrl: null,
        downloadAvailable: false,
        expiresAt: null,
        appVersion: '1.0.1+4',
      });
    await renderLanding();
    const site = getLandingShadow();
    await act(async () => site.querySelector<HTMLButtonElement>('[data-open-vip-modal]')?.click());
    const phone = site.querySelector<HTMLInputElement>('#phone')!;
    const consent = site.querySelector<HTMLInputElement>('#consent')!;
    const form = site.querySelector<HTMLFormElement>('#earlyAccessForm')!;
    phone.value = '0912 345 678';
    consent.checked = true;

    await submitAndFlush(form);
    expect(site.querySelector('#formError')?.textContent).toContain('kiểm tra kết nối');
    expect(site.querySelector('#submitButton span')?.textContent).toBe('Thử gửi lại');

    await submitAndFlush(form);
    expect(submitEarlyAccessMock).toHaveBeenCalledTimes(2);
    expect(submitEarlyAccessMock).toHaveBeenLastCalledWith(expect.objectContaining({
      phone: '0912 345 678', privacy_consent: true, landing_path: '/nanobio',
    }));
    expect(site.querySelector<HTMLElement>('#successState')?.hidden).toBe(false);
    expect(site.querySelector<HTMLAnchorElement>('#downloadButton')?.hidden).toBe(true);
    expect(site.querySelector('#downloadHint')?.textContent).toContain('đang được cập nhật');
  });

  it('ignores repeated submits while one request is pending', async () => {
    let resolveSubmit!: (result: {
      success: true;
      message: string;
      downloadUrl: null;
      downloadAvailable: false;
      expiresAt: null;
      appVersion: string;
    }) => void;
    submitEarlyAccessMock.mockReturnValue(new Promise((resolve) => { resolveSubmit = resolve; }));
    await renderLanding();
    const site = getLandingShadow();
    await act(async () => site.querySelector<HTMLButtonElement>('[data-open-vip-modal]')?.click());
    const phone = site.querySelector<HTMLInputElement>('#phone')!;
    const consent = site.querySelector<HTMLInputElement>('#consent')!;
    const form = site.querySelector<HTMLFormElement>('#earlyAccessForm')!;
    phone.value = '0912 345 678';
    consent.checked = true;

    await act(async () => {
      dispatchSubmit(form);
      dispatchSubmit(form);
    });
    expect(submitEarlyAccessMock).toHaveBeenCalledTimes(1);
    expect(site.querySelector<HTMLButtonElement>('#submitButton')?.disabled).toBe(true);

    await act(async () => {
      resolveSubmit({
        success: true, message: 'Đã ghi nhận.', downloadUrl: null,
        downloadAvailable: false, expiresAt: null, appVersion: '1.0.1+4',
      });
    });
    expect(site.querySelector<HTMLButtonElement>('#submitButton')?.disabled).toBe(false);
  });

  it('traps keyboard focus in the open dialog and restores focus when closed', async () => {
    await renderLanding();
    const site = getLandingShadow();

    const trigger = site.querySelector<HTMLButtonElement>('[data-open-vip-modal]')!;
    await act(async () => trigger.click());
    const modal = site.querySelector<HTMLElement>('#vipModal')!;
    const close = site.querySelector<HTMLButtonElement>('.vip-modal-close')!;
    const submit = site.querySelector<HTMLButtonElement>('#submitButton')!;
    expect(modal.hidden).toBe(false);

    await act(async () => new Promise((resolve) => window.setTimeout(resolve, 40)));
    close.focus();
    await act(async () => site.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab', shiftKey: true, bubbles: true })));
    expect(site.activeElement).toBe(submit);
    await act(async () => site.dispatchEvent(new KeyboardEvent('keydown', { key: 'Tab', bubbles: true })));
    expect(site.activeElement).toBe(close);
    await act(async () => site.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true })));
    expect(modal.hidden).toBe(true);
    expect(site.activeElement).toBe(trigger);
  });

  async function renderLanding() {
    await act(async () => root.render(<MemoryRouter initialEntries={['/nanobio']}><App /></MemoryRouter>));
  }

  function getLandingShadow(): ShadowRoot {
    return container.querySelector<HTMLElement>('.nanobio-landing-host')!.shadowRoot!;
  }

  async function submitWith(phone: HTMLInputElement, form: HTMLFormElement, value: string) {
    phone.value = value;
    phone.dispatchEvent(new Event('input', { bubbles: true }));
    await submitAndFlush(form);
  }

  async function submitAndFlush(form: HTMLFormElement) {
    await act(async () => {
      dispatchSubmit(form);
      await new Promise((resolve) => window.setTimeout(resolve, 0));
    });
  }

  function dispatchSubmit(form: HTMLFormElement) {
    form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
  }
});

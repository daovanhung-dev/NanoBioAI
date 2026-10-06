import { act } from 'react';
import { createRoot, type Root } from 'react-dom/client';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import { EventInfoPage } from './EventInfoPage';

const mocks = vi.hoisted(() => ({
  fetchEarlyAccessLeads: vi.fn(),
  updateEarlyAccessLeadStatus: vi.fn(),
  api: {} as { fetchEarlyAccessLeads: ReturnType<typeof vi.fn>; updateEarlyAccessLeadStatus: ReturnType<typeof vi.fn> },
}));
mocks.api.fetchEarlyAccessLeads = mocks.fetchEarlyAccessLeads;
mocks.api.updateEarlyAccessLeadStatus = mocks.updateEarlyAccessLeadStatus;

vi.mock('../auth/AuthProvider', () => ({
  useAdminAuth: () => ({
    session: {
      userId: 'admin-1',
      roles: ['support_admin'],
      permissions: ['early_access.read', 'early_access.update'],
      active: true,
      canUseUserApp: false,
    },
    api: mocks.api,
  }),
}));

const sampleLead = {
  id: 'lead-1',
  phoneE164: '+84912345678',
  phoneDisplay: '0912 345 678',
  fullName: 'Nguyễn An',
  age: 24,
  gender: 'female',
  address: 'Quận 1, Thành phố Hồ Chí Minh',
  status: 'new' as const,
  createdAt: '2026-10-07T00:00:00.000Z',
};

describe('EventInfoPage', () => {
  let container: HTMLDivElement;
  let root: Root;

  beforeEach(() => {
    (globalThis as typeof globalThis & { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true;
    mocks.fetchEarlyAccessLeads.mockReset().mockResolvedValue({
      rows: [sampleLead],
      total: 1,
      page: 0,
      pageSize: 25,
    });
    mocks.updateEarlyAccessLeadStatus.mockReset().mockResolvedValue({ success: true, message: 'Đã cập nhật.' });
    container = document.createElement('div');
    document.body.append(container);
    root = createRoot(container);
  });

  afterEach(async () => {
    await act(async () => root.unmount());
    container.remove();
  });

  it('shows submitted customer details to an allowed support admin', async () => {
    await act(async () => {
      root.render(<MemoryRouter><EventInfoPage /></MemoryRouter>);
      await new Promise((resolve) => setTimeout(resolve, 0));
    });

    expect(container.textContent).toContain('Thông tin sự kiện');
    expect(container.textContent).toContain('0912 345 678');
    expect(container.textContent).toContain('Nguyễn An');
    expect(container.textContent).toContain('24');
    expect(container.textContent).toContain('Nữ');
    expect(container.textContent).toContain('Quận 1, Thành phố Hồ Chí Minh');
    expect(container.textContent).toContain('Mới');
    expect(container.querySelector('.status-badge')?.classList.contains('warning')).toBe(true);
  });

  it('requires a reason before sending a status change', async () => {
    await act(async () => {
      root.render(<MemoryRouter><EventInfoPage /></MemoryRouter>);
      await new Promise((resolve) => setTimeout(resolve, 0));
    });
    const update = [...container.querySelectorAll('button')].find((button) => button.textContent?.includes('Cập nhật'));
    await act(async () => update?.click());

    const status = container.querySelector<HTMLSelectElement>('#early-access-status');
    expect(status?.querySelector('option[value="contacted"]')?.textContent).toBe('Đã liên hệ');
    const statusSetter = Object.getOwnPropertyDescriptor(HTMLSelectElement.prototype, 'value')?.set;
    await act(async () => {
      statusSetter?.call(status, 'contacted');
      status?.dispatchEvent(new Event('change', { bubbles: true }));
    });

    const reason = container.querySelector<HTMLTextAreaElement>('#early-access-reason');
    const setter = Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, 'value')?.set;
    await act(async () => {
      setter?.call(reason, 'Đã liên hệ khách hàng.');
      reason?.dispatchEvent(new Event('input', { bubbles: true }));
    });
    const save = [...container.querySelectorAll('button')].find((button) => button.textContent?.includes('Lưu trạng thái'));
    await act(async () => save?.click());

    expect(mocks.updateEarlyAccessLeadStatus).toHaveBeenCalledWith(expect.objectContaining({
      leadId: 'lead-1',
      status: 'contacted',
      reason: 'Đã liên hệ khách hàng.',
    }));
  });
});

import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import landingHtml from './landing.html?raw';
import { websitePeople } from './data';
import { mountNanoBioLanding } from './website-controller';

const { submitEarlyAccessMock } = vi.hoisted(() => ({ submitEarlyAccessMock: vi.fn() }));

vi.mock('./early-access', async (importOriginal) => ({
  ...await importOriginal<typeof import('./early-access')>(),
  submitEarlyAccess: submitEarlyAccessMock,
}));

describe('NanoBio landing page controller', () => {
  let host: HTMLDivElement;
  let shadow: ShadowRoot;
  let cleanup: (() => void) | undefined;
  let originalWidth: number;

  beforeEach(() => {
    submitEarlyAccessMock.mockReset();
    host = document.createElement('div');
    document.body.append(host);
    shadow = host.attachShadow({ mode: 'open' });
    shadow.innerHTML = new DOMParser().parseFromString(landingHtml, 'text/html').body.innerHTML;
    originalWidth = window.innerWidth;
    Object.defineProperty(window, 'innerWidth', { configurable: true, value: 390 });
    vi.stubGlobal('matchMedia', (query: string) => ({
      matches: query === '(max-width: 760px)',
      media: query,
      onchange: null,
      addListener: vi.fn(),
      removeListener: vi.fn(),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      dispatchEvent: vi.fn(),
    }));
    vi.spyOn(window, 'scrollTo').mockImplementation(() => undefined);
    cleanup = mountNanoBioLanding(shadow, host, vi.fn());
  });

  afterEach(() => {
    cleanup?.();
    cleanup = undefined;
    host.remove();
    Object.defineProperty(window, 'innerWidth', { configurable: true, value: originalWidth });
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it('renders five compact sourced profiles and keeps the non-endorsement note', () => {
    const profiles = shadow.querySelectorAll('#teamGrid .person-card');
    const sourceLinks = shadow.querySelectorAll<HTMLAnchorElement>('#teamGrid a');

    expect(websitePeople).toHaveLength(5);
    expect(profiles).toHaveLength(5);
    expect(sourceLinks).toHaveLength(5);
    expect(shadow.querySelector('#referenceGrid')).toBeNull();
    expect(shadow.querySelectorAll('#faqList .faq-item')).toHaveLength(4);
    expect(shadow.querySelectorAll('.steps-grid article')).toHaveLength(3);
    sourceLinks.forEach((link) => {
      expect(link.href).toMatch(/^https:\/\//);
      expect(link.target).toBe('_blank');
      expect(link.rel).toContain('noopener');
      expect(link.getAttribute('aria-label')).toContain('Nguồn hồ sơ');
    });
    expect(shadow.textContent).toContain('không đồng nghĩa các chuyên gia bảo chứng cho NanoBio');
    expect(shadow.textContent).not.toContain('Theo đuổi việc đưa công nghệ vào ứng dụng thực tiễn');
  });

  it('opens the existing form from the Hero and floating download actions, then restores focus', async () => {
    const hero = shadow.querySelector<HTMLElement>('#top');
    const downloadSection = shadow.querySelector<HTMLElement>('#early-access');
    const floatingButton = shadow.querySelector<HTMLButtonElement>('#downloadFloat');
    const heroButton = shadow.querySelector<HTMLButtonElement>('#top [data-open-vip-modal]');
    const modal = shadow.querySelector<HTMLElement>('#vipModal');
    const closeButton = shadow.querySelector<HTMLButtonElement>('[data-close-vip-modal]');

    expect(hero && downloadSection && floatingButton && heroButton && modal && closeButton).toBeTruthy();
    vi.spyOn(hero!, 'getBoundingClientRect').mockReturnValue({ bottom: -1 } as DOMRect);
    vi.spyOn(downloadSection!, 'getBoundingClientRect').mockReturnValue({ top: 1200 } as DOMRect);
    window.dispatchEvent(new Event('scroll'));
    expect(floatingButton!.hidden).toBe(false);

    heroButton!.focus();
    heroButton!.click();
    expect(modal!.hidden).toBe(false);
    expect(host.classList.contains('vip-modal-open')).toBe(true);
    expect(floatingButton!.hidden).toBe(true);
    closeButton!.click();
    expect(modal!.hidden).toBe(true);
    expect(host.classList.contains('vip-modal-open')).toBe(false);
    expect(shadow.activeElement).toBe(heroButton);

    floatingButton!.click();
    expect(modal!.hidden).toBe(false);
    await new Promise((resolve) => window.setTimeout(resolve, 40));
    expect(shadow.activeElement).toBe(shadow.querySelector('#phone'));
    expect(submitEarlyAccessMock).not.toHaveBeenCalled();
  });
});

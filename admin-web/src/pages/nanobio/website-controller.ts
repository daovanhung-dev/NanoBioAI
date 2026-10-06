import { submitEarlyAccess, EarlyAccessError, readCampaignValue } from './early-access';
import { displayVietnamPhone, normalizeVietnamPhone } from './phone';
import { websiteAssets, websiteFaq, websiteFeatures, websiteGallery, websitePeople } from './data';
import { websiteAssetUrls } from './assets';

type Navigate = (path: string) => void;

export function mountNanoBioLanding(root: ShadowRoot, host: HTMLElement, navigate: Navigate): () => void {
  const cleanup: Array<() => void> = [];
  const query = <T extends Element>(selector: string): T | null => root.querySelector<T>(selector);
  const queryAll = <T extends Element>(selector: string): T[] => Array.from(root.querySelectorAll<T>(selector));

  const featureGrid = query<HTMLElement>('#featureGrid');
  if (featureGrid) {
    featureGrid.innerHTML = websiteFeatures.map((feature, index) => `
      <article class="feature-card reveal" style="--delay:${(index % 3) * 60}ms">
        <div class="feature-top"><span class="feature-icon">${escapeHtml(feature.icon)}</span><span class="status ${feature.tone}">${escapeHtml(feature.status)}</span></div>
        <h3>${escapeHtml(feature.title)}</h3><p>${escapeHtml(feature.text)}</p>
      </article>`).join('');
  }

  const teamGrid = query<HTMLElement>('#teamGrid');
  if (teamGrid) {
    teamGrid.innerHTML = websitePeople.map((person, index) => `
      <article class="team-card reveal" style="--delay:${(index % 3) * 80}ms">
        <div class="team-photo asset-card"><div class="asset-fallback">${escapeHtml(person.name.split(' ').slice(-2).join(' '))}</div><img data-team-image="${person.image}" alt="Ảnh ${escapeHtml(person.name)}" loading="lazy" /></div>
        <div class="team-body"><span>${escapeHtml(person.role)}</span><h3>${escapeHtml(person.name)}</h3><p>${escapeHtml(person.story)}</p><small>Nguồn: ${escapeHtml(person.source)}</small></div>
      </article>`).join('');
  }

  const gallery = query<HTMLElement>('#galleryTrack');
  if (gallery) {
    gallery.innerHTML = websiteGallery.map((item) => `
      <figure class="gallery-card"><div class="gallery-image asset-card"><div class="asset-fallback">${escapeHtml(item.title)}</div><img data-gallery-image="${item.image}" alt="${escapeHtml(item.title)}" loading="lazy" /></div><figcaption>${escapeHtml(item.title)}</figcaption></figure>`).join('');
  }

  const faqList = query<HTMLElement>('#faqList');
  if (faqList) {
    faqList.innerHTML = websiteFaq.map((item, index) => `
      <details class="faq-item reveal"${index === 0 ? ' open' : ''}><summary>${escapeHtml(item.q)}<span>＋</span></summary><div><p>${escapeHtml(item.a)}</p></div></details>`).join('');
  }

  let imageObserver: IntersectionObserver | null = null;
  if ('IntersectionObserver' in window) {
    let observer: IntersectionObserver;
    observer = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        const image = entry.target as HTMLImageElement;
        assignLocalImage(image);
        observer.unobserve(image);
      }
    }, { rootMargin: '300px' });
    imageObserver = observer;
  }
  if (imageObserver) cleanup.push(() => imageObserver.disconnect());

  queryAll<HTMLImageElement>('img[data-src], img[data-team-image], img[data-gallery-image]').forEach((image) => {
    image.addEventListener('load', () => image.closest('.asset-card')?.classList.add('loaded'), { once: true });
    image.addEventListener('error', () => image.classList.add('failed'), { once: true });
    if (imageObserver) imageObserver.observe(image);
    else assignLocalImage(image);
  });

  const menuButton = query<HTMLButtonElement>('#menuButton');
  const nav = query<HTMLElement>('#mainNav');
  const onMenuClick = () => {
    if (!menuButton || !nav) return;
    const open = nav.classList.toggle('open');
    menuButton.setAttribute('aria-expanded', String(open));
    host.classList.toggle('menu-open', open);
  };
  menuButton?.addEventListener('click', onMenuClick);
  cleanup.push(() => menuButton?.removeEventListener('click', onMenuClick));

  const onRootClick = (event: Event) => {
    const target = event.target;
    if (!(target instanceof Element)) return;
    const anchor = target.closest<HTMLAnchorElement>('a[href]');
    if (!anchor) return;
    const href = anchor.getAttribute('href') ?? '';
    if (href === '#/nanobio/privacy') {
      event.preventDefault();
      closeModal();
      navigate('/nanobio/privacy');
      window.scrollTo({ top: 0, behavior: 'auto' });
      return;
    }
    if (href.startsWith('#') && href.length > 1) {
      const destination = root.getElementById(href.slice(1));
      if (!destination) return;
      event.preventDefault();
      nav?.classList.remove('open');
      host.classList.remove('menu-open');
      menuButton?.setAttribute('aria-expanded', 'false');
      destination.scrollIntoView({ behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth' });
    }
  };
  root.addEventListener('click', onRootClick);
  cleanup.push(() => root.removeEventListener('click', onRootClick));

  const galleryTrack = query<HTMLElement>('#galleryTrack');
  const scrollGallery = (direction: -1 | 1) => galleryTrack?.scrollBy({
    left: direction * Math.min(420, (galleryTrack.clientWidth || 420) * 0.8),
    behavior: window.matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth',
  });
  const galleryPrev = query<HTMLButtonElement>('#galleryPrev');
  const galleryNext = query<HTMLButtonElement>('#galleryNext');
  const onPrevious = () => scrollGallery(-1);
  const onNext = () => scrollGallery(1);
  galleryPrev?.addEventListener('click', onPrevious);
  galleryNext?.addEventListener('click', onNext);
  cleanup.push(() => galleryPrev?.removeEventListener('click', onPrevious));
  cleanup.push(() => galleryNext?.removeEventListener('click', onNext));

  const header = query<HTMLElement>('#siteHeader');
  const syncHeader = () => header?.classList.toggle('scrolled', window.scrollY > 12);
  syncHeader();
  window.addEventListener('scroll', syncHeader, { passive: true });
  cleanup.push(() => window.removeEventListener('scroll', syncHeader));

  const revealElements = queryAll<HTMLElement>('.reveal');
  if ('IntersectionObserver' in window && !window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    const revealObserver = new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        const element = entry.target as HTMLElement;
        const delay = element.dataset.delay ?? getComputedStyle(element).getPropertyValue('--delay') ?? '0';
        element.style.transitionDelay = delay.includes('ms') ? delay : `${delay}ms`;
        element.classList.add('shown');
        revealObserver.unobserve(element);
      }
    }, { threshold: 0.08, rootMargin: '0px 0px -40px' });
    revealElements.forEach((element) => revealObserver.observe(element));
    cleanup.push(() => revealObserver.disconnect());
  } else {
    revealElements.forEach((element) => element.classList.add('shown'));
  }

  const vipModal = query<HTMLElement>('#vipModal');
  const phone = query<HTMLInputElement>('#phone');
  const form = query<HTMLFormElement>('#earlyAccessForm');
  const consent = query<HTMLInputElement>('#consent');
  const submitButton = query<HTMLButtonElement>('#submitButton');
  const errorBox = query<HTMLElement>('#formError');
  const formState = query<HTMLElement>('#formState');
  const successState = query<HTMLElement>('#successState');
  const downloadButton = query<HTMLAnchorElement>('#downloadButton');
  const downloadHint = query<HTMLElement>('#downloadHint');
  const appVersion = import.meta.env.VITE_NANOBIO_APP_VERSION?.trim() || '1.0.1+4';
  const versionPill = query<HTMLElement>('#versionPill');
  const successVersion = query<HTMLElement>('#successVersion');
  if (versionPill) versionPill.textContent = `v${appVersion}`;
  if (successVersion) successVersion.textContent = appVersion;

  let lastFocused: HTMLElement | null = null;
  let previousBodyOverflow = '';
  let submissionInFlight = false;
  let toastTimer: number | undefined;
  const toast = query<HTMLElement>('#toast');
  const showToast = (message: string, kind: 'success' | 'warn') => {
    if (!toast) return;
    toast.textContent = message;
    toast.className = `toast show ${kind}`;
    if (toastTimer !== undefined) window.clearTimeout(toastTimer);
    toastTimer = window.setTimeout(() => { toast.className = 'toast'; }, 3600);
  };
  const showError = (message: string) => {
    if (!errorBox) return;
    errorBox.textContent = message;
    if (message) errorBox.focus();
    if (submitButton) {
      const label = submitButton.querySelector('span');
      if (label) label.textContent = 'Thử gửi lại';
    }
  };
  const closeModal = () => {
    if (!vipModal) return;
    vipModal.hidden = true;
    vipModal.setAttribute('aria-hidden', 'true');
    host.classList.remove('vip-modal-open');
    document.body.style.overflow = previousBodyOverflow;
    lastFocused?.focus();
  };
  const openModal = (trigger: HTMLElement) => {
    if (!vipModal) return;
    lastFocused = trigger;
    vipModal.hidden = false;
    vipModal.setAttribute('aria-hidden', 'false');
    host.classList.add('vip-modal-open');
    previousBodyOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    window.setTimeout(() => phone?.focus(), 30);
  };
  queryAll<HTMLElement>('[data-open-vip-modal]').forEach((button) => {
    const handler = () => openModal(button);
    button.addEventListener('click', handler);
    cleanup.push(() => button.removeEventListener('click', handler));
  });
  queryAll<HTMLElement>('[data-close-vip-modal]').forEach((button) => {
    button.addEventListener('click', closeModal);
    cleanup.push(() => button.removeEventListener('click', closeModal));
  });

  const onDialogKeydown = (rawEvent: Event) => {
    if (!(rawEvent instanceof KeyboardEvent)) return;
    const event = rawEvent;
    if (!vipModal || vipModal.hidden) return;
    if (event.key === 'Escape') {
      event.preventDefault();
      closeModal();
      return;
    }
    if (event.key !== 'Tab') return;
    const focusable = Array.from(vipModal.querySelectorAll<HTMLElement>(
      'a[href], button:not(:disabled), input:not(:disabled), [tabindex]:not([tabindex="-1"])',
    )).filter((element) => !element.closest('[hidden]'));
    const first = focusable[0];
    const last = focusable[focusable.length - 1];
    if (!first || !last) return;
    if (event.shiftKey && root.activeElement === first) {
      event.preventDefault();
      last.focus();
    } else if (!event.shiftKey && root.activeElement === last) {
      event.preventDefault();
      first.focus();
    }
  };
  root.addEventListener('keydown', onDialogKeydown);
  cleanup.push(() => root.removeEventListener('keydown', onDialogKeydown));

  const onPhoneInput = () => {
    if (!phone) return;
    phone.value = phone.value.replace(/[^\d+\s().-]/g, '');
    phone.removeAttribute('aria-invalid');
    if (errorBox) errorBox.textContent = '';
    const label = submitButton?.querySelector('span');
    if (label && !submissionInFlight) label.textContent = 'Nhận VIP 1 tháng & tải ứng dụng';
  };
  phone?.addEventListener('input', onPhoneInput);
  cleanup.push(() => phone?.removeEventListener('input', onPhoneInput));
  const onConsentChange = () => {
    if (!consent?.checked) return;
    consent.removeAttribute('aria-invalid');
    if (errorBox) errorBox.textContent = '';
    const label = submitButton?.querySelector('span');
    if (label && !submissionInFlight) label.textContent = 'Nhận VIP 1 tháng & tải ứng dụng';
  };
  consent?.addEventListener('change', onConsentChange);
  cleanup.push(() => consent?.removeEventListener('change', onConsentChange));

  const onSubmit = async (event: SubmitEvent) => {
    event.preventDefault();
    if (!phone || !consent || !submitButton || !form || submissionInFlight) return;
    if (errorBox) errorBox.textContent = '';
    const normalizedPhone = normalizeVietnamPhone(phone.value);
    if (!normalizedPhone) {
      consent.removeAttribute('aria-invalid');
      phone.setAttribute('aria-invalid', 'true');
      showError('Số điện thoại Việt Nam chưa đúng định dạng. Ví dụ: 0912 345 678.');
      phone.focus();
      return;
    }
    if (!consent.checked) {
      phone.removeAttribute('aria-invalid');
      consent.setAttribute('aria-invalid', 'true');
      showError('Bạn cần đồng ý với mục đích sử dụng thông tin để tiếp tục.');
      consent.focus();
      return;
    }

    submissionInFlight = true;
    submitButton.disabled = true;
    submitButton.classList.add('loading');
    const buttonLabel = submitButton.querySelector('span');
    if (buttonLabel) buttonLabel.textContent = 'Đang ghi nhận…';
    try {
      const routePath = window.location.hash.replace(/^#/, '').split('?')[0];
      const result = await submitEarlyAccess({
        phone: displayVietnamPhone(normalizedPhone),
        privacy_consent: true,
        utm_source: readCampaignValue('utm_source'),
        utm_medium: readCampaignValue('utm_medium'),
        utm_campaign: readCampaignValue('utm_campaign'),
        landing_path: routePath === '/nanobio/privacy' ? '/nanobio/privacy' : '/nanobio',
      });
      if (formState) formState.hidden = true;
      if (successState) successState.hidden = false;
      if (successVersion) successVersion.textContent = result.appVersion;
      if (downloadButton && downloadHint) {
        if (result.downloadUrl) {
          downloadButton.href = result.downloadUrl;
          downloadButton.hidden = false;
          downloadHint.textContent = 'Bạn có thể tải bản Android ngay. Đội ngũ sẽ hỗ trợ đối chiếu ưu đãi Plus 30 ngày cho tài khoản tương ứng.';
        } else {
          downloadButton.hidden = true;
          downloadHint.textContent = 'Đăng ký đã được ghi nhận. Bản cài đặt đang được cập nhật; bạn có thể quay lại sau để tải ứng dụng.';
        }
      }
      showToast('Đã ghi nhận yêu cầu của bạn.', 'success');
      successState?.scrollIntoView?.({ behavior: 'smooth', block: 'nearest' });
    } catch (error) {
      if (error instanceof EarlyAccessError && error.code === 'rate_limited') {
        showError('Bạn gửi yêu cầu hơi nhanh. Vui lòng chờ một chút rồi thử lại.');
      } else if (error instanceof EarlyAccessError && error.code === 'invalid_phone') {
        phone.setAttribute('aria-invalid', 'true');
        consent.removeAttribute('aria-invalid');
        showError('Số điện thoại Việt Nam chưa đúng định dạng. Vui lòng kiểm tra lại.');
        phone.focus();
      } else if (error instanceof EarlyAccessError && error.code === 'consent_required') {
        phone.removeAttribute('aria-invalid');
        consent.setAttribute('aria-invalid', 'true');
        showError('Bạn cần đồng ý với mục đích sử dụng thông tin để tiếp tục.');
        consent.focus();
      } else {
        showError('Chưa thể ghi nhận lúc này. Hãy kiểm tra kết nối rồi thử gửi lại.');
      }
      showToast('Chưa thể gửi yêu cầu. Bạn có thể thử lại.', 'warn');
    } finally {
      submissionInFlight = false;
      submitButton.disabled = false;
      submitButton.classList.remove('loading');
      if (buttonLabel && !formState?.hidden && !errorBox?.textContent) {
        buttonLabel.textContent = 'Nhận VIP 1 tháng & tải ứng dụng';
      }
    }
  };
  form?.addEventListener('submit', onSubmit);
  cleanup.push(() => form?.removeEventListener('submit', onSubmit));

  const resetButton = query<HTMLButtonElement>('#resetRegistration');
  const reset = () => {
    successState && (successState.hidden = true);
    formState && (formState.hidden = false);
    form?.reset();
    if (errorBox) errorBox.textContent = '';
    phone?.focus();
  };
  resetButton?.addEventListener('click', reset);
  cleanup.push(() => resetButton?.removeEventListener('click', reset));

  const activeSectionObserver = 'IntersectionObserver' in window
    ? new IntersectionObserver((entries) => {
      for (const entry of entries) {
        if (!entry.isIntersecting) continue;
        const sectionId = (entry.target as HTMLElement).id;
        queryAll<HTMLAnchorElement>('.main-nav a[href^="#"]').forEach((anchor) => {
          anchor.classList.toggle('active', anchor.getAttribute('href') === `#${sectionId}`);
        });
      }
    }, { rootMargin: '-35% 0px -55%', threshold: 0 })
    : null;
  if (activeSectionObserver) {
    queryAll<HTMLElement>('main section[id]').forEach((section) => activeSectionObserver.observe(section));
    cleanup.push(() => activeSectionObserver.disconnect());
  }

  cleanup.push(() => {
    if (toastTimer !== undefined) window.clearTimeout(toastTimer);
    if (vipModal && !vipModal.hidden) {
      vipModal.hidden = true;
      host.classList.remove('vip-modal-open');
      document.body.style.overflow = previousBodyOverflow;
    }
    host.classList.remove('menu-open');
  });
  window.scrollTo({ top: 0, behavior: 'auto' });

  return () => cleanup.reverse().forEach((dispose) => dispose());
}

function assignLocalImage(image: HTMLImageElement): void {
  const token = image.dataset.teamImage ?? image.dataset.galleryImage;
  if (token && token in websiteAssets) {
    const key = token as keyof typeof websiteAssets;
    image.src = websiteAssetUrls[key];
  } else if (image.dataset.src) {
    image.src = image.dataset.src;
  }
}

function escapeHtml(value: string): string {
  return value.replace(/[&<>"']/g, (character) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  })[character] ?? character);
}

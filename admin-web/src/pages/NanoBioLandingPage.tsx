import { useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { websiteAssetUrls } from './nanobio/assets';
import landingHtml from './nanobio/landing.html?raw';
import landingCss from './nanobio/styles.css?raw';
import { mountNanoBioLanding } from './nanobio/website-controller';

export function NanoBioLandingPage() {
  const hostRef = useRef<HTMLDivElement>(null);
  const navigate = useNavigate();

  useEffect(() => {
    const host = hostRef.current;
    if (!host) return;

    const shadow = host.shadowRoot ?? host.attachShadow({ mode: 'open' });
    const documentTemplate = new DOMParser().parseFromString(landingHtml, 'text/html');
    documentTemplate.querySelectorAll('script').forEach((script) => script.remove());
    documentTemplate.querySelectorAll('*').forEach((element) => {
      for (const attribute of Array.from(element.attributes)) {
        if (/^on/i.test(attribute.name)) element.removeAttribute(attribute.name);
      }
    });

    const styles = document.createElement('style');
    styles.textContent = scopeWebsiteStyles(landingCss);
    const content = document.createElement('div');
    content.innerHTML = replaceAssetTokens(documentTemplate.body.innerHTML);
    shadow.replaceChildren(styles, content);

    const previousTitle = document.title;
    const previousDescription = document.querySelector<HTMLMetaElement>('meta[name="description"]')?.content;
    document.title = 'NanoBio | Chăm sóc sức khỏe chủ động cùng Nabi';
    const description = document.querySelector<HTMLMetaElement>('meta[name="description"]');
    if (description) description.content = 'Theo dõi thói quen sức khỏe và lịch sinh hoạt cùng Nabi.';

    const cleanup = mountNanoBioLanding(shadow, host, navigate);
    return () => {
      cleanup();
      document.title = previousTitle;
      if (description && previousDescription !== undefined) description.content = previousDescription;
      shadow.replaceChildren();
    };
  }, [navigate]);

  return <div className="nanobio-landing-host" ref={hostRef} />;
}

function scopeWebsiteStyles(css: string): string {
  return css
    .replace(':root{', ':host{')
    .replace(/(^|})html\{/g, '$1:host{')
    .replace(/(^|})body\{/g, '$1:host{')
    .replace(/body\.menu-open/g, ':host(.menu-open)')
    .replace(/body\.vip-modal-open/g, ':host(.vip-modal-open)');
}

function replaceAssetTokens(markup: string): string {
  const tokens: Record<string, string> = {
    __NANOBIO_LOGO__: websiteAssetUrls.logo,
    __NANOBIO_NABI_WAVE__: websiteAssetUrls.nabiWave,
    __NANOBIO_NABI_THINK__: websiteAssetUrls.nabiThink,
    __NANOBIO_NABI_PLAN__: websiteAssetUrls.nabiPlan,
    __NANOBIO_FITNESS_ATLAS__: websiteAssetUrls.fitnessAtlas,
    __NANOBIO_NABI_STREAK__: websiteAssetUrls.nabiStreak,
  };
  return markup.replace(/__NANOBIO_[A-Z_]+__/g, (token) => tokens[token] ?? '');
}

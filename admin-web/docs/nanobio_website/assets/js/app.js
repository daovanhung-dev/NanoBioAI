(function () {
  'use strict';
  var config = window.NANOBIO_CONFIG || {};
  var data = window.NANOBIO_DATA || {};
  var phoneUtil = window.NanoBioPhone;

  function qs(sel, root) { return (root || document).querySelector(sel); }
  function qsa(sel, root) { return Array.prototype.slice.call((root || document).querySelectorAll(sel)); }
  function esc(s) { return String(s).replace(/[&<>"']/g, function(c){ return ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'})[c]; }); }

  // Header / mobile menu
  var header = qs('#siteHeader'); var menuBtn = qs('#menuButton'); var nav = qs('#mainNav');
  function syncHeader(){ header.classList.toggle('scrolled', window.scrollY > 12); }
  syncHeader(); window.addEventListener('scroll', syncHeader, { passive:true });
  menuBtn.addEventListener('click', function(){ var open = nav.classList.toggle('open'); menuBtn.setAttribute('aria-expanded', String(open)); document.body.classList.toggle('menu-open', open); });
  qsa('a', nav).forEach(function(a){ a.addEventListener('click', function(){ nav.classList.remove('open'); document.body.classList.remove('menu-open'); menuBtn.setAttribute('aria-expanded','false'); }); });

  // Lazy images with robust fallback
  qsa('img[data-src]').forEach(function(img){
    var load = function(){ img.src = img.getAttribute('data-src'); };
    img.addEventListener('load', function(){ img.closest('.asset-card') && img.closest('.asset-card').classList.add('loaded'); });
    img.addEventListener('error', function(){ img.classList.add('failed'); img.setAttribute('aria-hidden','true'); });
    if ('IntersectionObserver' in window) { var io = new IntersectionObserver(function(entries){ entries.forEach(function(e){ if(e.isIntersecting){ load(); io.disconnect(); } }); }, {rootMargin:'300px'}); io.observe(img); } else load();
  });

  // Features
  var featureGrid = qs('#featureGrid');
  featureGrid.innerHTML = (data.features || []).map(function(f, i){ return '<article class="feature-card reveal" style="--delay:'+((i%3)*60)+'ms"><div class="feature-top"><span class="feature-icon">'+esc(f.icon)+'</span><span class="status '+esc(f.tone)+'">'+esc(f.status)+'</span></div><h3>'+esc(f.title)+'</h3><p>'+esc(f.text)+'</p></article>'; }).join('');

  // Team
  var teamGrid = qs('#teamGrid');
  teamGrid.innerHTML = (data.team || []).map(function(m, i){
    return '<article class="team-card reveal" style="--delay:'+((i%3)*80)+'ms"><div class="team-photo asset-card"><div class="asset-fallback">'+esc(m.name.split(' ').slice(-2).join(' '))+'</div><img data-team-src="'+esc(m.image)+'" alt="Ảnh '+esc(m.name)+'" /></div><div class="team-body"><span>'+esc(m.role)+'</span><h3>'+esc(m.name)+'</h3><p>'+esc(m.story)+'</p><small>Nguồn: '+esc(m.source)+'</small></div></article>';
  }).join('');
  qsa('img[data-team-src]').forEach(function(img){ img.src=img.getAttribute('data-team-src'); img.addEventListener('load', function(){ img.closest('.asset-card').classList.add('loaded'); }); img.addEventListener('error', function(){ img.classList.add('failed'); }); });

  // Gallery
  var gallery = qs('#galleryTrack');
  gallery.innerHTML = (data.gallery || []).map(function(g){ return '<figure class="gallery-card"><div class="gallery-image asset-card"><div class="asset-fallback">'+esc(g.title)+'</div><img data-gallery-src="'+esc(g.image)+'" alt="'+esc(g.title)+'" loading="lazy" /></div><figcaption>'+esc(g.title)+'</figcaption></figure>'; }).join('');
  qsa('img[data-gallery-src]').forEach(function(img){ img.src=img.getAttribute('data-gallery-src'); img.addEventListener('load', function(){ img.closest('.asset-card').classList.add('loaded'); }); img.addEventListener('error', function(){ img.classList.add('failed'); }); });
  qs('#galleryPrev').addEventListener('click', function(){ gallery.scrollBy({left:-Math.min(420, gallery.clientWidth*.8),behavior:'smooth'}); });
  qs('#galleryNext').addEventListener('click', function(){ gallery.scrollBy({left:Math.min(420, gallery.clientWidth*.8),behavior:'smooth'}); });

  // FAQ
  var faqList = qs('#faqList');
  faqList.innerHTML = (data.faq || []).map(function(x, i){ return '<details class="faq-item reveal"'+(i===0?' open':'')+'><summary>'+esc(x.q)+'<span>＋</span></summary><div><p>'+esc(x.a)+'</p></div></details>'; }).join('');

  // Reveal animations
  var revealEls = qsa('.reveal');
  if ('IntersectionObserver' in window && !window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
    var observer = new IntersectionObserver(function(entries){ entries.forEach(function(e){ if(e.isIntersecting){ var delay=e.target.dataset.delay || getComputedStyle(e.target).getPropertyValue('--delay') || '0'; e.target.style.transitionDelay = String(delay).includes('ms') ? delay : delay+'ms'; e.target.classList.add('shown'); observer.unobserve(e.target); } }); }, { threshold:.08, rootMargin:'0px 0px -40px' });
    revealEls.forEach(function(el){ observer.observe(el); });
  } else revealEls.forEach(function(el){ el.classList.add('shown'); });

  // Download + 1 month VIP modal/form
  var vipModal = qs('#vipModal');
  var form = qs('#earlyAccessForm'); var phone = qs('#phone'); var consent = qs('#consent'); var errorBox = qs('#formError'); var submit = qs('#submitButton'); var success = qs('#successState'); var formState = qs('#formState'); var download = qs('#downloadButton'); var hint = qs('#downloadHint');
  var lastFocused = null;
  qs('#versionPill').textContent = 'v' + (config.appVersion || '1.0.1+4'); qs('#successVersion').textContent = config.appVersion || '1.0.1+4';
  phone.addEventListener('input', function(){ var v=phone.value.replace(/[^\d+\s]/g,''); phone.value=v; errorBox.textContent=''; });

  function toast(msg, kind){ var el=qs('#toast'); el.textContent=msg; el.className='toast show '+(kind||''); clearTimeout(el._t); el._t=setTimeout(function(){el.className='toast';},3600); }
  function setLoading(on){ submit.disabled=on; submit.classList.toggle('loading',on); submit.querySelector('span').textContent = on ? 'Đang xác nhận…' : 'Nhận VIP 1 tháng & tải ứng dụng'; }
  function error(message){ errorBox.textContent=message; if(message) errorBox.focus && errorBox.focus(); }
  function withTimeout(promise, ms){ return Promise.race([promise, new Promise(function(_,reject){ setTimeout(function(){ reject(new Error('TIMEOUT')); },ms); })]); }

  function openVipModal(){
    lastFocused = document.activeElement;
    vipModal.hidden = false; vipModal.setAttribute('aria-hidden','false'); document.body.classList.add('vip-modal-open');
    setTimeout(function(){ phone.focus(); }, 30);
  }
  function closeVipModal(){
    vipModal.hidden = true; vipModal.setAttribute('aria-hidden','true'); document.body.classList.remove('vip-modal-open');
    if(lastFocused && typeof lastFocused.focus === 'function') lastFocused.focus();
  }
  qsa('[data-open-vip-modal]').forEach(function(btn){ btn.addEventListener('click', openVipModal); });
  qsa('[data-close-vip-modal]').forEach(function(el){ el.addEventListener('click', closeVipModal); });
  document.addEventListener('keydown', function(ev){ if(ev.key === 'Escape' && !vipModal.hidden) closeVipModal(); });

  async function registerRemote(e164, display){
    if(!config.supabaseUrl || !config.supabaseAnonKey || !config.edgeFunctionName) throw new Error('BACKEND_NOT_CONFIGURED');
    var url=config.supabaseUrl.replace(/\/$/,'')+'/functions/v1/'+config.edgeFunctionName;
    var payload={
      phone:display,
      source:'nanobio_web',
      app_version:config.appVersion,
      privacy_consent:true,
      vip_support_requested:true,
      promotion_code:'EARLY_ACCESS_PLUS_30D',
      requested_plan:'plus',
      vip_duration_days:30
    };
    var res=await withTimeout(fetch(url,{method:'POST',headers:{'Content-Type':'application/json','apikey':config.supabaseAnonKey,'Authorization':'Bearer '+config.supabaseAnonKey},body:JSON.stringify(payload)}), config.requestTimeoutMs||12000);
    var body={}; try{ body=await res.json(); }catch(_e){}
    if(!res.ok || !body.success){ var err=new Error(body.message || 'BACKEND_ERROR'); err.code=body.code || String(res.status); throw err; }
    return body;
  }
  function registerDemo(e164, display){
    var leads=[]; try{leads=JSON.parse(localStorage.getItem('nanobio_early_access_demo')||'[]');}catch(_e){}
    if(!leads.some(function(x){return x.phone_e164===e164;})) leads.push({phone_e164:e164,phone_display:display,app_version:config.appVersion,promotion_code:'EARLY_ACCESS_PLUS_30D',requested_plan:'plus',vip_duration_days:30,vip_grant_status:'pending_account_link',created_at:new Date().toISOString(),mode:'demo'});
    localStorage.setItem('nanobio_early_access_demo',JSON.stringify(leads));
    return {success:true,message:'Đăng ký demo thành công',download_url:config.publicDownloadFallback||'',vip_plan:'plus',vip_duration_days:30,vip_grant_status:'pending_account_link',demo:true};
  }
  function showSuccess(result){
    formState.hidden=true; success.hidden=false;
    var url=result.download_url || config.publicDownloadFallback || '';
    if(url){ download.hidden=false; download.href=url; download.target='_blank'; hint.textContent=result.demo?'Chế độ Demo: liên kết tải dùng URL fallback trong config.':'Bạn có thể tải APK ngay. SĐT đã được ghi nhận để hỗ trợ kích hoạt quyền Plus/VIP 30 ngày.'; }
    else { download.hidden=true; hint.textContent=result.demo?'Chế độ Demo đang hoạt động. APK production chưa được deploy nên chưa có file để tải.':'SĐT và quyền nhận VIP đã được ghi nhận. Bản APK hiện đang được cập nhật.'; }
    if(result.demo){ success.classList.add('demo'); toast('Đã ghi nhận VIP 1 tháng ở chế độ Demo cục bộ.','warn'); } else { success.classList.remove('demo'); toast('Đã ghi nhận quyền nhận VIP 1 tháng!','success'); }
    success.scrollIntoView({behavior:'smooth',block:'nearest'});
  }
  form.addEventListener('submit', async function(ev){
    ev.preventDefault(); error('');
    var e164=phoneUtil.normalizeVietnamPhone(phone.value); if(!e164){ error('Số điện thoại Việt Nam chưa đúng định dạng. Ví dụ: 0912 345 678.'); phone.focus(); return; }
    if(!consent.checked){ error('Bạn cần đồng ý với mục đích sử dụng số điện thoại để đăng ký tải app và nhận VIP 1 tháng.'); consent.focus(); return; }
    setLoading(true);
    var display=phoneUtil.displayPhone(phone.value);
    try{ var result=await registerRemote(e164,display); showSuccess(result); }
    catch(err){
      if(config.allowDemoFallback){ showSuccess(registerDemo(e164,display)); }
      else { var map={INVALID_PHONE:'Số điện thoại chưa đúng định dạng.',CONSENT_REQUIRED:'Bạn cần xác nhận đồng ý trước khi tiếp tục.',INVALID_PROMOTION:'Ưu đãi VIP hiện không hợp lệ.',RATE_LIMITED:'Bạn thao tác quá nhanh. Vui lòng thử lại sau.',DOWNLOAD_UNAVAILABLE:'Bản cài đặt đang được cập nhật. Vui lòng quay lại sau.'}; error(map[err.code] || 'Chưa thể kết nối hệ thống đăng ký. Vui lòng thử lại sau.'); }
    } finally { setLoading(false); }
  });
  qs('#resetRegistration').addEventListener('click', function(){ success.hidden=true; formState.hidden=false; form.reset(); error(''); success.classList.remove('demo'); phone.focus(); });

  // Active nav via section observer
  if('IntersectionObserver' in window){ var sections=qsa('main section[id]'); var navLinks=qsa('.main-nav a[href^="#"]'); var so=new IntersectionObserver(function(entries){ entries.forEach(function(e){if(e.isIntersecting){navLinks.forEach(function(a){a.classList.toggle('active',a.getAttribute('href')==='#'+e.target.id);});}});},{rootMargin:'-35% 0px -55%',threshold:0}); sections.forEach(function(s){so.observe(s);}); }
})();

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.1';

const corsBase = {
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Vary': 'Origin',
};

const PROMOTION_CODE = 'EARLY_ACCESS_PLUS_30D';
const REQUESTED_PLAN = 'plus';
const VIP_DURATION_DAYS = 30;

function allowedOrigin(req: Request) {
  const origin = req.headers.get('origin') ?? '';
  const raw = Deno.env.get('ALLOWED_ORIGINS') ?? '*';
  if (raw === '*') return '*';
  const list = raw.split(',').map((x) => x.trim()).filter(Boolean);
  return list.includes(origin) ? origin : list[0] ?? '';
}

function json(req: Request, status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsBase, 'Access-Control-Allow-Origin': allowedOrigin(req), 'Content-Type': 'application/json; charset=utf-8' },
  });
}

function normalizeVietnamPhone(value: unknown) {
  let raw = String(value ?? '').replace(/[\s.()-]/g, '');
  if (raw.startsWith('+84')) raw = '0' + raw.slice(3);
  else if (raw.startsWith('84') && raw.length >= 11) raw = '0' + raw.slice(2);
  if (!/^0(3|5|7|8|9)\d{8}$/.test(raw)) return null;
  return `+84${raw.slice(1)}`;
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: { ...corsBase, 'Access-Control-Allow-Origin': allowedOrigin(req) } });
  }
  if (req.method !== 'POST') return json(req, 405, { success: false, code: 'METHOD_NOT_ALLOWED', message: 'Phương thức không được hỗ trợ.' });

  const contentLength = Number(req.headers.get('content-length') || '0');
  if (contentLength > 4096) return json(req, 413, { success: false, code: 'PAYLOAD_TOO_LARGE', message: 'Dữ liệu gửi lên quá lớn.' });

  let payload: Record<string, unknown>;
  try { payload = await req.json(); }
  catch { return json(req, 400, { success: false, code: 'INVALID_JSON', message: 'Dữ liệu gửi lên không hợp lệ.' }); }

  const phoneE164 = normalizeVietnamPhone(payload.phone);
  if (!phoneE164) return json(req, 400, { success: false, code: 'INVALID_PHONE', message: 'Số điện thoại chưa đúng định dạng.' });
  if (payload.privacy_consent !== true) return json(req, 400, { success: false, code: 'CONSENT_REQUIRED', message: 'Bạn cần xác nhận đồng ý trước khi tiếp tục.' });

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !serviceRoleKey) return json(req, 500, { success: false, code: 'SERVER_CONFIG_ERROR', message: 'Hệ thống đăng ký chưa được cấu hình đầy đủ.' });

  const admin = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false, autoRefreshToken: false } });
  const phoneDisplay = String(payload.phone ?? '').slice(0, 30);
  const appVersion = String(payload.app_version ?? Deno.env.get('APP_VERSION') ?? '1.0.1+4').slice(0, 50);
  const source = String(payload.source ?? 'nanobio_web').slice(0, 80);

  // Promotion values are server-owned. Browser input cannot request a different paid plan or duration.
  // Preserve an already processed promotion so repeated downloads cannot reset/renew it.
  const { data: existingLead } = await admin
    .from('early_access_leads')
    .select('vip_grant_status')
    .eq('phone_e164', phoneE164)
    .maybeSingle();
  const grantStatus = typeof existingLead?.vip_grant_status === 'string'
    ? existingLead.vip_grant_status
    : 'pending_account_link';

  const { error: upsertError } = await admin.from('early_access_leads').upsert({
    phone_e164: phoneE164,
    phone_display: phoneDisplay,
    source,
    app_version: appVersion,
    vip_support_requested: true,
    privacy_consent: true,
    promotion_code: PROMOTION_CODE,
    requested_plan: REQUESTED_PLAN,
    vip_duration_days: VIP_DURATION_DAYS,
    vip_grant_status: grantStatus,
  }, { onConflict: 'phone_e164' });

  if (upsertError) {
    console.error('early_access_upsert_failed', { code: upsertError.code });
    return json(req, 500, { success: false, code: 'INTERNAL_ERROR', message: 'Chưa thể ghi nhận đăng ký. Vui lòng thử lại.' });
  }

  const bucket = Deno.env.get('EARLY_ACCESS_BUCKET') ?? 'early-access-apk';
  const path = Deno.env.get('EARLY_ACCESS_APK_PATH') ?? 'nanobio-early-access.apk';
  const expiresIn = Number(Deno.env.get('SIGNED_URL_SECONDS') ?? '900');
  let downloadUrl = '';
  let expiresAt: string | null = null;

  const { data: signed, error: signError } = await admin.storage.from(bucket).createSignedUrl(path, expiresIn);
  if (!signError && signed?.signedUrl) {
    downloadUrl = signed.signedUrl;
    expiresAt = new Date(Date.now() + expiresIn * 1000).toISOString();
  } else {
    const fallback = Deno.env.get('PUBLIC_FALLBACK_URL') ?? '';
    if (fallback.startsWith('https://')) downloadUrl = fallback;
  }

  const base = {
    success: true,
    promotion_code: PROMOTION_CODE,
    vip_plan: REQUESTED_PLAN,
    vip_duration_days: VIP_DURATION_DAYS,
    vip_grant_status: grantStatus,
    vip_message: 'Số điện thoại đã được ghi nhận để hỗ trợ cấp quyền Plus/VIP 30 ngày cho tài khoản NanoBio tương ứng.',
    app_version: appVersion,
  };

  if (!downloadUrl) {
    return json(req, 200, {
      ...base,
      code: 'DOWNLOAD_UNAVAILABLE',
      message: 'Đăng ký VIP 1 tháng đã được ghi nhận. Bản cài đặt đang được cập nhật.',
      download_url: '',
      download_available: false,
      expires_at: null,
    });
  }

  return json(req, 200, {
    ...base,
    message: 'Đăng ký tải ứng dụng và VIP 1 tháng thành công',
    download_url: downloadUrl,
    download_available: true,
    expires_at: expiresAt,
  });
});

export type RuntimeConfig = {
  supabaseUrl: string;
  supabaseAnonKey: string;
};

export class RuntimeConfigError extends Error {
  constructor(message = 'Trang quản trị chưa được cấu hình kết nối.') {
    super(message);
    this.name = 'RuntimeConfigError';
  }
}

export function readRuntimeConfig(): RuntimeConfig {
  const supabaseUrl = String(import.meta.env.VITE_SUPABASE_URL ?? '').trim();
  const supabaseAnonKey = String(import.meta.env.VITE_SUPABASE_ANON_KEY ?? '').trim();

  if (!supabaseUrl || !supabaseAnonKey) {
    throw new RuntimeConfigError('Trang quản trị chưa có cấu hình kết nối. Hãy bổ sung cấu hình triển khai.');
  }

  try {
    const url = new URL(supabaseUrl);
    if (!['http:', 'https:'].includes(url.protocol)) throw new Error('invalid protocol');
  } catch {
    throw new RuntimeConfigError('Địa chỉ dịch vụ chưa hợp lệ. Hãy kiểm tra cấu hình triển khai.');
  }

  return { supabaseUrl, supabaseAnonKey };
}

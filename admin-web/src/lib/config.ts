export type RuntimeConfig = {
  apiBaseUrl: string;
};

export class RuntimeConfigError extends Error {
  constructor(message = 'Trang quản trị chưa được cấu hình kết nối.') {
    super(message);
    this.name = 'RuntimeConfigError';
  }
}

export function readRuntimeConfig(): RuntimeConfig {
  const apiBaseUrl = String(
    import.meta.env.VITE_API_BASE_URL ?? 'https://42.118.174.147',
  ).trim().replace(/\/+$/, '');
  try {
    const url = new URL(apiBaseUrl);
    const local = ['localhost', '127.0.0.1', '[::1]'].includes(url.hostname);
    if (url.protocol !== 'https:' && !(local && url.protocol === 'http:')) {
      throw new Error('HTTPS is required');
    }
    if (url.username || url.password || url.search || url.hash) {
      throw new Error('Invalid API origin');
    }
  } catch {
    throw new RuntimeConfigError('Địa chỉ máy chủ chưa hợp lệ. Hãy kiểm tra cấu hình triển khai.');
  }
  return { apiBaseUrl };
}

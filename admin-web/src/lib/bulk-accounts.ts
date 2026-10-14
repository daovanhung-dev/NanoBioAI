import type { BulkProvisionAccount } from '../types';

export type BulkAccountLineIssue = {
  index: number;
  message: string;
};

export type BulkAccountParseResult = {
  accounts: BulkProvisionAccount[];
  issues: BulkAccountLineIssue[];
};

const EMAIL_PATTERN = /^[^\s@|]+@[^\s@|]+\.[^\s@|]+$/i;

function normalizeVietnamPhone(value: string): string | null {
  if (!/^[+\d\s().-]+$/.test(value.trim())) return null;
  const digits = value.trim().replace(/\D/g, '');
  const local = digits.startsWith('0084') ? digits.slice(4) : digits.startsWith('84') ? digits.slice(2) : digits.startsWith('0') ? digits.slice(1) : '';
  return /^\d{9}$/.test(local) ? `+84${local}` : null;
}

export function parseBulkAccountLines(value: string): BulkAccountParseResult {
  const lines = value.split(/\r?\n/);
  const accounts: BulkProvisionAccount[] = [];
  const issues: BulkAccountLineIssue[] = [];
  const seen = new Set<string>();

  lines.forEach((line, index) => {
    const raw = line.trim();
    if (!raw) return;

    const parts = raw.split('|').map((part) => part.trim());
    if (parts.length < 2 || parts.length > 3) {
      issues.push({ index: index + 1, message: 'Cần nhập theo dạng số điện thoại | họ tên | email liên hệ tùy chọn.' });
      return;
    }

    const phone = normalizeVietnamPhone(parts[0] ?? '');
    const fullName = parts[1] ?? '';
    const email = (parts[2] ?? '').toLowerCase() || undefined;
    if (!phone) {
      issues.push({ index: index + 1, message: 'Số điện thoại chưa đúng định dạng Việt Nam.' });
      return;
    }
    if (email && !EMAIL_PATTERN.test(email)) {
      issues.push({ index: index + 1, message: 'Email liên hệ chưa đúng định dạng.' });
      return;
    }
    if (fullName.length < 2) {
      issues.push({ index: index + 1, message: 'Họ tên cần ít nhất 2 ký tự.' });
      return;
    }
    if (seen.has(phone)) {
      issues.push({ index: index + 1, message: 'Số điện thoại bị trùng trong danh sách.' });
      return;
    }

    seen.add(phone);
    accounts.push({ phone, fullName, ...(email ? { email } : {}) });
  });

  if (accounts.length > 100) {
    issues.push({ index: 0, message: 'Mỗi lần chỉ được xử lý tối đa 100 tài khoản.' });
  }
  if (accounts.length === 0 && issues.length === 0) {
    issues.push({ index: 0, message: 'Chưa có tài khoản nào trong danh sách.' });
  }

  return { accounts, issues };
}

export function bulkConfirmationText(count: number): string {
  return `TAO TAI KHOAN ${count}`;
}

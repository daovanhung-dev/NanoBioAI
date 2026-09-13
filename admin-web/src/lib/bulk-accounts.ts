import type { BulkProvisionAccount } from '../types';

export type BulkAccountLineIssue = {
  index: number;
  message: string;
};

export type BulkAccountParseResult = {
  accounts: BulkProvisionAccount[];
  issues: BulkAccountLineIssue[];
};

const GMAIL_PATTERN = /^[^\s@|]+@gmail\.com$/i;

export function parseBulkAccountLines(value: string): BulkAccountParseResult {
  const lines = value.split(/\r?\n/);
  const accounts: BulkProvisionAccount[] = [];
  const issues: BulkAccountLineIssue[] = [];
  const seen = new Set<string>();

  lines.forEach((line, index) => {
    const raw = line.trim();
    if (!raw) return;

    const separator = raw.indexOf('|');
    if (separator < 0 || raw.indexOf('|', separator + 1) >= 0) {
      issues.push({ index: index + 1, message: 'Cần nhập theo dạng email | họ tên.' });
      return;
    }

    const email = raw.slice(0, separator).trim().toLowerCase();
    const fullName = raw.slice(separator + 1).trim();
    if (!GMAIL_PATTERN.test(email)) {
      issues.push({ index: index + 1, message: 'Chỉ chấp nhận địa chỉ kết thúc bằng @gmail.com.' });
      return;
    }
    if (fullName.length < 2) {
      issues.push({ index: index + 1, message: 'Họ tên cần ít nhất 2 ký tự.' });
      return;
    }
    if (seen.has(email)) {
      issues.push({ index: index + 1, message: 'Email bị trùng trong danh sách.' });
      return;
    }

    seen.add(email);
    accounts.push({ email, fullName });
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

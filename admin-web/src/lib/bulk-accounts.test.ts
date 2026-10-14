import { describe, expect, it } from 'vitest';
import { parseBulkAccountLines } from './bulk-accounts';

describe('parseBulkAccountLines', () => {
  it('normalizes Vietnamese numbers and keeps optional contact email', () => {
    expect(parseBulkAccountLines(
      '0912 345 678 | Nguyen An | an@example.com\n+84 987 654 321 | Tran B',
    )).toEqual({
      accounts: [
        { phone: '+84912345678', fullName: 'Nguyen An', email: 'an@example.com' },
        { phone: '+84987654321', fullName: 'Tran B' },
      ],
      issues: [],
    });
  });

  it('rejects malformed and duplicated phone numbers', () => {
    const result = parseBulkAccountLines(
      'abc0912345678 | Invalid\n0912345678 | First\n+84912345678 | Duplicate',
    );
    expect(result.accounts).toEqual([{ phone: '+84912345678', fullName: 'First' }]);
    expect(result.issues).toEqual([
      { index: 1, message: 'Số điện thoại chưa đúng định dạng Việt Nam.' },
      { index: 3, message: 'Số điện thoại bị trùng trong danh sách.' },
    ]);
  });
});

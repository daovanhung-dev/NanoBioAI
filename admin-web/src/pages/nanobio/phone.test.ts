import { describe, expect, it } from 'vitest';
import { displayVietnamPhone, normalizeVietnamPhone } from './phone';

describe('Vietnamese mobile phone normalization', () => {
  it.each(['0912 345 678', '+84 912 345 678', '84912345678'])('normalizes %s to E.164', (phone) => {
    expect(normalizeVietnamPhone(phone)).toBe('+84912345678');
  });

  it.each(['0123 456 789', '0912 345 67', '0912 abc 678', '+1 912 345 678'])('rejects %s', (phone) => {
    expect(normalizeVietnamPhone(phone)).toBeNull();
  });

  it('formats a validated number for display', () => {
    expect(displayVietnamPhone('+84912345678')).toBe('0912 345 678');
    expect(displayVietnamPhone('not-a-phone')).toBe('');
  });
});

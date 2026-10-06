export function normalizeVietnamPhone(value: string): string | null {
  let digits = value.trim().replace(/[\s.()-]/g, '');
  if (digits.startsWith('+84')) digits = `0${digits.slice(3)}`;
  else if (digits.startsWith('84') && digits.length >= 11) digits = `0${digits.slice(2)}`;
  if (!/^0(3|5|7|8|9)\d{8}$/.test(digits)) return null;
  return `+84${digits.slice(1)}`;
}

export function displayVietnamPhone(value: string): string {
  const normalized = normalizeVietnamPhone(value);
  if (!normalized) return '';
  const local = `0${normalized.slice(3)}`;
  return `${local.slice(0, 4)} ${local.slice(4, 7)} ${local.slice(7)}`;
}

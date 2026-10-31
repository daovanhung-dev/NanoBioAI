export function normalizeVietnamPhone(value: string): string | null {
  const trimmed = value.trim();
  if (!/^[+\d\s().-]+$/.test(trimmed)) return null;
  const digits = trimmed.replace(/\D/g, "");
  const local = digits.startsWith("0084")
    ? digits.slice(4)
    : digits.startsWith("84")
    ? digits.slice(2)
    : digits.startsWith("0")
    ? digits.slice(1)
    : "";
  return /^\d{9}$/.test(local) ? `+84${local}` : null;
}

export function memberAuthEmail(normalizedPhone: string): string {
  const digits = normalizedPhone.replace(/\D/g, "");
  return `member-${digits}@phone.nanobio.invalid`;
}

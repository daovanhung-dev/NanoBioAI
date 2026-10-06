export function clientIp(request: Request): string | null {
  const value = request.headers.get("x-forwarded-for")?.split(",")[0]?.trim();
  return value && value.length <= 128 ? value : null;
}

export function rateWindowStart(now: Date): string {
  return new Date(Math.floor(now.getTime() / 3_600_000) * 3_600_000)
    .toISOString();
}

export async function hmacIpAddress(
  ip: string,
  secret: string,
): Promise<string> {
  if (secret.length < 32) throw new Error("RATE_LIMIT_SECRET_INVALID");
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const digest = await crypto.subtle.sign(
    "HMAC",
    key,
    new TextEncoder().encode(ip),
  );
  return Array.from(
    new Uint8Array(digest),
    (byte) => byte.toString(16).padStart(2, "0"),
  ).join("");
}

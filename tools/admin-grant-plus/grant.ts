type SearchRow = {
  id?: string;
  subtitle?: string;
};

type AccountResponse = {
  success?: boolean;
  user_id?: string;
  message?: string;
};

type GrantResponse = {
  success?: boolean;
  skipped?: boolean;
  message?: string;
};

const supabaseUrl = requiredEnvironment("SUPABASE_URL").replace(/\/$/, "");
const anonKey = requiredEnvironment("SUPABASE_ANON_KEY");
const targets = await readInput();
const startsAt = new Date();
const endsAt = new Date(startsAt.getTime() + 30 * 24 * 60 * 60 * 1000);

let completed = 0;
let granted = 0;
let skipped = 0;
for (let index = 0; index < targets.emails.length; index++) {
  const email = targets.emails[index];
  try {
    let userId = await findExistingUser(email, targets.jwt);
    let created = false;
    if (!userId) {
      const createdAccount = await createAccount(
        email,
        targets.password,
        targets.jwt,
      );
      userId = createdAccount.userId;
      created = true;
    }

    const result = await grantPlus(
      userId,
      email,
      targets.jwt,
      startsAt,
      endsAt,
    );
    completed++;
    if (result.skipped) {
      skipped++;
      console.log(
        `[${index + 1}/${targets.emails.length}] ${
          created ? "đã tạo" : "đã kiểm tra"
        }; giữ nguyên gói đang hoạt động`,
      );
    } else {
      granted++;
      console.log(
        `[${index + 1}/${targets.emails.length}] ${
          created ? "đã tạo và cấp Plus" : "đã cấp Plus"
        }`,
      );
    }
  } catch {
    console.error(
      `[${index + 1}/${targets.emails.length}] thất bại`,
    );
    console.error(
      "Đã dừng batch. Có thể chạy lại với cùng input; idempotency key sẽ không cấp trùng.",
    );
    Deno.exit(1);
  }
}

console.log(
  `Hoàn tất ${completed}/${targets.emails.length} tài khoản (${granted} cấp mới, ${skipped} giữ nguyên).`,
);
console.log(
  `Thời hạn Plus: ${startsAt.toISOString()} đến ${endsAt.toISOString()}`,
);

async function findExistingUser(
  email: string,
  jwt: string,
): Promise<string | null> {
  const rows = await rest<SearchRow[]>("/rest/v1/rpc/admin_search_users", {
    p_query: email,
    p_limit: 10,
  }, jwt);
  const exact = rows.find((row) => {
    if (typeof row.id !== "string" || typeof row.subtitle !== "string") {
      return false;
    }
    const listedEmail = row.subtitle.split(" - ", 1)[0]?.trim().toLowerCase();
    return listedEmail === email;
  });
  return exact?.id ?? null;
}

async function createAccount(email: string, password: string, jwt: string) {
  const response = await edge<AccountResponse>("admin-create-account", {
    email,
    password,
    full_name: displayNameFromEmail(email),
    reason: "Tạo tài khoản Plus theo danh sách Admin đã phê duyệt.",
    idempotency_key: `admin-create-plus-${await shortHash(email)}`,
  }, jwt);
  if (!response.success || !response.user_id) {
    throw new Error(response.message ?? "Không thể tạo tài khoản.");
  }
  return { userId: response.user_id };
}

async function grantPlus(
  userId: string,
  email: string,
  jwt: string,
  startsAt: Date,
  endsAt: Date,
): Promise<{ skipped: boolean }> {
  const response = await edge<GrantResponse>("admin-grant-membership", {
    user_id: userId,
    plan_code: "plus",
    starts_at: startsAt.toISOString(),
    ends_at: endsAt.toISOString(),
    preserve_existing_paid_plan: true,
    reason: "Cấp gói Plus 30 ngày theo danh sách Admin đã phê duyệt.",
    idempotency_key: `admin-grant-plus-${await shortHash(email)}`,
  }, jwt);
  if (!response.success) {
    throw new Error(response.message ?? "Không thể cấp gói Plus.");
  }
  return { skipped: response.skipped === true };
}

async function rest<T>(
  path: string,
  body: Record<string, unknown>,
  jwt: string,
): Promise<T> {
  const response = await fetch(`${supabaseUrl}${path}`, {
    method: "POST",
    headers: authHeaders(jwt),
    body: JSON.stringify(body),
  });
  if (!response.ok) {
    throw new Error(`Tra cứu tài khoản thất bại (HTTP ${response.status}).`);
  }
  return await response.json() as T;
}

async function edge<T>(
  functionName: string,
  body: Record<string, unknown>,
  jwt: string,
): Promise<T> {
  const response = await fetch(`${supabaseUrl}/functions/v1/${functionName}`, {
    method: "POST",
    headers: authHeaders(jwt),
    body: JSON.stringify(body),
  });
  let result: T;
  try {
    result = await response.json() as T;
  } catch {
    throw new Error(
      `Edge Function phản hồi không hợp lệ (HTTP ${response.status}).`,
    );
  }
  return result;
}

function authHeaders(jwt: string): HeadersInit {
  return {
    Authorization: `Bearer ${jwt}`,
    apikey: anonKey,
    "Content-Type": "application/json",
  };
}

async function readInput(): Promise<
  { jwt: string; password: string; emails: string[] }
> {
  const lines = new TextDecoder().decode(await readAll(Deno.stdin.readable))
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
  const jwt = lines.shift() ?? "";
  const password = lines.shift() ?? "";
  const emails = lines.map((email) => email.toLowerCase());
  if (!jwt) throw new Error("Dòng đầu tiên phải là session JWT Admin.");
  if (password.length < 8) {
    throw new Error("Dòng thứ hai phải là mật khẩu tối thiểu 8 ký tự.");
  }
  if (emails.length === 0 || emails.length > 100) {
    throw new Error("Danh sách email không hợp lệ.");
  }
  if (new Set(emails).size !== emails.length) {
    throw new Error("Danh sách email có phần tử trùng.");
  }
  for (const email of emails) {
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      throw new Error("Danh sách có email không đúng định dạng.");
    }
  }
  return { jwt, password, emails };
}

async function readAll(
  readable: ReadableStream<Uint8Array>,
): Promise<Uint8Array> {
  const reader = readable.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      if (value) {
        chunks.push(value);
        total += value.length;
      }
      if (total > 100_000) throw new Error("Input vượt giới hạn an toàn.");
    }
  } finally {
    reader.releaseLock();
  }
  const result = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    result.set(chunk, offset);
    offset += chunk.length;
  }
  return result;
}

function displayNameFromEmail(email: string): string {
  const localPart = email.split("@", 1)[0] ?? "NanoBio user";
  return localPart.replace(/[._+-]+/g, " ").trim() || "NanoBio user";
}

async function shortHash(value: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(value),
  );
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("")
    .slice(0, 24);
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Thiếu biến môi trường ${name}.`);
  return value;
}

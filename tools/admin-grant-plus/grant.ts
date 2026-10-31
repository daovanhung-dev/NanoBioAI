type SearchRow = {
  id?: string;
  user_id?: string;
  email?: string;
  subtitle?: string;
};

type ApiEnvelope<T> = { data?: T; success?: boolean; message?: string } & T;

type AccountResponse = { user_id?: string; success?: boolean; message?: string };
type GrantResponse = { success?: boolean; skipped?: boolean; message?: string };

const apiBaseUrl = requiredEnvironment("API_BASE_URL").replace(/\/$/, "");
const targets = await readInput();
const startsAt = new Date();
const endsAt = new Date(startsAt.getTime() + 30 * 24 * 60 * 60 * 1000);

let completed = 0;
let granted = 0;
let skipped = 0;
for (let index = 0; index < targets.accounts.length; index++) {
  const target = targets.accounts[index];
  try {
    let userId = await findExistingUser(target.email, targets.jwt);
    let created = false;
    if (!userId) {
      if (!target.phone) {
        throw new Error("Tài khoản mới cần số điện thoại trong dòng email,phone.");
      }
      const createdAccount = await createAccount(
        target.email,
        target.phone,
        targets.password,
        targets.jwt,
      );
      userId = createdAccount.user_id ?? "";
      if (!userId) throw new Error("Backend không trả về ID tài khoản.");
      created = true;
    }

    const result = await grantPlus(
      userId,
      target.email,
      targets.jwt,
      startsAt,
      endsAt,
    );
    completed++;
    if (result.skipped) {
      skipped++;
      console.log(
        `[${index + 1}/${targets.accounts.length}] ${
          created ? "đã tạo" : "đã kiểm tra"
        }; giữ nguyên gói đang hoạt động`,
      );
    } else {
      granted++;
      console.log(
        `[${index + 1}/${targets.accounts.length}] ${
          created ? "đã tạo và cấp Plus" : "đã cấp Plus"
        }`,
      );
    }
  } catch {
    console.error(`[${index + 1}/${targets.accounts.length}] thất bại`);
    console.error(
      "Đã dừng batch. Có thể chạy lại với cùng input; idempotency key sẽ không cấp trùng.",
    );
    Deno.exit(1);
  }
}

console.log(
  `Hoàn tất ${completed}/${targets.accounts.length} tài khoản (${granted} cấp mới, ${skipped} giữ nguyên).`,
);
console.log(`Thời hạn Plus: ${startsAt.toISOString()} đến ${endsAt.toISOString()}`);

async function findExistingUser(email: string, jwt: string): Promise<string | null> {
  const rows = unwrap(await api<SearchRow[]>(
    `/api/v1/admin/users/search?q=${encodeURIComponent(email)}&limit=10`,
    { method: "GET" },
    jwt,
  ));
  const exact = rows.find((row) => {
    const listedEmail = row.email ?? row.subtitle?.split(" - ", 1)[0]?.trim();
    return listedEmail?.toLowerCase() === email;
  });
  return exact?.user_id ?? exact?.id ?? null;
}

async function createAccount(
  email: string,
  phone: string,
  password: string,
  jwt: string,
): Promise<AccountResponse> {
  const response = unwrap(await api<AccountResponse>(
    "/api/v1/admin/accounts",
    {
      method: "POST",
      body: JSON.stringify({
        email,
        phone,
        password,
        full_name: displayNameFromEmail(email),
        reason: "Tạo tài khoản Plus theo danh sách Admin đã phê duyệt.",
        idempotency_key: `admin-create-plus-${await shortHash(email)}`,
      }),
    },
    jwt,
  ));
  if (!response.user_id) throw new Error(response.message ?? "Không thể tạo tài khoản.");
  return response;
}

async function grantPlus(
  userId: string,
  email: string,
  jwt: string,
  startsAt: Date,
  endsAt: Date,
): Promise<GrantResponse> {
  const response = unwrap(await api<GrantResponse>(
    "/api/v1/admin/memberships/grant",
    {
      method: "POST",
      body: JSON.stringify({
        user_id: userId,
        plan_code: "plus",
        starts_at: startsAt.toISOString(),
        ends_at: endsAt.toISOString(),
        preserve_existing_paid_plan: true,
        reason: "Cấp gói Plus 30 ngày theo danh sách Admin đã phê duyệt.",
        idempotency_key: `admin-grant-plus-${await shortHash(email)}`,
      }),
    },
    jwt,
  ));
  if (response.success === false) throw new Error(response.message ?? "Không thể cấp gói Plus.");
  return response;
}

async function api<T>(
  path: string,
  options: { method: "GET" | "POST"; body?: string },
  jwt: string,
): Promise<T> {
  const response = await fetch(`${apiBaseUrl}${path}`, {
    method: options.method,
    headers: {
      Authorization: `Bearer ${jwt}`,
      Accept: "application/json",
      ...(options.body ? { "Content-Type": "application/json" } : {}),
    },
    body: options.body,
  });
  const result = await response.json().catch(() => null) as unknown;
  if (!response.ok) {
    throw new Error(`Backend từ chối thao tác (HTTP ${response.status}).`);
  }
  if (!result || typeof result !== "object") {
    throw new Error("Backend phản hồi không hợp lệ.");
  }
  return result as T;
}

function unwrap<T>(response: ApiEnvelope<T>): T {
  return (response.data ?? response) as T;
}

async function readInput(): Promise<{
  jwt: string;
  password: string;
  accounts: Array<{ email: string; phone: string }>;
}> {
  const lines = new TextDecoder().decode(await readAll(Deno.stdin.readable))
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean);
  const jwt = lines.shift() ?? "";
  const password = lines.shift() ?? "";
  const accounts = lines.map((line) => {
    const [emailValue = "", phoneValue = ""] = line.split(",", 2);
    return { email: emailValue.trim().toLowerCase(), phone: phoneValue.trim() };
  });
  if (!jwt) throw new Error("Dòng đầu tiên phải là phiên đăng nhập Admin của backend.");
  if (password.length < 8) throw new Error("Dòng thứ hai phải là mật khẩu tối thiểu 8 ký tự.");
  if (accounts.length === 0 || accounts.length > 100) throw new Error("Danh sách email không hợp lệ.");
  if (new Set(accounts.map((account) => account.email)).size !== accounts.length) {
    throw new Error("Danh sách email có phần tử trùng.");
  }
  for (const account of accounts) {
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(account.email)) {
      throw new Error("Danh sách có email không đúng định dạng.");
    }
    if (account.phone && !/^\+?[0-9]{8,15}$/.test(account.phone)) {
      throw new Error("Số điện thoại phải có 8-15 chữ số.");
    }
  }
  return { jwt, password, accounts };
}

async function readAll(readable: ReadableStream<Uint8Array>): Promise<Uint8Array> {
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
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(value));
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

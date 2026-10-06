import {
  createEarlyAccessAdminHandler,
  type EarlyAccessAdminLead,
  type EarlyAccessLeadStatus,
} from "./handler.ts";

const origin = "https://daovanhung-dev.github.io";
const lead: EarlyAccessAdminLead = {
  id: "11111111-1111-4111-8111-111111111111",
  phone_e164: "+84912345678",
  phone_display: "0912 345 678",
  full_name: "Nguyễn An",
  age: 24,
  gender: "prefer_not_to_say",
  address: "Quận 1, Thành phố Hồ Chí Minh",
  status: "new",
  created_at: "2026-10-07T00:00:00.000Z",
};

function request(body: Record<string, unknown>, authorization = "Bearer valid") {
  return new Request("https://project.example/functions/v1/admin-early-access-leads", {
    method: "POST",
    headers: { origin, authorization, "content-type": "application/json" },
    body: JSON.stringify(body),
  });
}

function handler(options: {
  actorId?: string | null;
  allowed?: boolean;
  updateStatus?: (status: EarlyAccessLeadStatus) => Promise<void>;
} = {}) {
  const calls: Array<Record<string, unknown>> = [];
  const run = createEarlyAccessAdminHandler({
    allowedOrigins: [origin],
    authenticate: async () => options.actorId === undefined ? "admin-1" : options.actorId,
    isAllowedAdmin: async () => options.allowed ?? true,
    listLeads: async (query, offset, pageSize) => {
      calls.push({ query, offset, pageSize });
      return { rows: [lead], total: 51 };
    },
    updateStatus: async (input) => {
      calls.push(input);
      await options.updateStatus?.(input.status);
    },
  });
  return { run, calls };
}

Deno.test("requires an authenticated, explicitly allowed admin role", async () => {
  const noSession = handler({ actorId: null });
  const unauthorized = await noSession.run(request({ action: "list" }));
  if (unauthorized.status !== 401) throw new Error("missing JWT was not rejected");

  const wrongRole = handler({ allowed: false });
  const forbidden = await wrongRole.run(request({ action: "list" }));
  if (forbidden.status !== 403 || wrongRole.calls.length) {
    throw new Error("non-approved role could read lead data");
  }
});

Deno.test("lists only bounded pages and sanitizes search syntax", async () => {
  const { run, calls } = handler();
  const response = await run(request({
    action: "list",
    query: "Nguyễn,an%25 (x)",
    page: 2,
    page_size: 25,
  }));
  const body = await response.json();
  if (response.status !== 200 || body.total !== 51 || body.rows[0].age !== 24) {
    throw new Error("lead list response was malformed");
  }
  if (calls[0].offset !== 50 || calls[0].pageSize !== 25 || calls[0].query !== "Nguyễn an 25 x") {
    throw new Error("query was not sanitized or page bounds were ignored");
  }
  const tooLarge = await run(request({ action: "list", page_size: 1000 }));
  if (tooLarge.status !== 400) throw new Error("unbounded page size was accepted");
});

Deno.test("audits status changes through the protected dependency and requires a reason", async () => {
  let updated: EarlyAccessLeadStatus | null = null;
  const { run, calls } = handler({ updateStatus: async (status) => { updated = status; } });
  const invalid = await run(request({
    action: "update_status",
    lead_id: lead.id,
    status: "deleted",
    reason: "test",
    idempotency_key: "operation-1",
  }));
  if (invalid.status !== 400) throw new Error("unsupported status was accepted");

  const response = await run(request({
    action: "update_status",
    lead_id: lead.id,
    status: "contacted",
    reason: "Đã liên hệ khách hàng.",
    idempotency_key: "operation-2",
  }));
  if (response.status !== 200 || updated !== "contacted" || calls.length !== 1) {
    throw new Error("valid status update was not handled");
  }
});

Deno.test("rejects unapproved origins and serves exact-origin preflight", async () => {
  const { run } = handler();
  const blocked = new Request("https://project.example/functions/v1/admin-early-access-leads", {
    method: "POST",
    headers: { origin: "https://attacker.example", authorization: "Bearer valid" },
    body: JSON.stringify({ action: "list" }),
  });
  if ((await run(blocked)).status !== 403) throw new Error("origin was not blocked");

  const preflight = new Request("https://project.example/functions/v1/admin-early-access-leads", {
    method: "OPTIONS",
    headers: { origin },
  });
  const response = await run(preflight);
  if (response.status !== 204 || response.headers.get("access-control-allow-origin") !== origin) {
    throw new Error("preflight was not handled for the exact origin");
  }
});

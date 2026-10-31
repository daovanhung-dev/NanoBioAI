import { createReportAiContentHandler } from "./handler.ts";

function handlerFor(options?: {
  userId?: string | null;
  acceptRate?: boolean;
  persist?: (input: unknown) => Promise<string>;
}) {
  return createReportAiContentHandler({
    authenticate: async () => options?.userId ?? null,
    rateLimit: async () => options?.acceptRate ?? true,
    persist: async (input) => {
      if (options?.persist) return options.persist(input);
      return "report-1";
    },
  });
}

function request(body: Record<string, unknown>) {
  return new Request("https://example.test/report-ai-content", {
    method: "POST",
    headers: { "content-type": "application/json", "x-forwarded-for": "127.0.0.1" },
    body: JSON.stringify(body),
  });
}

const validBody = {
  message_id: "assistant-1",
  message_role: "assistant",
  reason_code: "unsafe",
  note: "Cần kiểm tra lại.",
  message_snapshot: "Hãy trao đổi thêm với bác sĩ.",
  app_version: "1.0.0+1",
};

Deno.test("accepts an authenticated report and persists bounded fields", async () => {
  let captured: unknown;
  const handler = handlerFor({ userId: "user-a", persist: async (input) => { captured = input; return "report-1"; } });
  const response = await handler(request(validBody));
  if (response.status !== 200) throw new Error(`expected 200, got ${response.status}`);
  const body = await response.json();
  if (body.accepted !== true || body.report_id !== "report-1") throw new Error("report was not accepted");
  if ((captured as { reasonCode: string }).reasonCode !== "unsafe") throw new Error("reason was not persisted");
});

Deno.test("accepts a guest report without a user id", async () => {
  let userId: string | null | undefined;
  const handler = handlerFor({ persist: async (input) => { userId = (input as { userId: string | null }).userId; return "guest-report"; } });
  const response = await handler(request(validBody));
  if (response.status !== 200 || userId !== null) throw new Error("guest report was not accepted safely");
});

Deno.test("rejects user messages and missing reasons", async () => {
  const handler = handlerFor();
  const userMessage = await handler(request({ ...validBody, message_role: "user" }));
  if (userMessage.status !== 400) throw new Error(`expected user message rejection, got ${userMessage.status}`);
  const missingReason = await handler(request({ ...validBody, reason_code: "" }));
  if (missingReason.status !== 400) throw new Error(`expected missing reason rejection, got ${missingReason.status}`);
});

Deno.test("does not report false success when persistence fails or rate limit is hit", async () => {
  const failed = await handlerFor({ persist: async () => { throw new Error("storage down"); } })(request(validBody));
  if (failed.status !== 500) throw new Error(`expected 500, got ${failed.status}`);
  const limited = await handlerFor({ acceptRate: false })(request(validBody));
  if (limited.status !== 429) throw new Error(`expected 429, got ${limited.status}`);
});

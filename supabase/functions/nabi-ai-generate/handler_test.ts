import {
  createNabiAiGenerateHandler,
  resolveGeminiProviderRequest,
} from "./handler.ts";

function request(
  body: Record<string, unknown>,
  headers?: Record<string, string>,
) {
  return new Request("https://example.test/nabi-ai-generate", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-forwarded-for": "127.0.0.1",
      "x-ai-trace-id": "test-ai-trace-001",
      ...headers,
    },
    body: JSON.stringify(body),
  });
}

const validBody = {
  model: "gemini-2.5-flash",
  contents: [{ role: "user", parts: [{ text: "Xin chào" }] }],
  generation_config: { maxOutputTokens: 128, temperature: 0.2 },
  system_instruction: "Trả lời an toàn.",
};

const providerInput = {
  model: "gemini-3.5-flash",
  contents: validBody.contents,
  generationConfig: {
    maxOutputTokens: 256,
    thinkingConfig: { thinkingLevel: "MINIMAL" },
  },
  systemInstruction: null,
  userId: null,
  ip: "127.0.0.1",
  traceId: "test-ai-trace-001",
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return value != null && typeof value === "object" && !Array.isArray(value);
}

Deno.test("normalizes fallback model and config as one provider request", () => {
  const resolved = resolveGeminiProviderRequest(
    providerInput,
    new Set(["gemini-2.5-flash"]),
    "gemini-2.5-flash",
  );
  if (resolved.model !== "gemini-2.5-flash" || !resolved.modelFallback) {
    throw new Error(
      "unapproved model was not resolved to the canonical fallback",
    );
  }
  if (resolved.generationConfig.maxOutputTokens !== 256) {
    throw new Error("generic generation config was not preserved");
  }
  if ("thinkingConfig" in resolved.generationConfig) {
    throw new Error("Gemini 2.5 request still contains thinkingConfig");
  }
  if (!("thinkingConfig" in providerInput.generationConfig)) {
    throw new Error("normalization mutated the incoming config");
  }
});

Deno.test("preserves thinking level for a model family that supports it", () => {
  const resolved = resolveGeminiProviderRequest(
    providerInput,
    new Set(["gemini-3.5-flash"]),
    "gemini-2.5-flash",
  );
  if (resolved.model !== "gemini-3.5-flash" || resolved.modelFallback) {
    throw new Error("allowed model was unexpectedly replaced");
  }
  const thinkingConfig = resolved.generationConfig.thinkingConfig;
  if (
    !isRecord(thinkingConfig) ||
    thinkingConfig.thinkingLevel !== "MINIMAL"
  ) {
    throw new Error("supported model lost its thinking level");
  }
});

Deno.test("keeps compatible thinking budget while stripping thinking level", () => {
  const resolved = resolveGeminiProviderRequest(
    {
      ...providerInput,
      generationConfig: {
        maxOutputTokens: 256,
        thinkingConfig: { thinkingLevel: "MINIMAL", thinkingBudget: 128 },
      },
    },
    new Set(["gemini-2.5-flash"]),
    "gemini-2.5-flash",
  );
  const thinkingConfig = resolved.generationConfig.thinkingConfig;
  if (
    !isRecord(thinkingConfig) ||
    thinkingConfig.thinkingLevel !== undefined ||
    thinkingConfig.thinkingBudget !== 128
  ) {
    throw new Error(
      "Gemini 2.5 config normalization changed compatible fields",
    );
  }
});

Deno.test("validates and delegates a bounded AI request with trace correlation", async () => {
  let captured: unknown;
  const handler = createNabiAiGenerateHandler({
    authenticate: async () => "user-a",
    rateLimit: async () => true,
    generate: async (input) => {
      captured = input;
      return "Nabi trả lời.";
    },
  });
  const response = await handler(request(validBody));
  if (response.status !== 200) {
    throw new Error(`expected 200, got ${response.status}`);
  }
  const body = await response.json();
  if (body.success !== true || body.text !== "Nabi trả lời.") {
    throw new Error("response was not normalized");
  }
  if ((captured as { userId: string }).userId !== "user-a") {
    throw new Error("user context missing");
  }
  if ((captured as { traceId: string }).traceId !== "test-ai-trace-001") {
    throw new Error("trace id was not forwarded to provider");
  }
  if (response.headers.get("x-ai-trace-id") !== "test-ai-trace-001") {
    throw new Error("trace id response header missing");
  }
});

Deno.test("allows guest generation but applies the same rate-limit gate", async () => {
  let seenKey = "";
  const handler = createNabiAiGenerateHandler({
    authenticate: async () => null,
    rateLimit: async (key) => {
      seenKey = key;
      return false;
    },
    generate: async () => "should not run",
  });
  const response = await handler(request(validBody));
  if (response.status !== 429 || seenKey !== "ip:127.0.0.1") {
    throw new Error("guest rate limit was not enforced");
  }
});

Deno.test("rejects malformed or oversized requests without invoking provider", async () => {
  let invoked = false;
  const handler = createNabiAiGenerateHandler({
    authenticate: async () => null,
    rateLimit: async () => true,
    generate: async () => {
      invoked = true;
      return "unexpected";
    },
  });
  const malformed = await handler(request({ ...validBody, contents: [] }));
  if (malformed.status !== 400) {
    throw new Error(`expected 400, got ${malformed.status}`);
  }
  const oversized = await handler(request({
    ...validBody,
    contents: [{ role: "user", parts: [{ text: "x".repeat(50_000) }] }],
  }));
  if (oversized.status !== 413 || invoked) {
    throw new Error("unsafe request reached provider");
  }
});

Deno.test("does not return false success when provider fails", async () => {
  const handler = createNabiAiGenerateHandler({
    authenticate: async () => "user-a",
    rateLimit: async () => true,
    generate: async () => {
      throw new Error("provider_403");
    },
  });
  const response = await handler(request(validBody));
  if (response.status !== 502) {
    throw new Error(`expected 502, got ${response.status}`);
  }
  if (response.headers.get("x-ai-trace-id") !== "test-ai-trace-001") {
    throw new Error("failed provider response lost trace correlation");
  }
});

Deno.test("normalizes provider status classes without exposing provider details", async () => {
  for (
    const providerCode of [
      "provider_401",
      "provider_403",
      "provider_404",
      "provider_429",
      "provider_500",
      "provider_network_error",
      "provider_empty_response",
    ]
  ) {
    const handler = createNabiAiGenerateHandler({
      authenticate: async () => null,
      rateLimit: async () => true,
      generate: async () => {
        throw new Error(providerCode);
      },
    });
    const response = await handler(request(validBody, {
      "x-ai-trace-id": `trace-${providerCode}`,
    }));
    if (response.status !== 502) {
      throw new Error(`${providerCode} did not map to 502`);
    }
    const body = await response.json();
    if (
      body.success !== false ||
      body.message !== "Dịch vụ AI tạm thời chưa sẵn sàng."
    ) {
      throw new Error(`${providerCode} leaked or changed the safe error body`);
    }
    if (response.headers.get("x-ai-trace-id") !== `trace-${providerCode}`) {
      throw new Error(`${providerCode} lost trace correlation`);
    }
  }
});

Deno.test("rejects empty and oversized generated responses", async () => {
  const responses = ["", "x".repeat(40_001)];
  for (const generated of responses) {
    const handler = createNabiAiGenerateHandler({
      authenticate: async () => null,
      rateLimit: async () => true,
      generate: async () => generated,
    });
    const response = await handler(request(validBody));
    if (response.status !== 502) {
      throw new Error("invalid generated response was not rejected");
    }
  }
});

Deno.test("normalizes unexpected handler failures with the same trace id", async () => {
  const handler = createNabiAiGenerateHandler({
    authenticate: async () => {
      throw new TypeError("auth dependency failed");
    },
    rateLimit: async () => true,
    generate: async () => "unused",
  });
  const response = await handler(request(validBody));
  if (response.status !== 500) {
    throw new Error(`expected 500, got ${response.status}`);
  }
  if (response.headers.get("x-ai-trace-id") !== "test-ai-trace-001") {
    throw new Error("unexpected failure response lost trace correlation");
  }
});

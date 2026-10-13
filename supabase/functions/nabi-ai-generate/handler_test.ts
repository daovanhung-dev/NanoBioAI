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
  generation_config: { temperature: 0.2 },
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
  operation: null,
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

Deno.test("normalizes thinking budget when escalating to Gemini 3.8 Flash", () => {
  const resolved = resolveGeminiProviderRequest(
    {
      ...providerInput,
      model: "gemini-3.8-flash",
      generationConfig: {
        maxOutputTokens: 65_536,
        thinkingConfig: { thinkingBudget: 1024 },
      },
    },
    new Set(["gemini-3.8-flash"]),
    "gemini-2.5-flash",
  );
  const thinkingConfig = resolved.generationConfig.thinkingConfig;
  if (
    resolved.model !== "gemini-3.8-flash" ||
    !isRecord(thinkingConfig) ||
    thinkingConfig.thinkingBudget !== undefined ||
    thinkingConfig.thinkingLevel !== "medium"
  ) {
    throw new Error("Gemini 3.8 did not receive its compatible thinking level");
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

Deno.test("accepts only the two M32 operations", async () => {
  let seenOperation: string | null = null;
  const handler = createNabiAiGenerateHandler({
    authenticate: async () => "user-a",
    rateLimit: async () => true,
    generate: async (input) => {
      seenOperation = input.operation;
      return '{"days":[]}';
    },
  });
  const response = await handler(request({
    ...validBody,
    operation: "fitness_training_generate",
  }));
  if (
    response.status !== 200 || seenOperation !== "fitness_training_generate"
  ) {
    throw new Error("M32 generation operation was not forwarded");
  }

  let invoked = false;
  const rejectingHandler = createNabiAiGenerateHandler({
    authenticate: async () => "user-a",
    rateLimit: async () => true,
    generate: async () => {
      invoked = true;
      return "should not run";
    },
  });
  const rejected = await rejectingHandler(request({
    ...validBody,
    operation: "fitness_training_unknown",
  }));
  if (rejected.status !== 400 || invoked) {
    throw new Error("unsupported AI operation reached provider");
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

Deno.test("allows content above 32k and rejects requests above the byte cap", async () => {
  let receivedTextLength = 0;
  const handler = createNabiAiGenerateHandler({
    authenticate: async () => null,
    rateLimit: async () => true,
    generate: async (input) => {
      const contents = input.contents as Array<{
        parts?: Array<{ text?: string }>;
      }>;
      receivedTextLength = contents[0]?.parts?.[0]?.text?.length ?? 0;
      return "accepted";
    },
  });
  const malformed = await handler(request({ ...validBody, contents: [] }));
  if (malformed.status !== 400) {
    throw new Error(`expected 400, got ${malformed.status}`);
  }
  const overCharacterLimit = await handler(request({
    ...validBody,
    contents: [{ role: "user", parts: [{ text: "x".repeat(50_000) }] }],
  }));
  if (overCharacterLimit.status !== 200 || receivedTextLength !== 50_000) {
    throw new Error("content above the old 32k cap was not delegated intact");
  }
  const overByteLimit = await handler(request({
    ...validBody,
    contents: [{ role: "user", parts: [{ text: "x".repeat(1_500_000) }] }],
  }));
  const overByteLimitBody = await overByteLimit.json();
  if (
    overByteLimit.status !== 413 ||
    overByteLimitBody.code !== "REQUEST_TOO_LARGE" ||
    !String(overByteLimitBody.message).includes("giới hạn an toàn") ||
    receivedTextLength !== 50_000
  ) {
    throw new Error("request above the finite byte cap reached provider");
  }
});

Deno.test("maps Gemini token limit failures to a clear 413 response", async () => {
  const handler = createNabiAiGenerateHandler({
    authenticate: async () => "user-a",
    rateLimit: async () => true,
    generate: async () => {
      throw new Error("provider_input_token_limit");
    },
  });
  const response = await handler(request(validBody));
  const body = await response.json();
  if (
    response.status !== 413 ||
    body.code !== "MODEL_CONTEXT_LIMIT_EXCEEDED" ||
    !String(body.message).includes("giới hạn token")
  ) {
    throw new Error("model token limit did not return a clear response");
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

Deno.test("returns only safe provider failure phase and status metadata", async () => {
  const handler = createNabiAiGenerateHandler({
    authenticate: async () => "user-a",
    rateLimit: async () => true,
    generate: async () => {
      const error = new Error("provider_400") as Error & {
        providerPhase: string;
        providerStatus: string;
      };
      error.providerPhase = "count_tokens";
      error.providerStatus = "INVALID_ARGUMENT";
      throw error;
    },
  });
  const response = await handler(request(validBody));
  const body = await response.json();
  if (
    body.providerErrorCode !== "provider_400" ||
    body.providerPhase !== "count_tokens" ||
    body.providerStatus !== "INVALID_ARGUMENT"
  ) {
    throw new Error("safe provider diagnostics were not returned");
  }

  const unsafeHandler = createNabiAiGenerateHandler({
    authenticate: async () => "user-a",
    rateLimit: async () => true,
    generate: async () => {
      const error = new Error("provider_400") as Error & {
        providerPhase: string;
        providerStatus: string;
      };
      error.providerPhase = "user_prompt";
      error.providerStatus = "invalid argument with user text";
      throw error;
    },
  });
  const unsafeBody = await (await unsafeHandler(request(validBody))).json();
  if (
    "providerPhase" in unsafeBody || "providerStatus" in unsafeBody
  ) {
    throw new Error("unsafe provider metadata was returned");
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
      "provider_timeout",
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
    const body = await response.json();
    const expectedStatus = providerCode === "provider_429"
      ? 429
      : providerCode === "provider_500" ||
          providerCode === "provider_network_error"
      ? 503
      : providerCode === "provider_timeout"
      ? 504
      : 502;
    const expectedCode = providerCode === "provider_429"
      ? "PROVIDER_RATE_LIMITED"
      : providerCode === "provider_500"
      ? "PROVIDER_TEMPORARY_FAILURE"
      : providerCode === "provider_network_error"
      ? "PROVIDER_NETWORK_ERROR"
      : providerCode === "provider_timeout"
      ? "PROVIDER_TIMEOUT"
      : "AI_UNAVAILABLE";
    if (response.status !== expectedStatus) {
      throw new Error(
        `${providerCode} mapped to ${response.status}, expected ${expectedStatus}`,
      );
    }
    if (
      body.success !== false ||
      body.code !== expectedCode ||
      body.providerErrorCode !== providerCode ||
      typeof body.message !== "string" ||
      body.message.includes(providerCode)
    ) {
      throw new Error(`${providerCode} leaked or changed the safe error body`);
    }
    if (response.headers.get("x-ai-trace-id") !== `trace-${providerCode}`) {
      throw new Error(`${providerCode} lost trace correlation`);
    }
  }
});

Deno.test("rejects provider output truncated by MAX_TOKENS with a typed code", async () => {
  const handler = createNabiAiGenerateHandler({
    authenticate: async () => "user-a",
    rateLimit: async () => true,
    generate: async () => {
      throw new Error("provider_max_tokens");
    },
  });
  const response = await handler(request(validBody));
  const body = await response.json();
  if (
    response.status !== 502 ||
    body.success !== false ||
    body.code !== "OUTPUT_TRUNCATED"
  ) {
    throw new Error("MAX_TOKENS was not mapped to OUTPUT_TRUNCATED");
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

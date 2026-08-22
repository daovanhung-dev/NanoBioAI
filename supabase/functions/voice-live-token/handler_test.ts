import {
  assertEquals,
  assertFalse,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  createGeminiEphemeralTokenRequest,
  createVoiceLiveTokenHandler,
  type LiveTokenDependencies,
  parseGeminiEphemeralTokenResponse,
} from "./handler.ts";

const now = new Date("2026-08-22T00:00:00.000Z");

Deno.test("rejects missing or invalid Supabase JWT before paid access or token work", async () => {
  let paidAccessCalls = 0;
  let tokenCalls = 0;
  const handler = createVoiceLiveTokenHandler(dependencies({
    authenticate: (header) =>
      Promise.resolve(
        header == "Bearer valid-jwt" ? "user-1" : null,
      ),
    hasPaidAccess: () => {
      paidAccessCalls++;
      return Promise.resolve(true);
    },
    createEphemeralToken: () => {
      tokenCalls++;
      return Promise.resolve({ value: "never", expiresAt: now.toISOString() });
    },
  }));

  for (const authorization of [null, "Bearer forged-jwt"]) {
    const response = await handler(request({ authorization }));
    assertEquals(response.status, 401);
    assertEquals(await response.json(), { error: "unauthorized" });
  }
  assertEquals(paidAccessCalls, 0);
  assertEquals(tokenCalls, 0);
});

Deno.test("denies Free access without minting an ephemeral token", async () => {
  let tokenCalls = 0;
  const handler = createVoiceLiveTokenHandler(dependencies({
    hasPaidAccess: () => Promise.resolve(false),
    createEphemeralToken: () => {
      tokenCalls++;
      return Promise.resolve({ value: "never", expiresAt: now.toISOString() });
    },
  }));

  const response = await handler(request());

  assertEquals(response.status, 403);
  assertEquals(await response.json(), { error: "plus_required" });
  assertEquals(tokenCalls, 0);
});

Deno.test("mints a paid member token without request ids or usage quota work", async () => {
  const calls: string[] = [];
  const handler = createVoiceLiveTokenHandler(dependencies({
    authenticate: () => {
      calls.push("authenticate");
      return Promise.resolve("user-1");
    },
    hasPaidAccess: (userId, authorization) => {
      calls.push(`access:${userId}:${authorization}`);
      return Promise.resolve(true);
    },
    createEphemeralToken: () => {
      calls.push("mint");
      return Promise.resolve({
        value: "auth-token-credential",
        expiresAt: "2026-08-22T00:15:00.000Z",
      });
    },
  }));

  const response = await handler(request({ body: {} }));

  assertEquals(response.status, 200);
  assertEquals(calls, [
    "authenticate",
    "access:user-1:Bearer valid-jwt",
    "mint",
  ]);
  assertEquals(await response.json(), {
    token: "auth-token-credential",
    model: "gemini-3.1-flash-live-preview",
    expiresAt: "2026-08-22T00:15:00.000Z",
  });
});

Deno.test("does not depend on a client session id", async () => {
  const handler = createVoiceLiveTokenHandler(dependencies());

  const response = await handler(request({
    body: { sessionId: "legacy-client-value-is-ignored" },
  }));

  assertEquals(response.status, 200);
});

Deno.test("keeps paid-access lookup failures retry-safe and secret-free", async () => {
  const handler = createVoiceLiveTokenHandler(dependencies({
    hasPaidAccess: () =>
      Promise.reject(new Error("membership transport failure")),
  }));

  const response = await handler(request());

  assertEquals(response.status, 503);
  assertEquals(await response.json(), { error: "voice_live_unavailable" });
});

Deno.test("does not reveal provider secrets when token issuance fails", async () => {
  const handler = createVoiceLiveTokenHandler(dependencies({
    createEphemeralToken: () =>
      Promise.reject(new Error("GEMINI_API_KEY=must-not-leak")),
  }));

  const response = await handler(request());
  const responseText = await response.text();

  assertEquals(response.status, 503);
  assertEquals(responseText, '{"error":"voice_live_unavailable"}');
  assertFalse(responseText.includes("must-not-leak"));
});

Deno.test("creates an AuthToken request locked to Gemini Live audio", () => {
  const tokenRequest = createGeminiEphemeralTokenRequest({
    model: "gemini-3.1-flash-live-preview",
    now,
    systemInstruction: "Nabi system instruction",
  });

  assertEquals(tokenRequest, {
    uses: 1,
    newSessionExpireTime: "2026-08-22T00:01:00.000Z",
    expireTime: "2026-08-22T00:15:00.000Z",
    fieldMask: "model,generationConfig,systemInstruction",
    bidiGenerateContentSetup: {
      model: "models/gemini-3.1-flash-live-preview",
      generationConfig: {
        responseModalities: ["AUDIO"],
      },
      systemInstruction: {
        parts: [{ text: "Nabi system instruction" }],
      },
    },
  });
});

Deno.test("accepts only AuthToken name as the ephemeral credential", () => {
  assertEquals(
    parseGeminiEphemeralTokenResponse({
      name: "auth-token-credential",
      expireTime: "2026-08-22T00:15:00.000Z",
    }),
    {
      value: "auth-token-credential",
      expiresAt: "2026-08-22T00:15:00.000Z",
    },
  );
  assertEquals(
    parseGeminiEphemeralTokenResponse({
      token: "legacy-token-field",
      expireTime: "2026-08-22T00:15:00.000Z",
    }),
    null,
  );
});

Deno.test("returns only the ephemeral credential and never API-key data", async () => {
  const handler = createVoiceLiveTokenHandler(dependencies({
    createEphemeralToken: () =>
      Promise.resolve({
        value: "ephemeral-token-only",
        expiresAt: "2026-08-22T00:15:00.000Z",
      }),
  }));
  const response = await handler(request());
  const responseText = await response.text();

  assertEquals(response.status, 200);
  assertStringIncludes(responseText, "ephemeral-token-only");
  assertFalse(responseText.includes("GEMINI_API_KEY"));
  assertFalse(responseText.includes("audio/pcm"));
});

function dependencies(
  overrides: Partial<LiveTokenDependencies> = {},
): LiveTokenDependencies {
  return {
    authenticate: (authorization) =>
      Promise.resolve(
        authorization == "Bearer valid-jwt" ? "user-1" : null,
      ),
    hasPaidAccess: () => Promise.resolve(true),
    createEphemeralToken: () =>
      Promise.resolve({
        value: "ephemeral-token",
        expiresAt: "2026-08-22T00:15:00.000Z",
      }),
    now: () => now,
    ...overrides,
  };
}

function request({
  authorization = "Bearer valid-jwt",
  body = {},
}: {
  authorization?: string | null;
  body?: Record<string, unknown>;
} = {}): Request {
  const headers = new Headers({ "Content-Type": "application/json" });
  if (authorization != null) headers.set("Authorization", authorization);
  return new Request("https://example.test/voice-live-token", {
    method: "POST",
    headers,
    body: JSON.stringify(body),
  });
}

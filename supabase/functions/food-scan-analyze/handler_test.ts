import { createFoodScanAnalyzeHandler, inspectContents } from "./handler.ts";

function request(
  body: Record<string, unknown> = visionBody,
  headers: Record<string, string> = {},
  method = "POST",
) {
  return new Request("https://example.test/food-scan-analyze", {
    method,
    headers: {
      "content-type": "application/json",
      "x-forwarded-for": "127.0.0.1",
      "x-ai-trace-id": "food-scan-test-001",
      ...headers,
    },
    body: method === "GET" ? undefined : JSON.stringify(body),
  });
}

const visionContents = [
  {
    role: "user",
    parts: [
      {
        inlineData: {
          mimeType: "image/jpeg",
          data: "synthetic-jpeg-data",
        },
      },
      { text: "Phân tích ảnh món ăn." },
    ],
  },
];

const healthContents = [
  {
    role: "user",
    parts: [{ text: "Đánh giá bữa ăn theo health context." }],
  },
];

const visionBody = {
  operation: "vision",
  model: "gemini-2.5-flash",
  contents: visionContents,
  generation_config: {
    maxOutputTokens: 256,
    responseMimeType: "application/json",
  },
  system_instruction: null,
};

const healthBody = {
  ...visionBody,
  operation: "health",
  contents: healthContents,
};

function testHandler(options: {
  authenticated?: string | null;
  hasPlusAccess?: boolean;
  allowed?: boolean;
  generate?: (input: unknown) => Promise<string>;
}) {
  return createFoodScanAnalyzeHandler({
    authenticate: async () =>
      options.authenticated === undefined ? "user-plus" : options.authenticated,
    hasPlusAccess: async () => options.hasPlusAccess ?? true,
    rateLimit: async () => options.allowed ?? true,
    generate: async (input) => {
      if (options.generate != null) return options.generate(input);
      return '{"ok":true}';
    },
  });
}

async function responseBody(
  response: Response,
): Promise<Record<string, unknown>> {
  return await response.json() as Record<string, unknown>;
}

Deno.test("rejects methods other than POST", async () => {
  const response = await testHandler({})(request({}, {}, "GET"));
  const body = await responseBody(response);
  if (response.status !== 405 || body.code !== "METHOD_NOT_ALLOWED") {
    throw new Error("unsupported method was not rejected");
  }
});

Deno.test("requires a valid authenticated user", async () => {
  const response = await testHandler({ authenticated: null })(request());
  const body = await responseBody(response);
  if (response.status !== 401 || body.code !== "AUTHENTICATION_REQUIRED") {
    throw new Error("missing authentication was not rejected");
  }
});

Deno.test("requires Plus or FamilyPlus access", async () => {
  let invoked = false;
  const response = await testHandler({
    hasPlusAccess: false,
    generate: async () => {
      invoked = true;
      return "unexpected";
    },
  })(request());
  const body = await responseBody(response);
  if (response.status !== 403 || body.code !== "PLUS_REQUIRED" || invoked) {
    throw new Error("paid access was not enforced before provider invocation");
  }
});

Deno.test("rejects an unknown operation", async () => {
  const response = await testHandler({})(request({
    ...visionBody,
    operation: "other",
  }));
  const body = await responseBody(response);
  if (response.status !== 400 || body.code !== "INVALID_OPERATION") {
    throw new Error("unknown operation was not rejected");
  }
});

Deno.test("requires exactly one non-empty image for vision", async () => {
  const response = await testHandler({})(request({
    ...visionBody,
    contents: [{ role: "user", parts: [{ text: "Không có ảnh." }] }],
  }));
  const body = await responseBody(response);
  if (response.status !== 400 || body.code !== "INVALID_CONTENT_SHAPE") {
    throw new Error("vision request without an image was accepted");
  }
});

Deno.test("rejects oversized image content", async () => {
  const response = await testHandler({})(request({
    ...visionBody,
    contents: [{
      role: "user",
      parts: [
        {
          inlineData: {
            mimeType: "image/jpeg",
            data: "x".repeat(1_300_001),
          },
        },
        { text: "Ảnh lớn." },
      ],
    }],
  }));
  const body = await responseBody(response);
  if (response.status !== 413 || body.code !== "CONTENT_TOO_LARGE") {
    throw new Error("oversized request did not hit the request limit");
  }
});

Deno.test("applies the per-user rate limit before provider invocation", async () => {
  let invoked = false;
  const response = await testHandler({
    allowed: false,
    generate: async () => {
      invoked = true;
      return "unexpected";
    },
  })(request());
  const body = await responseBody(response);
  if (response.status !== 429 || body.code !== "RATE_LIMITED" || invoked) {
    throw new Error("rate limit was not enforced");
  }
});

Deno.test("delegates a valid vision request with operation and trace id", async () => {
  let captured: Record<string, unknown> | null = null;
  const response = await testHandler({
    generate: async (input) => {
      captured = input as Record<string, unknown>;
      return '{"is_food_image":true,"foods":[]}';
    },
  })(request());
  const body = await responseBody(response);
  const seen = captured as Record<string, unknown> | null;
  if (
    response.status !== 200 ||
    body.success !== true ||
    body.text !== '{"is_food_image":true,"foods":[]}' ||
    seen?.operation !== "vision" ||
    seen?.traceId !== "food-scan-test-001" ||
    seen?.userId !== "user-plus"
  ) {
    throw new Error("valid vision request was not delegated correctly");
  }
  if (response.headers.get("x-ai-trace-id") !== "food-scan-test-001") {
    throw new Error("trace id response header missing");
  }
});

Deno.test("delegates a valid health request without image parts", async () => {
  let captured: Record<string, unknown> | null = null;
  const response = await testHandler({
    generate: async (input) => {
      captured = input as Record<string, unknown>;
      return '{"overall":{"status":"can_nhac"}}';
    },
  })(request(healthBody));
  const seen = captured as Record<string, unknown> | null;
  if (
    response.status !== 200 ||
    seen?.operation !== "health" ||
    JSON.stringify(seen?.contents).includes("inlineData")
  ) {
    throw new Error("valid health request was not delegated correctly");
  }
});

Deno.test("does not expose provider failures as a false success", async () => {
  const response = await testHandler({
    generate: async () => {
      throw new Error("provider_429");
    },
  })(request());
  const body = await responseBody(response);
  if (
    response.status !== 502 ||
    body.success !== false ||
    body.message !== "Dịch vụ AI tạm thời chưa sẵn sàng."
  ) {
    throw new Error("provider failure was not normalized safely");
  }
});

Deno.test("inspects image and text content without retaining payload data", () => {
  const shape = inspectContents(visionContents);
  if (
    !shape.hasText ||
    shape.textLength <= 0 ||
    shape.imageCount !== 1 ||
    shape.imageDataLength !== "synthetic-jpeg-data".length ||
    !shape.hasImageMimeType ||
    !shape.hasImageData
  ) {
    throw new Error("content shape was not summarized correctly");
  }
});

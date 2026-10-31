export type FoodEvidenceInput = {
  ingredients: string[];
};

export type FoodEvidenceDeps = {
  authenticate: (authorization: string | null) => Promise<string | null>;
  lookup: (ingredient: string) => Promise<Record<string, unknown>>;
  rateLimit: (userId: string) => Promise<boolean>;
};

const MAX_BODY_LENGTH = 12_000;
const MAX_INGREDIENTS = 30;
const MAX_INGREDIENT_LENGTH = 120;
const SAFE_TRACE_ID = /^[A-Za-z0-9._:-]{1,100}$/;

export function parseFoodEvidenceInput(value: unknown): FoodEvidenceInput {
  if (
    value == null || typeof value !== "object" || Array.isArray(value)
  ) {
    throw new Error("invalid_body");
  }
  const body = value as Record<string, unknown>;
  if (Object.keys(body).some((key) => key !== "ingredients")) {
    throw new Error("unsupported_field");
  }
  if (
    !Array.isArray(body.ingredients) || body.ingredients.length === 0 ||
    body.ingredients.length > MAX_INGREDIENTS
  ) {
    throw new Error("invalid_ingredients");
  }
  const ingredients: string[] = [];
  const seen = new Set<string>();
  for (const item of body.ingredients) {
    if (
      typeof item !== "string" || item.trim().length === 0 ||
      item.trim().length > MAX_INGREDIENT_LENGTH
    ) {
      throw new Error("invalid_ingredient");
    }
    const normalized = item.trim().toLocaleLowerCase();
    if (!seen.has(normalized)) {
      seen.add(normalized);
      ingredients.push(item.trim());
    }
  }
  return { ingredients };
}

export function createNabiFoodEvidenceHandler(deps: FoodEvidenceDeps) {
  return async (request: Request): Promise<Response> => {
    const traceId = resolveTraceId(request.headers.get("x-ai-trace-id"));
    if (request.method !== "POST") {
      return json(405, { error: "METHOD_NOT_ALLOWED", trace_id: traceId });
    }

    const userId = await deps.authenticate(
      request.headers.get("Authorization"),
    );
    if (!userId) {
      return json(401, { error: "AUTHENTICATION_REQUIRED", trace_id: traceId });
    }
    if (!await deps.rateLimit(userId)) {
      return json(429, { error: "RATE_LIMITED", trace_id: traceId });
    }

    let raw: string;
    try {
      raw = await request.text();
    } catch {
      return json(400, { error: "INVALID_BODY", trace_id: traceId });
    }
    if (raw.length > MAX_BODY_LENGTH) {
      return json(413, { error: "REQUEST_TOO_LARGE", trace_id: traceId });
    }

    let input: FoodEvidenceInput;
    try {
      input = parseFoodEvidenceInput(JSON.parse(raw));
    } catch (error) {
      const code = error instanceof Error ? error.message : "invalid_body";
      return json(400, { error: code.toUpperCase(), trace_id: traceId });
    }

    try {
      const foods = await Promise.all(
        input.ingredients.map((ingredient) => deps.lookup(ingredient)),
      );
      return json(200, { foods, trace_id: traceId });
    } catch {
      return json(503, { error: "FOOD_SOURCE_UNAVAILABLE", trace_id: traceId });
    }
  };
}

function resolveTraceId(value: string | null): string {
  return value && SAFE_TRACE_ID.test(value) ? value : crypto.randomUUID();
}

function json(status: number, value: unknown): Response {
  return new Response(JSON.stringify(value), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

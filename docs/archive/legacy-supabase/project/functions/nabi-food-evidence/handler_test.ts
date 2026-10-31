import {
  createNabiFoodEvidenceHandler,
  parseFoodEvidenceInput,
} from "./handler.ts";

function request(body: unknown, headers: Record<string, string> = {}) {
  return new Request("https://example.test/nabi-food-evidence", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: "Bearer test-token",
      ...headers,
    },
    body: JSON.stringify(body),
  });
}

Deno.test("accepts only bounded ingredient names", () => {
  const input = parseFoodEvidenceInput({
    ingredients: ["  Rau muống ", "rau muống", "200g gạo lứt"],
  });
  if (input.ingredients.length !== 2 || input.ingredients[0] !== "Rau muống") {
    throw new Error("ingredient list was not normalized and deduplicated");
  }
  for (
    const value of [
      { ingredients: ["gạo"], conditions: ["diabetes"] },
      { ingredients: ["gạo"], user_id: "user-1" },
      { ingredients: new Array(31).fill("food") },
    ]
  ) {
    try {
      parseFoodEvidenceInput(value);
      throw new Error("unsafe request was accepted");
    } catch (error) {
      if (
        error instanceof Error &&
        error.message === "unsafe request was accepted"
      ) {
        throw error;
      }
    }
  }
});

Deno.test("requires authenticated calls and returns source results only", async () => {
  let lookupCount = 0;
  const handler = createNabiFoodEvidenceHandler({
    authenticate: async () => "user-1",
    rateLimit: async () => true,
    lookup: async (ingredient) => {
      lookupCount++;
      return { queried_name: ingredient, evidence_status: "source_match" };
    },
  });
  const response = await handler(request({ ingredients: ["yến mạch"] }));
  const payload = await response.json();
  if (response.status !== 200 || lookupCount !== 1) {
    throw new Error("authenticated evidence request failed");
  }
  if (payload.foods[0].queried_name !== "yến mạch") {
    throw new Error("source result was not returned");
  }

  const denied = createNabiFoodEvidenceHandler({
    authenticate: async () => null,
    rateLimit: async () => true,
    lookup: async () => {
      throw new Error("lookup should not be reached");
    },
  });
  if ((await denied(request({ ingredients: ["rice"] }))).status !== 401) {
    throw new Error("unauthenticated request was not rejected");
  }
});

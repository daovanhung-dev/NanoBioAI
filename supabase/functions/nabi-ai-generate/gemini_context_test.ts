import {
  assertGeminiContextWithinLimits,
  inspectGeminiRequestContext,
} from "./gemini_context.ts";

Deno.test("counts the complete Gemini request without a live provider call", async () => {
  const requests: Array<{ url: string; init?: RequestInit }> = [];
  const fetcher: typeof fetch = async (input, init) => {
    const url = String(input);
    requests.push({ url, init });
    if (url.endsWith(":countTokens")) {
      return Response.json({ totalTokens: 41 });
    }
    return Response.json({ inputTokenLimit: 1000, outputTokenLimit: 512 });
  };
  const context = await inspectGeminiRequestContext({
    model: "gemini-2.5-flash",
    apiKey: "test-only-key",
    contents: [{ role: "user", parts: [{ text: "test prompt" }] }],
    generationConfig: { maxOutputTokens: 128 },
    systemInstruction: "test system instruction",
    fetcher,
  });

  if (context.inputTokens !== 41 || requests.length !== 2) {
    throw new Error(
      "model metadata or complete request token count is missing",
    );
  }
  const countBody = JSON.parse(String(requests[1].init?.body));
  const countedRequest = countBody.generateContentRequest;
  if (
    countedRequest.model !== "models/gemini-2.5-flash" ||
    countedRequest.systemInstruction?.parts?.[0]?.text !==
      "test system instruction" ||
    countedRequest.generationConfig?.maxOutputTokens !== 128
  ) {
    throw new Error("system instruction or generation config was not counted");
  }
  assertGeminiContextWithinLimits(context, { maxOutputTokens: 128 });
});

Deno.test("rejects input and requested output above the model's published limits", () => {
  const context = {
    inputTokens: 101,
    inputTokenLimit: 100,
    outputTokenLimit: 10,
  };
  let inputLimitRejected = false;
  try {
    assertGeminiContextWithinLimits(context, { maxOutputTokens: 10 });
  } catch (error) {
    inputLimitRejected = error instanceof Error &&
      error.message === "provider_input_token_limit";
  }
  if (!inputLimitRejected) throw new Error("input token overflow was accepted");

  let outputLimitRejected = false;
  try {
    assertGeminiContextWithinLimits(
      { ...context, inputTokens: 100 },
      { maxOutputTokens: 11 },
    );
  } catch (error) {
    outputLimitRejected = error instanceof Error &&
      error.message === "provider_output_token_limit";
  }
  if (!outputLimitRejected) {
    throw new Error("output token overflow was accepted");
  }
});

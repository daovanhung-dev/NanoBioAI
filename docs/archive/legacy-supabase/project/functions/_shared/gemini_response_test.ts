import { extractGeminiResponse } from "./gemini_response.ts";

Deno.test("extracts all visible text parts in order", () => {
  const result = extractGeminiResponse(JSON.stringify({
    candidates: [{
      content: {
        parts: [
          { thought: true, text: "Không hiển thị" },
          { text: "Phần một." },
          { text: "Phần hai." },
        ],
      },
    }],
  }));
  if (result.text !== "Phần một.\nPhần hai.") {
    throw new Error("response text parts were not joined in order");
  }
});

Deno.test("reports MAX_TOKENS even when a partial text exists", () => {
  const result = extractGeminiResponse({
    candidates: [{
      content: { parts: [{ text: "Phần đầu" }] },
      finishReason: "MAX_TOKENS",
    }],
  });
  if (result.text !== "Phần đầu" || result.finishReason !== "MAX_TOKENS") {
    throw new Error("partial MAX_TOKENS response was not reported");
  }
});

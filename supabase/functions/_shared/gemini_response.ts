export type GeminiResponseExtraction = {
  text: string;
  finishReason: string | null;
  blockReason: string | null;
};

/**
 * Extracts every visible Gemini text part in provider order. Thought parts
 * are deliberately excluded, and MAX_TOKENS is reported even when text was
 * emitted before the provider stopped.
 */
export function extractGeminiResponse(
  payload: unknown,
): GeminiResponseExtraction {
  const root = asRecord(payload);
  const candidates = root != null && Array.isArray(root.candidates)
    ? root.candidates
    : [];
  const segments: string[] = [];
  let finishReason: string | null = null;

  for (const candidate of candidates) {
    const candidateRecord = asRecord(candidate);
    if (candidateRecord == null) continue;
    const candidateFinishReason = stringValue(candidateRecord.finishReason);
    if (finishReason == null && candidateFinishReason != null) {
      finishReason = candidateFinishReason;
    }
    if (candidateFinishReason?.toUpperCase() === "MAX_TOKENS") {
      finishReason = candidateFinishReason;
    }

    const content = asRecord(candidateRecord.content);
    const parts = content != null && Array.isArray(content.parts)
      ? content.parts
      : [];
    for (const part of parts) {
      const partRecord = asRecord(part);
      if (partRecord == null || partRecord.thought === true) continue;
      if (typeof partRecord.text === "string") segments.push(partRecord.text);
    }
  }

  const promptFeedback = asRecord(root?.promptFeedback);
  return {
    text: segments.join("\n").trim(),
    finishReason,
    blockReason: stringValue(promptFeedback?.blockReason),
  };
}

function asRecord(value: unknown): Record<string, unknown> | null {
  if (typeof value === "string") {
    try {
      value = JSON.parse(value);
    } catch {
      return null;
    }
  }
  return value != null && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null;
}

function stringValue(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const normalized = value.trim();
  return normalized.length === 0 ? null : normalized;
}

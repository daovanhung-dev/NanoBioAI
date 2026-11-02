import { afterEach, describe, expect, it, vi } from "vitest";
import { readRuntimeConfig } from "./config";

describe("Admin Web runtime configuration", () => {
  afterEach(() => vi.unstubAllEnvs());

  it("uses the production API origin without a versioned path", () => {
    vi.stubEnv("VITE_API_BASE_URL", "https://nanobio.s2w.click");

    expect(readRuntimeConfig()).toEqual({
      apiBaseUrl: "https://nanobio.s2w.click",
    });
  });

  it("rejects an API-prefixed base URL", () => {
    vi.stubEnv("VITE_API_BASE_URL", "https://nanobio.s2w.click/api/v1");

    expect(readRuntimeConfig).toThrow(
      "VITE_API_BASE_URL chỉ nhận địa chỉ gốc của API.",
    );
  });
});

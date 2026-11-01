import { afterEach, describe, expect, it, vi } from "vitest";
import { BackendClient } from "./backend-client";

function testStorage(): Pick<Storage, "getItem" | "setItem" | "removeItem"> {
  return {
    getItem: () => null,
    setItem: () => undefined,
    removeItem: () => undefined,
  };
}

function response(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

describe("BackendClient readiness", () => {
  afterEach(() => vi.unstubAllGlobals());

  it("binds the default fetch function to globalThis", async () => {
    let receiver: unknown;
    const fetchMock = vi.fn(function (this: unknown) {
      receiver = this;
      return Promise.resolve(response({ status: "ready", database: "ready" }));
    });
    vi.stubGlobal("fetch", fetchMock);

    const client = new BackendClient("http://127.0.0.1:8000", testStorage());
    const result = await client.checkReadiness();

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(receiver).toBe(globalThis);
    expect(result.ready).toBe(true);
  });

  it("reports the backend readiness message when the API is unavailable", async () => {
    const fetchMock = vi.fn(async () =>
      response({ status: "not_ready", database: "unavailable", message: "Database unavailable" }, 503)
    );
    const client = new BackendClient("http://127.0.0.1:8000", testStorage(), fetchMock);

    const result = await client.checkReadiness();

    expect(result).toMatchObject({ ready: false, message: "Database unavailable" });
  });

  it("reports a connection failure without throwing", async () => {
    const client = new BackendClient(
      "http://127.0.0.1:8000",
      testStorage(),
      vi.fn(async () => {
        throw new TypeError("network unavailable");
      }),
    );

    const result = await client.checkReadiness();

    expect(result.ready).toBe(false);
    expect(result.message).toBe("Không kết nối được API.");
  });
});

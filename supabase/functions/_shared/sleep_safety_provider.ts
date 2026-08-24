export type SleepSafetyProviderChannel = "sms" | "voice" | "verification";
export type SleepSafetyProviderStatus =
  | "submitted"
  | "delivered"
  | "answered"
  | "failed"
  | "no_answer";

export interface SleepSafetyProviderResult {
  id: string;
  status: SleepSafetyProviderStatus;
}

export interface SleepSafetyProviderRequest {
  to: string;
  message: string;
  idempotencyKey: string;
  callbackUrl?: string;
  callbackToken?: string;
}

export interface SleepSafetyProvider {
  send(
    channel: SleepSafetyProviderChannel,
    request: SleepSafetyProviderRequest,
  ): Promise<SleepSafetyProviderResult>;
}

export interface GenericHttpProviderConfig {
  baseUrl: string;
  token: string;
  callbackUrl?: string;
  callbackToken?: string;
}

export function createGenericHttpSleepSafetyProvider(
  config: GenericHttpProviderConfig,
  fetchImpl: typeof fetch = fetch,
): SleepSafetyProvider {
  const baseUrl = config.baseUrl.replace(/\/+$/, "");
  return {
    async send(channel, request) {
      const endpoint = channel === "verification" ? "sms" : channel;
      const response = await fetchImpl(`${baseUrl}/${endpoint}`, {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: `Bearer ${config.token}`,
        },
        body: JSON.stringify({
          to: request.to,
          message: request.message,
          idempotency_key: request.idempotencyKey,
          callback_url: request.callbackUrl ?? config.callbackUrl,
          callback_token: request.callbackToken ?? config.callbackToken,
          metadata: { channel, source: "nanobio_sleep_safety" },
        }),
      });
      if (!response.ok) {
        return { id: "", status: "failed" };
      }
      const data = await response.json().catch(() => ({}));
      const status = normalizeStatus(data?.status);
      return {
        id: typeof data?.id === "string" ? data.id : "",
        status,
      };
    },
  };
}

export function normalizeStatus(value: unknown): SleepSafetyProviderStatus {
  switch (String(value ?? "").trim().toLowerCase()) {
    case "delivered":
      return "delivered";
    case "answered":
      return "answered";
    case "failed":
      return "failed";
    case "no_answer":
    case "noanswer":
      return "no_answer";
    default:
      return "submitted";
  }
}

export function isTerminalFailure(status: SleepSafetyProviderStatus): boolean {
  return status === "failed" || status === "no_answer";
}

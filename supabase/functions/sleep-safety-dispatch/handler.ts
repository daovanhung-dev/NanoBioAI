import type {
  SleepSafetyProvider,
  SleepSafetyProviderStatus,
} from "../_shared/sleep_safety_provider.ts";
import { isTerminalFailure } from "../_shared/sleep_safety_provider.ts";

export interface DispatchEvent {
  id: string;
  userId: string;
  detectedAt: string;
  response: string;
  escalationRequired: boolean;
}

export interface DispatchContact {
  id: string;
  phoneE164: string;
  priority: number;
}

export interface DispatchRow {
  id: string;
  contactId: string;
  priority: number;
  channel: "sms" | "voice";
  status: string;
  providerExternalId?: string | null;
}

export interface DispatchDependencies {
  authenticate(authorization: string | null): Promise<string | null>;
  getRuntimeConfig(): Promise<{ enabled: boolean; maxPerHour: number; freshnessSeconds: number }>;
  hasPaidAccess(userId: string): Promise<boolean>;
  getEvent(userId: string, eventId: string): Promise<DispatchEvent | null>;
  getVerifiedContacts(userId: string): Promise<DispatchContact[]>;
  countRecentRequests(userId: string): Promise<number>;
  getExisting(userId: string, idempotencyKey: string): Promise<DispatchRow[]>;
  createDispatch(input: {
    eventId: string;
    userId: string;
    contactId: string;
    priority: number;
    channel: "sms" | "voice";
    idempotencyKey: string;
    providerExternalId: string;
    status: string;
  }): Promise<void>;
  provider: SleepSafetyProvider;
  now(): Date;
  callbackUrl?: string;
  callbackToken?: string;
}

export function createSleepSafetyDispatchHandler(
  deps: DispatchDependencies,
): (request: Request) => Promise<Response> {
  return async (request) => {
    if (request.method !== "POST") return json(405, { error: "method_not_allowed" });
    const userId = await deps.authenticate(request.headers.get("authorization"));
    if (!userId) return json(401, { error: "authentication_required" });

    let body: Record<string, unknown>;
    try {
      body = await request.json();
    } catch (_) {
      return json(400, { error: "invalid_json" });
    }
    const eventId = String(body.event_id ?? "").trim();
    const idempotencyKey = String(body.idempotency_key ?? "").trim();
    if (!eventId || !idempotencyKey || idempotencyKey.length > 120) {
      return json(400, { error: "invalid_dispatch_request" });
    }

    const config = await deps.getRuntimeConfig();
    if (!config.enabled) return json(503, { error: "sleep_safety_rollout_disabled" });
    if (!(await deps.hasPaidAccess(userId))) return json(403, { error: "paid_access_required" });

    const existing = await deps.getExisting(userId, idempotencyKey);
    if (existing.length > 0) {
      return json(200, { accepted: true, reused: true, attempts: existing.length });
    }

    const event = await deps.getEvent(userId, eventId);
    if (!event || !isEligibleEvent(event, deps.now(), config.freshnessSeconds)) {
      return json(409, { error: "event_not_eligible_for_escalation" });
    }

    if ((await deps.countRecentRequests(userId)) >= config.maxPerHour) {
      return json(429, { error: "dispatch_rate_limited" });
    }

    const contacts = (await deps.getVerifiedContacts(userId))
      .filter((contact) => contact.priority >= 1 && contact.priority <= 3)
      .sort((a, b) => a.priority - b.priority);
    if (contacts.length === 0) return json(409, { error: "verified_contact_required" });

    for (const contact of contacts) {
      const voice = await submit(
        deps,
        event,
        contact,
        "voice",
        idempotencyKey,
        "NanoBio đang gửi cảnh báo an toàn giấc ngủ. Vui lòng kiểm tra tình trạng của người thân ngay khi có thể.",
      );
      if (!isTerminalFailure(voice)) {
        return json(202, { accepted: true, reused: false, priority: contact.priority, channel: "voice" });
      }

      const sms = await submit(
        deps,
        event,
        contact,
        "sms",
        idempotencyKey,
        "NanoBio phát hiện một tình huống âm thanh cần chú ý trong phiên giám sát giấc ngủ và người dùng chưa xác nhận an toàn. Vui lòng liên hệ hoặc kiểm tra người thân.",
      );
      if (!isTerminalFailure(sms)) {
        return json(202, { accepted: true, reused: false, priority: contact.priority, channel: "sms" });
      }
    }

    return json(502, { accepted: false, error: "all_contacts_failed" });
  };
}

async function submit(
  deps: DispatchDependencies,
  event: DispatchEvent,
  contact: DispatchContact,
  channel: "sms" | "voice",
  idempotencyKey: string,
  message: string,
): Promise<SleepSafetyProviderStatus> {
  const result = await deps.provider.send(channel, {
    to: contact.phoneE164,
    message,
    idempotencyKey: `${idempotencyKey}-${contact.id}-${channel}`,
    callbackUrl: deps.callbackUrl,
    callbackToken: deps.callbackToken,
  });
  await deps.createDispatch({
    eventId: event.id,
    userId: event.userId,
    contactId: contact.id,
    priority: contact.priority,
    channel,
    idempotencyKey,
    providerExternalId: result.id,
    status: toDatabaseStatus(result.status),
  });
  return result.status;
}

function isEligibleEvent(event: DispatchEvent, now: Date, freshnessSeconds: number): boolean {
  if (!event.escalationRequired) return false;
  if (event.response !== "needHelp" && event.response !== "noResponse") return false;
  const detectedAt = new Date(event.detectedAt).getTime();
  if (!Number.isFinite(detectedAt)) return false;
  const ageMs = now.getTime() - detectedAt;
  return ageMs >= 0 && ageMs <= Math.max(60, freshnessSeconds) * 1000;
}

function toDatabaseStatus(status: SleepSafetyProviderStatus): string {
  if (status === "no_answer") return "noAnswer";
  return status;
}

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

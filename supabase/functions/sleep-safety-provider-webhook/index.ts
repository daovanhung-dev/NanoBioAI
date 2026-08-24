import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import {
  createGenericHttpSleepSafetyProvider,
  isTerminalFailure,
  normalizeStatus,
} from "../_shared/sleep_safety_provider.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const serviceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
const webhookSecret = requiredEnvironment("SLEEP_SAFETY_PROVIDER_WEBHOOK_SECRET");
const provider = createGenericHttpSleepSafetyProvider({
  baseUrl: requiredEnvironment("SLEEP_SAFETY_PROVIDER_BASE_URL"),
  token: requiredEnvironment("SLEEP_SAFETY_PROVIDER_TOKEN"),
  callbackUrl: `${supabaseUrl}/functions/v1/sleep-safety-provider-webhook`,
  callbackToken: webhookSecret,
});
const admin = createClient(supabaseUrl, serviceRoleKey, {
  auth: { persistSession: false, autoRefreshToken: false },
});

Deno.serve(async (request) => {
  if (request.method !== "POST") return response(405, { error: "method_not_allowed" });
  if (request.headers.get("x-sleep-safety-token") !== webhookSecret) {
    return response(401, { error: "invalid_callback_token" });
  }

  let body: Record<string, unknown>;
  try {
    body = await request.json();
  } catch (_) {
    return response(400, { error: "invalid_json" });
  }
  const externalId = String(body.id ?? body.provider_external_id ?? "").trim();
  const providerStatus = normalizeStatus(body.status);
  if (!externalId) return response(400, { error: "provider_id_required" });

  const { data: dispatch, error } = await admin
    .from("sleep_safety_dispatches")
    .select("id,event_id,user_id,contact_id,priority,channel,idempotency_key,status")
    .eq("provider_external_id", externalId)
    .maybeSingle();
  if (error) throw error;
  if (!dispatch) return response(202, { accepted: true, ignored: true });

  const databaseStatus = providerStatus === "no_answer" ? "noAnswer" : providerStatus;
  await admin.from("sleep_safety_dispatches")
    .update({ status: databaseStatus })
    .eq("id", dispatch.id);

  if (!isTerminalFailure(providerStatus)) {
    return response(200, { accepted: true, continued: false });
  }

  const continued = await continueCascade({
    eventId: dispatch.event_id,
    userId: dispatch.user_id,
    contactId: dispatch.contact_id,
    priority: dispatch.priority,
    failedChannel: dispatch.channel,
    idempotencyKey: dispatch.idempotency_key,
  });
  return response(200, { accepted: true, continued });
});

async function continueCascade(input: {
  eventId: string;
  userId: string;
  contactId: string;
  priority: number;
  failedChannel: "sms" | "voice";
  idempotencyKey: string;
}): Promise<boolean> {
  if (input.failedChannel === "voice") {
    const contact = await getContact(input.userId, input.contactId);
    if (contact && !(await alreadyAttempted(input.idempotencyKey, contact.id, "sms"))) {
      const sms = await submit(
        input.eventId,
        input.userId,
        contact,
        "sms",
        input.idempotencyKey,
      );
      if (!isTerminalFailure(sms)) return true;
    }
  }

  const { data: contacts, error } = await admin
    .from("sleep_safety_contacts")
    .select("id,phone_e164,priority")
    .eq("user_id", input.userId)
    .eq("active", true)
    .eq("verification_status", "verified")
    .gt("priority", input.priority)
    .order("priority", { ascending: true });
  if (error) throw error;

  for (const contact of contacts ?? []) {
    if (await alreadyAttempted(input.idempotencyKey, contact.id, "voice")) continue;
    const voice = await submit(
      input.eventId,
      input.userId,
      contact,
      "voice",
      input.idempotencyKey,
    );
    if (!isTerminalFailure(voice)) return true;

    if (!(await alreadyAttempted(input.idempotencyKey, contact.id, "sms"))) {
      const sms = await submit(
        input.eventId,
        input.userId,
        contact,
        "sms",
        input.idempotencyKey,
      );
      if (!isTerminalFailure(sms)) return true;
    }
  }
  return false;
}

async function submit(
  eventId: string,
  userId: string,
  contact: { id: string; phone_e164: string; priority: number },
  channel: "sms" | "voice",
  idempotencyKey: string,
) {
  const message = channel === "voice"
    ? "NanoBio đang gửi cảnh báo an toàn giấc ngủ. Vui lòng kiểm tra tình trạng của người thân ngay khi có thể."
    : "NanoBio phát hiện một tình huống âm thanh cần chú ý trong phiên giám sát giấc ngủ và người dùng chưa xác nhận an toàn. Vui lòng liên hệ hoặc kiểm tra người thân.";
  const result = await provider.send(channel, {
    to: contact.phone_e164,
    message,
    idempotencyKey: `${idempotencyKey}-${contact.id}-${channel}`,
  });
  const status = result.status === "no_answer" ? "noAnswer" : result.status;
  const { error } = await admin.from("sleep_safety_dispatches").insert({
    event_id: eventId,
    user_id: userId,
    contact_id: contact.id,
    priority: contact.priority,
    channel,
    provider: "generic_http",
    provider_external_id: result.id || null,
    status,
    idempotency_key: idempotencyKey,
  });
  if (error) throw error;
  return result.status;
}

async function getContact(userId: string, contactId: string) {
  const { data, error } = await admin
    .from("sleep_safety_contacts")
    .select("id,phone_e164,priority")
    .eq("id", contactId)
    .eq("user_id", userId)
    .eq("active", true)
    .eq("verification_status", "verified")
    .maybeSingle();
  if (error) throw error;
  return data;
}

async function alreadyAttempted(
  idempotencyKey: string,
  contactId: string,
  channel: "sms" | "voice",
): Promise<boolean> {
  const { data, error } = await admin
    .from("sleep_safety_dispatches")
    .select("id")
    .eq("idempotency_key", idempotencyKey)
    .eq("contact_id", contactId)
    .eq("channel", channel)
    .limit(1);
  if (error) throw error;
  return (data ?? []).length > 0;
}

function response(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

function requiredEnvironment(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required Edge Function secret: ${name}`);
  return value;
}

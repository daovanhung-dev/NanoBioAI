import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.1";

import {
  createGenericHttpSleepSafetyProvider,
  isTerminalFailure,
  normalizeStatus,
} from "../_shared/sleep_safety_provider.ts";
import { type CascadeContact, continueSleepSafetyCascade } from "./cascade.ts";

const supabaseUrl = requiredEnvironment("SUPABASE_URL");
const serviceRoleKey = requiredEnvironment("SUPABASE_SERVICE_ROLE_KEY");
const webhookSecret = requiredEnvironment(
  "SLEEP_SAFETY_PROVIDER_WEBHOOK_SECRET",
);
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
  if (request.method !== "POST") {
    return response(405, { error: "method_not_allowed" });
  }
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
    .select(
      "id,event_id,user_id,contact_id,priority,channel,idempotency_key,status",
    )
    .eq("provider_external_id", externalId)
    .maybeSingle();
  if (error) throw error;
  if (!dispatch) return response(202, { accepted: true, ignored: true });

  const databaseStatus = providerStatus === "no_answer"
    ? "noAnswer"
    : providerStatus;
  await admin.from("sleep_safety_dispatches")
    .update({ status: databaseStatus })
    .eq("id", dispatch.id);

  if (!isTerminalFailure(providerStatus)) {
    return response(200, { accepted: true, continued: false });
  }

  const continued = await continueSleepSafetyCascade({
    eventId: dispatch.event_id,
    userId: dispatch.user_id,
    contactId: dispatch.contact_id,
    priority: dispatch.priority,
    failedChannel: dispatch.channel === "voice" ? "voice" : "sms",
    idempotencyKey: dispatch.idempotency_key,
  }, {
    getContact,
    getContactsAfterPriority,
    alreadyAttempted,
    submit,
  });
  return response(200, { accepted: true, continued });
});

async function getContactsAfterPriority(
  userId: string,
  priority: number,
): Promise<CascadeContact[]> {
  const { data: contacts, error } = await admin
    .from("sleep_safety_contacts")
    .select(
      "id,phone_e164,priority,verification_status,allow_unverified_voice_alert",
    )
    .eq("user_id", userId)
    .eq("active", true)
    .gt("priority", priority)
    .order("priority", { ascending: true });
  if (error) throw error;
  return (contacts ?? []).map(mapContact);
}

async function getContact(
  userId: string,
  contactId: string,
): Promise<CascadeContact | null> {
  const { data, error } = await admin
    .from("sleep_safety_contacts")
    .select(
      "id,phone_e164,priority,verification_status,allow_unverified_voice_alert",
    )
    .eq("id", contactId)
    .eq("user_id", userId)
    .eq("active", true)
    .maybeSingle();
  if (error) throw error;
  return data == null ? null : mapContact(data);
}

function mapContact(row: {
  id: string;
  phone_e164: string;
  priority: number;
  verification_status: string;
  allow_unverified_voice_alert: boolean;
}): CascadeContact {
  return {
    id: row.id,
    phoneE164: row.phone_e164,
    priority: row.priority,
    isVerified: row.verification_status === "verified",
    allowUnverifiedVoiceAlert: row.allow_unverified_voice_alert === true,
  };
}

async function submit(
  eventId: string,
  userId: string,
  contact: CascadeContact,
  channel: "sms" | "voice",
  idempotencyKey: string,
) {
  const message = channel === "voice"
    ? "NanoBio đang gửi cảnh báo an toàn giấc ngủ. Vui lòng kiểm tra tình trạng của người thân ngay khi có thể."
    : "NanoBio phát hiện một tình huống âm thanh cần chú ý trong phiên giám sát giấc ngủ và người dùng chưa xác nhận an toàn. Vui lòng liên hệ hoặc kiểm tra người thân.";
  const result = await provider.send(channel, {
    to: contact.phoneE164,
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

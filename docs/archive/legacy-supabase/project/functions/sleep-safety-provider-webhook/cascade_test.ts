import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { continueSleepSafetyCascade } from "./cascade.ts";

Deno.test("unverified voice failure skips SMS and continues to next eligible contact", async () => {
  const submitted: string[] = [];
  const contacts = [
    {
      id: "c2",
      phoneE164: "+84902222222",
      priority: 2,
      isVerified: true,
      allowUnverifiedVoiceAlert: false,
    },
  ];
  const continued = await continueSleepSafetyCascade({
    eventId: "e1",
    userId: "u1",
    contactId: "c1",
    priority: 1,
    failedChannel: "voice",
    idempotencyKey: "k1",
  }, {
    getContact: async () => ({
      id: "c1",
      phoneE164: "+84901111111",
      priority: 1,
      isVerified: false,
      allowUnverifiedVoiceAlert: true,
    }),
    getContactsAfterPriority: async () => contacts,
    alreadyAttempted: async () => false,
    submit: async (_eventId, _userId, contact, channel) => {
      submitted.push(`${contact.id}:${channel}`);
      return "submitted";
    },
  });

  assertEquals(continued, true);
  assertEquals(submitted, ["c2:voice"]);
});

Deno.test("unverified next contact without voice consent is skipped", async () => {
  const submitted: string[] = [];
  const continued = await continueSleepSafetyCascade({
    eventId: "e1",
    userId: "u1",
    contactId: "c1",
    priority: 1,
    failedChannel: "sms",
    idempotencyKey: "k1",
  }, {
    getContact: async () => null,
    getContactsAfterPriority: async () => [{
      id: "c2",
      phoneE164: "+84902222222",
      priority: 2,
      isVerified: false,
      allowUnverifiedVoiceAlert: false,
    }],
    alreadyAttempted: async () => false,
    submit: async (_eventId, _userId, contact, channel) => {
      submitted.push(`${contact.id}:${channel}`);
      return "submitted";
    },
  });

  assertEquals(continued, false);
  assertEquals(submitted, []);
});

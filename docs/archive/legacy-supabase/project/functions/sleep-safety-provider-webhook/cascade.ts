import {
  isTerminalFailure,
  type SleepSafetyProviderStatus,
} from "../_shared/sleep_safety_provider.ts";

export interface CascadeContact {
  id: string;
  phoneE164: string;
  priority: number;
  isVerified: boolean;
  allowUnverifiedVoiceAlert: boolean;
}

export interface CascadeDependencies {
  getContact(userId: string, contactId: string): Promise<CascadeContact | null>;
  getContactsAfterPriority(
    userId: string,
    priority: number,
  ): Promise<CascadeContact[]>;
  alreadyAttempted(
    idempotencyKey: string,
    contactId: string,
    channel: "sms" | "voice",
  ): Promise<boolean>;
  submit(
    eventId: string,
    userId: string,
    contact: CascadeContact,
    channel: "sms" | "voice",
    idempotencyKey: string,
  ): Promise<SleepSafetyProviderStatus>;
}

export async function continueSleepSafetyCascade(
  input: {
    eventId: string;
    userId: string;
    contactId: string;
    priority: number;
    failedChannel: "sms" | "voice";
    idempotencyKey: string;
  },
  deps: CascadeDependencies,
): Promise<boolean> {
  if (input.failedChannel === "voice") {
    const contact = await deps.getContact(input.userId, input.contactId);
    if (
      contact?.isVerified &&
      !(await deps.alreadyAttempted(input.idempotencyKey, contact.id, "sms"))
    ) {
      const sms = await deps.submit(
        input.eventId,
        input.userId,
        contact,
        "sms",
        input.idempotencyKey,
      );
      if (!isTerminalFailure(sms)) return true;
    }
  }

  const contacts = (await deps.getContactsAfterPriority(
    input.userId,
    input.priority,
  ))
    .filter((contact) => contact.priority >= 1 && contact.priority <= 3)
    .filter((contact) =>
      contact.isVerified || contact.allowUnverifiedVoiceAlert
    )
    .sort((a, b) => a.priority - b.priority);

  for (const contact of contacts) {
    if (
      !(await deps.alreadyAttempted(input.idempotencyKey, contact.id, "voice"))
    ) {
      const voice = await deps.submit(
        input.eventId,
        input.userId,
        contact,
        "voice",
        input.idempotencyKey,
      );
      if (!isTerminalFailure(voice)) return true;
    }

    if (!contact.isVerified) continue;
    if (await deps.alreadyAttempted(input.idempotencyKey, contact.id, "sms")) {
      continue;
    }
    const sms = await deps.submit(
      input.eventId,
      input.userId,
      contact,
      "sms",
      input.idempotencyKey,
    );
    if (!isTerminalFailure(sms)) return true;
  }
  return false;
}

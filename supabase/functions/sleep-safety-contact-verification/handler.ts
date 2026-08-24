export interface VerificationContact {
  id: string;
  userId: string;
  phoneE164: string;
  active: boolean;
}

export interface VerificationChallenge {
  id: string;
  contactId: string;
  codeHash: string;
  attemptCount: number;
  expiresAt: string;
  status: string;
}

export interface VerificationDependencies {
  authenticate(authorization: string | null): Promise<string | null>;
  getContact(userId: string, contactId: string): Promise<VerificationContact | null>;
  countRecentChallenges(userId: string, contactId: string): Promise<number>;
  createChallenge(input: {
    userId: string;
    contactId: string;
    codeHash: string;
    expiresAt: string;
  }): Promise<string>;
  getActiveChallenge(userId: string, contactId: string): Promise<VerificationChallenge | null>;
  updateChallenge(id: string, values: Record<string, unknown>): Promise<void>;
  markContactVerified(userId: string, contactId: string): Promise<void>;
  sendCode(input: {
    phoneE164: string;
    code: string;
    idempotencyKey: string;
  }): Promise<boolean>;
  hash(value: string): Promise<string>;
  generateCode(): string;
  now(): Date;
  verificationTtlSeconds(): Promise<number>;
}

export function createSleepSafetyContactVerificationHandler(
  deps: VerificationDependencies,
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

    const action = String(body.action ?? "").trim();
    const contactId = String(body.contact_id ?? "").trim();
    if (!contactId) return json(400, { error: "contact_id_required" });

    const contact = await deps.getContact(userId, contactId);
    if (!contact || !contact.active) return json(404, { error: "contact_not_found" });

    if (action === "request") {
      const recentCount = await deps.countRecentChallenges(userId, contactId);
      if (recentCount >= 3) return json(429, { error: "verification_rate_limited" });

      const code = deps.generateCode();
      if (!/^\d{6}$/.test(code)) throw new Error("Verification code generator contract violated.");
      const codeHash = await deps.hash(code);
      const ttlSeconds = Math.max(120, Math.min(await deps.verificationTtlSeconds(), 1800));
      const expiresAt = new Date(deps.now().getTime() + ttlSeconds * 1000).toISOString();
      const challengeId = await deps.createChallenge({ userId, contactId, codeHash, expiresAt });
      const sent = await deps.sendCode({
        phoneE164: contact.phoneE164,
        code,
        idempotencyKey: `verify-${challengeId}`,
      });
      if (!sent) {
        await deps.updateChallenge(challengeId, { status: "locked" });
        return json(502, { error: "verification_provider_failed" });
      }
      return json(202, { accepted: true, expires_at: expiresAt });
    }

    if (action === "confirm") {
      const code = String(body.code ?? "").trim();
      if (!/^\d{6}$/.test(code)) return json(400, { error: "verification_code_invalid" });
      const challenge = await deps.getActiveChallenge(userId, contactId);
      if (!challenge) return json(410, { error: "verification_challenge_missing" });
      if (new Date(challenge.expiresAt).getTime() <= deps.now().getTime()) {
        await deps.updateChallenge(challenge.id, { status: "expired" });
        return json(410, { error: "verification_code_expired" });
      }
      if (challenge.attemptCount >= 5) {
        await deps.updateChallenge(challenge.id, { status: "locked" });
        return json(429, { error: "verification_attempt_limit" });
      }

      const actualHash = await deps.hash(code);
      if (actualHash !== challenge.codeHash) {
        await deps.updateChallenge(challenge.id, {
          attempt_count: challenge.attemptCount + 1,
          status: challenge.attemptCount + 1 >= 5 ? "locked" : "pending",
        });
        return json(400, { error: "verification_code_invalid" });
      }

      await deps.markContactVerified(userId, contactId);
      await deps.updateChallenge(challenge.id, { status: "verified" });
      return json(200, { verified: true });
    }

    return json(400, { error: "unsupported_action" });
  };
}

function json(status: number, body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });
}

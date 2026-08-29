const jsonHeaders = {
  "Content-Type": "application/json; charset=utf-8",
  "Cache-Control": "no-store",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type",
};

export type DeleteAccountDependencies = {
  authenticate: (authorization: string | null) => Promise<string | null>;
  /** Remove account-owned objects before deleting the auth subject. */
  deleteOwnedStorage?: (userId: string) => Promise<void>;
  deleteAccount: (userId: string) => Promise<void>;
};

export function createDeleteAccountHandler(
  dependencies: DeleteAccountDependencies,
) {
  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") {
      return new Response("ok", { headers: jsonHeaders });
    }
    if (request.method !== "POST") {
      return errorResponse(405, "method_not_allowed");
    }

    const authorization = request.headers.get("Authorization");
    const userId = await dependencies.authenticate(authorization);
    if (userId == null || authorization == null) {
      return errorResponse(401, "unauthorized");
    }

    const body = await parseBody(request);
    if (body == null || body.confirm !== true) {
      return errorResponse(400, "confirmation_required");
    }

    try {
      // Storage objects are not covered by Postgres foreign-key cascades. Keep
      // the deletion operation all-or-nothing from the caller's perspective:
      // if owned-object cleanup cannot be completed, do not remove auth/data
      // and ask the user to retry.
      await dependencies.deleteOwnedStorage?.(userId);
      await dependencies.deleteAccount(userId);
      return jsonResponse({ deleted: true });
    } catch (_) {
      // Do not disclose user IDs, service-role errors, or database details.
      return errorResponse(503, "account_deletion_unavailable");
    }
  };
}

async function parseBody(request: Request): Promise<Record<string, unknown> | null> {
  try {
    const body: unknown = await request.json();
    if (body == null || typeof body !== "object" || Array.isArray(body)) {
      return null;
    }
    return body as Record<string, unknown>;
  } catch (_) {
    return null;
  }
}

function jsonResponse(body: Record<string, unknown>): Response {
  return new Response(JSON.stringify(body), { status: 200, headers: jsonHeaders });
}

function errorResponse(status: number, code: string): Response {
  return new Response(JSON.stringify({ error: code }), {
    status,
    headers: jsonHeaders,
  });
}

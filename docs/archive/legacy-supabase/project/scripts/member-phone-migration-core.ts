export type PublicUser = {
  id: string;
  email: string | null;
  phone: string | null;
  app_access_mode: string | null;
};

export type AuthUser = {
  id: string;
  email?: string | null;
  phone?: string | null;
  user_metadata?: Record<string, unknown> | null;
  app_metadata?: Record<string, unknown> | null;
};

export type MigrationReviewRow = {
  user_id: string;
  status: "ready_to_migrate" | "already_phone_login_enabled" | "manual_review";
  reason?: string;
  phone: string | null;
};

export type MigrationCandidate = {
  userId: string;
  phone: string;
  authEmail: string;
  contactEmail: string | null;
};

export function normalizeVietnamPhone(value: string): string | null {
  if (!/^[+\d\s().-]+$/.test(value.trim())) return null;
  const digits = value.trim().replace(/\D/g, "");
  const local = digits.startsWith("0084")
    ? digits.slice(4)
    : digits.startsWith("84")
    ? digits.slice(2)
    : digits.startsWith("0")
    ? digits.slice(1)
    : "";
  return /^\d{9}$/.test(local) ? `+84${local}` : null;
}

export function memberAuthEmail(normalizedPhone: string): string {
  const digits = normalizedPhone.replace(/\D/g, "");
  return `member-${digits}@phone.nanobio.invalid`;
}

export function maskPhone(value: string): string {
  return `${value.slice(0, 5)}••••${value.slice(-2)}`;
}

export function reviewMemberAccounts(
  publicUsers: PublicUser[],
  authUsers: AuthUser[],
  adminAssignments: Set<string>,
): { rows: MigrationReviewRow[]; candidates: MigrationCandidate[] } {
  const authById = new Map(authUsers.map((user) => [user.id, user]));
  const authIdsByEmail = new Map<string, Set<string>>();
  for (const user of authUsers) {
    const email = user.email?.trim().toLowerCase();
    if (!email) continue;
    const ids = authIdsByEmail.get(email) ?? new Set<string>();
    ids.add(user.id);
    authIdsByEmail.set(email, ids);
  }
  const publicIdsByPhone = groupIdsByPhone(
    publicUsers,
    (user) => user.phone ?? "",
  );
  const candidates: MigrationCandidate[] = [];
  const rows = publicUsers.map((user): MigrationReviewRow => {
    const authUser = authById.get(user.id);
    const phone = normalizeVietnamPhone(user.phone ?? "");
    let status: MigrationReviewRow["status"];
    let reason: string | undefined;

    if (user.app_access_mode !== "user" || adminAssignments.has(user.id)) {
      status = "manual_review";
      reason = "admin_or_dual_access_account";
    } else if (!authUser) {
      status = "manual_review";
      reason = "auth_user_missing";
    } else if (!phone) {
      status = "manual_review";
      reason = user.phone ? "invalid_phone" : "phone_missing";
    } else if ((publicIdsByPhone.get(phone)?.size ?? 0) > 1) {
      status = "manual_review";
      reason = "duplicate_public_phone";
    } else {
      const authEmail = memberAuthEmail(phone);
      const otherAuthOwners = [...(authIdsByEmail.get(authEmail) ?? [])].filter(
        (id) => id !== user.id,
      );
      if (otherAuthOwners.length > 0) {
        status = "manual_review";
        reason = "phone_login_alias_owned_by_another_auth_user";
      } else if (authUser.email?.toLowerCase() === authEmail) {
        status = "already_phone_login_enabled";
      } else {
        status = "ready_to_migrate";
        const metadata = authUser.user_metadata ?? {};
        const metadataEmail = typeof metadata.contact_email === "string"
          ? metadata.contact_email
          : null;
        const authEmailContact = authUser.email?.toLowerCase().endsWith(
            "@phone.nanobio.invalid",
          )
          ? null
          : authUser.email ?? null;
        candidates.push({
          userId: user.id,
          phone,
          authEmail,
          contactEmail: user.email ?? metadataEmail ?? authEmailContact,
        });
      }
    }

    return {
      user_id: user.id,
      status,
      ...(reason ? { reason } : {}),
      phone: phone ? maskPhone(phone) : null,
    };
  });

  const publicIds = new Set(publicUsers.map((user) => user.id));
  for (const authUser of authUsers) {
    if (publicIds.has(authUser.id) || adminAssignments.has(authUser.id)) {
      continue;
    }
    const accessMode = authUser.app_metadata?.app_access_mode;
    if (accessMode === "admin" || accessMode === "both") continue;
    rows.push({
      user_id: authUser.id,
      status: "manual_review",
      reason: "auth_user_without_public_profile",
      phone: null,
    });
  }

  return { rows, candidates };
}

function groupIdsByPhone<T extends { id: string }>(
  users: T[],
  getPhone: (user: T) => string,
): Map<string, Set<string>> {
  const grouped = new Map<string, Set<string>>();
  for (const user of users) {
    const phone = normalizeVietnamPhone(getPhone(user));
    if (!phone) continue;
    const ids = grouped.get(phone) ?? new Set<string>();
    ids.add(user.id);
    grouped.set(phone, ids);
  }
  return grouped;
}

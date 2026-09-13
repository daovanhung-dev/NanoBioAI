export type ExistingMembership = {
  id: string;
  plan_code: string;
  status: string;
  starts_at: string;
  ends_at: string | null;
};

export function chooseCurrentPaidSubscription(
  rows: ExistingMembership[],
  now = Date.now(),
): ExistingMembership | null {
  return rows
    .filter((row) => {
      if (!row.id || !["plus", "family_plus"].includes(row.plan_code)) {
        return false;
      }
      if (!(["active", "trialing"] as string[]).includes(row.status)) {
        return false;
      }
      const startsAt = Date.parse(row.starts_at);
      if (!Number.isFinite(startsAt) || startsAt > now) return false;
      if (row.ends_at === null) return true;
      const endsAt = Date.parse(row.ends_at);
      return Number.isFinite(endsAt) && endsAt > now;
    })
    .sort((left, right) => {
      const planRank = (planCode: string) => planCode === "family_plus" ? 2 : 1;
      const rankDelta = planRank(right.plan_code) - planRank(left.plan_code);
      if (rankDelta !== 0) return rankDelta;
      return Date.parse(right.starts_at) - Date.parse(left.starts_at);
    })[0] ?? null;
}

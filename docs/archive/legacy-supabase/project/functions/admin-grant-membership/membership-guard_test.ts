import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

import {
  chooseCurrentPaidSubscription,
  type ExistingMembership,
} from "./membership-guard.ts";

const now = Date.parse("2026-09-13T10:00:00.000Z");

Deno.test("paid-plan guard selects the current FamilyPlus entitlement first", () => {
  const selected = chooseCurrentPaidSubscription([
    membership("plus", "2026-09-01T00:00:00.000Z", "2026-10-01T00:00:00.000Z"),
    membership(
      "family_plus",
      "2026-09-02T00:00:00.000Z",
      "2026-09-20T00:00:00.000Z",
    ),
  ], now);

  assertEquals(selected?.plan_code, "family_plus");
});

Deno.test("paid-plan guard selects the newest current Plus entitlement", () => {
  const selected = chooseCurrentPaidSubscription([
    membership("plus", "2026-09-01T00:00:00.000Z", "2026-09-20T00:00:00.000Z"),
    membership("plus", "2026-09-05T00:00:00.000Z", "2026-10-05T00:00:00.000Z"),
  ], now);

  assertEquals(selected?.starts_at, "2026-09-05T00:00:00.000Z");
});

Deno.test("paid-plan guard excludes free, expired, and not-yet-started records", () => {
  const selected = chooseCurrentPaidSubscription([
    membership("free", "2026-09-01T00:00:00.000Z", "2026-10-01T00:00:00.000Z"),
    membership("plus", "2026-08-01T00:00:00.000Z", "2026-09-13T09:59:59.000Z"),
    membership("plus", "2026-09-13T10:00:01.000Z", "2026-10-13T10:00:01.000Z"),
  ], now);

  assertEquals(selected, null);
});

Deno.test("paid-plan guard accepts an active entitlement without an end date", () => {
  const record = membership("plus", "2026-09-01T00:00:00.000Z", null);
  const selected = chooseCurrentPaidSubscription([record], now);

  assertEquals(selected?.id, record.id);
});

function membership(
  plan_code: string,
  starts_at: string,
  ends_at: string | null,
): ExistingMembership {
  return {
    id: `${plan_code}-${starts_at}`,
    plan_code,
    status: "active",
    starts_at,
    ends_at,
  };
}

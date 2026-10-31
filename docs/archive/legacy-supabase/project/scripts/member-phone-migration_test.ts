import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  type AuthUser,
  normalizeVietnamPhone,
  type PublicUser,
  reviewMemberAccounts,
} from "./member-phone-migration-core.ts";

Deno.test("normalizes supported Vietnam phone forms to E.164", () => {
  assertEquals(normalizeVietnamPhone("0912 345 678"), "+84912345678");
  assertEquals(normalizeVietnamPhone("84 (912) 345-678"), "+84912345678");
  assertEquals(normalizeVietnamPhone("0084 912345678"), "+84912345678");
  assertEquals(normalizeVietnamPhone("+84912345678"), "+84912345678");
  assertEquals(normalizeVietnamPhone("091234567"), null);
  assertEquals(normalizeVietnamPhone("nabi@example.com"), null);
});

Deno.test("migration review selects only unique eligible member accounts", () => {
  const publicUsers: PublicUser[] = [
    {
      id: "ready",
      email: "member@example.com",
      phone: "0912 345 678",
      app_access_mode: "user",
    },
    {
      id: "duplicate-a",
      email: null,
      phone: "+84911111111",
      app_access_mode: "user",
    },
    {
      id: "duplicate-b",
      email: null,
      phone: "0911111111",
      app_access_mode: "user",
    },
    { id: "invalid", email: null, phone: "bad", app_access_mode: "user" },
    {
      id: "admin",
      email: null,
      phone: "+84922222222",
      app_access_mode: "admin",
    },
  ];
  const authUsers: AuthUser[] = [
    { id: "ready", phone: null, app_metadata: {} },
    { id: "duplicate-a", phone: null, app_metadata: {} },
    { id: "duplicate-b", phone: null, app_metadata: {} },
    { id: "invalid", phone: null, app_metadata: {} },
    { id: "admin", phone: null, app_metadata: { app_access_mode: "admin" } },
    { id: "orphan", phone: "+84933333333", app_metadata: {} },
  ];
  const result = reviewMemberAccounts(
    publicUsers,
    authUsers,
    new Set(["admin"]),
  );

  assertEquals(result.candidates.map((candidate) => candidate.userId), [
    "ready",
  ]);
  assertEquals(
    result.rows.find((row) => row.user_id === "ready")?.status,
    "ready_to_migrate",
  );
  assertEquals(
    result.rows.find((row) => row.user_id === "duplicate-a")?.reason,
    "duplicate_public_phone",
  );
  assertEquals(
    result.rows.find((row) => row.user_id === "invalid")?.reason,
    "invalid_phone",
  );
  assertEquals(
    result.rows.find((row) => row.user_id === "admin")?.reason,
    "admin_or_dual_access_account",
  );
  assertEquals(
    result.rows.find((row) => row.user_id === "orphan")?.reason,
    "auth_user_without_public_profile",
  );
  assertEquals(JSON.stringify(result.rows).includes("0912 345 678"), false);
});

Deno.test("migration review sends Auth alias conflicts to manual review", () => {
  const publicUsers: PublicUser[] = [
    {
      id: "member",
      email: "member@example.com",
      phone: "0912 345 678",
      app_access_mode: "user",
    },
    {
      id: "other",
      email: null,
      phone: "+84911111111",
      app_access_mode: "user",
    },
  ];
  const authUsers: AuthUser[] = [
    { id: "member", email: "member@example.com", app_metadata: {} },
    {
      id: "other",
      email: "member-84912345678@phone.nanobio.invalid",
      app_metadata: {},
    },
  ];
  const result = reviewMemberAccounts(publicUsers, authUsers, new Set());
  assertEquals(result.candidates.map((candidate) => candidate.userId), [
    "other",
  ]);
  assertEquals(
    result.rows.find((row) => row.user_id === "member")?.reason,
    "phone_login_alias_owned_by_another_auth_user",
  );
});

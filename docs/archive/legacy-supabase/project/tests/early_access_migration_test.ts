const migration = await Deno.readTextFile(
  new URL("../migrations/20261007130000_nanobio_early_access_customer_admin.sql", import.meta.url),
);
const baseMigration = await Deno.readTextFile(
  new URL("../migrations/20261007000000_nanobio_early_access.sql", import.meta.url),
);

Deno.test("closed lead retention is 12 months and leaves open leads intact", () => {
  const match = migration.match(
    /create or replace function public\.purge_early_access_closed_leads\(\)([\s\S]*?)\$\$;/i,
  );
  const body = match?.[1]?.toLowerCase();
  if (!body) throw new Error("retention function is missing");
  if (!body.includes("interval '12 months'")) {
    throw new Error("closed leads must use the declared 12 month retention period");
  }
  if (!body.includes("status in ('registered','converted','rejected')")) {
    throw new Error("only closed lead statuses may be purged");
  }
  if (body.includes("status in ('new','contacted')")) {
    throw new Error("open leads must not be purged by the retention job");
  }
  if (!body.includes("promo_phone_suppressions")) {
    throw new Error("promotion suppression hashes must survive lead deletion");
  }

  if (
    !migration.includes("'nanobio-purge-closed-early-access-leads'") ||
    !migration.includes("'17 3 * * *'")
  ) throw new Error("closed-lead retention must run once a day");
});

Deno.test("lead tables stay closed to client roles and admin updates are audited", () => {
  if (!baseMigration.includes("alter table public.early_access_leads enable row level security;")) {
    throw new Error("early-access leads require RLS");
  }
  if (!baseMigration.includes("revoke all on table public.early_access_leads from public, anon, authenticated;")) {
    throw new Error("early-access leads must not have direct client grants");
  }
  if (!migration.includes("grant execute on function public.save_early_access_lead(jsonb) to service_role;")) {
    throw new Error("only the trusted service function may save leads");
  }
  if (!migration.includes("alter table early_access_private.promo_phone_suppressions enable row level security;")) {
    throw new Error("phone suppression hashes require RLS");
  }
  if (!migration.includes("revoke all on table early_access_private.promo_phone_suppressions from public, anon, authenticated, service_role;")) {
    throw new Error("phone suppression hashes must not have direct client grants");
  }
  if (!migration.includes("'early_access_lead_status_updated'")) {
    throw new Error("admin status updates must be written to the audit log");
  }
  for (const role of ["super_admin", "support_admin", "operations_admin"]) {
    if (!migration.includes(`'${role}'`)) throw new Error(`missing allowed role ${role}`);
  }
});

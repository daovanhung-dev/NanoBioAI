# ENV-001 — Hosted sandbox rebuild/reseed/rollback path audit

## Safe technical record

- Run ID: `FP-20260728-SBX-001`
- Command ID: `CMD-20260728-SBX-AUDIT-001`
- Date: 2026-07-28
- Scope: read-only capability audit from the campaign workspace. No SQL, reset,
  seed, Storage call, credential print, or remote mutation was performed.
- Outcome: **BLOCKED — the workspace has no usable database-admin channel for
  the requested destructive rebuild.**

The test owner has confirmed that the configured hosted endpoint is a
disposable sandbox. That authorization establishes the target scope, but it
does not provide the database/SQL Editor credential or a local Supabase runtime
needed to execute the rebuild safely.

## What is available

| Capability | Result | Evidence / implication |
| --- | --- | --- |
| Canonical destructive rebuild source | Available | `docs/supabase/config.sql` is the only rebuild entrypoint. It starts by truncating `auth.users` and recreating `public`, so it requires an admin SQL connection. |
| Opt-in demo rollout source | Available | `docs/supabase/20-dev-sandbox-demo-profile.sql` is a separate post-rebuild transaction that enables the sandbox demo profile. |
| Storage fixture runner | Available, but not runnable here | `tools/supabase/Seed-StorageFixtures.ps1` exists and deliberately uses real Auth/RPC/Storage paths. It is state-changing and one-shot after each rebuild. |
| Rollback-only fixture smoke source | Available | `test/docs/fixtures/supabase_comprehensive_seed_smoke.sql` exists, begins a transaction and ends with `ROLLBACK`; it is executable only after rebuild, demo profile, and Storage fixture setup. |
| `psql` client | Installed | PostgreSQL client version `18.4` is present, but no database connection setting was supplied in the workspace or current process environment checked by this audit. |
| Supabase CLI | Unavailable | `Get-Command supabase` returned not found. |
| Local Supabase/Docker fallback | Unavailable | The repository has no `supabase/config.toml` or Compose file; Docker Desktop's daemon pipe is unavailable, so no local service can be started or inspected. |
| App-level Supabase configuration | Insufficient by design | `.env` and `.env.example` expose only the app endpoint/anonymous-key configuration. They do not contain a database-admin connection or service-role credential. Flutter anon/authenticated clients must never execute `config.sql`. |
| Storage runner credential environment | Missing | No `NANOBIO_*` process variables are set. The runner explicitly requires `NANOBIO_SUPABASE_URL`, `NANOBIO_SUPABASE_ANON_KEY`, and `NANOBIO_SUPABASE_SERVICE_ROLE_KEY`; none was printed or inferred. |

User-level credential stores (for example a password manager, a `pgpass` file,
or a browser profile) were intentionally not inspected. They are outside the
campaign workspace and must be supplied through an approved, secret-safe
operator path rather than discovered or copied by the campaign.

## Unambiguous blocker condition

Do **not** attempt a reset from this workspace until one of these two approved
paths is available for the already-confirmed disposable sandbox:

1. An authenticated Supabase SQL Editor session with privilege to operate on
   `auth.*`, `public`, and the Storage policy objects; or
2. A secure, process-injected PostgreSQL connection for an account with the
   same privileges, plus the three runner environment variables above from a
   secret manager.

An anonymous app key, an authenticated fixture session, a normal REST/RPC
request, or the installed `psql` executable alone is **not** a substitute for
that capability. Running the rebuild with any of them would either fail or
violate the database ownership/security contract.

## Correct execution path once access is supplied

Only an operator who verifies the exact project is disposable may run the
following. The examples intentionally use a placeholder process variable;
never put a connection string, service-role key, fixture password, JWT, or
object path in shell history, source control, campaign evidence, or command
output.

```powershell
# Run in a secret-injected, already-authorized PowerShell session.
# The database variable is illustrative and must not be written to .env.
psql -X -v ON_ERROR_STOP=1 -d "$env:NANOBIO_SUPABASE_DB_URL" `
  -f docs/supabase/config.sql

psql -X -v ON_ERROR_STOP=1 -d "$env:NANOBIO_SUPABASE_DB_URL" `
  -f docs/supabase/20-dev-sandbox-demo-profile.sql

# The three NANOBIO_SUPABASE_* runner variables must already be injected by a
# secret manager. Keep the fixture password as a SecureString in this same
# PowerShell process; do not pass it on the command line.
$fixturePassword = Read-Host 'Fixture password' -AsSecureString
& .\tools\supabase\Seed-StorageFixtures.ps1 -FixturePassword $fixturePassword

# This smoke script has its own BEGIN/ROLLBACK and leaves no smoke mutation.
psql -X -v ON_ERROR_STOP=1 -d "$env:NANOBIO_SUPABASE_DB_URL" `
  -f test/docs/fixtures/supabase_comprehensive_seed_smoke.sql
```

If the confirmed disposable hostname is neither loopback, `.local`, nor named
with `sandbox`, the runner will refuse it by default. Only after the operator
has reconfirmed the target may they add its explicit `-AllowNonLocal` switch.
That switch is not appropriate for shared staging or production.

`config.sql` already contains the comprehensive fixture seed. Do not run
`19-dev-sandbox-comprehensive-seed.sql` again after it. The required order is
therefore exactly: **config → demo profile → Storage runner → rollback-only
smoke**. For another mutation-heavy test cluster, rebuild from the first step;
do not retry the one-shot Storage runner against an existing proof state.

## Evidence assertions to record after the blocker is cleared

Record only these safe facts per execution: command ID, confirmed disposable
target alias, tool exit status, source-file SHA-256, run start/end time,
runner success/failure category, and rollback-smoke outcome. Do not retain raw
SQL output, credentials, fixture emails, proof paths, voucher codes, token
material, or database identifiers.

The smoke source covers the prerequisite fixture contract, private Storage
objects, authenticated RLS negative assertions, and retry/idempotency
assertions. Its `ROLLBACK` makes it suitable as the final SQL verification only
after the persistent fixture setup has succeeded.

## Source references

- `docs/supabase/config.sql:1-24,12655` — destructive transaction, privileged
  `auth.users` reset/public-schema recreation, and final commit.
- `docs/supabase/README.md:29-69,124-130` — canonical rebuild entrypoint,
  local/sandbox restriction, and post-rebuild Storage sequence.
- `docs/supabase/20-dev-sandbox-demo-profile.sql:1-57` — opt-in post-rebuild
  demo profile and independent commit.
- `tools/supabase/Seed-StorageFixtures.ps1:8-33,61-84,485-500,636-640` —
  runner safety boundary, target-host guard, required environment variables,
  one-shot constraint, and sensitive-path console output that must not be
  captured into campaign evidence.
- `test/docs/fixtures/supabase_comprehensive_seed_smoke.sql:2-7,211,333-366,853`
  — ordered prerequisites, RLS/idempotency assertions, and rollback-only end.

## Boundary

This file is an environment-capability record, not evidence that the hosted
sandbox was rebuilt, reseeded, Storage-populated, or SQL-smoked. Any campaign
case that depends on those mutations must cite this blocker until a fresh,
authorized run produces its own redacted technical evidence.

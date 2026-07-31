# PF-028 — Sale-A dashboard/customer RPC smoke

## Safe technical record

- Run ID: `FP-20260728-SALE-A-001`
- Command ID: `CMD-20260728-001`
- Entry point: `lib/main.dart`
- Device: physical Android 11 (API 30), `220333QPG`, 720 × 1650
- Package: `com.example.nano_app`
- Build source revision: `9e81b08b9ae2aab4e1c263f99b044002059b4bb0` (dirty worktree)
- Persona: `SALE-A` alias only; no credential, email, JWT, referral code, or customer value is recorded.

## Checks performed

1. A disposable-sandbox fixture-authentication smoke completed with HTTP 200. Authentication material was kept in process only and was not written to a command log or this campaign.
2. On the physical device, the authenticated `SALE-A` session navigated through Settings to the Sale workspace.
3. The Overview loaded its fixture metrics instead of its generic load-error state. The visible aggregate cards reported four direct customers and four successful payments.
4. The Customers tab loaded four direct-customer cards. Its refresh control completed and the post-refresh surface remained loaded; it did not show the generic load-error state.

## Reported-load-failure diagnosis

The local Sale SQL remediation currently present in the dirty worktree qualifies the aggregate expression as `max(public.commission_records.currency)` in both Sale RPCs and grants execution to `authenticated`. The immediately preceding version used unqualified `max(currency)`. In a PostgreSQL function with a returned `currency` column, that unqualified reference can be ambiguous and fail the RPC with SQLSTATE `42702`, which explains why both independent Sale surfaces could have fallen into their generic load-error state.

This campaign did not apply that SQL to the hosted sandbox and cannot prove the deployment provenance. It does prove that the currently connected sandbox/device path succeeds after the remediation is available: both surfaces loaded and the refresh completed. The local remediation is in `docs/supabase/config.sql` and `docs/supabase/12-sale-module-update.sql`.

## Screenshot handling

The original device captures are deliberately not stored in this campaign. Two copies were visually inspected and privacy-redacted before they were copied into `assets/`. The redaction covers the referral code and every customer identifier, age, and phone value. These are evidence-preserving redacted renderings, not byte-for-byte raw captures.

| Asset | SHA-256 | Purpose |
| --- | --- | --- |
| `assets/PF-028-overview-pass.png` | `5BA35C747283BEF1950962CE2E27AD44ECC9D85243C84BE618BCE6ED672362B2` | Overview successfully loaded. |
| `assets/PF-028-pass.png` | `2283C383EB167C6E427E57D35B56E16983E9E189150364536673D3DC2FBCF9AC` | Customers successfully loaded after refresh. |

## Boundary

This is a read-only rendering and refresh smoke. It did not mutate payment, commission, conversion, or referral state; it therefore does not replace the controlled ledger/RLS cases in the campaign. The customer screen observation also produced the separate privacy/requirements finding below.

Related finding: [FP-20260728-001 — Sale direct-customer PII requirements gap](../findings/FP-20260728-001-sale-direct-customer-privacy-gap.md).

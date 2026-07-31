# FP-20260728-001 — Direct-customer screen exposes more PII than the approved requirement resolves

## Classification

- Severity: High / P1 privacy and requirements-acceptance gap
- Type: privacy, RBAC/data-minimization, product-requirements gap
- Status: Open; no product-code change was made by this campaign
- Persona scope: `SALE-A` and any active Sale persona allowed to call the direct-customer endpoint
- Related case: [PF-028](../cases/PF-028.md)

## Environment

- Physical Android 11 (API 30), `220333QPG`, package `com.example.nano_app`
- Unified entry point `lib/main.dart`; source revision `9e81b08b9ae2aab4e1c263f99b044002059b4bb0` with a pre-existing dirty worktree
- Disposable sandbox fixture session; no real-person data was recorded in campaign evidence

## Reproduction

1. Sign in with an active Sale fixture (alias `SALE-A`).
2. Open Settings, enter the Sale workspace, and select **Customers**.
3. Observe the cards returned for direct customers.

## Expected versus actual

- Expected: Product Flow must make an explicit decision for Q-18: whether Sale may see customer names/identifiers or only aggregate/minimized data. If identification is approved, its minimum necessary fields, consent, RBAC boundary, and audit expectations must be explicit.
- Actual: the live direct-customer UI showed each customer’s full display name, age, and phone value. The Sales RLS scope being “direct customer” does not itself answer the data-minimization question.
- Interpretation: this is not asserted as a finalized product-rule violation because Q-18 remains open. It is an acceptance-blocking privacy/requirements gap and should not be silently accepted as a PASS for the broader Sale privacy surface.

## Safe evidence

- [Redacted device evidence](../assets/PF-028-pass.png) shows the rendered customer-card structure with all identifiers, age, and phone values covered.
- [Technical record](../technical/PF-028--sale-a-rpc-smoke.md) records the on-device observation without retaining the original values.
- Product requirement source: `docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md` (Q-18).
- Data/UI implementation points for triage: `docs/supabase/12-sale-module-update.sql` (`get_my_sale_direct_customers`) and `lib/sale_referral/presentation/pages/sale_shell_page.dart` (customer-card rendering).

## Impact and suspected cause

- Impact: a Sale actor can receive directly identifying and demographic customer data. If that disclosure is not explicitly approved and minimized, it creates a privacy, trust, and compliance risk across every active Sale account.
- Suspected cause: the endpoint selects identity/contact fields and the UI renders them without a documented business rule that resolves Q-18. This is a triage hypothesis, not a confirmed root cause.
- Recommended resolution: product/privacy owners should resolve Q-18 before acceptance, then align the RPC projection, UI masking/minimization, consent/RBAC policy, and audit expectation with that decision. Preserve any necessary direct-customer relationship semantics without exposing unnecessary values.

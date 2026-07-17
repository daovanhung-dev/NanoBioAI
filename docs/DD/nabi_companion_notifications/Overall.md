# Overall — NABI_COMPANION_NOTIFICATIONS / Thông báo đồng hành từ Nabi

## 1. Document information

| Field | Value |
|---|---|
| Module | M30 `NABI_COMPANION_NOTIFICATIONS` |
| Version / status | v1.0 / Approved - implementation contract |
| Source | `BD-NABI-NOTIFICATION-001` sections 1-22 and accepted plan 2026-07-17 |
| Release | One code release; staged rollout by feature flags |

## 2. Business goal and boundary

M30 gives Nabi a measurable, non-judgmental notification channel that explains
context, supports healthy habits and offers relevant Plus benefits without spam.
It owns the floating presentation, rule engine, delivery state, local OS campaign
delivery and analytics. It does not own payment approval, health algorithms,
expert booking, M09 schedule completion, or Sale referral/commission.

## 3. Actors and access

| Actor | Allowed | Excluded |
|---|---|---|
| Guest | Local `FREE-001`, care and profile; quick actions allowed by v1 | Cloud state, redeemable invite/reward writes |
| Authenticated Free | Free/contextual, milestone, care, report and profile catalog | Plus-only benefits before approved payment |
| Plus monthly | Annual upsell, care, reward, report, profile and invite eligibility by config | FamilyPlus-only behavior |
| Plus yearly | Care, reward, report, profile and user invite | Annual upsell |
| FamilyPlus | Care, reward, report and profile | Plus upsell catalog |
| Content Admin | Version/preview/activate definitions through audited RPC | Direct client-table writes |

## 4. Features

| ID | Feature | Source |
|---|---|---|
| `NABI_COMPANION_NOTIFICATIONS-F01` | Versioned catalog/config | BD §§7, 19 |
| `NABI_COMPANION_NOTIFICATIONS-F02` | Evaluate, prioritize and claim | BD §§8, 16, 17 |
| `NABI_COMPANION_NOTIFICATIONS-F03` | Global Nabi overlay and quick panel | BD §5, AC-01/10/11 |
| `NABI_COMPANION_NOTIFICATIONS-F04` | In-app and local OS delivery | BD §§16, 18, AC-09 |
| `NABI_COMPANION_NOTIFICATIONS-F05` | CTA, defer, dismiss, return intent | BD §§16.2-16.3, 18 |
| `NABI_COMPANION_NOTIFICATIONS-F06` | Preferences, analytics and invalidation | BD §§19-20, AC-07/12 |

## 5. State and flow

```text
eligible -> queued -> presented -> collapsed/opened
         -> deferred | actioned -> converted
         -> expired | cancelled | failed
```

Business event → typed snapshot gateways → pure evaluation policy → atomic claim →
foreground bubble or local OS scheduling → interaction outbox → optional Supabase sync.
One `occurrenceId` correlates both channels. Foreground presentation suppresses its
native twin. A background callback only persists an interaction; it never accesses UI,
Riverpod or performs a health action.

## 6. Business rules

| ID | Rule |
|---|---|
| `NABI_COMPANION_NOTIFICATIONS-BR01` | Priority: contextual, expiry, reward/streak, report, care, proactive upsell, referral; tie-break `priority`, `eligibleAt`, `notificationId`. |
| `...-BR02` | One proactive/session; new session on cold start or background ≥30 minutes. Contextual bypasses this cap but is once/screen instance and respects 30-second guard. |
| `...-BR03` | Proactive upsell ≤2/day, ≤5/rolling 7 days, same ID cooldown 72 hours. |
| `...-BR04` | “Để sau” snoozes 24 hours. Quiet hours use personal sleep window, fallback 21:00–07:00 in `Asia/Ho_Chi_Minh`. |
| `...-BR05` | Suppress during onboarding, input/keyboard collision, payment, consultation/call, critical error, inactive program, owned benefit or stale entitlement. |
| `...-BR06` | Dynamic content and destination use allowlisted keys only; missing/expired variables fail closed. No raw deep link or executable rule from config. |
| `...-BR07` | Only trusted `payment_approved` invalidates upsell, records conversion and resumes `returnTo`; pending payment shows verification state. |
| `...-BR08` | M30 native IDs/channels and `kind=nabi_companion` are separate from M09; legacy or `schedule_reminder` payload remains M09. |
| `...-BR09` | Analytics uses auth UUID/installation ID, never question text/raw health payload; remote upload requires opt-in and raw events expire after 90 days. |
| `...-BR10` | User invite is one-level and separate from Sale/FamilyPlus; 72-hour Plus trial and Wellness Point award are idempotent by source ID. |

## 7. Data ownership

| Entity | Owner/source | Key integrity |
|---|---|---|
| Definition cache | Supabase versioned definition → SQLite cache | `notification_id + content_version` |
| Occurrence | Local-first; authenticated merge via dedicated RPC | unique actor/notification/source/version |
| Event outbox | SQLite append-only until acknowledged/expired | unique event UUID |
| Preferences | Local; authenticated self-scoped remote copy | actor/installation |
| Membership/payment | M06/M13 trusted backend | never trusted from route/local flags |
| Reward/invite | M08/new trusted invite RPC | idempotent source IDs |

## 8. APIs/events

| ID | Contract |
|---|---|
| `NABI_COMPANION_NOTIFICATIONS-API01` | `get_active_nabi_notification_definitions()` returns safe active config. |
| `...-API02` | `claim_nabi_notification_occurrence(...)` atomically deduplicates multi-device delivery. |
| `...-API03` | `record_nabi_notification_events(jsonb)` batch-ingests allowlisted analytics. |
| `...-API04` | `merge_nabi_notification_guest_state(jsonb)` merges suppression state after login. |
| `...-API05` | Admin version/activate/kill-switch RPC requires `notifications.write`, reason, idempotency and audit. |

## 9. Non-functional requirements

- Engine is pure Dart and table-tested for all 20 IDs.
- Overlay supports 200% text scale, screen reader, contrast, keyboard/viewInsets and SafeArea.
- Config/state failures fail closed; local user interactions remain available offline.
- Schema/RLS/RPC updates are rebuildable from `docs/supabase/config.sql`.
- Production acceptance requires sandbox RLS/idempotency and Android/iOS foreground/background/terminated smoke.

## 10. ADRs and risks

| ID | Decision/risk | Status |
|---|---|---|
| `NABI_COMPANION_NOTIFICATIONS-ADR01` | M30 is separate from M09 and shares only bootstrap/navigation primitives. | Accepted |
| `...-ADR02` | `lib/features/nabi/` is canonical; v1 barrel temporarily re-exports compatibility APIs. | Accepted |
| `...-ADR03` | Local OS delivery only; server changes cannot notify until the app next synchronizes. | Accepted limitation |
| `...-RISK01` | Missing launch config disables affected definition; no production fake benefits/rewards. | Mitigated by fail-closed config |

## 11. Traceability

| Source | Feature | Rules | Tests |
|---|---|---|---|
| BD §5, AC-01/10/11 | F03 | BR05 | overlay/widget/accessibility |
| BD §§8,16,17 | F02/F04 | BR01-08 | engine/native/dedup |
| BD §§9-15 | F01/F02/F05 | catalog | 20-ID table tests |
| BD §§19-20, AC-12 | F06 | BR09 | outbox/RLS/retention |


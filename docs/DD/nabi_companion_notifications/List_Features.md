# List Features — NABI_COMPANION_NOTIFICATIONS

## 1. Inventory

| ID | Feature | Trigger | Functions | Views |
|---|---|---|---|---|
| `...-F01` | Catalog/config | startup/resume/config refresh | FN01 | V04 |
| `...-F02` | Evaluate and claim | typed business event/time tick | FN02/FN03 | V01 |
| `...-F03` | Nabi overlay/quick panel | app shell and presentation state | FN04 | V01/V02 |
| `...-F04` | In-app/local OS delivery | claimed occurrence | FN05 | V01 |
| `...-F05` | Interaction/navigation | open/close/defer/CTA/native tap | FN06/FN07 | V01-V03 |
| `...-F06` | Preference/analytics/invalidation | interaction/access/config change | FN08/FN09 | V03/V04 |

## 2. Required outcomes

### F01 — Catalog

- Load only active, effective, allowlisted definitions; cache the last valid version.
- Reject unknown policy/action/channel, missing dynamic variables or expired programs.
- Content Admin changes require reason, idempotency and audit.

### F02 — Evaluate and claim

- Build snapshots through typed gateways; never query UI widget state.
- Apply BR01-BR05 and the per-ID rule from `Notification_Catalog.md`.
- Persist eligibility, then claim one highest-priority occurrence atomically; duplicate events are idempotent.

### F03 — Overlay and quick panel

- One overlay in the user app shell, never Admin/onboarding/payment/input-sensitive contexts.
- Bubble has arrow, primary/secondary CTA, close, collapsed dot and reopen behavior.
- Empty quick panel exposes allowed AI Chat, today's tasks and partial profile actions.
- Position stores edge + normalized Y and clamps for SafeArea, keyboard and bottom navigation.

### F04 — Delivery

- Foreground presents in-app; background/terminated may schedule local OS when `pushEnabled` is true.
- M30 uses separate channel/ID namespace and `kind=nabi_companion`; M09 remains compatible.
- Reconcile/cancel stale OS entries after access, config or terminal-state change.

### F05 — Interaction and return intent

- Dismiss, defer, open and CTA are local-first and appended to analytics outbox.
- Offline network CTA keeps the occurrence retryable; invalid destination falls back safely.
- Pending payment never unlocks; `payment_approved` clears incompatible upsell and resumes return intent.

### F06 — Preference, analytics and invalidation

- In-app contextual explanation remains available even when native delivery is disabled.
- Remote analytics upload requires explicit opt-in; payload excludes question/health content.
- Raw events expire after 90 days; conversion attribution is the last primary CTA within 7 days.

## 3. Acceptance

- Every BD AC-01..15 maps to at least one function/view/test.
- All 20 IDs have audience/trigger/cooldown/destination/channel tests.
- Multi-device claim, guest merge and event ingestion are idempotent.
- Missing launch config, denied permission, offline state and invalid payload do not crash or expose stale benefits.


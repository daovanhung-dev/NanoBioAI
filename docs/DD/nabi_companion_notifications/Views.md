# Views — NABI_COMPANION_NOTIFICATIONS

## Inventory

| ID | View | Entry | Actor | States |
|---|---|---|---|---|
| `...-V01` | Global Nabi overlay/bubble | user app shell | Guest/User | idle, unread, open, deferred, offline, error |
| `...-V02` | Nabi quick panel | tap with no unread occurrence | Guest/User | actions filtered by access |
| `...-V03` | Notification preferences | Settings | User | native toggle, analytics consent, quiet hours |
| `...-V04` | Admin catalog/preview/metrics | Admin notifications section | Content Admin | list, preview, version, kill switch, metrics |

## V01 — Overlay

- Render above v1/v2/v3 user routes once; never render on Admin, onboarding, payment,
  critical error, consultation/call or when it would cover active input.
- Avatar semantics describe notification availability and drag instructions.
- Bubble content uses Nabitone, up to one message, primary CTA, optional secondary CTA,
  close button and an arrow toward Nabi. Collapsed state shows unread dot.
- Supports text scale 200%, screen reader, high contrast, SafeArea, keyboard viewInsets,
  bottom navigation reserve, drag/snap and persisted edge/normalized Y.

## V02 — Quick panel

Shows only authorized actions: talk to Nabi, today's tasks and partial profile update.
When a notification is unread, tap opens it instead of this panel.

## V03 — Preferences

- `pushEnabled` defaults false and requests OS permission only after user action.
- Analytics upload defaults false; local measurement and deletion policy are explained.
- Personal sleep schedule drives quiet hours; fallback 21:00–07:00 is displayed.

## V04 — Admin

Content Admin can preview copy, create a version, activate/archive a version and toggle
global/per-ID/channel rollout through audited RPC. UI cannot enter raw routes/scripts.
Metrics expose counts/rates only and no raw health or question payload.

## Navigation behavior

All CTA actions use `NabiNotificationDestination` and an allowlisted gateway. Invalid
resource IDs fall back to dashboard or membership comparison. Upgrade flow preserves
`returnTo`; only approved entitlement resumes it.


# Feature — M31 direct call on explicit help request

## Goal

When a user taps `Tôi cần hỗ trợ`, call the highest-priority active safety
contact that permits phone calling. Keep this action on-device. Preserve the
automatic +60-second no-response voice/SMS flow.

## Flow

1. Before starting monitoring, request Android `CALL_PHONE` permission when the
   global `phone_fallback_enabled` flag and an eligible contact are present.
2. On explicit help, save the local `needHelp` response without cloud dispatch,
   outbox insertion, or a claim that the call connected.
3. Select active phone-enabled contacts in ascending priority order.
4. Android calls with `ACTION_CALL` when permission and native launch succeed.
   If permission is denied or launch fails, open the system dialer with the
   selected number filled in and ask the user to press Call.
5. iOS opens `tel:`; iOS may ask the user to confirm.
6. If the global flag is off or there is no eligible contact, keep the alert
   active and show guidance. If both call and dialer launch fail, keep the alert
   active and show that another contact method is needed.

## Automatic escalation

- No response after 60 seconds continues through authenticated server voice/SMS
  dispatch and the existing bounded retry rules.
- The Edge dispatcher accepts `noResponse` events only. Explicit `needHelp`
  events are not eligible for server dispatch.
- SMS remains verified-only. Unverified contacts receive automatic voice only
  after separate, default-off per-contact consent.

## Data and rollout

- The global phone-call flag defaults to false. QA may enable it temporarily
  after the QA target and contact are verified; restore it to false after
  acceptance. Production is not changed.
- SQLite v28 removes the obsolete local contact preference while preserving
  the contact and its remaining fields.
- A forward Supabase migration removes the retired runtime/contact fields and
  restricts new dispatch rows to voice/SMS. It leaves previously applied
  migrations untouched and refuses to rewrite historical dispatch rows.
- Never store the QA number in source, fixtures, logs, or documents.

## Acceptance

- Unit tests cover contact priority, no dispatch on explicit help, disabled
  global flag, no eligible contact, permission denial, native call failure, and
  dialer fallback.
- Edge tests cover voice/SMS escalation after no response and reject explicit
  help.
- On the Xiaomi QA device, a user manually taps help and confirms that the
  other device rings and is answered. UI automation is not used for this step.
- iOS source behavior is covered; no connected iPhone acceptance is available.
- A successful test records only that the OS initiated a call under test
  conditions. It cannot guarantee all calls connect under every carrier, SIM,
  network, and recipient state.

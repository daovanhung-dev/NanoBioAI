# List Features — M31

| Feature ID | Feature | Actor | Trigger | Main functions | Views |
|---|---|---|---|---|---|
| M31-F01 | Paid access + rollout gate | Plus/FamilyPlus | Open sleep route | M31-FN01 | M31-V01 |
| M31-F02 | Start/stop monitoring | User | CTA | M31-FN02..04 | M31-V01 |
| M31-F03 | Room calibration | User/System | First start/recalibrate | M31-FN05 | M31-V01 |
| M31-F04 | Acoustic anomaly detection | Native runtime | PCM frame | M31-FN06 | M31-V01/M31-V05 |
| M31-F05 | 15s safety response | User/System | Confirmed event | M31-FN07..10 | M31-V05 |
| M31-F06 | SafetyContact CRUD/verify | User | Contacts settings | M31-FN11..14 | M31-V02 |
| M31-F07 | Automatic local phone handoff | System | no response after 15s + eligible contact | M31-FN10/FN27 | M31-V05 |
| M31-F08 | Scheduled arming reminder | User/System | Saved schedule/time | M31-FN18..19 | M31-V03 |
| M31-F09 | Metadata history | User | Open history | M31-FN20 | M31-V04 |
| M31-F10 | Native state recovery | System | Flutter engine attach/reconnect | M31-FN21 | M31-V01/M31-V05 |
| M31-F11 | Direct call on explicit help request | User | Tap `Tôi cần hỗ trợ` | M31-FN27 | M31-V05 |
| M31-F12 | Prefilled dialer fallback | User | Permission denied or direct-call launch failure | M31-FN24 | M31-V05 |
| M31-F13 | Retire legacy no-response dispatch retries | System | App start or local timeout handoff | M31-FN25 | M31-V05 |
| M31-F14 | Unverified voice-call consent | User | Contact settings | M31-FN26 | M31-V02 |

## M31-F01 — Paid access + rollout gate

**Main:** active FeatureHub entry → authenticated user → effective access → paid
check → server rollout → mount feature.  
**Errors:** auth missing, access unresolved, Free, rollout unavailable/off all
fail closed before microphone runtime mounts. Server runtime configuration
remains the authoritative rollout kill switch for monitoring entry. Local
phone handoff uses saved contact consent and operating-system permissions.

## M31-F02 — Monitoring lifecycle

User explicitly starts. Controller creates local session before native start.
Native returns service events and stop reason. Session stays local-first and
best-effort syncs cloud metadata.

## M31-F03 — Calibration

~30 seconds room baseline. UI shows progress. Completed noise-floor metadata is
stored; audio frames are discarded. User may recalibrate while active.

## M31-F04 — Detection

Native frame extractor labels non-medical acoustic candidates. Sensitivity
changes thresholds; detector output is rollout-gated. Only confirmed metadata
crosses Method/EventChannel.

## M31-F05 — Safety response

T0 alert + OK/help buttons; the same local phone flow starts after 15 seconds
without a response when an eligible contact is available. There is no intermediate
reminder. `OK` enters cooldown; `Need help` calls immediately without cloud
dispatch.

## M31-F06 — Safety contacts

Max 3. Server RPC owns insert/update/delete boundaries; phone change invalidates
verification. Verification Edge Function uses hashed OTP and provider SMS.
Verification is required for SMS, not calls; automated voice to a pending
number requires a separate default-off per-contact consent.

## M31-F07 — Automatic local phone handoff

At +15 seconds, use the highest-priority active contact opted into phone calls
without a server runtime-flag check. Android tries `ACTION_CALL` with permission
and otherwise opens `ACTION_DIAL`; iOS hands off `tel:`. Missing consent/contact
or failed handoff keeps the alert active with manual guidance. No backend
dispatch or retry is created.

## M31-F08 — Schedule reminder

Schedules up to the next seven matching local arming reminders. Reminder opens
feature with `source=scheduled_reminder`; never starts mic automatically.

## M31-F09 — History

Shows only event metadata: time, acoustic label/severity, user response and
escalation status. No playback because no raw recording exists.

## M31-F10 — State recovery

Native runtime snapshot on Flutter attach protects overnight sessions from UI
recreation. Current event metadata is enough to rebuild local event/state and
route a pending +15-second event through the same phone handler. Event state
prevents repeat handoff after success; an interrupted handoff is not retried
automatically. A stored `needHelp` response is never sent to the server.

## M31-F11 — Direct call on explicit help request

Select the active contact with the lowest priority number that allows phone
calling. Android requests `CALL_PHONE` before monitoring and uses `ACTION_CALL`
after an explicit help action; iOS opens `tel:` and leaves confirmation to iOS.
The app records only OS initiation or dialer handoff, never a connected call.
The legacy global `phone_fallback_enabled` flag does not control local timeout
or explicit calling. With no eligible contact, keep the alert and show guidance
without attempting cloud dispatch.

## M31-F12 — Prefilled dialer fallback

If Android call permission is denied or the OS cannot start the direct call,
open the system dialer with the selected number filled in. The user checks the
number and presses Call. If the dialer cannot open, the alert remains active and
the app explains that another contact method is needed. No automatic
emergency-service call is made.

## M31-F13 — Retire legacy dispatch retry

The timeout path creates no retry. On startup and for the current timeout event,
legacy no-response retry rows are marked failed locally so reconnect cannot
restart the old voice/SMS path. No outbox schema change is required.

## M31-F14 — Unverified voice-call consent

Each contact can separately allow automatic voice alerts while its number is
pending verification. Consent defaults off and is saved through the eight-
argument contact RPC. It permits voice only: SMS remains verified-only.
OTP remains available for users who want those channels.

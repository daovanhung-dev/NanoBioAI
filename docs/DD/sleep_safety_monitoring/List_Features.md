# List Features — M31

| Feature ID | Feature | Actor | Trigger | Main functions | Views |
|---|---|---|---|---|---|
| M31-F01 | Paid access + rollout gate | Plus/FamilyPlus | Open sleep route | M31-FN01 | M31-V01 |
| M31-F02 | Start/stop monitoring | User | CTA | M31-FN02..04 | M31-V01 |
| M31-F03 | Room calibration | User/System | First start/recalibrate | M31-FN05 | M31-V01 |
| M31-F04 | Acoustic anomaly detection | Native runtime | PCM frame | M31-FN06 | M31-V01/M31-V05 |
| M31-F05 | 30/60s safety response | User/System | Confirmed event | M31-FN07..10 | M31-V05 |
| M31-F06 | SafetyContact CRUD/verify | User | Contacts settings | M31-FN11..14 | M31-V02 |
| M31-F07 | Cloud escalation cascade | System | needHelp/noResponse | M31-FN15..17 | M31-V05 |
| M31-F08 | Scheduled arming reminder | User/System | Saved schedule/time | M31-FN18..19 | M31-V03 |
| M31-F09 | Metadata history | User | Open history | M31-FN20 | M31-V04 |
| M31-F10 | Native state recovery | System | Flutter engine attach/reconnect | M31-FN21 | M31-V01/M31-V05 |

## M31-F01 — Paid access + rollout gate

**Main:** active FeatureHub entry → authenticated user → effective access → paid
check → server rollout → mount feature.  
**Errors:** auth missing, access unresolved, Free, rollout unavailable/off all
fail closed before microphone runtime mounts. SQL 08 enables the current rollout
while preserving the server kill switch.

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

T0 alert + OK/help buttons; native reminder at 30 seconds; native escalation at
60 seconds if no response. `OK` enters cooldown; `Need help` escalates now.

## M31-F06 — Safety contacts

Max 3. Server RPC owns insert/update/delete boundaries; phone change invalidates
verification. Verification Edge Function uses hashed OTP and provider SMS.

## M31-F07 — Escalation

Server revalidates paid access and event eligibility. Stable event idempotency.
Voice then SMS fallback per verified priority. Webhook can continue after async
no-answer/failure.

## M31-F08 — Schedule reminder

Schedules up to the next seven matching local arming reminders. Reminder opens
feature with `source=scheduled_reminder`; never starts mic automatically.

## M31-F09 — History

Shows only event metadata: time, acoustic label/severity, user response and
escalation status. No playback because no raw recording exists.

## M31-F10 — State recovery

Native runtime snapshot on Flutter attach protects overnight sessions from UI
recreation. Current event metadata is enough to rebuild local event/state and
retry cloud escalation idempotently.

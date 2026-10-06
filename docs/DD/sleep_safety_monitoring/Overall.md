# Overall — M31 SLEEP_SAFETY_MONITORING

## 1. Traceability

| DD item | Source |
|---|---|
| Access Plus/FamilyPlus | `Q-M31-07`, `M31-BR01` |
| Android+iOS | `Q-M31-01` |
| Non-medical acoustic labels | `Q-M31-02`, `M31-BR05` |
| On-device/no raw audio | `Q-M31-03`, `M31-BR04` |
| 15 second response window | `Q-M31-04`, `M31-BR06/07` |
| Local phone handoff after 15s; retained Edge API contract | `Q-M31-05`, `M31-BR09`, BD v1.3 |
| SafetyContact max 3 | `Q-M31-06`, `M31-BR08` |
| Manual + scheduled reminder | `Q-M31-08`, `M31-BR03` |
| Sensitivity/calibration/cooldown | `Q-M31-09`, `M31-BR11` |
| No auto-115 | `Q-M31-10`, `M31-BR10` |

## 2. Architecture

```text
SleepTrackingPage
  -> SleepSafetyController (Riverpod Notifier, non-auto-dispose)
    -> SleepSafetyRepository
      -> SleepSafetyLocalDatasource -> SleepSafetyDao -> SQLite v28
      -> SleepSafetyCloudDatasource -> Supabase tables/RPC/Edge Functions
      -> SleepSafetyNativeGateway -> Method/EventChannel
        -> Android SleepSafetyForegroundService / AudioRecord
        -> iOS AVAudioSession + AVAudioEngine

Native PCM frame (RAM only)
  -> calibration / feature extraction
  -> experimental acoustic anomaly label
  -> confirmedSafetyEvent metadata
  -> Controller local-first event
  -> T0 alert
  -> +15s no response or immediate needHelp
  -> local Phone Gateway -> Android call/dialer or iOS tel:
  -> OS handoff silences alert; monitoring session remains active
```

The no-response route uses the highest-priority eligible contact and local
phone-call consent. It does not depend on `phone_fallback_enabled`, invoke the
backend dispatcher, or create a dispatch retry. The existing Edge
Function/provider cascade remains a separate server contract and is not used
by the M31 timeout.

Dependency rule remains:

```text
Presentation -> Controller -> Repository -> Datasource -> DAO/API/native gateway
```

Presentation does not import SQLite DAO or Supabase client.

## 3. State machine

| Phase | Entry | Exit |
|---|---|---|
| `idle` | no active session | user start |
| `arming` | permissions/session accepted | calibration or monitoring |
| `calibrating` | no valid baseline/recalibration | calibration complete |
| `monitoring` | detector active | confirmed event / stop / failure |
| `awaitingResponse` | T0 confirmed event | user ok/help or +15s no response |
| `escalating` | +15s no response | phone handoff accepted, unavailable, or failed; native session remains active |
| `cooldown` | user ok | cooldown elapsed -> monitoring |
| `failed` | permission/native/runtime failure | explicit restart after problem fixed |

Native timers are authoritative for wake/background response timing. Flutter
state mirrors them for UI/history/cloud orchestration. Native active-session
snapshot allows Flutter-engine recreation to recover session/event state.

## 4. Data model

### M31-E-preference

`user_id, enabled, sensitivity, schedule_enabled, schedule_start_minutes,
schedule_end_minutes, timezone, selected_weekdays, calibration_required,
calibration_noise_floor, calibration_updated_at, cooldown_seconds,
consent_version, updated_at`.

### M31-E-session

`id, user_id, started_at, ended_at, scheduled_window_start/end, sensitivity,
calibration_noise_floor, status, start_source, stop_reason, platform,
app_version, created_at, updated_at`.

### M31-E-event

`id, session_id, user_id, detected_at, event_type, severity, confidence,
relative_energy, baseline_delta, repetition_count, state, response, response_at,
escalation_required, escalation_status, created_at, updated_at`.

### M31-E-safety-contact

Server canonical: UUID id, owner user, name, relationship, E.164 phone, priority
1..3, verification status, verified timestamp, active timestamps, phone-call
opt-in (default true), and unverified voice-alert opt-in (default false).
Flutter stores only a local cache copy.

### M31-E-verification-challenge

Service-only OTP hash + expiry + attempts. No client select/write grant.

### M31-E-dispatch

Event/contact/channel/provider delivery evidence + idempotency; server channels
are voice and SMS. This retained backend contract is not invoked by the
15-second client timeout. Client may read its own dispatch summary if needed but
cannot write dispatch status.

### M31-E-runtime-config

`enabled, max_dispatches_per_hour, event_freshness_seconds,
phone_fallback_enabled, updated_at`. The legacy phone-call flag defaults false
but does not gate the local timeout handoff.

### Explicitly forbidden fields

No `audio`, `audio_blob`, `audio_path`, `recording`, `pcm`, `transcript`, or
similar raw-capture payload in M31 persistence schemas.

## 5. Detection design

### M31-ADR01 — deterministic rollout-gated detector v2

The delivery uses an on-device deterministic feature detector on Android/iOS.
Raw PCM remains RAM-only and is discarded after numeric feature extraction.
Detector v2 uses:

- RMS + peak signal level;
- peak / RMS (crest-like ratio);
- zero-crossing rate;
- robust room baseline from trimmed/median calibration samples;
- slow baseline adaptation on quiet frames only;
- rolling RMS / attack ratio;
- sustained high-energy frames and short-window repeated bursts;
- extreme-event bypass while calibration is still running.

The detector owns the **single** confirmed/candidate decision. The foreground
service does not apply a second independent energy/confidence threshold. Labels
remain acoustic hints only: sudden loud sound, impact-like, shout-like,
scream-like and repeated suspicious pattern.

Native also emits throttled transient `audioMetrics` (`signalLevel`, `peakLevel`,
`baselineLevel`, `relativeEnergy`, phase) for the live UI meter. These metrics
are not stored in SQLite/Supabase; no PCM, file, transcript or raw waveform is
sent through Flutter channels.

Numeric thresholds remain experimental implementation values, not medical or
clinical rules. SQL 08 enables the current paid rollout decision while the
server kill switch remains authoritative. Device hit-rate / false-positive /
battery evidence is still required before calling the detector production
validated.

### M31-ADR02 — no STT for sleep monitoring

Existing `speech_to_text` is for conversational voice and is not reused for
overnight monitoring because M31 must not transcribe the environment and needs
low-overhead frame-level features instead.

## 6. Platform contract

### Android

- `RECORD_AUDIO`
- `FOREGROUND_SERVICE`
- `FOREGROUND_SERVICE_MICROPHONE`
- user-visible microphone foreground service
- `START_NOT_STICKY`; no boot auto-start
- `AudioRecord` mono PCM frame -> feature extraction only
- persistent monitoring notification + native safety alert actions

### iOS

- `NSMicrophoneUsageDescription`
- `UIBackgroundModes = audio`
- `AVAudioSession.playAndRecord` + measurement mode
- `AVAudioEngine` input tap -> in-memory feature extraction
- native `UNNotificationCategory` actions for OK/Need help
- user-selected `tel:` fallback action is available for any active contact
  with phone fallback enabled, including pending contacts; a cold-start action
  is handed back to Flutter after contact config loads
- implementation kept in existing `AppDelegate.swift` in this delivery so no
  unsafe manual `project.pbxproj` mutation is required.

## 7. Cloud trust boundary

### Client may

- write own preferences/session/event metadata under RLS;
- read own contacts/runtime config;
- call approved RPC/functions with JWT.

### Client may not

- mark a contact verified;
- write OTP challenge;
- write dispatch success/provider status;
- set rollout true;
- bypass Plus/FamilyPlus with local state.

### Edge Function dispatch checks

1. Valid JWT/user.
2. `sleep_safety_runtime_config.enabled = true`.
3. `effective_user_access.membership_plan in ('plus','family_plus')`.
4. Event belongs to caller.
5. Event is recent and has `escalation_required` plus `noResponse`; an explicit
   `needHelp` response stays in the device's phone-call flow.
6. Stable idempotency not already processed.
7. Hourly request limit not exceeded.
8. At least one active verified contact or unverified contact explicitly opted
   into voice alerts. Unverified contacts are voice-only; SMS requires verified.

## 8. Retained server provider contract

The server-side contract below remains documented for compatibility, but the
M31 no-response timer does not call it. The app timeout is local phone handoff
only and uses saved contact opt-in; it is independent of server runtime flags.

Default no-response transport order:

```text
P1 voice
 -> immediate failed/no_answer: P1 SMS
 -> failed: P2 voice -> P2 SMS
 -> failed: P3 voice -> P3 SMS
```

The diagram above describes verified contacts. A pending contact receives voice
only when its separate default-off consent is enabled. If that call fails or is
not answered, the cascade skips SMS for that number and moves to the next
eligible priority. SMS remains verified-only.

When a user selects `Tôi cần hỗ trợ`, or the native no-response timer expires,
Flutter calls the highest-priority active contact that allows phone calls.
Both routes use saved contact consent and OS permissions; neither depends on
`phone_fallback_enabled`. Android requests `CALL_PHONE` before monitoring and
uses `ACTION_CALL` when permission is granted; otherwise it opens a prefilled
dialer. iOS opens `tel:` and may require system confirmation. The
event records OS call initiation or dialer handoff, never a connected call. If
no contact is eligible or handoff fails, the local alert remains active with
guidance. No new dispatch outbox row is created.

Provider callbacks carrying a valid webhook secret can continue this cascade
when failure/no-answer is asynchronous. A submitted/delivered/answered result
stops automatic priority advancement.

No official emergency service number is part of this flow.

## 9. Schedule contract

- Local notification may be scheduled for selected days/time.
- Tapping it navigates to `/sleep-tracking?source=scheduled_reminder`.
- It never calls `startMonitoring` directly from background.
- If monitoring starts, native runtime receives calculated schedule end and may
  stop the already-running session at that time.

## 10. Recovery / idempotency

- Android/iOS native runtime exposes `statusSnapshot` on EventChannel attach.
- Snapshot carries active session + current event metadata needed to recover UI.
- Controller reloads session/event from SQLite; if native event occurred while
  Flutter sink was unavailable, metadata is reconstructed locally without raw
  audio.
- Native `statusSnapshot` and live `escalationRequired` use the same local call
  handler. Event state prevents duplicate calls by event ID. A process restored
  in `no_response_call_starting` becomes interrupted and is not auto-retried;
  retry requires a user action.
- Legacy no-response outbox rows are marked failed locally and never dispatched
  after this contract change. The SQLite v28 outbox schema remains unchanged.

## 11. Security/privacy

- Provider/service-role/OTP secret never shipped in Flutter/native source.
- SafetyContact phone is not included in analytics/log copy.
- Native source does not write audio to disk.
- Edge responses expose only safe delivery summary, not contact phone/OTP.
- Direct DB writes to verification/dispatch state are revoked from authenticated.

## 12. Rollout

M31 runtime config keeps phone calling disabled by default. Forward migrations
through 12:00 and the changed Edge Functions are applied only to the confirmed
QA project. One Xiaomi direct-call acceptance passed; the temporary contact was
removed and the QA phone-call flag was restored to `false`. Production remains
unchanged. Never run `01_build_system.sql` or `02_seed_data.sql` against
staging/production.

This does not grant membership: Flutter and Edge Functions still require trusted
Plus/FamilyPlus access. The kill switch can be returned to `false` server-side
without shipping a client update. Phone calling requires Android/iOS acceptance.
Android/iOS physical-device, battery/thermal, acoustic, RLS,
Supabase and provider callback evidence remain explicitly
`Runtime-unverified`/`Sandbox-unverified` until actually executed.


## 13. FeatureHub entry

`Giám sát giấc ngủ` is an active FeatureHub action and routes to `/sleep-tracking`.
Free users may see the action but are stopped by the trusted paid access gate;
Plus/FamilyPlus users continue to the rollout gate and feature runtime. Stress and
Community remain planned surfaces.

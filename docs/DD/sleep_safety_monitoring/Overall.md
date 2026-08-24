# Overall — M31 SLEEP_SAFETY_MONITORING

## 1. Traceability

| DD item | Source |
|---|---|
| Access Plus/FamilyPlus | `Q-M31-07`, `M31-BR01` |
| Android+iOS | `Q-M31-01` |
| Non-medical acoustic labels | `Q-M31-02`, `M31-BR05` |
| On-device/no raw audio | `Q-M31-03`, `M31-BR04` |
| 30/60 second state machine | `Q-M31-04`, `M31-BR06/07` |
| Edge Function + SMS/voice | `Q-M31-05`, `M31-BR09` |
| SafetyContact max 3 | `Q-M31-06`, `M31-BR08` |
| Manual + scheduled reminder | `Q-M31-08`, `M31-BR03` |
| Sensitivity/calibration/cooldown | `Q-M31-09`, `M31-BR11` |
| No auto-115 | `Q-M31-10`, `M31-BR10` |

## 2. Architecture

```text
SleepTrackingPage
  -> SleepSafetyController (Riverpod Notifier, non-auto-dispose)
    -> SleepSafetyRepository
      -> SleepSafetyLocalDatasource -> SleepSafetyDao -> SQLite v21
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
  -> +30s reminder
  -> +60s escalation or immediate needHelp
  -> sleep-safety-dispatch Edge Function
  -> verified SafetyContact priority cascade
```

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
| `awaitingResponse` | T0 confirmed event | user ok/help, +30s, +60s |
| `reminder` | +30s no response | user ok/help, +60s |
| `escalating` | needHelp or +60s | dispatch accepted/failed; native session remains active |
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
1..3, verification status, verified timestamp, active timestamps. Flutter stores
only a local cache copy.

### M31-E-verification-challenge

Service-only OTP hash + expiry + attempts. No client select/write grant.

### M31-E-dispatch

Event/contact/channel/provider delivery evidence + idempotency. Client may read
own dispatch summary if needed but cannot write dispatch status.

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
5. Event is recent and has `escalation_required` plus `needHelp/noResponse`.
6. Stable idempotency not already processed.
7. Hourly request limit not exceeded.
8. At least one verified active contact.

## 8. Provider cascade

Default transport order:

```text
P1 voice
 -> immediate failed/no_answer: P1 SMS
 -> failed: P2 voice -> P2 SMS
 -> failed: P3 voice -> P3 SMS
```

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
- Cloud dispatch key is stable `sleep-safety-<eventId>` so reconnect does not
  create a new cascade for the same event.

## 11. Security/privacy

- Provider/service-role/OTP secret never shipped in Flutter/native source.
- SafetyContact phone is not included in analytics/log copy.
- Native source does not write audio to disk.
- Edge responses expose only safe delivery summary, not contact phone/OTP.
- Direct DB writes to verification/dispatch state are revoked from authenticated.

## 12. Rollout

`07_schema_sleep_safety.sql` creates the server config with `enabled=false` as a
fail-safe baseline. `08_enable_sleep_safety_rollout.sql` is the approved current
rollout decision and changes only `config_key=default` to `enabled=true`.

This does not grant membership: Flutter and Edge Functions still require trusted
Plus/FamilyPlus access. The kill switch can be returned to `false` server-side
without shipping a client update. Android/iOS physical-device, battery/thermal,
acoustic, RLS/sandbox and provider callback evidence remain explicitly
`Runtime-unverified`/`Sandbox-unverified` until actually executed.


## 13. FeatureHub entry

`Giám sát giấc ngủ` is an active FeatureHub action and routes to `/sleep-tracking`.
Free users may see the action but are stopped by the trusted paid access gate;
Plus/FamilyPlus users continue to the rollout gate and feature runtime. Stress and
Community remain planned surfaces.

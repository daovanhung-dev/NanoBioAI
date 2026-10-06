# Function List — M31

| ID | Function | Layer / planned source | Input | Output / side effect | Error / test focus |
|---|---|---|---|---|---|
| M31-FN01 | Resolve paid + rollout access | FeatureHub + presentation/providers | auth user | active tile → child or locked state | fail closed, Free upgrade, rollout off/error |
| M31-FN02 | `startMonitoring` | Controller | source + already-resolved rollout state | local session + native start | no duplicate rollout fetch; permission/native failure |
| M31-FN03 | `stopMonitoring` | Controller/native | reason | native stop + ended session | idempotent stop |
| M31-FN04 | Native service/audio session start | Android/iOS | session config | microphone capture active | user-start only, permission lost |
| M31-FN05 | Robust calibration | Native + Controller | 30s frames | trimmed/median numeric noise floor + progress | extreme-event bypass; no audio persistence |
| M31-FN06 | Acoustic detector v2 | Native | PCM frame RAM | confirmed/candidate decision + transient metrics | single decision layer, rolling energy/attack/impact/vocal-like policy |
| M31-FN07 | Confirm event | Native/Controller | candidate | event + T0 alert | duplicate suppression |
| M31-FN08 | No-response deadline | Native timer | event | emit automatic escalation at +15s | timer cancel on response |
| M31-FN09 | `respondOk` | Controller/native | eventId | response ok + cooldown | no dispatch |
| M31-FN10 | `requestHelp` / no-response timeout | Controller/native | eventId | direct local phone request / timeout phone handoff | neither route invokes server dispatch; timeout is +15s and flag-gated |
| M31-FN11 | Upsert SafetyContact | Cloud RPC | name/relation/phone/priority | contact pending/verified preserved if phone same | max3/E164/priority conflict |
| M31-FN12 | Delete SafetyContact | Cloud RPC | contact id | delete own contact | ownership |
| M31-FN13 | Request OTP | Edge Function | contact id | accepted + expiry | auth/rate/provider/no OTP leak |
| M31-FN14 | Confirm OTP | Edge Function | contact id + 6 digits | verified | hash/expiry/attempt limit |
| M31-FN15 | Retained server dispatch contract | Edge Function | eventId + idempotency | accepted/reused | existing backend API; not invoked by the M31 timeout |
| M31-FN16 | Provider submit | Shared Edge adapter | channel/to/message | provider id/status | generic HTTP contract |
| M31-FN17 | Provider callback cascade | Edge webhook | provider id/status | status + next attempt | secret/idempotency/priority; no SMS fallback to unverified contact |
| M31-FN18 | Save schedule | Controller/repository | preference | local/cloud preference | valid minutes/weekdays |
| M31-FN19 | Schedule arming notifications | Reminder service | preference | local notifications | no mic auto-start |
| M31-FN20 | List event history | Local datasource/DAO | user id | recent metadata | ownership/no raw audio |
| M31-FN21 | Restore native status | EventChannel/Controller | snapshot | session/event/machine recovery | same local phone route; event-ID handoff dedupe; interrupted handoff is not auto-retried |
| M31-FN22 | Live sound metrics | Native/EventChannel/Controller/UI | RMS/peak numeric features | 0..1 signal/peak/baseline meter state | throttled, RAM-only, stale-signal watchdog, no PCM payload |
| M31-FN24 | Open dialer fallback | Flutter/Android/iOS | user help action + active phone-call contact | dialer opens with number | used after permission denial or call launch failure; handoff is not a connected call |
| M31-FN25 | Retire legacy no-response retry | Controller/local datasource/DAO | app start or timeout event | old retry marked failed locally | no new outbox rows or backend dispatch; schema unchanged |
| M31-FN26 | Set unverified voice-alert consent | Contact form + 7-argument Cloud RPC | contact + explicit opt-in | preference saved; default off | does not enable SMS; legacy 5-argument RPC remains compatible |
| M31-FN27 | Initiate direct phone handoff | Controller + Android channel / iOS `tel:` | explicit help or enabled +15s timeout + highest-priority opted-in contact | Android OS call request or dialer handoff | `CALL_PHONE` requested before monitoring; fallback after denial/failure; never report connected |

## API / RPC contracts

### M31-API01 — `upsert_sleep_safety_contact`

Authenticated RPC. Inputs: nullable UUID contact id, name, relationship, E.164
phone, priority, phone-call opt-in and unverified voice opt-in. Server owns
`user_id`, verification and timestamps; phone calling defaults on per contact
and unverified voice alerts default off. The app uses the seven-argument
overload; the legacy five-argument overload remains available.

### M31-API02 — `delete_sleep_safety_contact`

Authenticated own-contact deletion.

### M31-API03 — Edge `sleep-safety-contact-verification`

```json
{ "action": "request", "contact_id": "uuid" }
```

or

```json
{ "action": "confirm", "contact_id": "uuid", "code": "123456" }
```

Response never includes OTP.

### M31-API04 — Edge `sleep-safety-dispatch`

```json
{ "event_id": "event-id", "idempotency_key": "sleep-safety-event-id" }
```

Server returns safe acceptance/reuse/priority/channel summary only.

### M31-API05 — Provider callback

Provider POSTs external id/status with `x-sleep-safety-token`. Server updates
trusted dispatch state and may continue cascade.

## Native channel contract

Control channel: `com.nanobioai.app/sleep_safety/control`  
Event channel: `com.nanobioai.app/sleep_safety/events`

Methods:

- `startMonitoring`
- `stopMonitoring`
- `startCalibration`
- `updateRuntimeConfig`
- `callPhone`
- `openDialer`
- `respondToAlert`
- `getMonitoringStatus`

Events:

- `statusSnapshot`
- `serviceStarted`
- `calibrationProgress`
- `calibrationCompleted`
- `monitoringReady`
- `audioMetrics`
- `detectorCandidate`
- `confirmedSafetyEvent`
- `userResponse`
- `escalationRequired`
- `serviceStopped`
- `permissionLost`
- `nativeFailure`
- `phoneFallbackRequested`
- `phoneFallbackUnavailable`


### M31-FN01/FN02 activation delta — 2026-08-24

- FeatureHub promotes `sleep-tracking` into the active grid and keeps the same
  `/sleep-tracking` route.
- `SleepSafetyAccessGate` remains the trusted Plus/FamilyPlus + rollout boundary.
- `sleepSafetyRolloutApprovedProvider` exposes a synchronous fail-closed view of
  the already-resolved `sleepSafetyRolloutProvider`.
- `startMonitoring()` reads that resolved state and never invokes
  `SleepSafetyRepository.isRolloutEnabled()` a second time.
- Notification permission is exposed through an injectable M31-only boundary;
  starting monitoring does not request Exact Alarm access.

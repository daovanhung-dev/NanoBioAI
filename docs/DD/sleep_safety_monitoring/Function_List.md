# Function List — M31

| ID | Function | Layer / planned source | Input | Output / side effect | Error / test focus |
|---|---|---|---|---|---|
| M31-FN01 | Resolve paid + rollout access | FeatureHub + presentation/providers | auth user | active tile → child or locked state | fail closed, Free upgrade, rollout off/error |
| M31-FN02 | `startMonitoring` | Controller | source + already-resolved rollout state | local session + native start | no duplicate rollout fetch; permission/native failure |
| M31-FN03 | `stopMonitoring` | Controller/native | reason | native stop + ended session | idempotent stop |
| M31-FN04 | Native service/audio session start | Android/iOS | session config | microphone capture active | user-start only, permission lost |
| M31-FN05 | Calibration | Native + Controller | 30s frames | numeric noise floor | no audio persistence |
| M31-FN06 | Acoustic feature detection | Native | PCM frame RAM | metadata candidate | sensitivity/feature thresholds |
| M31-FN07 | Confirm event | Native/Controller | candidate | event + T0 alert | duplicate suppression |
| M31-FN08 | Alert reminder | Native timer | event | +30s reminder | timer cancel on response |
| M31-FN09 | `respondOk` | Controller/native | eventId | response ok + cooldown | no dispatch |
| M31-FN10 | `requestHelp` / timeout | Controller/native | eventId | escalation required | immediate vs 60s |
| M31-FN11 | Upsert SafetyContact | Cloud RPC | name/relation/phone/priority | contact pending/verified preserved if phone same | max3/E164/priority conflict |
| M31-FN12 | Delete SafetyContact | Cloud RPC | contact id | delete own contact | ownership |
| M31-FN13 | Request OTP | Edge Function | contact id | accepted + expiry | auth/rate/provider/no OTP leak |
| M31-FN14 | Confirm OTP | Edge Function | contact id + 6 digits | verified | hash/expiry/attempt limit |
| M31-FN15 | Dispatch event | Edge Function | eventId + idempotency | accepted/reused | paid/event/rate/verified-contact checks |
| M31-FN16 | Provider submit | Shared Edge adapter | channel/to/message | provider id/status | generic HTTP contract |
| M31-FN17 | Provider callback cascade | Edge webhook | provider id/status | status + next attempt | secret/idempotency/priority |
| M31-FN18 | Save schedule | Controller/repository | preference | local/cloud preference | valid minutes/weekdays |
| M31-FN19 | Schedule arming notifications | Reminder service | preference | local notifications | no mic auto-start |
| M31-FN20 | List event history | Local datasource/DAO | user id | recent metadata | ownership/no raw audio |
| M31-FN21 | Restore native status | EventChannel/Controller | snapshot | session/event/machine recovery | engine recreation/idempotent escalation |

## API / RPC contracts

### M31-API01 — `upsert_sleep_safety_contact`

Authenticated RPC. Inputs: nullable UUID contact id, name, relationship, E.164
phone, priority. Server owns `user_id`, verification and timestamps.

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
- `respondToAlert`
- `getMonitoringStatus`

Events:

- `statusSnapshot`
- `serviceStarted`
- `calibrationProgress`
- `calibrationCompleted`
- `monitoringReady`
- `confirmedSafetyEvent`
- `alertReminder`
- `userResponse`
- `escalationRequired`
- `serviceStopped`
- `permissionLost`
- `nativeFailure`


### M31-FN01/FN02 activation delta — 2026-08-24

- FeatureHub promotes `sleep-tracking` into the active grid and keeps the same
  `/sleep-tracking` route.
- `SleepSafetyAccessGate` remains the trusted Plus/FamilyPlus + rollout boundary.
- `sleepSafetyRolloutApprovedProvider` exposes a synchronous fail-closed view of
  the already-resolved `sleepSafetyRolloutProvider`.
- `startMonitoring()` reads that resolved state and never invokes
  `SleepSafetyRepository.isRolloutEnabled()` a second time.
- Notification permission is exposed through an injectable provider boundary for
  deterministic controller tests; production still delegates to
  `NotificationBootstrap.scheduler.requestPermissions`.

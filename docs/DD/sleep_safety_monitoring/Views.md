# Views — M31

## M31-V01 — Sleep Safety Home (active paid route)

**Source:** `sleep_tracking_page.dart` + `sleep_safety_access_gate.dart`  
**Route:** `/sleep-tracking`

Entry:

- FeatureHub active tile: `Giám sát giấc ngủ`.
- The tile is visible as a normal capability, not under `Sắp ra mắt`.
- Free still reaches the paid gate and cannot start monitoring.

States:

- Access loading/error/Free/rollout-off.
- Idle ready.
- Arming/calibrating with progress.
- Monitoring.
- Alert overlay.
- Escalating.
- Cooldown.
- Native/permission failure.

Primary CTA: `Bắt đầu giám sát đêm nay` / `Dừng giám sát`.  
Secondary: sensitivity, schedule, contacts, history, recalibrate.  
Copy must always include the non-medical disclaimer and never say the system can
guarantee safety.

## M31-V02 — Safety Contacts

- list priority 1..3;
- status verified/pending/failed/revoked;
- add/edit/delete;
- request OTP and confirm 6-digit code;
- no FamilyPlus-member inference;
- user-visible errors must be friendly, not PostgREST/internal exception text.

## M31-V03 — Schedule

- enabled switch;
- start/end local time;
- selected weekdays;
- explanatory copy: schedule **reminds** the user to open NanoBio; it does not
  silently turn on microphone.

## M31-V04 — History

- latest metadata events;
- event type, detected time, response, escalation result;
- no audio player, waveform or transcript because no recording is stored.

## M31-V05 — Safety Alert Overlay

- title: `Bạn có ổn không?`
- countdown to escalation;
- primary safety actions:
  - `Tôi ổn`
  - `Tôi cần hỗ trợ`
- at +30s copy indicates Nabi is asking again;
- at +60s/needHelp indicates contact workflow is being requested;
- no “đã gọi thành công” copy until trusted server returns acceptance.

## Accessibility / lock-screen

- actions must have readable text, not color-only meaning;
- tap target >= 48dp where practical;
- high-contrast/dark text must remain legible;
- critical alert interaction also exists through native notification actions when
  screen is locked/backgrounded;
- reduced motion affects decorative animation only, never timers/state.

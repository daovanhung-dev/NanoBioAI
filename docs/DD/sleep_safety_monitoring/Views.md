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
- Monitoring with `Âm thanh môi trường` live level meter driven only by native numeric metrics.
- Candidate/loud-sound indication on the same meter; missing metrics show a no-signal state instead of fake animation.
- Alert overlay.
- Escalating.
- Cooldown.
- Native/permission failure.

Primary CTA: `Bắt đầu giám sát đêm nay` / `Dừng giám sát`.  
Secondary: live signal meter, sensitivity, schedule, contacts, history, analysis, recalibrate.  
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

- completed monitoring sessions plus latest acoustic metadata events;
- each completed session can open the night analysis page;
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
- Android keeps the microphone foreground notification separate from the alert
  notification and loops the alarm tone until OK/Need help/stop/failure.

## M31-V06 — Night Analysis

**Source:** `presentation/pages/sleep_night_analysis_page.dart`

Information hierarchy:

1. `Nabi Sleep Wellness Score` + data quality.
2. Monitoring duration and key local metrics.
3. Event timeline and event distribution.
4. Seven-night personal trend.
5. Optional morning self-report.
6. Optional Gemini analysis.
7. Safety/medical disclaimer.

Rules:

- The page is available only for a completed session belonging to the current
  authenticated user.
- Local formulas work offline and are persisted in SQLite v23.
- Fewer than three nights shows a baseline-building state instead of a fake
  trend conclusion.
- The morning check-in is self-reported. It may estimate sleep minutes and
  self-reported efficiency, but microphone data alone never produces sleep
  stages or actual sleep duration.
- Before Gemini is called, show a confirmation explaining that only aggregated
  metrics are sent. No recording, transcript, contact phone or API key is sent.
- AI error does not hide or invalidate deterministic local analysis.

## Accessibility / lock-screen

- actions must have readable text, not color-only meaning;
- tap target >= 48dp where practical;
- high-contrast/dark text must remain legible;
- critical alert interaction also exists through native notification actions when
  screen is locked/backgrounded;
- reduced motion affects decorative animation only, never timers/state.

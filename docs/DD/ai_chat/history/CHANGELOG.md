# CHANGELOG — AI_CHAT / AI Chat

## [v1.7] - 2026-08-23
### Changed
- Increased the per-turn app/plugin `listenFor` hard cap from 60 seconds to
  180.000 ms (3 minutes).
- Kept final results and the selected 200/500/1.000/2.000 ms endpointing rules
  able to end a turn earlier.
- Increased Voice user/history-item input bounds from 2.000 to 6.000
  characters while retaining the 2.000-character Gemini response bound and
  `maxOutputTokens = 256`.
- Documented that Android/iOS recognition services may final or stop before the
  hard cap; this is not a guarantee of continuous raw audio for 3 minutes.

### Validation
- DD/feature/checklist duration and text-bound contract is documented under
  `AI_CHAT-BR11`, `AI_CHAT-ADR05`, and `AI_CHAT-TC18`.
- Source, expanded 90/90 tests, targeted analyze (10 items/0 issues), format
  (21 files/0 changed), Android debug build and Xiaomi install PASS. Device
  continuity beyond 60 seconds remains pending; previous reaction-speed Android
  evidence remains valid.

## [v1.6] - 2026-08-23
### Changed
- Added user-selectable Voice endpointing: Siêu nhanh 200 ms, Nhanh 500 ms,
  Bình thường 1.000 ms by default, and Chậm 2.000 ms.
- Defined the value as silence after the latest recognized speech result, not
  Gemini or network response latency.
- Kept selection in page/controller RAM across Stop/Start, disabled changes
  while a session is active, and reset to 1.000 ms when the page/controller is
  recreated.
- Required native listen to start without a pause timer and arm the selected
  threshold only after the first non-empty partial result; final still ends the
  turn immediately.

### Validation
- Preserved the v1.5 Android baseline acceptance. Expanded format/analyze and
  86/86 tests PASS; Android debug build/install and reaction-speed smoke PASS on
  Xiaomi `220333QPG`, including delayed arm, two-turn/safe retry, selector
  lock/persistence and Stop during TTS. iOS remains pending macOS/iPhone evidence.

## [v1.5] - 2026-08-23
### Changed
- Replaced the `voice-chat-turn` Edge Function with a direct Flutter
  `GeminiRestClient.generateText` datasource; Supabase now serves only auth and
  effective-access data for the app gate.
- Locked the STT null-return/native-settle regression, bounded Gemini/TTS
  timeouts and client-only error mapping into `AI_CHAT-F03/FN03/API03`.
- Removed Deno/deploy acceptance from current Voice and retained Android/iOS
  real-device conversation evidence as release backlog.

### Accepted risk
- `GEMINI_API_KEY` is not committed or logged, but it is bundled into the app
  runtime and can be extracted from an APK.
- Plus/FamilyPlus enforcement is client-only and can be bypassed by a modified
  app or direct use of an extracted key. A trusted backend is required if this
  risk is no longer acceptable.

## [v1.4] - 2026-08-23
### Changed
- Added `AI_CHAT-F03`, `AI_CHAT-FN03`, `AI_CHAT-V03` and `AI_CHAT-API03` for
  Plus/FamilyPlus sequential Voice.
- Replaced Gemini Live/direct-key/custom PCM design with
  `speech_to_text -> voice-chat-turn -> Gemini REST -> flutter_tts`.
- Added exact-user fail-closed access, server JWT/entitlement ordering, bounded
  six-turn RAM history, lifecycle cancellation, safe error mapping and no
  NanoBio Voice quota contract.

### Validation
- DD/source mapping is documented. The source implementation is being delivered
  in the current coding session, but targeted validation, Supabase sandbox
  deploy/smoke, Android conversation smoke and iOS build/device acceptance are
  not claimed here.

### Superseded
- Gemini Live direct from Flutter, API key in the APK, guest Voice access,
  `voice-live-token`, custom PCM and barge-in are no longer accepted M07 Voice
  runtime contracts.
- This Edge Function design is itself superseded by v1.5 client-only Voice.

## [v1.3] - 2026-07-15
### Changed
- Added unified runtime defines, typed fail-closed AI behavior and quota commit retry ordering for logbug 14-7-26.

### Validation
- AI chat and launcher contract tests are linked from the delta.

## [v1.2] - 2026-06-30
### Changed
- Marked AI_CHAT DD docs as `Approved - DD docs complete`.
- Separated runtime/test/sandbox evidence into the Implementation Evidence Backlog.
- Converted unchecked DD requirement lists into documented acceptance/evidence requirement tables without claiming tests were executed.

### Validation
- Docs-only change; runtime code, SQL, Supabase config, and tests were not changed.

## [v1.1] - 2026-06-30
### Changed
- Recorded accepted product decisions Q-16 in README, Overall, Import_File, and checklist traceability.
- Reclassified prior question rows as answered decisions; remaining gaps are implementation evidence, sandbox/RLS/API verification, or planned assets.

### Decisions
- Q-16: Use Vietnam timezone, Asia/Ho_Chi_Minh.

### Validation
- Docs-only change; runtime code was not changed.

## [v1.0] - 2026-06-28
### Added
- Initial DD created from docs/BD/project_flow/BD_BioAI_Product_Flow_Sale_Admin_v2.0.md (BD-BIOAI-PRODUCT-FLOW-002), scope BD sections 6/M07, 16.1 AC-03/AC-04/AC-06, Appendix A UC-07.
- Created README, Overall, List_Features, Function_List, Views, Import_File, diagrams README, assets README, and changelog.

### Impact
- Affected module: M07 / AI_CHAT.
- Migration required: No runtime migration in this docs-only pass.
- Regression test required: Yes when implementation starts; see module test checklist and BD section 17.2.

### Historical Decisions - answered 2026-06-30
- Q-16: Múi giờ chuẩn cho reset quota, thời hạn gói, báo cáo và duyệt payment là gì?

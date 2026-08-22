# Worklog — Gemini Live song công cho Trò chuyện bằng giọng nói

## Phạm vi

- Thay pipeline voice realtime cũ `speech_to_text → text AI → flutter_tts` bằng
  Gemini Live audio-to-audio cho route V1 đã có auth guard.
- Giữ nguyên WIP text chat/SSE; không đọc `.env`, không thêm API key vào Flutter
  và không lưu audio/transcript.
- M07 `AI_CHAT` đã Approved/coding 100%. Delta này bổ sung implementation source
  cho voice realtime nhưng không được xem là production acceptance.

## Đã triển khai

- Domain contracts cho Live event/session, native PCM audio, ephemeral-token và
  consent theo tài khoản trên thiết bị.
- `GeminiLiveVoiceGateway`: PCM16 mono 16 kHz input, output PCM16 24 kHz,
  input/output transcription, VAD 700 ms + 300 ms prefix, interruption flush,
  session-resumption/GoAway, timeout 15 phút và teardown an toàn.
- UI chỉ mở session sau nút **Bắt đầu**; lần đầu hiển thị consent Gemini;
  pause/resume chỉ micro, Dừng/Lifecycle giải phóng toàn bộ audio.
- Android `AudioRecord(VOICE_COMMUNICATION)` + AEC/NS/AGC, AudioTrack,
  communication audio focus/route loa-Bluetooth; iOS `playAndRecord` +
  `voiceChat`, voice processing, `AVAudioEngine` PCM bridge và route/interruption.
- Edge Function `voice-live-token`: JWT user-scoped, check/commit quota
  `ai_chat_message`, Gemini ephemeral token locked model/audio/system prompt,
  generic safe errors only. Config giữ `verify_jwt = true`.
- Unit-source tests cho protocol/controller và Deno handler contracts.

## Validation

| Check | Result |
|---|---|
| `git diff --check` | PASS |
| `dart format` touched voice files | PASS |
| `flutter analyze` 18 touched Dart/test files | PASS — 0 issues |
| `flutter test` controller + protocol + interruption queue + GoAway resume | PASS — 13 tests |
| `./gradlew :app:compileDebugKotlin` | PASS — Android Kotlin/Flutter debug compile |
| `deno test --allow-net supabase/functions/voice-live-token/handler_test.ts` | BLOCKED — `deno` không có trong môi trường |
| iOS compile + Android/iOS real-device smoke | BLOCKED — không có Xcode/iOS toolchain hoặc thiết bị trong môi trường |

## Self-review

- API key chỉ được đọc từ Edge secret `GEMINI_API_KEY`; response Flutter nhận
  ephemeral token, model và expiry, không có key/audio/transcript/log provider.
- Voice controller không gọi AI text repository, SSE, `speech_to_text` hoặc
  `flutter_tts`; các implementation cũ giữ lại để không đụng WIP ngoài voice
  realtime.
- App rời foreground, stop, token/network failure và native interruption đều
  dừng capture/playback; voice xử lý nói chen bằng server `interrupted` thay vì
  heuristic echo/STT restart.
- Cần deploy Edge Function với secret thật, chạy Deno/Flutter targeted tests và
  smoke Android+iPhone (speaker/Bluetooth, deny permission, background, network
  reset, nhiều lượt/nói chen) trước khi phát hành.

# XiaoZhi ESP32 and Phone-Local AI

Use this domain for work under `iot/xiaozhi-esp32/`. This imported project is
an independent ESP-IDF firmware repository with an Android companion app; it is
not part of NanoBioAI's Flutter runtime or feature architecture. Paths under
`main/`, `scripts/`, and `phone_app/` below are relative to that subproject root.

## Required Context

Before changing or making claims about the subproject:

1. Read `iot/xiaozhi-esp32/AGENTS.md` and inspect `git status --short` from the
   NanoBioAI repository. Preserve all existing changes.
2. Read `iot/xiaozhi-esp32/docs/agent-context/README.md`, then follow its
   architecture, task-routing, and file-index links for the specific task.
3. For board, target, Kconfig, CMake, partition, or release work, also read
   `iot/xiaozhi-esp32/docs/agent-context/BOARDS_AND_BUILD.md` and the owning board README/config.
4. For phone app work, read `iot/xiaozhi-esp32/phone_app/README.md`, `iot/xiaozhi-esp32/phone_app/pubspec.yaml`,
   and the owning Dart/Android source before editing.

The imported snapshot includes current worktree edits and first-party
untracked files. Keep the source XiaoZhi project and this NanoBioAI copy
independent; do not add runtime imports, routes, services, or API coupling to
the main NanoBioAI app unless a separate request explicitly defines that
integration.

## Project Boundaries

- Firmware is C/C++ on ESP-IDF. `main/application.*` coordinates board,
  audio, display, network protocol, MCP, settings, assets, and OTA. Common
  hardware interfaces live under `main/boards/common/`; concrete wiring and
  drivers belong to a board directory.
- Each firmware build selects exactly one board implementation. Use
  `scripts/build.py` and the board's `config.json`/variant instead of editing
  generated `sdkconfig` or `build/` state as portable defaults.
- ESP-IDF 6.0.1 is the documented minimum; 6.1 is recommended. Do not assume
  ESP-IDF 5.x compatibility.
- `iot/xiaozhi-esp32/phone_app/` is a separate Android Flutter app. It manages/imports GGUF
  models, runs local LLM and Whisper inference, uses Android TTS/Opus, and
  offers an HTTP OTA-config endpoint plus a XiaoZhi WebSocket server.
- The phone-local flow is: the ESP requests OTA configuration over HTTP; that
  endpoint returns the phone's LAN WebSocket URL and a bearer token; firmware
  sends framed Opus/audio and XiaoZhi JSON messages over WebSocket; the phone
  performs speech recognition, LLM inference, and TTS locally. The OTA endpoint
  supplies connection configuration and does not itself provide AI inference.
  The current Android app keeps the screen awake while serving but has no
  foreground service, so it must remain open during use; model downloads need
  Internet initially, while device communication uses the same working LAN.
- `main/boards/ostb/ostb-xiaozhi-3st/` is the OSTB XiaoZhi 3ST ESP32-S3 board.
  Its local-AI build profile is `config.local-ai.json`, alongside the normal
  `config.json`; keep that machine/LAN profile unchanged unless specifically
  asked to update it. Its partition layout is for 16 MB flash and must be
  preserved when flashing devices with existing NVS/data.

## Change and Verification Boundaries

- Keep board-specific pin, peripheral, and configuration changes in that
  board's directory. Shared interfaces or protocol behavior belong in shared
  owners and should be checked against every affected transport.
- Treat NVS keys, board/release identity, partition layouts, OTA URLs, and
  local network configuration as compatibility-sensitive. Never copy a local
  profile's address into shared production configuration or project-wide
  examples.
- Ignore generated/dependency state such as `.git/`, `build/`,
  `managed_components/`, local `sdkconfig`, `iot/xiaozhi-esp32/phone_app/.dart_tool/`, and
  `iot/xiaozhi-esp32/phone_app/build/`. `sdkconfig.defaults*` and tracked source configuration
  remain project inputs.
- Firmware build success is not physical-device acceptance. Report source,
  build, and device evidence separately. Do not run firmware or Flutter builds
  for docs/context-only work.

## Context Entry Points

- Subproject rules: `iot/xiaozhi-esp32/AGENTS.md`
- Context router: `iot/xiaozhi-esp32/docs/agent-context/README.md`
- Runtime ownership: `iot/xiaozhi-esp32/docs/agent-context/ARCHITECTURE.md`
- Board/build constraints: `iot/xiaozhi-esp32/docs/agent-context/BOARDS_AND_BUILD.md`
- Task routing: `iot/xiaozhi-esp32/docs/agent-context/TASK_ROUTING.md`
- File and asset inventory: `iot/xiaozhi-esp32/docs/agent-context/FILE_INDEX.md`
- Phone-local AI implementation: `iot/xiaozhi-esp32/phone_app/README.md` and
  `iot/xiaozhi-esp32/phone_app/lib/services/`

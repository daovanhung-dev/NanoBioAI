# Nabi ESP32 and Nabi Cloud Assistant

Use this domain for work under `iot/nabi-esp32/` and its explicit NanoBioAI
cloud-assistant integration. The imported firmware snapshot and its
`phone_app/` remain separate, while `config.cloud-ai.json` pairs with the main
app's `nabi_esp_assistant` feature and the self-hosted backend. Paths under
`main/`, `scripts/`, and `phone_app/` below are relative to that subproject root.

## Required Context

Before changing or making claims about the subproject:

1. Read `iot/nabi-esp32/AGENTS.md` and inspect `git status --short` from the
   NanoBioAI repository. Preserve all existing changes.
2. Read `iot/nabi-esp32/docs/agent-context/CONNECTED_DEVICE_OSTB_3ST.md`.
   Do this for every IoT/ESP32 task, including tasks outside this subproject.
   Separate live-device readings from source configuration; apply board-specific
   values only when the task targets this OSTB 3ST.
3. Read `iot/nabi-esp32/docs/agent-context/README.md`, then follow its
   architecture, task-routing, and file-index links for the specific task.
4. For board, target, Kconfig, CMake, partition, or release work, also read
   `iot/nabi-esp32/docs/agent-context/BOARDS_AND_BUILD.md` and the owning board README/config.
5. For phone app work, read `iot/nabi-esp32/phone_app/README.md`, `iot/nabi-esp32/phone_app/pubspec.yaml`,
   and the owning Dart/Android source before editing.

The imported Nabi snapshot may include worktree edits and first-party
untracked files. Cloud integration is owned jointly by the main NanoBioAI app
under `lib/app_versions/v1/features/nabi_esp_assistant/`, the backend IoT
module, and this firmware tree. Keep `iot/nabi-esp32/phone_app/` independent
and outside this integration; do not import its runtime or edit it unless a
separate request explicitly asks for that app.

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
- `iot/nabi-esp32/phone_app/` remains a separate Android Flutter application
  and is not part of the Nabi integration.
- Nabi cloud uses the main Flutter app's `nabi_esp_assistant` feature, backend
  IoT endpoints and `iot/nabi_esp_cloud_contract.json`. The user signs in while
  the phone has Internet, then joins the ESP's WPA2 AP. During local setup,
  Android sends Wi-Fi plus the cached account credential over the ESP's local
  HTTP API; mobile data is not required. App credentials are encrypted in
  SQLite with an Android Keystore key and cleared on logout. Firmware stores
  account credentials in NVS as requested, authenticates over HTTPS using cloud
  contract v4, then opens the authenticated protocol-v3 server WebSocket. The
  separate `config.local-ai` flow and `iot/nabi_esp_contract.json` remain
  distinct. Read the feature DD and firmware integration flow before edits.
- `main/boards/ostb/ostb-nabi-3st/` is the OSTB Nabi 3ST ESP32-S3 board.
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
  `managed_components/`, local `sdkconfig`, `iot/nabi-esp32/phone_app/.dart_tool/`, and
  `iot/nabi-esp32/phone_app/build/`. `sdkconfig.defaults*` and tracked source configuration
  remain project inputs.
- Firmware build success is not physical-device acceptance. Report source,
  build, and device evidence separately. Do not run firmware or Flutter builds
  for docs/context-only work.

## Context Entry Points

- Subproject rules: `iot/nabi-esp32/AGENTS.md`
- Context router: `iot/nabi-esp32/docs/agent-context/README.md`
- Connected device snapshot (mandatory for every IoT/ESP32 task):
  `iot/nabi-esp32/docs/agent-context/CONNECTED_DEVICE_OSTB_3ST.md`
- Runtime ownership: `iot/nabi-esp32/docs/agent-context/ARCHITECTURE.md`
- Board/build constraints: `iot/nabi-esp32/docs/agent-context/BOARDS_AND_BUILD.md`
- Task routing: `iot/nabi-esp32/docs/agent-context/TASK_ROUTING.md`
- File and asset inventory: `iot/nabi-esp32/docs/agent-context/FILE_INDEX.md`
- Phone-local AI implementation: `iot/nabi-esp32/phone_app/README.md` and
  `iot/nabi-esp32/phone_app/lib/services/`

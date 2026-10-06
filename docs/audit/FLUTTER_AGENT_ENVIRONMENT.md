# Flutter Agent Environment Report

Updated: 2026-10-06

## Installed Skills

- Global Codex skill: `ui-ux-pro-max` at `~/.agents/skills/ui-ux-pro-max/SKILL.md`. The installer also generated `ui-styling`, `banner-design`, `slides`, `design`, `brand`, and `design-system` companion skills.
- Global Codex skills already present: `frontend-design`, `review-agent`, `imagegen`, `openai-docs`, `skill-creator`, and `skill-installer`.
- Project skills already present in `.codex/skills/` and mirrored in `.agents/skills/`: `nanobio-project-agent` and `create-dd-from-bd`.
- The official Flutter/Dart plugin is installed and enabled globally as `dart-flutter@dart-flutter` version `1.0.6`. It provides these Flutter skills:
  - `flutter-add-integration-test`
  - `flutter-add-widget-preview`
  - `flutter-add-widget-test`
  - `flutter-apply-architecture-best-practices`
  - `flutter-build-responsive-layout`
  - `flutter-fix-layout-issues`
  - `flutter-implement-json-serialization`
  - `flutter-setup-declarative-routing`
  - `flutter-setup-localization`
  - `flutter-use-http-package`
- It also provides Dart skills: `dart-add-unit-test`, `dart-build-cli-app`, `dart-collect-coverage`, `dart-fix-runtime-errors`, `dart-generate-test-mocks`, `dart-migrate-to-checks-package`, `dart-resolve-package-conflicts`, `dart-run-static-analysis`, `dart-setup-ffi-assets`, `dart-use-doc-examples`, `dart-use-ffigen`, `dart-use-path-package`, `dart-use-pattern-matching`, `dart-use-primary-constructors`, and `dart-write-documentation`.

## MCP Servers

Codex CLI currently lists these local/configured servers:

| Server | Status |
| --- | --- |
| `codex_app` | Disabled |
| `cua_repl` | Enabled |
| `dart-mcp-server` | Enabled |
| `node_repl` | Enabled |
| `supabase` | Enabled, OAuth |

The Dart server completed an MCP `initialize` handshake and `tools/list` call using Flutter `3.47.1` / Dart `3.13.1`. Server identity: `dart and flutter tooling` `1.1.2`. The returned tools include `dtd`, `widget_inspector`, `get_runtime_errors`, `hot_reload`, `hot_restart`, `flutter_driver_command`, `vm_service`, `pub`, `pub_dev_search`, `read_package_uris`, and `rip_grep_packages`.

The current Codex conversation's tool registry has not refreshed and does not yet expose Dart/Flutter tools. Restart Codex and open a new session to load the installed plugin into the active agent context.

## Available Flutter Workflows

Installed Flutter skills cover widget previews, responsive layout, layout issue fixes, widget tests, integration tests, architecture guidance, JSON serialization, declarative routing, localization, and HTTP usage. The official plugin is maintained at `https://github.com/flutter/agent-plugins`.

Project readiness checked:

- Flutter SDK: `3.47.1`; Dart SDK: `3.13.1` at `/home/daovanhung/development/Flutter/flutter`.
- `flutter widget-preview --help` exposes `start` and `clean`.
- `pubspec.yaml` already includes `flutter_test` and `integration_test`.
- No `@Preview` or `widget_previews` usage was found under `lib/`, `test/`, or `integration_test/`; no preview annotations were added by this setup.
- The UI/UX Pro Max Flutter stack search runs successfully, but its catalog currently labels guidance for Flutter `3.44.x` (verified `2026-08-13`). For version-sensitive Flutter behavior on this SDK, prefer current Flutter/Dart documentation and the official Flutter plugin.

## Install Results

- Official Flutter/Dart plugin: installed and enabled.
- UI/UX Pro Max CLI: `2.15.0`, installed globally under the existing NVM Node `20.20.2` / npm `10.8.2` environment; Python `3` is available for its local search scripts.
- UI/UX Pro Max global skill installation: succeeded.
- Failed installations: none. A preflight `uipro init --dry-run` command was rejected because this installed CLI version does not accept that option; the supported `uipro init --ai universal --global` command succeeded.

## Manual Configuration

- Added `/home/daovanhung/development/Flutter/flutter/bin` to `~/.profile`, so login shells resolve `dart` and `flutter`; verified with `bash -lc`.
- Restart Codex before expecting plugin skills or Dart MCP tools in the active conversation. The NVM-managed `uipro` command is available from the interactive shell that loads NVM.

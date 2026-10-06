Commit de xuat: chore(docs): thiet lap Flutter agent workflows

# Worklog - Cai dat Flutter Agent va UI UX Pro Max

## Thoi gian

- Ngay: 2026-10-06
- Bat dau: Khong ghi nhan rieng; phien tiep tuc tu buoc kiem ke moi truong.
- Ket thuc: 22:36 +07.
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: docs-context
- Module chinh: Codex global plugins/skills, `.codex`, docs audit.
- Yeu cau goc: cai Flutter/Dart agent plugin va UI/UX Pro Max neu chua co; xac minh Dart MCP; cau hinh workflow preview, responsive layout, layout diagnostics, widget/integration tests, hot reload; khong sua application code.

## Da lam

- Cai marketplace `flutter/agent-plugins` va plugin Codex `dart-flutter` global, version `1.0.6`, enabled.
- Cai `ui-ux-pro-max-cli` `2.15.0` va UI/UX Pro Max skill global qua NVM Node `20.20.2`; xac nhan Python 3 scripts tra ket qua.
- Dang ky Dart MCP global. MCP initialize va `tools/list` thanh cong; server `dart and flutter tooling` version `1.1.2`, co DTD, widget inspector, runtime diagnostics, reload/restart va cac cong cu Dart/Flutter.
- Them Flutter SDK bin vao `~/.profile`; login shell hien phan giai `dart` va `flutter`.
- Them quy tac Flutter UI vao `.codex/AGENTS.md`, tao bao cao moi `docs/audit/FLUTTER_AGENT_ENVIRONMENT.md`; worklog duoc dung de refresh canonical task-key index, khong them task key moi.
- Khong sua `lib/`, `test/`, `integration_test/`, API hay schema; khong them widget preview annotation.

## File code/docs da sua

- `.codex/AGENTS.md` - them workflow previews, responsive, diagnostics, tests va hot reload.
- `.codex/domains/ui-nami.md` - lien ket domain UI den Flutter workflow rules.
- `.codex/task-skills/README.md` - generated canonical task-key index duoc refresh tu worklog; khong them task key moi.
- `docs/audit/FLUTTER_AGENT_ENVIRONMENT.md` - ghi skills/MCP/workflows, trang thai, loi preflight va viec can restart.
- `~/.profile` - them Flutter SDK bin vao PATH login theo cach khong lap duong dan.
- `.codex/history/`, `.codex/task-skills/docs-context.md`, `docs/worklog/2026-10-06/013-worklog-flutter-agent-environment.md` - history/task-skill sinh lai tu worklog.

## Tai lieu lien quan

- `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, `.codex/workflows/docs-context.md`, `.codex/task-skills/docs-context.md`.
- Flutter official setup: `https://docs.flutter.dev/ai/get-started`.
- Flutter plugin: `https://github.com/flutter/agent-plugins`.
- Flutter hot reload rule: `https://raw.githubusercontent.com/flutter/agent-plugins/main/rules/flutter-hot-reload.md`.
- UI/UX Pro Max: `https://github.com/nextlevelbuilder/ui-ux-pro-max-skill`.

## Commands

- `codex plugin marketplace add flutter/agent-plugins`: PASS.
- `codex plugin add dart-flutter@dart-flutter`: PASS, version `1.0.6`.
- `codex plugin list` / `codex mcp list`: PASS; Flutter plugin enabled and `dart-mcp-server` enabled.
- `bash -ic 'npm install -g ui-ux-pro-max-cli'`: PASS, installed under existing NVM Node `20.20.2`.
- `bash -ic 'uipro init --ai universal --global'`: PASS, installed UI/UX Pro Max into `~/.agents/skills/`.
- `bash -ic 'uipro init --ai universal --global --dry-run'`: FAIL, this CLI version rejects `--dry-run`; normal install succeeded.
- `AGENT_PLUGIN=codex dart mcp-server` JSON-RPC initialize + `tools/list`: PASS, server `1.1.2` returned tools.
- `python3 ~/.agents/skills/ui-ux-pro-max/scripts/search.py "responsive mobile layout" --stack flutter`: PASS; catalog result currently targets Flutter `3.44.x`, so use official Flutter sources for version-sensitive guidance on `3.47.1`.
- `bash -n ~/.profile` and `bash -lc 'command -v dart && command -v flutter && dart --version'`: PASS; Dart `3.13.1` resolves from login shell.
- `flutter widget-preview --help`: PASS; `start` and `clean` are available.
- `grep` of `pubspec.yaml`: PASS; `flutter_test` and `integration_test` already exist.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL on existing baseline after history refresh: missing `docs/audit/source_truth_manifest.json`, historical stale Supabase/Nabi paths, and repository-wide source-truth validation; no new warning from this setup.
- `git diff --check`: PASS after history refresh and final docs updates.

## Loi/Rui ro

- Da fix: Flutter SDK was only on interactive `.bashrc` PATH; login profile now adds it for Codex MCP.
- Chua fix: current Codex conversation tool registry has not refreshed. Start a new Codex session and confirm Dart MCP tools become visible.
- Can kiem tra tiep: verify widget previews and MCP tools from the restarted Codex session.

## Ty le hoan thanh

- Hoan thanh: global plugin/skill install, MCP direct handshake and CLI registration, project docs/report, login PATH setup.
- Dang do: active agent-session plugin discovery awaits Codex restart.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - installs were verified and the Flutter-version lag in the UI/UX catalog was disclosed.
- Muc do hoan thanh task: project/environment setup complete; active-session tool exposure needs a new session.
- Bang chung kiem chung: Codex plugin/MCP listings, MCP JSON-RPC handshake and tool list, CLI skill search, login-shell SDK lookup, preview CLI help, dependency grep, `git diff --check`.
- Diem ton token/chua toi uu: `rg` is unavailable here; use `grep` and `find` for repository searches.
- Cach toi uu cho phien sau: after restarting Codex, check the active tool registry first and run a no-source-change preview/MCP smoke check.
- Task-skill can doc lan sau: `.codex/task-skills/docs-context.md`

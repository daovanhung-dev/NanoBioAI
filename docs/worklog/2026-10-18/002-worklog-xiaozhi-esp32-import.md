Commit de xuat: docs(worklog): ghi nhan nhap XiaoZhi ESP32 vao NanoBioAI

# Worklog - Nhap XiaoZhi ESP32 va noi context agent

## Thoi gian

- Ngay: 2026-10-18
- Bat dau: 15:25
- Ket thuc: 15:33
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: docs-context va nhap snapshot local
- Module chinh: `iot/xiaozhi-esp32/`, `.codex/`
- Yeu cau goc: copy working tree XiaoZhi ESP32 vao NanoBioAI, doc context project-owned va them routing/domain context cho agent; khong noi firmware vao runtime NanoBioAI.

## Da lam

- Copy theo manifest working tree XiaoZhi: 1,739 tracked va 32 first-party untracked, tong 1,771 file / 9,319,053 byte. Bao gom cac thay doi dang co, `phone_app/`, va `config.local-ai.json`; khong sua source goc.
- Bo qua Git metadata va output/dependency/cache da bi ignore; ban sao khong co `.git/`, `build/`, `managed_components/`, `.dart_tool/`, `phone_app/build/`, hoac `sdkconfig` local. Giu cac `sdkconfig.defaults*` va source config duoc track.
- Doc router/architecture/build/task context, file index, board OSTB 3ST, OTA flow va source phone-local AI lien quan. Binary asset inventory: 639 file (629 OGG, 7 PNG, 2 JPG, 2 EAF), tong 3,111,309 byte.
- Them domain `.codex/domains/xiaozhi-esp32.md` va route trong `.codex/AGENTS.md`, `PROJECT_MAP.md`, `.codex/README.md`, domain registry, project skill/router va `MAP_TREE.md`.
- Them ngoai le `.gitignore` de `iot/xiaozhi-esp32/phone_app/pubspec.lock` duoc Git nhan dien.
- File index trong snapshot ghi 1,770 path / 31 untracked, trong khi manifest live co 1,771 / 32 untracked. Ban copy theo manifest live; giu nguyen file index source de dam bao snapshot byte-for-byte.

## File code/docs da sua

- `iot/xiaozhi-esp32/` - tao snapshot 1,771 file tu working tree XiaoZhi hien tai.
- `.codex/domains/xiaozhi-esp32.md` - tao domain context, ownership, local AI flow va guardrails.
- `.codex/AGENTS.md`, `.codex/PROJECT_MAP.md`, `.codex/README.md`, `.codex/domains/README.md` - noi router/domain/source map.
- `.codex/skills/nanobio-project-agent/SKILL.md` va `references/{context-router,domain-map}.md` - them entry point cho subproject.
- `.codex/MAP_TREE.md` - cap nhat inventory context va source root.
- `.gitignore` - them ngoai le lockfile theo dung path.
- `docs/worklog/2026-10-18/002-worklog-xiaozhi-esp32-import.md` - ghi nhan pham vi, evidence va self-review.

## Tai lieu lien quan

- `iot/xiaozhi-esp32/AGENTS.md`
- `iot/xiaozhi-esp32/docs/agent-context/{README,ARCHITECTURE,BOARDS_AND_BUILD,TASK_ROUTING,FILE_INDEX}.md`
- `iot/xiaozhi-esp32/phone_app/README.md`
- `iot/xiaozhi-esp32/main/ota.cc`
- `iot/xiaozhi-esp32/main/boards/ostb/ostb-xiaozhi-3st/README.md`

## Commands

- Manifest + SHA-256 source/destination comparison: PASS - 1,771/1,771 path va noi dung khop.
- Binary asset inventory: PASS - 639 file, 3,111,309 byte.
- `git status --short --untracked-files=all -- iot/xiaozhi-esp32 | wc -l`: PASS - Git nhan dien 1,771 file; `phone_app/pubspec.lock` duoc bao gom.
- `pwsh -NoProfile -File .codex/tools/validate_codex_integrity.ps1`: FAIL - con thieu `docs/audit/source_truth_manifest.json` va stale path trong history/task-skill Nabi ngoai pham vi; sau khi sua, khong con bao path moi cua XiaoZhi.
- `git diff --check`: PASS.
- Flutter/ESP-IDF build va test: SKIPPED - chi nhap snapshot/context, khong sua runtime code.

## Loi/Rui ro

- Da fix: Git ignore root khong con loai `phone_app/pubspec.lock` khoi snapshot.
- Chua fix: validator repository-wide van phat hien source-truth manifest thieu va cac tham chieu stale khong thuoc thay doi nay.
- Can kiem tra tiep: chay build firmware va kiem tra tren OSTB 3ST khi co task rieng; task nay khong thuc hien build hay device QA.

## Ty le hoan thanh

- Hoan thanh: 100% pham vi copy, routing context va kiem chung snapshot local.
- Dang do: 0%; khong commit/push theo yeu cau local-only.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - snapshot byte-identical, context co routing ro rang va khong noi vao runtime app.
- Muc do hoan thanh task: hoan thanh theo plan; khong build/test runtime va khong commit/push.
- Bang chung kiem chung: manifest + SHA-256, dem binary assets, `git status`, `git diff --check`, va ket qua validator co ghi ro loi ngoai pham vi.
- Diem ton token/chua toi uu: output doc context dai; file index da giup thay inventory toan bo nhanh hon viec doc lan luot source.
- Cach toi uu cho phien sau: nap domain nay, doc `AGENTS.md` va file index cua subproject, sau do chi mo source theo task-routing.
- Task-skill can doc lan sau: `.codex/task-skills/docs-context.md`

Commit de xuat: fix(ci): restore Admin Web Pages deployment

# Worklog - Sua pipeline deploy Admin Web

## Thoi gian

- Ngay: 2026-11-01
- Bat dau: Khong ghi nhan chinh xac
- Ket thuc: 19:53
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: bugfix
- Module chinh: admin-web deployment workflow
- Yeu cau goc: Sua pipeline GitHub Pages dang dung tai Setup Node, bo sung test frontend that, tao commit local va khong push/deploy.

## Da lam

- Xac nhan workflow dung `admin-web/package-lock.json` cho npm cache va chay `npm ci`, trong khi lockfile da bi xoa.
- Xac nhan workflow co `npm test` nhung package chua khai bao script test.
- Them Vitest 5.0.5 va script `vitest run`; npm registry chua co Vitest 5.1 tai thoi diem kiem tra. Can Vite tu 6.4 tro len; lockfile giai ra Vite 6.4.5.
- Them ba regression test cho global fetch receiver, API readiness response va loi ket noi.
- Tai Node 22.23.4 vao `/tmp`, doi chieu SHA-256 voi file checksum chinh thuc, khong cai Node vao he thong.
- Tao `package-lock.json` va chay npm trong ban sao tam sach de tranh metadata `workspace:*` tu `node_modules` do Deno quan ly trong checkout.
- Khong thay doi workflow vi lockfile va script test da lam cac buoc hien co hop le. Khong sua API backend hoac config Ubuntu.

## File code/docs da sua

- `admin-web/package.json` - them test script, Vitest va rang buoc Vite tu 6.4.
- `admin-web/package-lock.json` - khoa dependency graph cho `npm ci` va cache Actions.
- `admin-web/src/lib/backend-client.test.ts` - regression tests cho readiness va fetch binding.
- `docs/fixbug/admin-web-deploy-lockfile/001-fixbug-admin-web-deploy-lockfile.md` - ghi symptom, root cause va fix.
- `docs/worklog/2026-11-01/003-worklog-admin-web-deploy-pipeline.md` - bang chung task.
- `.codex/history/` va `.codex/task-skills/` - refresh tu worklog.

## Tai lieu lien quan

- `.github/workflows/deploy-admin-web.yml` - cache dependency, `npm ci`, typecheck, test, build va deploy Pages.
- [Vitest Getting Started](https://vitest.dev/guide/) - yeu cau Node/Vite va cach chay Vitest.
- [Vitest Releases](https://main.vitest.dev/releases) - trang phien ban duoc duy tri.

## Commands

- Node 22.23.4 tai tu nodejs.org; SHA-256 checksum: PASS.
- `npm install --package-lock-only --ignore-scripts --no-audit --no-fund` (ban sao package sach): PASS.
- `npm ci` (ban sao project sach): PASS; 0 vulnerabilities.
- `npm run typecheck`: PASS.
- `npm test`: PASS; 3 tests.
- `npm run build`: PASS; Vite 6.4.5.
- `git diff --check`: PASS sau khi cap nhat tai lieu.
- `python3 tools/validate_docs_source_truth.py`: FAIL do thieu `docs/audit/source_truth_manifest.json`.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL vi cung thieu source-truth manifest va cac stale path cu trong history/task-skill; khong sua ngoai pham vi.
- GitHub Actions sau push: SKIPPED theo pham vi; khong push va khong deploy.

## Loi/Rui ro

- Da fix trong checkout: cache dependency co lockfile, `npm ci` va buoc test co the chay bang package/scripts hien tai.
- Chua xac nhan: GitHub Actions va Pages chua chay lai vi thay doi chi commit local.
- Can kiem tra tiep: sau khi nguoi dung push commit, xac nhan toan bo job deploy va bundle tren Pages.

## Ty le hoan thanh

- Hoan thanh: lockfile, test runner, regression tests va local CI sequence.
- Dang do: runtime deploy tren GitHub Pages cho toi khi commit duoc push.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - loi workflow duoc doi chieu voi run live va manifest; test runner bao ve lai loi fetch truoc day.
- Muc do hoan thanh task: hoan tat phan local; deploy chua chay do khong push.
- Bang chung kiem chung: npm ci, typecheck, 3 Vitest tests, production build, diff check.
- Diem ton token/chua toi uu: npm lan dau doc Deno `node_modules` va gap `workspace:*`; lan thu tiep theo da cach ly vao temp.
- Cach toi uu cho phien sau: kiem tra package-manager artifacts va node_modules mode truoc khi npm lockfile resolution.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`

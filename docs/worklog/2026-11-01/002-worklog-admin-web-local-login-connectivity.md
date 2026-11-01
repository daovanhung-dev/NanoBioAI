Commit de xuat: fix(admin-web): sua ket noi login local toi backend

# Worklog - Khac phuc dang nhap Admin Web local

## Thoi gian

- Ngay: 2026-11-01
- Bat dau: Khong ghi nhan chinh xac
- Ket thuc: 19:15
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: bugfix
- Module chinh: admin-web va NanoBio backend Ubuntu
- Yeu cau goc: Tai hien loi dang nhap local, tim nguyen nhan, sua ket noi va xac minh tai khoan super_admin.

## Da lam

- Tai hien banner loi tren `http://localhost:5173/NanoBioAI/`; Vite proxy khong co backend local tai `127.0.0.1:8000`.
- Xac dinh loi frontend rieng: `BackendClient` goi ham `window.fetch` nhu method cua client, gay `Illegal invocation` truoc khi gui request. Bind fetch vao `globalThis` va bo sung huong dan SSH tunnel cho Admin Web local.
- Xac nhan PostgreSQL role `nanobio_app` bi tu choi xac thuc trong khi PostgreSQL service van online; API `/health/live` tra 200 va `/health/ready` tra 503.
- Kiem tra role DB la login non-superuser, database `nanobio` ton tai va unit dang cai dat dung environment file cua backend. Xoay credential app bang gia tri ngau nhien sinh tren server, cap nhat dong bo role va `/etc/nanobio-backend/backend.env`; khong dua gia tri bi mat vao repo, terminal output hay worklog.
- Giu owner/group/mode environment file la `root:nanobio-backend`/`0640`, restart `nanobio-backend.service`; health live va ready deu tra 200.
- Mo SSH tunnel localhost toi loopback API Ubuntu; kiem tra `/health/live` va `/health/ready` ca truc tiep qua tunnel va qua Vite proxy, deu HTTP 200.
- Dang nhap qua UI local, xac nhan vao duoc Admin workspace, dang xuat; khong thay doi ho so hay du lieu user.
- Mot preflight credential rotation dung lai truoc khi thay doi do khac biet cach PostgreSQL in boolean; cap nhat kiem tra dinh dang va chay lai thanh cong.

## File code/docs da sua

- `admin-web/src/lib/backend-client.ts` - bind fetch vao global browser receiver de tranh `Illegal invocation`.
- `admin-web/README.md` - them cach mo SSH tunnel va chay Vite local.
- `/etc/nanobio-backend/backend.env` tren Ubuntu - cap nhat credential DB da xoay; file giu owner/group/mode ban dau.
- `docs/worklog/2026-11-01/002-worklog-admin-web-local-login-connectivity.md` - bang chung va gioi han task.
- `.codex/history/` va `.codex/task-skills/` - refresh tu worklog theo workflow du an.

## Tai lieu lien quan

- `backend/systemd/nanobio-backend.service` - backend doc environment file tu server.
- `backend/src/nanobio_backend/main.py` - health readiness probe chay `SELECT 1`.
- `.codex/domains/backend.md` - pham vi self-hosted backend.

## Commands

- Kiem tra direct va Vite proxy: `/health/live` HTTP 200, `/health/ready` HTTP 200.
- Deno regression smoke cho `BackendClient.checkReadiness()` voi fetch receiver strict: PASS.
- `deno run -A npm:typescript@5.7.3/bin/tsc -b --pretty false` (cwd `admin-web/`): PASS.
- `deno run -A npm:vite@6.4.3 build` (cwd `admin-web/`): PASS.
- Browser login qua local UI: PASS; vao Admin workspace; sign out PASS.
- Full API test suite: SKIPPED - khong co test script/test runner trong package hien tai; regression duoc kiem tra bang Deno va browser login end-to-end.
- `python3 .codex/tools/update_worklog_learning.py --check`: PASS, 19 generated history/task-skill files.
- `git diff --check`: PASS.
- `python3 tools/validate_docs_source_truth.py`: FAIL do thieu `docs/audit/source_truth_manifest.json`.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL do cung thieu source-truth manifest va con stale paths trong history/task-skill ve tai lieu cu; khong sua vi ngoai pham vi.
- Deploy GitHub Pages: SKIPPED - trang loi la Vite local; sua server service va local tunnel du de kiem chung yeu cau.

## Loi/Rui ro

- Da fix: local proxy tunnel hoat dong; readiness PostgreSQL duoc khoi phuc; fetch client khong con bi bind sai receiver.
- Chua fix: public IP API van khong truy cap duoc tu moi truong dev; local Admin Web can SSH tunnel con mo. Kiem tra unit runtime tim thay `nanobio-backend.service` su dung environment file; maintenance unit co trong source checkout nhung khong nam trong danh sach unit cai dat tren server luc kiem tra.
- Can kiem tra tiep: neu tunnel dong, mo lai SSH local forward truoc khi dung Admin Web. Khong luu credential DB hay SSH vao repo.

## Ty le hoan thanh

- Hoan thanh: sua loi local fetch, khoi phuc DB authentication, xac nhan health va dang nhap super_admin.
- Dang do: khong deploy GitHub Pages theo scope local.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - loi frontend duoc tai hien truc tiep, credential server duoc xoay khong lo secret, va login duoc xac nhan qua tunnel.
- Muc do hoan thanh task: hoan tat theo plan; khong thay doi du lieu user.
- Bang chung kiem chung: direct/proxy health 200, Deno regression smoke, TypeScript build, Vite build, browser login va sign out.
- Diem ton token/chua toi uu: can bat network trace som de phan biet proxy target, browser fetch receiver va database readiness.
- Cach toi uu cho phien sau: giu mot regression test frontend chinh thuc khi project chon lai test runner.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`

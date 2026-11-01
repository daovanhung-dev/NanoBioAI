Commit de xuat: feat(admin-web): quan ly tai khoan va goi Plus

# Worklog - Admin Web quan ly tai khoan va goi Plus

## Thoi gian

- Ngay: 2026-11-01
- Bat dau: Truoc 17:28 (khong ghi nhan chinh xac)
- Ket thuc: 17:32
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: coding
- Module chinh: Admin Web va backend modules/admin
- Yeu cau goc: Implement SPA quan tri tai khoan, du lieu user, va entitlement Plus theo plan da duyet; chi thay doi checkout, khong deploy hoac sua Ubuntu server.

## Da lam

- Tao lai SPA React/Vite/TypeScript tieng Viet trong `admin-web/`: dang nhap, sessionStorage va refresh rotation, kiem tra `super_admin`, tim theo ten/so dien thoai/email, chi tiet theo nhom, tao tai khoan tung dong, sua ho so, dong tai khoan, reset mat khau, va quan ly Plus.
- Them kiem tra `/health/ready`; hien trang thai loi ro rang va khoa thao tac ghi neu API chua san sang. Vite dev proxy khong ghi gia tri query hay thong tin nhay cam vao terminal.
- Backend tao/reset mat khau tam rieng cho tung tai khoan va chi tra plaintext mot lan; ho tro phone/email trong profile va kiem tra trung; gioi han cac route quan tri lien quan cho `super_admin`.
- Them API truy xuat du lieu user theo section, phan trang va audit ly do truy cap; loc password hash, token, secret, provider ID va duong dan tep khoi response.
- Them thu hoi entitlement Plus ngay trong NanoBio co audit/idempotency; khong goi billing provider va khong hoan tien. Dong tai khoan la soft close va thu hoi session.
- Bo sung API tests cho cac contract moi. Khong gui request ghi len server live va khong deploy.

## File code/docs da sua

- `admin-web/` - tao lai SPA quan tri va huong dan cau hinh local; cac xoa cu trong thu muc tai nguyen va microsite duoc giu nguyen.
- `backend/src/nanobio_backend/modules/admin/models.py` - request schemas cho tao tai khoan, cap nhat profile va thu hoi membership.
- `backend/src/nanobio_backend/modules/admin/query.py` - truy van du lieu theo section va loc truong nhay cam.
- `backend/src/nanobio_backend/modules/admin/router.py` - route du lieu user va revoke membership, kiem tra role.
- `backend/src/nanobio_backend/modules/admin/view.py` - xu ly profile, password, audit, idempotency va membership revoke.
- `backend/tests/test_api_core.py` - bo sung kiem tra contract admin.
- `docs/worklog/2026-11-01/001-worklog-admin-web-user-plus-management.md` - ghi nhan pham vi, bang chung va gioi han.
- `.codex/history/` va `.codex/task-skills/` - refresh tu worklog bang script du an; cac thay doi dirty co san duoc giu va cap nhat theo output deterministic.

## Tai lieu lien quan

- `docs/backend/listapi.md` - danh muc API backend.
- `docs/backend/result.md` - ket qua probe duoc ghi lai; can doc nhu bang chung tai thoi diem probe, khong phai xac nhan runtime hien tai.
- `.codex/domains/backend.md` - ranh gioi va quy tac backend self-hosted.
- `.codex/workflows/coding.md` - workflow coding.

## Commands

- `deno run -A npm:typescript@5.7.3/bin/tsc -b --pretty false`: PASS - typecheck frontend.
- `deno run -A npm:vite@6.4.3 build`: PASS - build frontend local.
- `uv run ruff check src/nanobio_backend/modules/admin tests/test_api_core.py`: PASS.
- `uv run ruff format --check src/nanobio_backend/modules/admin tests/test_api_core.py`: PASS - 6 files formatted.
- `uv run mypy src/nanobio_backend`: PASS - khong co loi tren 94 source files.
- `uv run pytest tests/test_api_core.py -q`: PASS trong dot validation truoc khi bo sung test coverage section; test coverage section moi chay rieng va PASS.
- Browser accessibility inspection cua trang login: PASS - hien ro API chua san sang va khong co user gia; chup screenshot bi timeout.
- `python3 tools/validate_docs_source_truth.py`: FAIL - checkout thieu `docs/audit/source_truth_manifest.json`.
- `pwsh -NoProfile -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: FAIL - cung thieu manifest va co cac path cu trong `.codex/history/WORKLOG_2026-08-16_meal_nutrition_estimation.md` va `.codex/task-skills/nabi-character/SKILL.md`.
- Live API integration/deploy: SKIPPED - plan ghi nhan `/health/ready` dang 503 do ket noi PostgreSQL; khong gui thao tac ghi live.
- `.codex/tools/update_worklog_learning.ps1`: chay sau khi ghi worklog; ket qua duoc xac nhan trong history refresh.

## Loi/Rui ro

- Da fix: tao/reset password tam duoc sinh rieng tu server, khong luu plaintext trong idempotency record; profile phone/email duoc chuan hoa va kiem tra trung.
- Chua fix: live database readiness dang la blocker theo evidence cua plan; cac API du lieu vua them chua duoc xac nhan tren server live. Kiem tra source-truth/integrity toan repo cung dang fail do manifest thieu va cac duong dan lich su cu ngoai pham vi task.
- Can kiem tra tiep: sau khi `/health/ready` tra 200, chay integration bang tai khoan test rieng cho login, tim user, phan trang, audit, profile, soft close, reset va membership. Provider billing khong bi huy khi thu hoi entitlement.

## Ty le hoan thanh

- Hoan thanh: implementation local cua SPA va backend contract trong pham vi plan.
- Dang do: live integration va production acceptance doi PostgreSQL readiness; chua deploy.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - UI va backend duoc thay doi cung contract; password, role, audit va readiness duoc xu ly phia server.
- Muc do hoan thanh task: implementation hoan tat local; live acceptance chua thuc hien theo gioi han plan.
- Bang chung kiem chung: TypeScript/Vite build, Ruff, mypy, backend API tests va browser accessibility inspection; readiness hien co la gioi han live.
- Diem ton token/chua toi uu: checkout co nhieu thay doi va xoa co san; can tiep tuc doi chieu staged/unstaged khi tao commit.
- Cach toi uu cho phien sau: khi DB san sang, dung tai khoan/test data rieng va ghi ro source, runtime, deploy, migration va acceptance.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`

Commit de xuat: fix(admin-web): phuc vu admin tren HTTPS IP cung origin

# Worklog - Chuyen Admin Web sang cung origin voi API

## Thoi gian

- Ngay: 2026-10-31
- Bat dau: 13:42
- Ket thuc: 13:55
- Timezone: Asia/Ho_Chi_Minh

## Pham vi

- Loai task: bugfix va trien khai Admin Web
- Module chinh: Admin Web auth, Nginx HTTPS IP
- Yeu cau goc: Dang nhap duoc Admin Web bang tai khoan `admin` co quyen `super_admin`.

## Da lam

- Tach loi `fetch` khoi loi thong tin dang nhap; loi ket noi gio hien thong bao rieng va co the thu lai.
- Build Admin Web voi base `/admin/` va API base `https://42.118.174.147`.
- Backup cau hinh Nginx thanh file thuong, mode 600; deploy static bundle theo release `/var/www/nanobio-admin/releases/20261031-01` va symlink `current`.
- Them Nginx route `/admin/` phuc vu static assets; giu proxy API/health, HTTPS va chuyen HTTP sang HTTPS.
- Xac minh user `admin`: active, `admin_status=active`, `force_password_change=true`, role `super_admin`. Khong sua DB, UUID, role, hash hoac session.
- Kiem tra qua trinh login tren trang cung origin. UI hien loi ket noi chinh xac hon; access log khong co POST `/api/v1/auth/login` tu thao tac nay, nen thong tin dang nhap chua toi backend va chua the xac nhan dang nhap thanh cong.

## File code/docs da sua

- `admin-web/src/lib/admin-api.ts` - tach loi mang khoi loi credential.
- `admin-web/src/lib/admin-api.test.ts` - them regression test cho loi `fetch`.
- `docs/worklog/2026-10-31/003-worklog-admin-web-same-origin-access.md` - ghi nhan ket qua va blocker.

## Trien khai server

- Nginx backup: `/var/backups/nanobio/nanobio-backend-before-admin-web-20261031-01.conf` (file thuong, mode 600).
- Admin Web release: `/var/www/nanobio-admin/releases/20261031-01`; current tro den release nay.
- Admin URL: `https://42.118.174.147/admin/`.
- Nginx `location /admin/` dung `root /var/www/nanobio-admin/current`; `/api/v1` va `/health` van duoc proxy den `127.0.0.1:8000`.

## Commands

- `npm test`: FAIL - host khong co `npm`; thay bang Vitest chay qua Deno voi dependency local.
- `deno run --allow-all --node-modules-dir=auto node_modules/vitest/vitest.mjs run`: PASS - 13 test files, 68 tests.
- `deno run --allow-all --node-modules-dir=auto node_modules/typescript/bin/tsc --noEmit`: PASS.
- `deno run --allow-all --node-modules-dir=auto node_modules/vite/bin/vite.js build --base=/admin/ --outDir=/tmp/nanobio-admin-dist --emptyOutDir`: PASS.
- `nginx -t`: PASS; Nginx reload: PASS.
- HTTPS probes: `/health/live`, `/admin/`, va Admin JS deu HTTP 200; asset bundle co IP server va khong co Supabase hay `api.nanobio.vn`.
- Login browser: NOT COMPLETE - trang cung origin hien loi ket noi; Nginx access log khong co POST login moi. API smoke truoc do da tra 200 va admin session tra 403 `PASSWORD_CHANGE_REQUIRED` theo dung chinh sach doi mat khau lan dau.
- `git diff --check -- admin-web/src/lib/admin-api.ts admin-web/src/lib/admin-api.test.ts`: PASS.

## Loi/Rui ro

- Da fix: Admin Web co the duoc phuc vu tai IP cung origin voi API; loi fetch khong con bi nhan la sai mat khau.
- Chua fix: Chrome van khong gui POST login den server, ke ca tren tab IP cung origin; do do chua co phien dang nhap Admin Web.
- Can kiem tra tiep: cho phep request XHR/fetch toi `https://42.118.174.147/api/v1/auth/login` trong Chrome profile dang dung hoac dung browser profile khong chan; sau do dang nhap lai va tu dat mat khau ca nhan khi form doi mat khau xuat hien.

## Ty le hoan thanh

- Hoan thanh: build, deploy static Admin Web tren IP, thong bao loi mang va xac minh role server.
- Dang do: dang nhap thuc te trong browser va mo dashboard; can request POST toi backend.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - thay doi hep, backup Nginx, deploy theo release va co rollback point.
- Muc do hoan thanh task: mot phan; chua dat yeu cau dang nhap vao dashboard.
- Bang chung kiem chung: 68 test pass, typecheck/build pass, Nginx health/static 200, user active `super_admin`; browser fetch fail va khong co POST trong access log.
- Diem ton token/chua toi uu: npm khong co tren host dev; phai chuyen sang Deno chay Vitest/TypeScript/Vite.
- Cach toi uu cho phien sau: lay trang thai request trong DevTools Network som hon; chi cap nhat credential neu backend thuc su tra 401.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`

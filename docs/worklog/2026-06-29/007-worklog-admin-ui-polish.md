Commit de xuat: docs(worklog): ghi nhan phien admin ui polish

# Worklog - Admin UI Polish

## Thoi gian

- Ngay: 2026-06-29
- Bat dau: khoang 19:55
- Ket thuc: 20:12
- Timezone: Asia/Saigon

## Pham vi

- Loai task: coding
- Module chinh: M15 `ADMIN_DASHBOARD`, M16 `ADMIN_OPS`
- Yeu cau goc: Toi uu lai UI Admin theo huong sang trong, hien dai, than thien; sua loi UI/overflow; Viet hoa co dau; them nut huong dan chi tiet.

## Da lam

- Thay `AdminShellPage` bang layout responsive: desktop co sidebar, man hinh hep co drawer/app bar, top bar/search/actions tu wrap de giam nguy co overflow.
- Lam moi dashboard, work queue, audit row bang card responsive, status chip, shadow, gradient accent va hover/tap animation nhe.
- Them nut `Huong dan` trong sidebar/top bar va dialog huong dan theo khu vuc: Tong quan, Nguoi dung, Thanh toan, Sale, Doi soat, Bao cao/Cau hinh, Audit.
- Viet hoa co dau cac label/status/action/error/loading/empty state hien thi trong UI Admin.
- Lam moi `AdminLoginPage` voi bo cuc responsive, intro panel va login card cao cap hon, giu nguyen flow dang nhap qua `adminControllerProvider`.
- Viet hoa thong bao controller va cap nhat test fixture tuong ung.
- Khong sua Supabase SQL/RPC/route contract/repository/datasource/schema.

## File code/docs da sua

- `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart` - sua - redesign responsive Admin shell, dashboard/work queue/audit, guide dialog va copy co dau.
- `lib/app_versions/admin/features/admin_panel/presentation/pages/admin_login_page.dart` - sua - redesign login responsive, card/form/copy/validator co dau.
- `lib/app_versions/admin/features/admin_panel/presentation/controllers/admin_controller.dart` - sua - Viet hoa thong bao ly do, cap nhat va permission denied.
- `test/app_versions/admin/admin_controller_test.dart` - sua - dong bo expected copy tieng Viet co dau.
- `docs/worklog/2026-06-29/007-worklog-admin-ui-polish.md` - tao - ghi nhan phien coding UI Admin.

## Tai lieu lien quan

- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `.codex/domains/ui-nami.md`
- `docs/checklist/checklist_complete_DD.md`
- `docs/checklist/checklist_task_coding.md`

## Commands

- `dart format lib/app_versions/admin/features/admin_panel/presentation/pages/admin_shell_page.dart lib/app_versions/admin/features/admin_panel/presentation/pages/admin_login_page.dart lib/app_versions/admin/features/admin_panel/presentation/controllers/admin_controller.dart test/app_versions/admin/admin_controller_test.dart`: PASS.
- `dart analyze lib/app_versions/admin`: PASS - No issues found.
- `flutter test test/app_versions/admin/admin_models_test.dart test/app_versions/admin/admin_controller_test.dart`: PASS - All tests passed.
- `git diff --check -- <Admin UI/controller/test files>`: PASS - chi co warning line ending LF/CRLF tu Git, khong co whitespace error.
- `flutter run -d web-server --web-hostname 127.0.0.1 --web-port 5210 -t lib/main_admin.dart`: PASS - Admin web server dang serve tai `http://127.0.0.1:5210`.
- `Invoke-WebRequest http://127.0.0.1:5210/admin/login`: PASS - HTTP 200.
- Playwright screenshot desktop/tablet/mobile: SKIPPED - browser plugin `iab` khong kha dung, may khong co Chrome/Edge, Playwright package co san nhung browser binary chua duoc cai; khong tu cai browser moi trong phien nay.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/update_worklog_learning.ps1`: PASS - refresh sau khi tao worklog.

## Loi/Rui ro

- Da fix: loi analyzer do dung `minHeight` truc tiep tren `AnimatedContainer`; da doi sang `ConstrainedBox`.
- Chua fix: chua co screenshot tu dong 3 viewport do thieu browser runtime local; can kiem tra thu cong tai URL web-server.
- Can kiem tra tiep: dang nhap bang `dev.admin@nanobio.local` khi Supabase sandbox/local san sang; kiem tra dashboard sau login tren desktop/tablet/mobile; bam nut `Huong dan` va cac action co dialog ly do.

## Ty le hoan thanh

- Hoan thanh: UI/Admin presentation polish, copy co dau, targeted analyze/test, web-server smoke HTTP 200.
- Dang do: visual screenshot acceptance tu dong va sandbox SQL/RPC/audit evidence van la blocker rieng cua M15/M16, khong thuoc pham vi polish nay.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - thay doi dung presentation/copy, khong dong vao Supabase contract, co validation muc tieu.
- Muc do hoan thanh task: hoan thanh phan implement; con thieu screenshot tu dong do moi truong khong co browser binary.
- Bang chung kiem chung: `dart analyze lib/app_versions/admin` PASS, targeted Admin tests PASS, `git diff --check` PASS, web-server `/admin/login` HTTP 200.
- Diem ton token/chua toi uu: file `admin_shell_page.dart` lon, nen can cat widget rieng trong phien refactor sau neu Admin UI tiep tuc mo rong.
- Cach toi uu cho phien sau: cai san browser runtime/Chrome hoac them widget/golden harness cho Admin presentation de verify responsive khong phu thuoc Supabase session.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`

Commit de xuat: docs(worklog): ghi nhan phien sale-dashboard-rpc-permission

# Worklog - Sale dashboard RPC permission

## Thoi gian

- Ngay: 2026-07-28
- Bat dau: 15:30
- Ket thuc: 16:16
- Timezone: Asia/Saigon

## Pham vi

- Loai task: bugfix + test
- Module chinh: Sale/referral dashboard va direct customers
- Yeu cau goc: khac phuc trang Tong quan va Khach hang khong tai duoc du lieu
  bang fixture Sale A.

## Da lam

- Xac nhan contract quyen `get_my_sale_dashboard()` can revoke/grant ro rang.
- Tai hien tren sandbox ca dashboard va direct customers loi PostgreSQL `42702`
  do `currency` mo ho trong hai RPC.
- Cap nhat quyen dong bo trong `config.sql` va
  `12-sale-module-update.sql`.
- Qualify `public.commission_records.currency` trong ca hai RPC va them
  regression contract.
- Them contract regression cho quyen dashboard va chay test/analyze focus.
- Kiem tra runtime an toan: `.env` tro den Supabase cloud, khong dung fixture
  hay ap dung SQL khi chua xac nhan local/sandbox.
- Xac nhan sandbox theo chi dinh va dang nhap fixture Sale A qua REST thanh
  cong; ca hai RPC van tra `42702` tren backend dang phuc vu app.
- Tai hien tren may that `12b304f9`: ca Tong quan va Khach hang deu hien trang
  thai loi khi app da dang nhap fixture Sale A.
- Kiem tra duong rollout co san: khong co Supabase CLI, ket noi Postgres hay
  phien SQL Editor/browser; khong ap dung SQL va khong chay `config.sql`.
- Nhan xac nhan transaction `12-sale-module-update.sql` da duoc ap dung vao
  sandbox; REST smoke sau deploy tra thanh cong Sale state, dashboard va direct
  customers cho fixture Sale A.
- Test lai tren may that `12b304f9`: tu Cai dat vao Sale, Tong quan hien 4
  khach/4 thanh toan va Khach hang hien 4 dong; refresh va quay lai Cai dat
  khong lam mat phien dang nhap.

## File code/docs da sua

- `docs/supabase/config.sql` - them revoke/grant cho Sale dashboard RPC.
- `docs/supabase/12-sale-module-update.sql` - them grant tuong ung cho cap
  nhat database hien huu.
- `test/docs/supabase_config_contract_test.dart` - regression contract.
- `docs/fixbug/sale-dashboard-rpc-permission/001-fixbug-sale-dashboard-rpc-permission.md` - tai lieu loi va cach sua.
- `docs/test/sale-dashboard-rpc-permission/001-test-sale-dashboard-rpc-permission.md` - ket qua kiem thu.

## Tai lieu lien quan

- `docs/supabase/README.md`
- `docs/supabase/19-dev-sandbox-accounts.md`

## Commands

- `powershell -ExecutionPolicy Bypass -File tools/run_v2.ps1 -ValidateOnly`: PASS.
- Focused Sale/rebuild contract tests: PASS, 36 tests.
- `flutter analyze test/docs/supabase_config_contract_test.dart`: PASS, khong co loi.
- Fixture Sale A REST RPC smoke: FAIL nhu ky vong truoc deploy, hai RPC tra
  `42702` sau khi dang nhap thanh cong.
- Fixture Sale A app smoke tren may that `12b304f9`: FAIL nhu ky vong, ca Tong
  quan va Khach hang hien loi tai du lieu.
- SQL Editor/CLI/Postgres rollout trong workspace: BLOCKED truoc khi nguoi dung
  ap dung transaction qua SQL Editor sandbox.
- `docs/supabase/12-sale-module-update.sql`: PASS, da duoc ap dung vao sandbox
  theo xac nhan cua nguoi dung.
- Fixture Sale A REST RPC smoke sau deploy: PASS, dashboard tra 4 khach/4
  thanh toan va direct customers tra 4 dong.
- Fixture Sale A app smoke sau deploy tren may that `12b304f9`: PASS, Tong
  quan va Khach hang hien du lieu sau khi vao tu Cai dat.

## Loi/Rui ro

- Da fix trong source: quyen dashboard va `currency` mo ho trong hai RPC.
- Da fix runtime: transaction SQL da duoc ap dung vao sandbox va ca hai RPC
  Sale tra du lieu cho fixture active.
- Can kiem tra tiep: khong co blocker cho pham vi loi nay; rollout moi truong
  khac can theo quy trinh Supabase rieng.

## Ty le hoan thanh

- Hoan thanh: sua SQL, regression test, deploy sandbox va xac minh REST/may
  that cho ca Tong quan va Khach hang.
- Dang do: khong co.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - da co bang chung tu regression, REST va may that
  sau deploy.
- Muc do hoan thanh task: hoan thanh toan bo pham vi duoc yeu cau.
- Bang chung kiem chung: loi sandbox `42702` truoc deploy, REST PASS sau
  deploy, UI PASS tren `12b304f9`, 36 Flutter tests va targeted analyze PASS.
- Diem ton token/chua toi uu: da dung RPC va UI dump focus thay vi broad check.
- Cach toi uu cho phien sau: bao gom quyen SQL sandbox ngay tu dau de rut ngan
  thoi gian giua tai hien va device acceptance.
- Task-skill can doc lan sau: `.codex/task-skills/bugfix.md`

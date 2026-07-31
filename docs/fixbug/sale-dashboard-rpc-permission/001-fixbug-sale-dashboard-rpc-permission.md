Commit de xuat: fix(sale): cap quyen RPC tong quan cho cong tac vien

# Fixbug - Sale dashboard RPC permission

## Van de

Tai khoan Sale da active co the mo khong gian Cong tac vien, nhung tab Tong
quan va Khach hang hien trang thai khong tai duoc du lieu.

Smoke RPC tren sandbox bang fixture Sale A da tai hien ca hai loi voi PostgreSQL
`42702`: `column reference "currency" is ambiguous`. Hai ham PL/pgSQL co output
`currency` va cung goi `max(currency)` tu `commission_records`, nen Postgres
khong phan biet duoc output variable va cot bang.

## Cach sua

- Revoke ro rang RPC dashboard khoi `public` va `anon`.
- Grant `EXECUTE` RPC dashboard cho `authenticated` trong ca entrypoint
  rebuild `config.sql` va ban cap nhat module Sale.
- Qualify cot bang `public.commission_records.currency` trong dashboard va
  direct-customer RPC.
- Them regression contract de bat buoc cap quyen nay trong rebuild SQL.

## Pham vi giu nguyen

- Khong thay doi UI, Dart API, payload RPC hoac logic hien thi khach hang.
- `get_my_sale_direct_customers()` van la hop dong doc du lieu rieng cua Sale
  active.

## Xac minh

- Unit/widget/contract Sale: PASS (36 tests).
- Static analysis cua regression test: PASS.
- Fixture Sale A REST smoke truoc deploy: FAIL nhu ky vong; ca dashboard va
  direct customers tra `42702` (`currency` ambiguous) sau khi dang nhap thanh
  cong.
- `12-sale-module-update.sql` da duoc ap dung vao sandbox da xac nhan.
- Fixture Sale A REST smoke sau deploy: PASS. Sale active, payout profile hoan
  chinh; dashboard tra 4 khach/4 thanh toan va direct customers tra 4 dong.
- Device `12b304f9`: PASS. Tu Cai dat mo khong gian Cong tac vien, lam moi
  Tong quan va mo Khach hang deu hien du lieu, khong con trang thai loi.

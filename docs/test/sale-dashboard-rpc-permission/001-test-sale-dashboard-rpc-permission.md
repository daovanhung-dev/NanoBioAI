Commit de xuat: test(sale): xac minh quyen RPC tong quan

# Test - Sale dashboard RPC permission

## Pham vi

- Sale dashboard va danh sach khach hang truc tiep.
- Contract quyen Supabase cho `get_my_sale_dashboard()`.

## Ket qua

| Kiem tra | Ket qua | Ghi chu |
| --- | --- | --- |
| Validate auth environment | PASS | Cau hinh runtime hop le, khong in gia tri nhay cam. |
| Focused Sale/rebuild contract tests | PASS | 36 tests pass, bao gom regression grant va currency RPC. |
| `flutter analyze test/docs/supabase_config_contract_test.dart` | PASS | Khong co loi analyzer. |
| Fixture Sale A REST RPC smoke truoc deploy | FAIL | Dang nhap thanh cong, sau do dashboard va direct customers deu tra PostgreSQL `42702` do `currency` mo ho. |
| Ap dung `12-sale-module-update.sql` | PASS | Da ap dung vao sandbox da xac nhan. |
| Fixture Sale A REST RPC smoke sau deploy | PASS | State active/payout hoan chinh; dashboard tra 4 khach, 4 thanh toan va customer RPC tra 4 dong. |
| Fixture Sale A app smoke tren may that `12b304f9` | PASS | Tu Cai dat mo Sale; Tong quan va Khach hang hien du lieu sau refresh, khong con trang thai loi. |
| Giu phien dang nhap fixture | PASS | Quay ve Cai dat va vao lai Sale thanh cong, khong dang xuat hoac xoa du lieu app. |

## Tieu chi smoke can chay khi co local/sandbox

- Dang nhap fixture Sale A va goi thanh cong Sale state, dashboard, direct
  customers sau khi ap dung `12-sale-module-update.sql` moi nhat.
- Tong quan tra 4 khach, 4 thanh toan, 199.000 diem cho, 3.097.000 diem da
  duyet, 2.500.000 diem da quy doi va 597.000 diem kha dung.
- Tab Khach hang hien 4 khach; Ready co 3 thanh toan, Pending co 1 va Prospect
  co 0.

## Bang chung device

- Tong quan hien 4 khach truc tiep, 4 thanh toan hop le, 199.000 diem dang
  giu va 597.000 diem kha dung.
- Khach hang hien 4 fixture direct customers; khong co thong bao “Chua tai
  duoc khach hang truc tiep”.

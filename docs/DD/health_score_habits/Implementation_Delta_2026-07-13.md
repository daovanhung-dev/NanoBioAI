# Implementation Delta — M08 và ranh giới hệ điểm thứ ba

| Thuộc tính | Giá trị |
|---|---|
| Module | M08 `HEALTH_SCORE_HABITS` |
| Trạng thái DD gốc | Approved — giữ nguyên |
| Nguồn bổ sung | `BD-BIOAI-WELLNESS-REWARDS-001` |
| Ngày | 2026-07-13 |

## 1. Quyết định ranh giới bắt buộc

Từ ngày 2026-07-13, hệ thống có ba loại điểm độc lập:

| Loại điểm | Mục đích | Có đổi voucher/tiền không | Nguồn dữ liệu |
|---|---|---|---|
| Điểm sức khỏe | Phản ánh tiến độ thói quen theo công thức M08 version hóa | Không | `health_score_ledgers` và completion projection |
| Điểm chăm sóc | Thưởng `+10` cho eligibility nhiệm vụ được xác nhận bằng proof | Chỉ đổi voucher | wellness wallet/ledger/allocation server-owned |
| Điểm Sale | Ghi nhận hoa hồng Cộng tác viên bán hàng | Theo chính sách quy đổi Điểm Sale | Sale commission/point ledger |

Không được dùng chung số dư, ledger, calculator, route, nhãn UI hoặc nghiệp vụ
điều chỉnh giữa ba loại. FamilyPlus vẫn tính Điểm sức khỏe theo subject, nhưng
ví Điểm chăm sóc thuộc tài khoản và không gộp theo gói gia đình.

## 2. Delta đối với completion M08

- Hoàn thành task có proof vẫn phát completion projection cho M08 theo transaction
  local; việc có/không có eligibility Điểm chăm sóc không thay đổi công thức M08.
- Hoàn tác trong cửa sổ yêu cầu M08 cập nhật/tính lại projection minh bạch; proof
  được giữ để truy vết.
- `wellness_point_ledgers` legacy `+1/-1` được nâng nhãn lịch sử thành `+10/-10`
  nhưng không được nhập vào số dư đổi voucher mới.
- Lỗi reward backend không được làm mất completion/proof local hoặc làm sai Điểm
  sức khỏe; trạng thái reward phải được biểu diễn riêng.

## 3. Implementation evidence

| Evidence | Trạng thái |
|---|---|
| Transaction local schedule/proof/linked data/health-score projection | Source-ready trong lifestyle local datasource và SQLite v14 |
| Wellness wallet/ledger/allocation tách riêng, append-only/server-owned | Source-ready trong migration 16 |
| Snapshot sync không push/delete wellness ledger | Source contract và cloud-sync test hiện có |
| M08 formula/version/disclaimer hiện hành | Không thay đổi bởi delta này |

Targeted daily/proof analyze sạch; các bundle 59 lifestyle/migration/notification/
cloud-sync và 50 dashboard test pass. Supabase static contract bundle 40 test,
full `config.sql` rebuild trên PostgreSQL 18 tạm, local end-to-end reward smoke,
RLS chéo user và direct-ledger rejection đều PASS. Bằng chứng này không thay thế
Supabase sandbox thật cho health-score/wellness ledger, nên không claim
production-ready.

## 4. Acceptance còn lại

- Chứng minh một completion hợp lệ cập nhật M08 và tạo đúng một `+10 Điểm chăm
  sóc` mà không trộn ledger.
- Chứng minh Guest/offline vẫn có health completion local nhưng không có số dư
  voucher.
- Chứng minh legacy history hiển thị đúng nhưng summary/redeem bỏ qua.
- Chạy RLS/snapshot tampering smoke trong sandbox cho hai tài khoản và FamilyPlus.

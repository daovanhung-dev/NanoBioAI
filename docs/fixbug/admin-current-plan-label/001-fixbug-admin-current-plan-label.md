Commit đề xuất: fix(admin-web): hiển thị đúng gói hiện tại

# Fixbug - Hiển thị sai gói hiện tại trong danh sách người dùng

## Nguyên nhân

- RPC `admin_search_users` trả `product_access_status` trong `subtitle` theo
  format cố định `email - product_access_status - sale_status`.
- Adapter dùng mapper chung nên không đưa mã gói vào `metadata.plan_code`.
- `AccountTable` vì vậy luôn dùng fallback `Miễn phí`, kể cả khi subtitle có
  `plus` hoặc `family_plus`.

## Thay đổi

- Thêm mapper riêng cho user, ưu tiên các trường gói có cấu trúc và fallback
  bằng parser strict theo format subtitle hiện tại.
- Chuẩn hóa bốn mã gói hợp lệ: `guest`, `free`, `plus`, `family_plus`.
- Hiển thị nhãn: `Khách`, `Miễn phí`, `Plus`, `FamilyPlus`; dữ liệu thiếu hoặc
  không hợp lệ hiển thị `Chưa xác định`.
- Giữ nguyên RPC, schema, RLS, membership, payment, Edge Function và
  credential.

## Kiểm chứng

- `git diff --check`: PASS.
- `npm run typecheck`: PASS.
- `npm test`: PASS - 16 tests.
- `npm run build`: PASS - production bundle được tạo; Vite chỉ cảnh báo chunk
  JavaScript lớn hơn 500 kB.
- Test regression bao phủ `free`, `plus`, `family_plus`, `guest`, subtitle sai
  format, chuỗi chứa `plus` không hợp lệ và ưu tiên metadata có cấu trúc.

## Rollout

1. Publish bundle Admin Web bằng workflow deploy hiện tại.
2. Mở trang người dùng và refresh bundle mới.
3. Kiểm tra tài khoản Plus hiển thị `Plus`, FamilyPlus hiển thị `FamilyPlus`,
   free hiển thị `Miễn phí` và guest hiển thị `Khách`.

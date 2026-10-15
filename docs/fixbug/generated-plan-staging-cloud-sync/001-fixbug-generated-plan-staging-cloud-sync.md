Commit de xuat: fix(ai): preserve generated plan staging across cloud sync

# Fix lỗi staging và hoàn tất lịch trình AI

## Triệu chứng

Trên điện thoại Android, thao tác tạo lịch trình 7 ngày bị ghi nhận thất bại dù
không có Flutter runtime exception. Lần tái hiện đầu có trạng thái
`failed / staging_fingerprint_changed`, 0 bữa ăn và 0 mục lịch. Khi chỉ thêm
khóa single-flight cho lần tạo lịch guest, lỗi staging vẫn tái hiện, nên khóa
đồng thời không phải nguyên nhân duy nhất.

## Nguyên nhân

1. Cloud pull thay dữ liệu user bằng `INSERT OR REPLACE`. SQLite xóa bản ghi
   `users` cũ trước khi chèn bản ghi mới; khóa ngoại `ON DELETE CASCADE` xóa
   request tạo lịch đang chạy cùng các chunk staging của nó. Cloud pull cũng
   có thể áp trạng thái request cũ lên request còn staging.
2. Cloud sync chuẩn hóa khóa bản ghi lịch/bữa ăn không phải UUID thành UUID.
   Transaction hoàn tất lịch vẫn kiểm tra các ID deterministic cũ, nên không
   khớp các hàng đã lưu: đủ nội dung nhưng request thành
   `failed / invalid_generation`.
3. Hai lần gọi tạo lịch guest đồng thời cho cùng một user dùng chung request
   mặc định và có thể tranh nhau ghi fingerprint. Đây là một race riêng; cần
   gộp cùng một lượt tạo lịch đang chạy.

## Thay đổi

- Chỉ chèn user nếu chưa tồn tại; nếu đã có thì cập nhật tại chỗ để không kích
  hoạt cascade xóa request/staging.
- Khi thay snapshot cloud, giữ request cục bộ có staging và bỏ qua trạng thái
  request cloud cũ cho request đó.
- Gộp các lần gọi tạo lịch guest đang chạy theo user ID.
- Sinh UUID v5 ổn định cho ID bữa ăn và mục lịch trước khi lưu từng ngày. Cùng
  một ID được dùng khi ghi từng ngày và khi commit toàn lịch, kể cả sau cloud
  sync.

## Kiểm chứng

- Regression test cho cloud replacement ban đầu đỏ: request `generating` bị
  đổi thành `failed` và staging bị cascade xóa. Sau sửa, test xác nhận trạng
  thái cùng 2 hàng staging được giữ nguyên.
- Regression test single-flight ban đầu tái hiện `Staging fingerprint
  mismatch`; sau sửa, 2 lần gọi chỉ chạy một lượt tạo và một commit.
- Test service: 21/21 PASS. Test cloud sync: 4/4 PASS.
- Dart analyzer trên 4 file Dart/test liên quan: không có lỗi.
- Hot reload trên app đang chạy: PASS; kiểm tra runtime sau cùng không thấy
  lỗi.
- Trên điện thoại với backend production đã được người dùng cho phép dùng để
  tái hiện, lần chạy đầu tiên sau khi giữ staging tạo đủ 7 ngày nhưng không
  hoàn tất do `invalid_generation`. Sau khi sửa ID ổn định, tiếp tục từ các
  chunk đã staging hoàn tất thành công: `succeeded`, 7 ngày, 35 bữa ăn, 14 bài
  tập, 77 mục lịch; `error_code` rỗng; staging còn 0 hàng và sync outbox còn 0
  hàng.

## Phạm vi xác nhận

Xác nhận này dựa trên SQLite của app trên điện thoại production-config và
runtime app. Không thực hiện thêm yêu cầu AI sau lần hoàn tất từ staging; không
thực hiện thay đổi schema hoặc Edge Function Supabase. `generation_source` của
request sau khi tiếp tục từ staging được lưu là `unknown`; trạng thái và dữ
liệu lịch đã hoàn tất đúng số lượng, nhưng provenance chưa được làm rõ trong
phạm vi fix này.

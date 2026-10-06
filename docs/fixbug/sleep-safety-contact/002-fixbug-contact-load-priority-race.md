Commit de xuat: fix(m31): cho tai safety contact truoc khi them

# Fix bug — Thêm liên hệ khi danh sách chưa tải xong

## Hiện tượng

Vừa mở trang người liên hệ an toàn, người dùng có thể bấm “Thêm người” trước
khi danh sách hiện có được tải. Form mặc định chọn ưu tiên 1; nếu ưu tiên đó đã
được dùng, RPC từ chối lưu do ràng buộc mỗi người dùng chỉ có một liên hệ ở mỗi
mức ưu tiên.

## Tái hiện và nguyên nhân

- Regression test giữ request tải liên hệ ở trạng thái chờ, rồi gửi yêu cầu lưu
  với ưu tiên 1 trong khi đã có liên hệ ưu tiên 1.
- Trước khi sửa, fake RPC trả `sleep_safety_contact_priority_conflict` và test
  thất bại.
- Controller khởi tạo danh sách bất đồng bộ; trang trước đó cho phép mở form
  ngay trên state rỗng ban đầu.

## Sửa

- Thêm trạng thái `contactsLoaded`; controller tải danh sách trước khi chọn
  ưu tiên nếu lần khởi tạo chưa hoàn tất.
- Trang hiển thị trạng thái đang tải và ẩn nút thêm cho đến khi có danh sách.
- Không đổi RPC, schema, giới hạn ba liên hệ hoặc quy tắc xung đột phía server.

## Kiểm chứng

- Regression đỏ trước sửa, xanh sau sửa.
- M31 focused Flutter suite: 22/22 PASS; targeted Flutter analyze: không có lỗi.
- Migration v26 test cần symlink tạm `libsqlite3.so` trong `/tmp` tới thư viện
  hệ thống.
- Tái hiện trên Android chưa hoàn tất: thiết bị từ chối `adb shell input tap`
  do thiếu `INJECT_EVENTS`. Không có liên hệ QA, OTP hay cuộc gọi nào được tạo.

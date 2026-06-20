# WORK RULE — FIX ISSUES

## Mục tiêu

Sửa đúng lỗi đã được ghi nhận, không làm thay đổi ngoài phạm vi issue và không phát sinh ảnh hưởng tới các chức năng ổn định khác.

## Quy trình bắt buộc

```text
Đọc Issue → Đọc Todo fix issue → Đọc BD/DD liên quan → Xác định nguyên nhân → Fix code → Ghi tài liệu fix
```

## Bước 1. Đọc issue

Đọc issue cần xử lý trong thư mục:

```text
docs/issues
```

Phải xác định rõ:

* Mã hoặc tên issue.
* Mô tả lỗi.
* Các bước tái hiện lỗi.
* Kết quả thực tế.
* Kết quả mong đợi.
* Mức độ ảnh hưởng.
* Module hoặc chức năng liên quan.
* File hoặc luồng nghi ngờ gây lỗi.

Không tự sửa lỗi khi issue chưa mô tả đủ để xác định phạm vi.

## Bước 2. Đọc todo fix issue

Đọc todo tương ứng trong thư mục:

```text
docs/todo
```

Todo phải làm rõ:

* Nguyên nhân dự kiến.
* Phạm vi file cần kiểm tra hoặc chỉnh sửa.
* Các bước fix.
* Rủi ro có thể ảnh hưởng tới chức năng khác.
* Điều kiện để xác nhận lỗi đã được xử lý.

Không tự ý thêm chức năng mới trong quá trình fix issue.

## Bước 3. Đọc BD và DD liên quan

Đọc BD gốc trong:

```text
docs/BD
```

Đọc DD tương ứng trong:

```text
docs/DD
```

Chỉ đọc BD/DD có liên quan trực tiếp tới issue để xác định:

* Hành vi nghiệp vụ đúng của chức năng.
* Luồng kỹ thuật đúng cần duy trì.
* Validation, trạng thái và điều kiện nghiệm thu.
* Phần nào là lỗi, phần nào là hành vi đúng theo thiết kế.

## Bước 4. Xác định nguyên nhân lỗi

Trước khi sửa code, phải xác định nguyên nhân gốc.

Có thể kiểm tra:

* Luồng gọi hàm hoặc luồng điều hướng.
* Dữ liệu đầu vào và đầu ra.
* Validation.
* State management.
* Repository, datasource, DAO hoặc API.
* Mapping model/entity.
* Điều kiện hiển thị UI.
* Logic xử lý bất đồng bộ.
* Migration hoặc cấu trúc database nếu liên quan.

Không sửa theo kiểu thử ngẫu nhiên nhiều file.

## Bước 5. Fix code

Chỉ sửa các file cần thiết để giải quyết đúng issue.

Khi fix phải:

* Bám theo BD, DD và todo đã có.
* Giữ nguyên kiến trúc dự án.
* Không refactor lớn nếu không cần thiết.
* Không đổi tên, di chuyển hoặc xóa file không liên quan.
* Không thêm mock data cho production.
* Không thay đổi hành vi của chức năng khác.
* Không trộn nhiều issue vào cùng một lần fix.
* Không thêm tính năng mới trong phiên fix issue.

## Bước 6. Ghi tài liệu fix bug

Sau khi fix, tạo tài liệu tại:

```text
docs/fixbug/<ma_issue_or_ten_issue>/
```

Tài liệu phải có các nội dung:

```text
1. Mã hoặc tên issue
2. Ngày fix
3. Mô tả lỗi ban đầu
4. Nguyên nhân gốc
5. Phạm vi file đã sửa
6. Mô tả thay đổi từng file
7. Luồng trước khi fix
8. Luồng sau khi fix
9. Rủi ro hoặc ảnh hưởng liên quan
10. Tên commit fix bug
11. Link tới issue và todo tương ứng
```

Đồng thời cập nhật worklog tại:

```text
docs/worklog/<yyyy-mm-dd>/
```

Worklog phải ghi rõ thời gian làm việc, phạm vi fix, file code đã sửa, tài liệu issue/todo/fixbug liên quan và commit.

## Quy tắc bắt buộc

```text
Fix issue chỉ được fix issue.
Không test toàn hệ thống trong phiên fix issue.
Không tạo issue mới trong phiên fix issue.
Không tạo todo mới trong phiên fix issue.
Không làm tính năng mới trong phiên fix issue.
Không sửa ngoài phạm vi issue nếu không có lý do kỹ thuật bắt buộc.
Nếu phát hiện issue khác, chỉ ghi nhận để xử lý ở phiên tìm issue riêng.
```

## Luồng xử lý chuẩn

```text
Đọc issue
        ↓
Đọc todo fix issue
        ↓
Đọc BD/DD liên quan
        ↓
Xác định nguyên nhân gốc
        ↓
Fix đúng phạm vi
        ↓
Ghi docs/fixbug
        ↓
Ghi docs/worklog
        ↓
Kết thúc phiên fix issue
```

## Checklist trước khi kết thúc

* [ ] Đã đọc issue tương ứng trong `docs/issues`.
* [ ] Đã đọc todo tương ứng trong `docs/todo`.
* [ ] Đã đọc BD và DD liên quan.
* [ ] Đã xác định nguyên nhân gốc của lỗi.
* [ ] Chỉ sửa file nằm trong phạm vi cần thiết.
* [ ] Không thêm chức năng mới.
* [ ] Không sửa các module không liên quan.
* [ ] Đã ghi tài liệu tại `docs/fixbug`.
* [ ] Đã cập nhật worklog.
* [ ] Đã ghi tên commit fix bug.
* [ ] Sẵn sàng chuyển sang phiên test riêng.

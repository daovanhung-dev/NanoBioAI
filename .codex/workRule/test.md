# WORK RULE — TEST

## Mục tiêu

Đảm bảo chức năng hoạt động đúng với nghiệp vụ trong BD, thiết kế trong DD và phạm vi code đã triển khai.

## Quy trình bắt buộc

Mọi phiên **test chức năng** phải thực hiện đúng thứ tự sau:

```text
Đọc BD gốc → Đọc DD tương ứng → Đọc phạm vi code đã triển khai → Test → Ghi kết quả
```

## Bước 1. Đọc BD gốc

* Đọc BD mô tả chức năng cần test trong:

```text
docs/BD
```

* Xác định:

  * Mục tiêu chức năng.
  * Vai trò người dùng.
  * Luồng chính.
  * Luồng ngoại lệ.
  * Điều kiện đầu vào và đầu ra.
  * Kết quả mong đợi.

## Bước 2. Đọc DD tương ứng

* Đọc DD của chức năng trong:

```text
docs/DD
```

* Xác định:

  * Điều kiện nghiệm thu.
  * Validation cần kiểm tra.
  * Các trạng thái loading, empty, success và error.
  * Dữ liệu, API, database hoặc service liên quan.
  * Các trường hợp biên cần test.

## Bước 3. Đọc phạm vi code đã triển khai

* Xác định các file đã được thêm, sửa hoặc xóa.
* Xác định luồng chạy thực tế của chức năng.
* Chỉ đọc các file liên quan trực tiếp tới chức năng đang test.
* Không mở rộng sang các module không liên quan.

## Bước 4. Test

Thực hiện test theo các nhóm sau:

### 1. Happy path

* Người dùng nhập dữ liệu hợp lệ.
* Người dùng thao tác đúng luồng chính.
* Chức năng trả về kết quả đúng như BD và DD.

### 2. Validation

* Bỏ trống trường bắt buộc.
* Nhập sai định dạng.
* Nhập dữ liệu vượt giới hạn.
* Nhập dữ liệu không hợp lệ theo nghiệp vụ.

### 3. Error handling

* Mất kết nối mạng.
* API lỗi hoặc timeout.
* Dữ liệu không tồn tại.
* Lỗi lưu hoặc đọc dữ liệu.
* Người dùng thao tác nhiều lần liên tiếp.

### 4. UI states

* Loading.
* Empty.
* Success.
* Error.
* Responsive trên các kích thước màn hình cần hỗ trợ.

### 5. Regression

* Kiểm tra các luồng cũ liên quan vẫn hoạt động.
* Không để việc thêm chức năng mới làm hỏng chức năng cũ.

## Bước 5. Ghi kết quả test

Sau khi test, tạo tài liệu kết quả tại:

```text
docs/test/<ten_chuc_nang>/
```

Nội dung cần có:

```text
1. Tên chức năng
2. Ngày test
3. Phạm vi test
4. BD đã tham chiếu
5. DD đã tham chiếu
6. Danh sách test case
7. Kết quả từng test case
8. Các lỗi phát hiện
9. Kết luận test
10. Tên commit liên quan
```

## Quy tắc bắt buộc

```text
Test chỉ thực hiện test.
Không sửa code trong phiên test.
Không fix bug trong phiên test.
Nếu phát hiện bug, chỉ ghi nhận bug.
Bug phải được lưu riêng tại docs/issues.
Chỉ xác nhận test pass khi toàn bộ tiêu chí BD và DD đều đạt.
```

## Luồng xử lý khi phát hiện lỗi

```text
Test phát hiện lỗi
        ↓
Ghi rõ bước tái hiện lỗi
        ↓
Ghi kết quả mong đợi và kết quả thực tế
        ↓
Lưu issue tại docs/issues
        ↓
Kết thúc phiên test
```

## Checklist trước khi kết thúc test

* [ ] Đã đọc BD tương ứng.
* [ ] Đã đọc DD tương ứng.
* [ ] Đã xác định phạm vi code cần test.
* [ ] Đã test happy path.
* [ ] Đã test validation.
* [ ] Đã test error handling.
* [ ] Đã test loading, empty, success và error state.
* [ ] Đã kiểm tra regression.
* [ ] Đã lưu kết quả tại `docs/test`.
* [ ] Đã tạo issue nếu phát hiện lỗi.
* [ ] Không sửa code trong phiên test.

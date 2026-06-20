# WORK RULE — DEVELOP

## Mục tiêu

- Đảm bảo mọi chức năng được lập trình đúng theo tài liệu nghiệp vụ và tài liệu thiết kế đã được phê duyệt.

- Mặc định coding ở v2, chỉ coding ở v1 khi có chỉ định rõ ràng

## Quy trình bắt buộc

Mọi phiên **develop/coding chức năng** phải thực hiện đúng thứ tự sau:

```text
Đọc BD gốc → Đọc DD tương ứng → Coding
```

### Bước 1. Đọc BD gốc

- Tìm và đọc bản **BD gốc** mô tả chức năng được yêu cầu trong thư mục:

```text
docs/BD
```

- Xác định rõ:
  - Mục tiêu nghiệp vụ của chức năng.
  - Vai trò người dùng được sử dụng chức năng.
  - Luồng hoạt động chính và luồng ngoại lệ.
  - Điều kiện đầu vào, đầu ra và kết quả mong đợi.
  - Các ràng buộc nghiệp vụ liên quan.

- Không tự suy diễn hoặc thay đổi nghiệp vụ khi BD chưa mô tả rõ.

### Bước 2. Đọc DD tương ứng

- Tìm và đọc tài liệu **DD** tương ứng với chức năng trong thư mục:

```text
docs/DD
```

- Xác định rõ:
  - Thành phần cần tạo hoặc chỉnh sửa.
  - Luồng xử lý kỹ thuật.
  - Model, Entity, Repository, Datasource, API hoặc Database liên quan.
  - Validation, trạng thái loading, empty, success và error.
  - Điều kiện nghiệm thu của chức năng.

- DD là tài liệu kỹ thuật trực tiếp để triển khai code.

### Bước 3. Coding

Chỉ bắt đầu coding sau khi đã đọc đầy đủ BD và DD tương ứng.

Khi coding phải:

- Bám đúng nghiệp vụ trong BD.
- Bám đúng thiết kế kỹ thuật trong DD.
- Tuân thủ kiến trúc hiện có của dự án.
- Không tự ý sửa phạm vi của chức năng.
- Không tạo logic giả, dữ liệu mock hoặc đường xử lý tạm cho production.
- Không sửa các module không liên quan nếu không cần thiết.
- Giữ nguyên các luồng đang hoạt động ổn định.
- Đảm bảo code có thể test, bảo trì và mở rộng.

## Quy tắc bắt buộc

```text
Không có BD → Không coding nghiệp vụ mới.
Không có DD → Không triển khai kỹ thuật chi tiết.
BD và DD mâu thuẫn → Dừng coding, ghi nhận điểm mâu thuẫn.
Yêu cầu ngoài BD/DD → Không tự ý thực hiện, cần bổ sung tài liệu trước.
```

## Checklist trước khi coding

- [ ] Đã xác định BD tương ứng trong `docs/BD`.
- [ ] Đã đọc toàn bộ luồng chức năng trong BD.
- [ ] Đã xác định DD tương ứng trong `docs/DD`.
- [ ] Đã đọc luồng kỹ thuật, model và ràng buộc trong DD.
- [ ] Đã xác định đúng phạm vi file cần chỉnh sửa.
- [ ] Không có mâu thuẫn giữa yêu cầu, BD và DD.
- [ ] Sẵn sàng bắt đầu coding.

## Luồng rút gọn

```text
Nhận yêu cầu develop
        ↓
Đọc BD gốc trong docs/BD
        ↓
Đọc DD tương ứng trong docs/DD
        ↓
Xác định phạm vi code
        ↓
Coding theo kiến trúc dự án
```

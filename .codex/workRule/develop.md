# WORK RULE — DEVELOP

> Áp dụng cho mọi phiên **develop / coding chức năng** trong dự án.

---

## 1. Mục tiêu

Đảm bảo mọi chức năng được lập trình đúng theo tài liệu nghiệp vụ và tài liệu thiết kế đã được phê duyệt.

---

## 2. Quy tắc Version: V1 và V2

### 2.1. Nguyên tắc mặc định

- Mặc định tạo chức năng mới ở `v2`.
- Trước khi coding ở `v2`, vẫn phải đọc qua `v1` để nắm rõ cấu trúc hiện tại của dự án.
- Nếu task yêu cầu cập nhật dữ liệu hoặc logic thuộc `v1`, vẫn phải sửa lại `v1`.

### 2.2. Cách hiểu version

```text
V2 là bản viết tiếp chức năng của V1.

Việc tách version nhằm thuận tiện cho việc fix bug và vá lỗi.

Mỗi version chính phải được coi là một chương trình hoàn tất.

V(n) kế thừa V(n - 1).
```

---

# 3. Workflow bắt buộc

Mọi phiên **develop / coding chức năng** phải thực hiện đúng thứ tự:

```text
Đọc BD gốc → Đọc DD tương ứng → Coding
```

Không được đảo thứ tự hoặc bỏ qua bước.

---

## 4. Bước 1 — Đọc BD gốc

### 4.1. Vị trí tài liệu

Tìm và đọc bản **BD gốc** mô tả chức năng được yêu cầu tại:

```text
docs/BD
```

### 4.2. Nội dung phải xác định

Trước khi chuyển sang DD, phải xác định rõ:

- Mục tiêu nghiệp vụ của chức năng.
- Vai trò người dùng được sử dụng chức năng.
- Luồng hoạt động chính và luồng ngoại lệ.
- Điều kiện đầu vào, đầu ra và kết quả mong đợi.
- Các ràng buộc nghiệp vụ liên quan.

### 4.3. Ràng buộc

```text
Không tự suy diễn hoặc thay đổi nghiệp vụ khi BD chưa mô tả rõ.
```

---

## 5. Bước 2 — Đọc DD tương ứng

### 5.1. Vị trí tài liệu

Tìm và đọc tài liệu **DD** tương ứng với chức năng tại:

```text
docs/DD
```

### 5.2. Nội dung phải xác định

Trước khi coding, phải xác định rõ:

- Thành phần cần tạo hoặc chỉnh sửa.
- Luồng xử lý kỹ thuật.
- Model, Entity, Repository, Datasource, API hoặc Database liên quan.
- Validation, trạng thái loading, empty, success và error.
- Điều kiện nghiệm thu của chức năng.

### 5.3. Vai trò của DD

```text
DD là tài liệu kỹ thuật trực tiếp để triển khai code.
```

---

## 6. Bước 3 — Coding

Chỉ bắt đầu coding sau khi đã đọc đầy đủ BD và DD tương ứng.

### 6.1. Yêu cầu bắt buộc khi coding

- Bám đúng nghiệp vụ trong BD.
- Bám đúng thiết kế kỹ thuật trong DD.
- Tuân thủ kiến trúc hiện có của dự án.
- Không tự ý sửa phạm vi của chức năng.
- Không tạo logic giả, dữ liệu mock hoặc đường xử lý tạm cho production.
- Không sửa các module không liên quan nếu không cần thiết.
- Giữ nguyên các luồng đang hoạt động ổn định.
- Đảm bảo code có thể test, bảo trì và mở rộng.

---

# 7. Quy tắc chặn Coding

Các điều kiện dưới đây có tính bắt buộc:

```text
Không có BD → Không coding nghiệp vụ mới.

Không có DD → Không triển khai kỹ thuật chi tiết.

BD và DD mâu thuẫn → Dừng coding, ghi nhận điểm mâu thuẫn.

Yêu cầu ngoài BD/DD → Không tự ý thực hiện, cần bổ sung tài liệu trước.
```

---

# 8. Checklist trước khi Coding

Chỉ được bắt đầu coding khi hoàn thành toàn bộ checklist:

- [ ] Đã xác định BD tương ứng trong `docs/BD`.
- [ ] Đã đọc toàn bộ luồng chức năng trong BD.
- [ ] Đã xác định DD tương ứng trong `docs/DD`.
- [ ] Đã đọc luồng kỹ thuật, model và ràng buộc trong DD.
- [ ] Đã xác định đúng phạm vi file cần chỉnh sửa.
- [ ] Đã xác định version cần thực hiện: `v1` hoặc `v2`.
- [ ] Đã đọc cấu trúc liên quan của `v1` khi thực hiện tại `v2`.
- [ ] Không có mâu thuẫn giữa yêu cầu, BD và DD.
- [ ] Sẵn sàng bắt đầu coding.

---

# 9. Luồng rút gọn

```text
Nhận yêu cầu develop
        ↓
Xác định version cần thực hiện: v1 hoặc v2
        ↓
Nếu làm v2: đọc v1 để nắm cấu trúc hiện tại
        ↓
Đọc BD gốc trong docs/BD
        ↓
Đọc DD tương ứng trong docs/DD
        ↓
Xác định phạm vi code
        ↓
Coding theo kiến trúc dự án
```

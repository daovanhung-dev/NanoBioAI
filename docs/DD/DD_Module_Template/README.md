# DD Module Template

> Mẫu Design Description (DD) cho **một module** phần mềm. Sao chép toàn bộ thư mục này, đổi `[MODULE_CODE]` và thay các nội dung trong `{{...}}` trước khi bắt đầu coding.

## Cấu trúc

```text
DD_[MODULE_CODE]/
├── README.md
├── Overall.md
├── List_Features.md
├── Function_List.md
├── Views.md
├── Import_File.md
├── diagrams/                  # Mermaid / draw.io / PNG / sequence diagram
├── assets/                    # wireframe, mockup, ảnh minh chứng
└── history/                   # bản cũ hoặc tài liệu đã thay thế
```

## Quy ước mã truy vết

| Loại | Mẫu mã | Ví dụ |
|---|---|---|
| Module | `[MODULE_CODE]` | `PAYMENT` |
| Feature | `[MODULE_CODE]-Fxx` | `PAYMENT-F01` |
| Function / Use case | `[MODULE_CODE]-FNxx` | `PAYMENT-FN01` |
| View | `[MODULE_CODE]-Vxx` | `PAYMENT-V01` |
| Business rule | `[MODULE_CODE]-BRxx` | `PAYMENT-BR01` |
| API | `[MODULE_CODE]-APIxx` | `PAYMENT-API01` |
| Entity / table | `[MODULE_CODE]-E-<name>` | `PAYMENT-E-transaction` |
| ADR / quyết định thiết kế | `[MODULE_CODE]-ADRxx` | `PAYMENT-ADR01` |

## Quy tắc dùng mẫu

1. **Không viết trùng nguồn sự thật.** Business rule được định nghĩa đầy đủ ở `Overall.md`; các file khác chỉ liên kết tới mã rule.
2. **Mỗi feature phải có mã, actor, trigger, luồng chính, luồng lỗi, function và view liên quan.**
3. **Mỗi function phải chỉ rõ layer, file dự kiến, input/output, phân quyền, lỗi, side effect và test.**
4. **Mỗi view phải chỉ rõ trạng thái Loading / Empty / Error / Success và hành động người dùng gọi function nào.**
5. **Mỗi import hoặc dependency mới phải được cập nhật ở `Import_File.md` trong cùng pull request/commit.**
6. Khi thay đổi logic: cập nhật tối thiểu `Overall.md` → `List_Features.md` → `Function_List.md` → `Views.md` → `Import_File.md` theo ảnh hưởng thực tế.

## Thứ tự viết DD

1. Đọc BD/BRD gốc và gắn liên kết nguồn.
2. Hoàn thành `Overall.md` để chốt ranh giới, actor, rule, dữ liệu, tích hợp và luồng xuyên suốt.
3. Tách feature và luồng liên kết trong `List_Features.md`.
4. Tách use case/hàm thực thi trong `Function_List.md`.
5. Định nghĩa màn hình/trạng thái/tương tác trong `Views.md`.
6. Lập bản đồ file, package, API client, constant và import trong `Import_File.md`.
7. Đính kèm sơ đồ vào `diagrams/`, mockup vào `assets/`.

## Trạng thái tài liệu

`Draft` → `In Review` → `Approved` → `Implemented` → `Deprecated`.

Không được code một feature ở trạng thái `Draft` khi chưa thống nhất business rule hoặc luồng lỗi trọng yếu.

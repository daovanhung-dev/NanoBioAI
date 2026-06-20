# NanoBio / BioAI - DD Authentication Package

Gói này được thiết kế để đặt trực tiếp vào repository NanoBio:

```text
<project-root>/
└── docs/
    └── DD/
        └── authentication/
```

## Mục đích

Bộ tài liệu Detailed Design (DD) này cắt nhỏ BD-AUTH-001 thành các đơn vị có thể đọc, review, code và test độc lập. Mỗi tài liệu chức năng liên kết ngược về Business Requirement tương ứng, ghi rõ input, xử lý, dữ liệu, bảo mật, lỗi, tiêu chí hoàn thành và phạm vi file Flutter/Supabase bị ảnh hưởng.

## Cách dùng nhanh

1. Chép thư mục `docs/` trong gói này vào root project.
2. Khi triển khai module Auth, đọc `docs/DD/authentication/00_READ_FIRST.md`.
3. Khi nhận một task cụ thể, chỉ đọc DD của chức năng đó cùng các tài liệu phụ thuộc được nêu trong phần **Đọc trước khi code**.
4. Chỉ sửa database sau khi đọc `03_DATA_MODEL_RLS_AND_MIGRATIONS.md` và migration liên quan.
5. Sau khi code hoặc sửa bug, cập nhật worklog/feature/fixbug theo workflow dự án hiện có.

## Thành phần

- `00-16_*.md`: DD đã hoàn thiện cho chức năng Auth.
- `database/`: migration và truy vấn kiểm tra dành cho Supabase SQL Editor.
- `guides/`: cách đọc, viết mới và review DD.
- `templates/`: khung tài liệu tái sử dụng cho module khác.
- `references/`: BD nguồn để truy vết yêu cầu.

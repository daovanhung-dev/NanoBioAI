# Fix NaBi Invalid Constant

- **Phạm vi:** `NabiExpressionResolver.fromEvent`
- **Lỗi:** `Invalid constant value` khi xử lý `NabiEvent.formNeedsAttention`.
- **Nguyên nhân:** `fallbackContext` là giá trị runtime nhưng được sử dụng bên trong `const`.
- **Khắc phục:** Dùng `NabiResolvedPresentation(...)` không `const` tại đúng nhánh này.
- **Không đổi:** Quy tắc chọn context, emotion, bubble text và các nhánh event khác.

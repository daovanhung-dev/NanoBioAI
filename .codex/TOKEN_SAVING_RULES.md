# TOKEN_SAVING_RULES

## Mục tiêu

Codex chỉ đọc đúng tài liệu và đúng source cần thiết cho task.

## Luật tiết kiệm token

- Luôn đọc `.codex/AGENTS.md` + `.codex/PROJECT_MAP.md` trước.
- Sau đó chỉ đọc 1 playbook liên quan.
- Dùng `rg` trước khi mở file lớn.
- Không đọc toàn bộ `lib/` nếu task chỉ nằm trong một feature.
- Không mở file generated/build/cache.
- Không copy lại nội dung dài trong báo cáo cuối.
- Không đọc tài liệu cũ nếu không được yêu cầu.

## Khi cần hiểu sâu hơn

Mở rộng theo thứ tự:

1. File đang lỗi.
2. File import trực tiếp.
3. Test liên quan.
4. DAO/model/table liên quan.
5. Router/provider usage bằng `rg`.

Dừng mở rộng khi đã đủ nguyên nhân gốc.

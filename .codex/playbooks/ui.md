# Playbook — UI / Theme / Nami Copywriting

## Mục tiêu

UI đơn giản, chuyên nghiệp, nhất quán, responsive, có cảm giác được Nami chăm sóc.

## Quy tắc UI

- Ưu tiên token có sẵn: `AppColors`, `AppSpacing`, `AppRadius`, `AppTextStyles`, `AppDecoration`, `AppGradients`, `AppShadows`.
- Không hard-code style lặp lại nếu theme đã có.
- Tránh overflow: dùng `Flexible`, `Expanded`, `SingleChildScrollView`, constraint hợp lý.
- Không dùng quá nhiều card/gradient gây rối.
- Empty/error/loading state phải có thông điệp rõ.

## Copywriting Nami

- Tiếng Việt có dấu.
- Giọng nhẹ nhàng, ân cần, không phán xét.
- Không hù dọa sức khỏe.
- Ưu tiên câu ngắn, tự nhiên.

Ví dụ:

- Không nên: `Bạn chưa hoàn thành nhiệm vụ.`
- Nên: `Hôm nay mình còn một việc nhỏ cần chăm sóc nhé.`

## Test nên có

- Widget render không lỗi.
- State loading/error/empty/data.
- Key text quan trọng xuất hiện đúng.

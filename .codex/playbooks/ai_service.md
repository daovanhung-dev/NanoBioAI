# Playbook — AI Service / Meal / Exercise Parser

## Mục tiêu

AI có thể fail hoặc trả dữ liệu xấu nhưng app không crash. Text hiển thị cho user phải có dấu.

## Khi sửa AI

Đọc:

- `lib/services/ai/`
- `lib/features/meal_plan/`
- Normalizer/catalog/seed liên quan nếu có.

## Quy tắc

- Không gọi API thật trong unit test.
- Parser phải validate schema, type, required fields.
- Nếu AI trả code kỹ thuật, map qua catalog local sang text tiếng Việt có dấu.
- Không phụ thuộc 100% vào prompt để đảm bảo dữ liệu đúng; phải có validator/normalizer local.
- Lỗi transient như 503 nên có retry/backoff hoặc fallback rõ ràng nếu đã thiết kế.

## Test nên có

- JSON hợp lệ parse đúng.
- Thiếu field -> lỗi rõ ràng.
- Sai type -> lỗi rõ ràng.
- Text không dấu/user-facing invalid -> bị reject hoặc map lại qua catalog.
- API exception -> convert sang app exception ổn định.

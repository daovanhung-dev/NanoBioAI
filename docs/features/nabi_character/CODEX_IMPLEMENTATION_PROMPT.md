# CODEX_IMPLEMENTATION_PROMPT

Bạn là AI coding agent của dự án Flutter NanoBio/NamiAI. Hãy triển khai hệ thống nhân vật Nabi dựa trên các file trong package này.

## Bắt buộc đọc trước khi sửa

1. `.codex/AGENTS.md`
2. `.codex/PROJECT_MAP.md`
3. `.codex/task-skills/coding.md`
4. `docs/features/nabi_character/NABI_CHARACTER_CONTEXT.md`
5. `docs/features/nabi_character/NABI_ASSET_MANIFEST.md`
6. `docs/features/nabi_character/NABI_INTEGRATION_GUIDE.md`
7. `assets/config/nabi/nabi_state_matrix.yaml`
8. `assets/config/nabi/nabi_motion_library.json`
9. `assets/config/nabi/nabi_expression_map.json`

## Mục tiêu

Tạo module `Nabi Character System` để UI chọn đúng ảnh/animation recipe cho từng ngữ cảnh: onboarding, AI chat, nhiệm vụ hằng ngày, kết quả complete/skip, mức độ dùng app, đồng bộ/offline và future FamilyPlus/Sale/Referral.

## Ràng buộc kiến trúc

- Tuân thủ `Presentation → Provider/Controller → Repository → Datasource → DAO/API`.
- Không để Widget trực tiếp đọc SQLite/Supabase hay tự suy luận tần suất dùng app.
- Không thêm mock production data.
- Không hard-code asset path rải rác. Tạo registry typed duy nhất.
- Không thay đổi luồng lõi: onboarding → local SQLite → AI tạo lịch → local reminders → login/Supabase access gate → dashboard dữ liệu thật.
- UI/copy phải là tiếng Việt tự nhiên theo persona Nabi: ấm áp, tinh tế, không phán xét, chủ động vừa đủ.

## Việc cần làm

1. Tạo feature/module phù hợp với cấu trúc dự án (ví dụ `lib/shared/nabi_character/` hoặc feature-specific adapter).
2. Tạo model typed: `NabiVisualState`, `NabiEngagementBand`, `NabiAssetDescriptor`, `NabiMotionRecipe`.
3. Tạo một resolver/controller nhận context nghiệp vụ và trả về `NabiAssetDescriptor`.
4. Tích hợp ít nhất các context: onboarding intro/generating/ready; chat listening/generating/answer-ready; dashboard empty; daily task pending/complete/skip; away 3d/7d/welcome back; offline/sync success/login prompt.
5. Tạo reusable widget `NabiCharacter` nhận descriptor, semantic label, size và motion recipe. PNG chỉ là static asset; animation ban đầu dùng `AnimatedScale`, `AnimatedSlide`, `TweenAnimationBuilder`, không yêu cầu Rive/Lottie.
6. Viết unit/widget test theo hướng dẫn trong integration guide.
7. Tạo docs commit/worklog theo quy tắc `.codex`.

## Tiêu chí chấp nhận

- Chọn asset theo priority trong `nabi_state_matrix.yaml`.
- Không có string đường dẫn `assets/images/nabi/...` bị lặp trong screen widget.
- Tất cả 84 asset được manifest kiểm tra tồn tại.
- Kịch bản skip/away không có copy gây áp lực.
- `flutter analyze` và relevant tests pass.
- Xuất changed files dưới dạng zip giữ project-relative path.

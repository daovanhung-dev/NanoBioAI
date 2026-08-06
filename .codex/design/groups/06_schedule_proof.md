# Lifestyle Schedule, routine và proof

## Goal

Dùng timeline liên tục, complete/skip rõ trạng thái, ảnh proof có shared transition.

## Current evidence

- Files: **6**.
- Page/screen: **3**.
- Files có motion: **1**.
- Files dùng duration raw: **1**.
- Files dùng color trực tiếp: **1**.
- Files gọi haptic trực tiếp: **1**.

## Group design rules

- Timeline line phản ánh trạng thái DB thật.
- Complete/skip chỉ feedback sau transaction.
- Proof image có Hero/privacy/permission states.
- Notification/outbox side effect không tạo duplicate celebration.

## Views

| View | Entrance | State transition | Feedback | Design intent |
| --- | --- | --- | --- | --- |
| lib/app_versions/v1/features/daily_routine/presentation/pages/daily_routine_preferences_page.dart | Timeline reveal theo trục dọc | Date/filter/timeline/complete/skip/proof | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Routine blocks reorder/expand có stable identity; time change color/number tween nhẹ. |
| lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart | Timeline reveal theo trục dọc | Date/filter/timeline/complete/skip/proof | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Tách file lớn; timeline progress line, complete/skip morph, date/filter indicator và refresh delta. |
| lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/schedule_proof_gallery_page.dart | Timeline reveal theo trục dọc | Date/filter/timeline/complete/skip/proof | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Thumbnail-to-fullscreen Hero, capture/upload progress, delete/replace transition và sensitive-image privacy states. |

## File-by-file design

| File | Kind | Role | Current evidence | Target design | Transition contract | Wave |
| --- | --- | --- | --- | --- | --- | --- |
| lib/app_versions/v1/features/daily_routine/presentation/pages/daily_routine_preferences_page.dart | page | DailyRoutinePreferencesPage / _DailyRoutinePreferencesPageState / _EditorBody | Nabi×2 | Routine blocks reorder/expand có stable identity; time change color/number tween nhẹ. | Date/filter/timeline/complete/skip/proof | W5 Schedule/Proof |
| lib/app_versions/v1/features/daily_routine/presentation/widgets/daily_routine_preferences_editor.dart | widget | DailyRoutinePreferencesEditor / _TemplateEditor / _RangeEditor / _TimeRow | Chưa có motion/feedback đáng kể | Dùng temporal identity, timeline progress, complete/skip/proof states và notification-consistent feedback. | Date/filter/timeline/complete/skip/proof | W5 Schedule/Proof |
| lib/app_versions/v1/features/lifestyle_schedule/presentation/controllers/lifestyle_schedule_controller.dart | controller | LifestyleScheduleController | haptic trực tiếp×1, Nabi×4 | Giữ nguyên nghiệp vụ; chuẩn hóa UI phase/state identity; loại bỏ haptic trực tiếp khỏi controller và phát feedback sau khi state thành công/thất bại được xác nhận. | Stable state/identity contract | W5 Schedule/Proof |
| lib/app_versions/v1/features/lifestyle_schedule/presentation/controllers/lifestyle_schedule_state.dart | controller | LifestyleScheduleState | Chưa có motion/feedback đáng kể | Giữ nguyên nghiệp vụ; chuẩn hóa UI phase/state identity; loại bỏ haptic trực tiếp khỏi controller và phát feedback sau khi state thành công/thất bại được xác nhận. | Stable state/identity contract | W5 Schedule/Proof |
| lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/lifestyle_schedule_page.dart | page | LifestyleSchedulePage / _LifestyleSchedulePageState / _ScheduleContent / _SchedulePageFrame | AnimatedContainer×6, AnimatedOpacity×1, AnimatedScale×1, duration raw×2, Colors.*×2, motion token×14, Semantics×3, RefreshIndicator×1, Nabi×14 | Tách file lớn; timeline progress line, complete/skip morph, date/filter indicator và refresh delta. | Date/filter/timeline/complete/skip/proof | W5 Schedule/Proof |
| lib/app_versions/v1/features/lifestyle_schedule/presentation/pages/schedule_proof_gallery_page.dart | page | ScheduleProofPreviewSection / ScheduleProofGalleryPage / _ProofCard / _ProofImage | Nabi×2 | Thumbnail-to-fullscreen Hero, capture/upload progress, delete/replace transition và sensitive-image privacy states. | Date/filter/timeline/complete/skip/proof | W5 Schedule/Proof |

## Acceptance

- Không raw sound/haptic call ngoài feedback service.
- Không motion replay khi state không đổi.
- Có reduced-motion behavior.
- Có loading/empty/error/ready hoặc lý do không áp dụng.
- Targeted widget/route/state test được bổ sung trong coding wave.

# Care views, community và shared loading

## Goal

Đồng bộ trạng thái tính năng, care suggestion và AI generation surface, không giả lập tính năng chưa có.

## Current evidence

- Files: **7**.
- Page/screen: **4**.
- Files có motion: **1**.
- Files dùng duration raw: **1**.
- Files dùng color trực tiếp: **0**.
- Files gọi haptic trực tiếp: **0**.

## Group design rules

- Care tone nhẹ, không phán xét.
- Planned/locked/empty khác nhau rõ.
- AI loading dùng shared generation surface.
- Không thêm fake data/feature để làm UI sinh động.

## Views

| View | Entrance | State transition | Feedback | Design intent |
| --- | --- | --- | --- | --- |
| lib/app_versions/v1/features/community/presentation/pages/community_page.dart | Card reveal nhẹ, không loop | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Giữ planned/shell state minh bạch; không thêm fake feed hoặc animation giả hoạt động. |
| lib/app_versions/v1/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart | Card reveal nhẹ, không loop | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Calm low-motion surface, suggestion reveal chậm vừa, sound mặc định tắt. |
| lib/app_versions/v1/features/other/presentation/pages/other_page.dart | Card reveal nhẹ, không loop | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Health insight list dùng expand/refresh delta; giữ tải lại không replay toàn view. |
| lib/app_versions/v1/features/quick_care/presentation/pages/quick_care_page.dart | Card reveal nhẹ, không loop | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Quick action card press rõ, immediate routing, không dùng entrance dài. |

## File-by-file design

| File | Kind | Role | Current evidence | Target design | Transition contract | Wave |
| --- | --- | --- | --- | --- | --- | --- |
| lib/app_versions/v1/features/community/presentation/pages/community_page.dart | page | CommunityPage | Chưa có motion/feedback đáng kể | Giữ planned/shell state minh bạch; không thêm fake feed hoặc animation giả hoạt động. | Loading/empty/error/ready và action result | W7 Care/Shared |
| lib/app_versions/v1/features/gentle_care_mode/presentation/pages/gentle_care_mode_page.dart | page | GentleCareModePage / _GentleCareModePageState / _CareMood / _CareSuggestion | Nabi×4 | Calm low-motion surface, suggestion reveal chậm vừa, sound mặc định tắt. | Loading/empty/error/ready và action result | W7 Care/Shared |
| lib/app_versions/v1/features/other/presentation/pages/other_page.dart | page | HealthInsightsView | RefreshIndicator×1 | Health insight list dùng expand/refresh delta; giữ tải lại không replay toàn view. | Loading/empty/error/ready và action result | W7 Care/Shared |
| lib/app_versions/v1/features/other/presentation/widgets/health_insights_widgets.dart | widget | _HealthInsightsHeader / _HealthSnapshotCard / _ScoreBadge / _SnapshotMetric | Nabi×5 | Chuẩn hóa insight card/icon/status và expand transition bằng primitive. | Loading/empty/error/ready và action result | W7 Care/Shared |
| lib/app_versions/v1/features/quick_care/presentation/pages/quick_care_page.dart | page | QuickCarePage / _QuickCareAction | Nabi×1 | Quick action card press rõ, immediate routing, không dùng entrance dài. | Loading/empty/error/ready và action result | W7 Care/Shared |
| lib/shared/widgets/loading_gen_ai.dart | widget | AIGeneratingPage / _AIGeneratingPageState / _ThoughtEntry | controller×6, AnimatedContainer×1, AnimatedSwitcher×1, duration raw×6, motion token×2, Semantics×1, Nabi×5 | Một AI generation surface dùng chung: staged progress, thought text crossfade, timeout/error, Nabi loading lifecycle. | Loading/empty/error/ready và action result | W7 Care/Shared |
| lib/shared/widgets/vietnamese_ui_text.dart | widget | vietnamese_ui_text | Nabi×29 | Dùng care card/state primitives, planned/empty minh bạch và motion nhẹ theo mức ưu tiên. | Loading/empty/error/ready và action result | W7 Care/Shared |

## Acceptance

- Không raw sound/haptic call ngoài feedback service.
- Không motion replay khi state không đổi.
- Có reduced-motion behavior.
- Có loading/empty/error/ready hoặc lý do không áp dụng.
- Targeted widget/route/state test được bổ sung trong coding wave.

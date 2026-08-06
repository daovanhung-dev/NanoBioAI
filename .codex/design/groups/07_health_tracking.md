# Health tracking và health score

## Goal

Tạo tactile capture, trend reveal và progress feedback, ưu tiên khả năng đọc chỉ số.

## Current evidence

- Files: **11**.
- Page/screen: **9**.
- Files có motion: **0**.
- Files dùng duration raw: **0**.
- Files dùng color trực tiếp: **0**.
- Files gọi haptic trực tiếp: **1**.

## Group design rules

- Metric capture tactile nhưng không haptic theo mọi pixel/slider tick.
- Chart/ring animation một lần hoặc theo delta.
- Critical values không dùng celebration/pulse lặp.
- Shell/stub phải minh bạch trạng thái chưa triển khai.

## Views

| View | Entrance | State transition | Feedback | Design intent |
| --- | --- | --- | --- | --- |
| lib/app_versions/v1/features/body_metrics/presentation/pages/body_metrics_page.dart | Metric fade-size, chart draw một lần | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Metric entry tactile, report card number tween và warning state rõ; không celebration cho chỉ số bất thường. |
| lib/app_versions/v1/features/daily_health_tracking/presentation/pages/daily_health_tracking_page.dart | Metric fade-size, chart draw một lần | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Thay shell nhỏ bằng metric hub chuẩn hoặc xác nhận chỉ là forwarder; không tạo animation giả khi chưa có UI thực. |
| lib/app_versions/v1/features/personal_goals/presentation/pages/personal_goals_page.dart | Metric fade-size, chart draw một lần | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Goal option selection morph, reorder/prioritize transition và save feedback. |
| lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart | Metric fade-size, chart draw một lần | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Thiết kế explicit planned/redirect state nếu còn shell; không trình bày như module hoàn chỉnh. |
| lib/app_versions/v1/features/stress_tracking/presentation/pages/stress_tracking_page.dart | Metric fade-size, chart draw một lần | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Thiết kế explicit planned/redirect state nếu còn shell; copy không phán xét và motion rất nhẹ. |
| lib/app_versions/v1/features/water_tracking/presentation/pages/water_tracking_page.dart | Metric fade-size, chart draw một lần | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Water fill/progress animation có clamp, haptic theo mốc chứ không theo mỗi tap. |
| lib/app_versions/v1/features/weekly_summary/presentation/pages/weekly_summary_page.dart | Metric fade-size, chart draw một lần | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Chart reveal theo thời gian, summary item count-up một lần, share/export transition nếu có. |
| lib/app_versions/v2/features/health_scoring/presentation/pages/health_score_habits_page.dart | Metric fade-size, chart draw một lần | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Score ring draw/delta, breakdown expand, history chart transition; critical text ưu tiên hơn motion. |
| lib/app_versions/v3/features/advanced_tracking/presentation/pages/advanced_tracking_page.dart | Metric fade-size, chart draw một lần | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Goal roadmap progression, hydration capture tactile và empty-to-created transition. |

## File-by-file design

| File | Kind | Role | Current evidence | Target design | Transition contract | Wave |
| --- | --- | --- | --- | --- | --- | --- |
| lib/app_versions/v1/features/body_metrics/presentation/pages/body_metrics_page.dart | page | BodyMetricsPage / _BodyMetricsPageState / _NumberField / _ReportCard | Nabi×3 | Metric entry tactile, report card number tween và warning state rõ; không celebration cho chỉ số bất thường. | Loading/empty/error/ready và action result | W7 Health Tracking |
| lib/app_versions/v1/features/daily_health_tracking/presentation/controllers/daily_health_tracking_controller.dart | controller | DailyHealthTrackingController | haptic trực tiếp×1 | Giữ nguyên nghiệp vụ; chuẩn hóa UI phase/state identity; loại bỏ haptic trực tiếp khỏi controller và phát feedback sau khi state thành công/thất bại được xác nhận. | Stable state/identity contract | W7 Health Tracking |
| lib/app_versions/v1/features/daily_health_tracking/presentation/controllers/daily_health_tracking_state.dart | controller | DailyHealthTrackingState | Chưa có motion/feedback đáng kể | Giữ nguyên nghiệp vụ; chuẩn hóa UI phase/state identity; loại bỏ haptic trực tiếp khỏi controller và phát feedback sau khi state thành công/thất bại được xác nhận. | Stable state/identity contract | W7 Health Tracking |
| lib/app_versions/v1/features/daily_health_tracking/presentation/pages/daily_health_tracking_page.dart | page | DailyHealthTrackingPage | Chưa có motion/feedback đáng kể | Thay shell nhỏ bằng metric hub chuẩn hoặc xác nhận chỉ là forwarder; không tạo animation giả khi chưa có UI thực. | Loading/empty/error/ready và action result | W7 Health Tracking |
| lib/app_versions/v1/features/personal_goals/presentation/pages/personal_goals_page.dart | page | PersonalGoalsPage / _PersonalGoalsPageState / _GoalOption | Nabi×6 | Goal option selection morph, reorder/prioritize transition và save feedback. | Loading/empty/error/ready và action result | W7 Health Tracking |
| lib/app_versions/v1/features/sleep_tracking/presentation/pages/sleep_tracking_page.dart | page | SleepTrackingPage | Chưa có motion/feedback đáng kể | Thiết kế explicit planned/redirect state nếu còn shell; không trình bày như module hoàn chỉnh. | Loading/empty/error/ready và action result | W7 Health Tracking |
| lib/app_versions/v1/features/stress_tracking/presentation/pages/stress_tracking_page.dart | page | StressTrackingPage | Chưa có motion/feedback đáng kể | Thiết kế explicit planned/redirect state nếu còn shell; copy không phán xét và motion rất nhẹ. | Loading/empty/error/ready và action result | W7 Health Tracking |
| lib/app_versions/v1/features/water_tracking/presentation/pages/water_tracking_page.dart | page | WaterTrackingPage / _WaterTrackingPageState | Nabi×4 | Water fill/progress animation có clamp, haptic theo mốc chứ không theo mỗi tap. | Loading/empty/error/ready và action result | W7 Health Tracking |
| lib/app_versions/v1/features/weekly_summary/presentation/pages/weekly_summary_page.dart | page | WeeklySummaryPage / _SummaryItem | Nabi×5 | Chart reveal theo thời gian, summary item count-up một lần, share/export transition nếu có. | Loading/empty/error/ready và action result | W7 Health Tracking |
| lib/app_versions/v2/features/health_scoring/presentation/pages/health_score_habits_page.dart | page | HealthScoreHabitsPage / _HealthScoreLoading / _HealthScoreReady / _ScoreHeader | RefreshIndicator×1, Nabi×1 | Score ring draw/delta, breakdown expand, history chart transition; critical text ưu tiên hơn motion. | Loading/empty/error/ready và action result | W7 Health Tracking |
| lib/app_versions/v3/features/advanced_tracking/presentation/pages/advanced_tracking_page.dart | page | AdvancedTrackingPage / _EmptyGoalState / _RoadmapReady / _HydrationIntro | RefreshIndicator×1, Nabi×3 | Goal roadmap progression, hydration capture tactile và empty-to-created transition. | Loading/empty/error/ready và action result | W7 Health Tracking |

## Acceptance

- Không raw sound/haptic call ngoài feedback service.
- Không motion replay khi state không đổi.
- Có reduced-motion behavior.
- Có loading/empty/error/ready hoặc lý do không áp dụng.
- Targeted widget/route/state test được bổ sung trong coding wave.

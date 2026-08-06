# Dashboard, menu và feature hub

## Goal

Biến dữ liệu sức khỏe thành câu chuyện trực quan sống động nhưng không làm dashboard nhấp nháy khi refresh.

## Current evidence

- Files: **36**.
- Page/screen: **4**.
- Files có motion: **5**.
- Files dùng duration raw: **0**.
- Files dùng color trực tiếp: **5**.
- Files gọi haptic trực tiếp: **1**.

## Group design rules

- Entrance chỉ lần đầu; refresh chỉ animate delta.
- Score/timeline/insight có entity key ổn định.
- Stagger tối đa 4 section; không animate tất cả card.
- Navigation destination dùng sliding indicator + fade-through.

## Views

| View | Entrance | State transition | Feedback | Design intent |
| --- | --- | --- | --- | --- |
| lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart | Section reveal 8 px, tối đa 4 stagger | Loading/empty/error/ready và data delta | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Chỉ orchestrate page state và refresh; entrance chạy lần đầu, refresh chỉ animate delta; giữ scroll position. |
| lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart | Section reveal 8 px, tối đa 4 stagger | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Bottom navigation indicator trượt liên tục; icon/label micro motion; body dùng fade-through, không slide toàn màn hình. |
| lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart | Section reveal 8 px, tối đa 4 stagger | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Feature card depth/press đồng bộ; locked/planned state rõ và không animate như tính năng đang hoạt động. |
| lib/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart | Section reveal 8 px, tối đa 4 stagger | Loading/empty/error/ready và action result | Press visual; selection haptic; sound chỉ cho success/error/voice/milestone semantic | Trở thành shared care composition dùng primitive canonical; loại bỏ raw Colors và duration riêng. |

## File-by-file design

| File | Kind | Role | Current evidence | Target design | Transition contract | Wave |
| --- | --- | --- | --- | --- | --- | --- |
| lib/app_versions/v1/features/dashboard/presentation/controllers/dashboard_controller.dart | controller | DashboardController | Chưa có motion/feedback đáng kể | Giữ nguyên nghiệp vụ; chuẩn hóa UI phase/state identity; loại bỏ haptic trực tiếp khỏi controller và phát feedback sau khi state thành công/thất bại được xác nhận. | Stable state/identity contract | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/enums/insight_type.dart | enum | InsightType | Chưa có motion/feedback đáng kể | Giữ logic thuần; bổ sung semantic presentation metadata hoặc stable identity chỉ khi cần cho transition; không chứa animation, sound hay BuildContext. | Stable state/identity contract | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/mappers/dashboard_health_status_mapper.dart | mapper | DashboardHealthStatusMapper | Chưa có motion/feedback đáng kể | Giữ logic thuần; bổ sung semantic presentation metadata hoặc stable identity chỉ khi cần cho transition; không chứa animation, sound hay BuildContext. | Stable state/identity contract | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/pages/dashboard_page.dart | page | DashboardPage / _DashboardPageState | Nabi×18 | Chỉ orchestrate page state và refresh; entrance chạy lần đầu, refresh chỉ animate delta; giữ scroll position. | Loading/empty/error/ready và data delta | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/pages/menu_page.dart | page | MainNavigationPage / _MainNavigationPageState / _AnimatedNavItem / _AnimatedBackground | controller×4, AnimatedContainer×1, AnimatedOpacity×1, AnimatedScale×1, TweenAnimationBuilder×1, haptic trực tiếp×1, Colors.*×4, motion token×6, Semantics×1, Nabi×6 | Bottom navigation indicator trượt liên tục; icon/label micro motion; body dùng fade-through, không slide toàn màn hình. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/utils/dashboard_helpers.dart | utility | dashboard_helpers | Chưa có motion/feedback đáng kể | Giữ logic thuần; bổ sung semantic presentation metadata hoặc stable identity chỉ khi cần cho transition; không chứa animation, sound hay BuildContext. | Stable state/identity contract | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/common/section_header.dart | widget | SectionHeader | Chưa có motion/feedback đáng kể | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/companion/dashboard_companion_widgets.dart | widget | DashboardDailySummaryCard / DashboardSlowDayBanner / DashboardNextActionSection / DashboardDailyCheckInCard | AnimatedContainer×1, motion token×1, Nabi×10 | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và data delta | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/dashboard_content.dart | widget | DashboardContent | RefreshIndicator×1, Nabi×1 | Section choreography theo nhóm, stagger tối đa 4 section đầu; stable keys cho score/timeline/insight. | Loading/empty/error/ready và data delta | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_chip.dart | widget | GoalChip | Chưa có motion/feedback đáng kể | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_chips_grid.dart | widget | GoalChipsGrid | Chưa có motion/feedback đáng kể | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_data.dart | widget | GoalData | Chưa có motion/feedback đáng kể | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_progress_row.dart | widget | GoalProgressRow | Chưa có motion/feedback đáng kể | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/goals/goal_progress_section.dart | widget | GoalProgressSection | Chưa có motion/feedback đáng kể | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/health_status/health_metrics_overview_section.dart | widget | HealthMetricsOverviewSection / _ScoreBadge / _MetricGrid / _MetricTile | Nabi×1 | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/hero/header_stat_pill.dart | widget | HeaderStatPill | Chưa có motion/feedback đáng kể | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/insights/ai_insight_section.dart | widget | AiInsightSection | Chưa có motion/feedback đáng kể | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/insights/insight_card.dart | widget | InsightCard | Nabi×1 | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/insights/insight_data.dart | widget | InsightData | Chưa có motion/feedback đáng kể | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/lifestyle/conditions_card.dart | widget | ConditionsCard | Chưa có motion/feedback đáng kể | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/lifestyle/lifestyle_metric_card.dart | widget | LifestyleMetricCard | Chưa có motion/feedback đáng kể | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/overview/dashboard_overview_widgets.dart | widget | DashboardHeader / DashboardSnapshotCard / DashboardQuickActions / DashboardMoodCheckInSheet | TweenAnimationBuilder×1, motion token×1, Semantics×4 | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và data delta | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/score/score_metric_row.dart | widget | ScoreMetricRow | Colors.*×1 | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/score/score_ring_painter.dart | widget | ScoreRingPainter | Color raw×1 | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/sections/dashboard_sections.dart | widget | DashboardTimelinePreview / DashboardProgressCard / DashboardPrimaryInsight / DashboardHealthDetails | Semantics×1, Nabi×3 | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và data delta | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/states/dashboard_error.dart | widget | DashboardError | Chưa có motion/feedback đáng kể | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và data delta | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/states/dashboard_loading.dart | widget | DashboardLoading | Chưa có motion/feedback đáng kể | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và data delta | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/states/dashboard_state_widgets.dart | widget | DashboardUserDataSyncBanner / DashboardSyncBanner / DashboardInlineErrorBanner / DashboardLoadingView | Nabi×1 | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và data delta | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/states/skeleton_box.dart | widget | SkeletonBox / _SkeletonBoxState | controller×2, motion token×1 | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/stats/stat_card.dart | widget | StatCard | Chưa có motion/feedback đáng kể | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/stats/stat_item.dart | widget | StatItem | Chưa có motion/feedback đáng kể | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/timeline/daily_timeline.dart | widget | DailyTimeline | Chưa có motion/feedback đáng kể | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/timeline/timeline_event.dart | widget | TimelineEvent | Chưa có motion/feedback đáng kể | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/dashboard/presentation/widgets/timeline/timeline_row.dart | widget | TimelineRow | Chưa có motion/feedback đáng kể | Dùng delta animation, stable keys và section-level choreography; không replay khi provider refresh cùng dữ liệu. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/features_hub/presentation/pages/features_hub_page.dart | page | FeaturesHubPage / _CareJourneyHero / _ResponsiveFeatureList / _FeatureTile | Colors.*×1, Semantics×3, Nabi×2 | Feature card depth/press đồng bộ; locked/planned state rõ và không animate như tính năng đang hoạt động. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |
| lib/app_versions/v1/features/features_hub/presentation/widgets/nami_care_page.dart | page | NamiCareScaffold / NamiCareSurfaceCard / NamiCareSectionTitle / NamiCareInfoTile | AnimatedContainer×2, Colors.*×2, motion token×2 | Trở thành shared care composition dùng primitive canonical; loại bỏ raw Colors và duration riêng. | Loading/empty/error/ready và action result | W4 Dashboard/Menu |

## Acceptance

- Không raw sound/haptic call ngoài feedback service.
- Không motion replay khi state không đổi.
- Có reduced-motion behavior.
- Có loading/empty/error/ready hoặc lý do không áp dụng.
- Targeted widget/route/state test được bổ sung trong coding wave.

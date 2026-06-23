Commit đề xuất: feat(dashboard): thêm Nabicompanion cho trang chủ

# Dashboard NabiCompanion

## Mục tiêu

- Biến Dashboard thành màn hình đồng hành hằng ngày của Nami.
- Ưu tiên việc nhỏ tiếp theo, check-in cảm nhận, cập nhật nước/cân nặng nhanh và hiện trạng thái kế hoạch hiện có.
- Dùng dữ liệu SQLite sẵn có, không thêm bảng/cột/migration.

## Phạm vi

- Bao gồm: timeline metadata, next action, slow-day mode, daily check-in, water/weight quick update, plan status, 7-day self-care streak, score breakdown local, chat FAB dùng chung.
- Không bao gồm: schema mới, persisted skip status, AI summary call, truyền dashboard context vào AI chat route.

## Luồng dữ liệu

1. UI Dashboard gọi `DashboardController`.
2. Controller gọi repository đúng feature:
   - Daily health: task, mood, water, weight.
   - Lifestyle schedule: schedule item completion.
   - Meal plan: meal completion.
3. Repository gọi datasource.
4. Datasource gọi DAO hoặc raw SQLite đọc tổng hợp.
5. Controller invalidate `dashboardProvider`, `dashboardDynamicProvider` và provider feature liên quan.

## Dữ liệu đọc

- `health_tracking_logs`: mood, weight, water, steps, score, sleep, stress, vital signals.
- `daily_health_tasks`: task progress và completion signal.
- `lifestyle_schedule_items`: schedule timeline và completion signal.
- `meal_plans`: meal timeline, calories và plan end date.
- `notifications`: timeline nhắc nhở, không complete trực tiếp.

## Hành vi chính

- Timeline item có `sourceType`, `sourceId`, `status`, `canComplete`.
- Schedule item chỉ hiện complete action khi đã tới `startTime`, khớp guard của `LifestyleScheduleLocalDatasource`.
- Next action chỉ chọn item chưa xong và có thể complete.
- Slow-day mode bật khi mood là `tired`, `stressed` hoặc `uncomfortable`; thứ tự ưu tiên dựa vào category: water, mind/stress/sleep, body/exercise, meal.
- Daily check-in lưu stable mood code vào `health_tracking_logs.mood`.
- Quick weight lưu vào `health_tracking_logs.weight_kg`; Dashboard ưu tiên weight hôm nay, fallback profile weight.
- Quick water lưu vào `health_tracking_logs.water_ml` và sync task water hôm nay nếu có.
- Nút `Để lát nữa` chỉ hiện snackbar cục bộ, không ghi skipped status vì schema hiện tại không có trường skip.

## UI/UX

- Companion copy dùng tiếng Việt và persona Nami.
- Summary là local-rule summary, không gọi AI.
- Score breakdown mở bằng bottom sheet, giải thích các nhóm Nhiệm vụ, Nước, Bữa ăn, Vận động, Giấc ngủ.
- Nabichat button dùng `DraggableAIChatButton` chung:
  - Menu shell: chỉ hiện ở Dashboard tab.
  - Route `/dashboard`: hiện standalone.
  - Chat route: mở `RoutePaths.aiChat` bình thường.

## Files chính

- `lib/features/dashboard/domain/entities/dashboard_dynamic_entity.dart`
- `lib/features/dashboard/data/datasources/dashboard_dynamic_local_datasource.dart`
- `lib/features/dashboard/domain/services/dashboard_companion_service.dart`
- `lib/features/dashboard/presentation/controllers/dashboard_controller.dart`
- `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- `lib/features/dashboard/presentation/widgets/companion/dashboard_companion_widgets.dart`
- `lib/shared/widgets/ai_chat_fab.dart`

## Cap nhat 2026-06-21

- Tao du lieu lich trinh AI 7 ngay tren Dashboard yeu cau co Supabase session.
- Khi chua dang nhap, `GeneratedPlanService.generateNextPlan()` nem `DashboardGenerationAuthRequiredException` truoc khi goi AI, save meal plan, seed schedule hoac tao reminder.
- Nabihien copy dang nhap rieng tren Dashboard thay vi loi chung.
- Guest onboarding van hoan tat duoc; callback tao plan se skip neu chua co session va khong tao du lieu moi.

## TODO

- AI chat route chưa support `extra`; cần thêm route/context contract trước khi truyền Dashboard context vào `AIChatScreen`.
- Score breakdown hiện là breakdown local từ metrics Dashboard, không phải công thức điểm persisted/có version trong database.

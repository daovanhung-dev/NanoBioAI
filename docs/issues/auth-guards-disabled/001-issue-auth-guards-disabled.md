Commit đề xuất: docs(issue): ghi nhận lỗi route guard bị tắt trước release

# Dashboard và AI Chat đang tắt auth guard

## Tóm tắt
- `RouteGuards.authGuard` đã có logic kiểm tra Supabase user.
- Route Dashboard và AI Chat đang comment guard, trong khi Nutrition/Profile vẫn bật guard.

## Mức độ ảnh hưởng
- Severity: high
- Ảnh hưởng user: người chưa đăng nhập có thể vào màn chính hoặc AI Chat nếu biết route hoặc sau khi onboarding hoàn tất.
- Ảnh hưởng dev/build/test: hành vi route không nhất quán giữa các màn protected.

## Cách tái hiện
1. Mở router config.
2. Kiểm tra route `/dashboard` và `/ai-chat`.
3. Guard auth bị comment.

## Đã xác nhận
- `lib/core/router/route_guards.dart:8-16` có `authGuard`.
- `lib/core/router/app_router.dart:49-52` Dashboard comment `redirect: RouteGuards.authGuard`.
- `lib/core/router/app_router.dart:105-109` AI Chat comment `redirect: RouteGuards.authGuard`.
- `lib/core/router/app_router.dart:113-125` Nutrition/Profile vẫn bật `redirect: RouteGuards.authGuard`.
- `lib/features/splash/presentation/pages/splash_page.dart:67-70` điều hướng theo onboarding flag, không kiểm tra Supabase session.

## Giả thuyết
- Guard bị tắt trong lúc phát triển onboarding/offline flow và chưa bật lại trước release.

## Workaround
- Không expose deep link tới các route này.

## Hướng fix đề xuất
- Quyết định rõ màn nào offline được dùng không cần auth.
- Nếu Dashboard/AI Chat là protected route, bật lại `RouteGuards.authGuard`.
- Thêm test route guard cho user null và user đã đăng nhập.

## Files/log liên quan
- `lib/core/router/app_router.dart`
- `lib/core/router/route_guards.dart`
- `lib/features/splash/presentation/pages/splash_page.dart`

## Liên kết
- Worklog: ../../worklog/2026-06-19/007-worklog-release-1-0-bug-audit.md

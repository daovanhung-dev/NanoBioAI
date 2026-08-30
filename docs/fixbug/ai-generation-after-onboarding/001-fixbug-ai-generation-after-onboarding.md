# Fixbug: không tạo được dữ liệu AI sau onboarding

## Kết luận

Nguyên nhân trực tiếp đã được xác định và đã sửa: luồng refresh catalog dùng
`replaceMeals(remoteItems)`, khiến 40 món ăn built-in đã được duyệt bị xóa bởi
163 dòng source-imported từ Supabase. Các dòng source này có
`meal_type=unclassified` và `is_plan_eligible=false`, nên safety selector loại
hết món ăn và dừng ở `_ensureMealSlotsAvailable()` trước khi gọi AI.

Bản sửa đổi refresh sang merge bằng `upsertMeals(remoteItems)`. Các dòng chưa
được duyệt vẫn được lưu để giữ provenance nhưng không được dùng để tạo lịch.

## Triệu chứng và điều kiện tái hiện

- Hoàn tất onboarding trên Android từ profile sạch.
- Màn hình chuyển sang trạng thái tạo lộ trình rồi quay lại màn hình review.
- Không có meal plan hoặc schedule được lưu.
- SQLite ghi request `initial_guest` ở trạng thái `failed` với mã
  `invalid_generation`.
- Sau khi refresh catalog, SQLite có 163 món source nhưng không có món nào
  `is_plan_eligible=true`.
- Log lỗi tương ứng là `No approved meal candidate remains for breakfast.`

## Thiết bị, build và tài khoản

- Thiết bị: Xiaomi `220333QPG`, serial `12b304f9`.
- Package: `com.nanobioai.app`.
- Build: Flutter debug APK, version `1.0.0`, version code `1`, target SDK 36.
- Profile dùng để tái hiện initial onboarding: profile test tổng hợp, không phải
  dữ liệu người dùng thật.
- Plus session: **BLOCKED**. Việc cài debug APK và clear dữ liệu đã làm mất
  session cũ; trạng thái hiện tại trên thiết bị là guest/free. Không tự cấp Plus
  ở client và không tuyên bố đã nghiệm thu member Plus.

## Call chain đã kiểm tra

```text
OnboardingController.saveOnboarding
  -> onboardingCompletionCallbackProvider
  -> GeneratedPlanService.generateInitialGuestPlan
  -> AIService.generateMealPlanWithSource / generateExerciseTasksWithSource
  -> NabiAiBackendClient (Supabase Functions invoke + x-ai-trace-id)
  -> nabi-ai-generate Edge Function
  -> Gemini generateContent
  -> GeneratedPlanRequestStore / SQLite meal_plans / lifestyle_schedule_items
  -> Dashboard
```

Lỗi tái hiện trên thiết bị xảy ra trước nhánh `AIService`: catalog sau refresh
không còn slot meal hợp lệ. Vì vậy lần lỗi đó không tạo execution của Edge
Function.

## Bằng chứng request, trace và provider

Các mã dưới đây là mã kiểm thử không chứa thông tin tài khoản, prompt hay dữ
liệu sức khỏe.

| Trace ID | Execution ID | HTTP | Phân loại |
|---|---|---:|---|
| `codex-plan-probe-20260830` | `096c41fd-4474-4bc2-8e29-9a245150e15f` | 502 | `provider_empty_response`; provider call được bắt đầu với model server mặc định `gemini-2.5-flash` nhưng không có text hiển thị |
| `codex-postdeploy-final` | `b0a43fa0-8a06-4a80-8c78-92d89fd80249` | 200 | smoke hosted thành công; response giữ nguyên `x-ai-trace-id` |

Provider error đầu tiên được log ở dạng an toàn với model, status, error code,
duration và thống kê candidate/part; không log API key, bearer token, prompt,
health data hoặc response thô. Probe đầu tiên không đủ cơ sở để kết luận quota,
key hay model là root cause của lỗi onboarding; root cause đã được xác nhận từ
SQLite/catalog như phần trên.

## Root cause và nguyên nhân phụ

### Root cause chính: refresh catalog phá hủy catalog đã duyệt

Supabase hiện có 164 active rows: 163 source-imported chưa được duyệt và 1 row
đã được duyệt. Code cũ thay thế toàn bộ local meal cache bằng projection đó.
Trong khi đó app đã seed sẵn catalog built-in gồm các slot breakfast,
morning snack, lunch, afternoon snack và dinner. Sau thao tác replace, selector
không còn ứng viên cho breakfast và generation dừng trước network.

### Nguyên nhân phụ: model config bị drift

Client trước đây có candidate mặc định khác với model server mặc định; remote
secret cũng chưa có `GEMINI_MODEL` và `GEMINI_ALLOWED_MODELS`. Đã đồng bộ plan
generation về `gemini-2.5-flash`, là model đã smoke thành công với output budget
đầy đủ, và đặt allowlist server tương ứng.

### Nguyên nhân phụ về chẩn đoán provider

Edge Function cũ gom mọi lỗi provider thành HTTP 502 và không ghi metadata đủ
để phân biệt response bị block, response chỉ có thought parts hay response
rỗng. Đã bổ sung finish reason, block reason, candidate/part counts và
`modelFallback` ở dạng safe structured logging; body contract vẫn là
`{success, text}` hoặc message an toàn.

## File/config đã sửa

- `lib/services/supabase/meal_catalog/meal_catalog_cache_refresh_service.dart`
  - merge remote rows bằng `upsertMeals`, không xóa catalog built-in đã duyệt.
- `lib/app_versions/v1/services/ai/ai_service.dart`
  - đồng bộ candidate mặc định của plan với model allowlist đã kiểm chứng.
- `lib/app_versions/v1/services/ai/nabi_ai_backend_client.dart`
  - giữ interface `AiTextClient`, thêm correlation header và mapping lỗi an toàn.
- `lib/app_versions/v1/services/ai/ai_trace_logger.dart`
  - allowlist metadata cho trace/model/status/duration, không chứa secret hoặc
    nội dung riêng tư.
- `supabase/functions/nabi-ai-generate/handler.ts` và `index.ts`
  - trace propagation, provider status classification và structured logging an
    toàn.
- Các test catalog, generated-plan auth, model candidates và Edge Function
  - cập nhật contract theo hành vi đã sửa.
- `.env` local đã đổi model plan sang `gemini-2.5-flash`; file này bị ignore và
  không được đóng gói vào APK bởi launcher. Credential Gemini cũ trong `.env`
  chưa được in, đọc ngược hoặc ghi vào source.

Không thay đổi schema, RLS hoặc membership business rule.

## Bằng chứng Supabase CLI/deploy

- Project ref đã link: `rnwohifdnylqfofkydfl`, project ACTIVE_HEALTHY.
- `nabi-ai-generate`: ACTIVE, version `4`, `verify_jwt=false`.
- Deployed source đã download vào thư mục tạm trước/sau deploy; hash handler và
  index sau deploy khớp worktree.
- Remote secrets được kiểm tra bằng names/fingerprints, không đọc value. Đã cấu
  hình `GEMINI_MODEL` và `GEMINI_ALLOWED_MODELS` chỉ với model đã smoke.
- Hosted smoke sau deploy trả HTTP 200 và giữ trace response header.
- Supabase CLI dùng cho project link, inventory, secrets, download và deploy;
  log event được kiểm tra theo execution/trace khi endpoint logs cho phép.

`verify_jwt=false` được giữ nguyên để không chặn guest initial onboarding; Edge
Function vẫn tự xác định auth member/guest.

## Kiểm thử và nghiệm thu

| Phạm vi | Kết quả | Bằng chứng |
|---|---|---|
| Edge Function guest/member handler | PASS | valid guest, member stub, trace header và safe response |
| Edge Function provider 401/403/404/429/500/network/empty | PASS | 7 status/error classes được normalize, không lộ provider detail |
| Edge Function malformed/oversized request/response | PASS | 400/413/502 và provider không bị gọi khi request unsafe |
| Deno handler tests | PASS | 7 tests passed |
| Catalog merge DAO tests | PASS | 8 tests passed |
| `generated_plan_service_auth_test.dart` | PASS | 13 tests passed |
| Model candidate/Backend contract tests | PASS | 4 targeted tests passed |
| Targeted Flutter analyze | PASS | 5 source items, no issues |
| `flutter build apk --debug` | PASS | APK build thành công |
| Real-device initial onboarding | PASS | local request `succeeded`, `generation_source=ai`; 35 meals, 14 exercises, 77 schedule items; Dashboard hiển thị dữ liệu |
| Real-device authenticated Plus new schedule | BLOCKED | debug reinstall/clear làm mất Plus session; thiết bị hiện guest/free |
| Full `ai_service_test.dart` | EXISTING FAILURES | một số assertion cũ bắt `debugPrint` trong khi logger dùng `dart:developer`, và có message contract cũ; không liên quan trực tiếp catalog fix |

## Credential và bảo mật còn tồn đọng

Credential Gemini đã xuất hiện trong context làm việc nên phải xem là đã lộ.
Chưa thể hoàn tất revoke/rotate trong lần chạy này vì chưa có credential mới
được nhập qua kênh ẩn. Không dùng lại credential đó để ghi vào repo, log hoặc
APK. Cần revoke key cũ tại provider, tạo key mới và cập nhật trực tiếp bằng
secret manager/terminal; sau đó chạy lại hosted smoke.

## Residual risks và bước nghiệm thu còn lại

1. Đăng nhập một tài khoản Plus thật trên debug build, xác minh
   `effective_user_access` là Plus từ backend, rồi chạy tạo lịch 7 ngày mới.
2. Kiểm tra quota check/commit và refresh Dashboard cho member flow.
3. Sau khi xoay credential, redeploy/smoke lại và xác nhận không có secret trong
   APK hoặc logcat.
4. Chuẩn hóa test logger để `ai_service_test.dart` bắt đúng sink hiện tại;
   không hạ safety filter để làm test catalog pass.

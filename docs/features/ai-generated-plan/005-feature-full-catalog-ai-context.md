Commit de xuat: feat(ai): gui day du catalog ma ten vao prompt

# Gửi đầy đủ catalog SQLite cho AI tạo lịch

## Mục tiêu

Để mỗi lượt AI lập lịch có thể chọn từ toàn bộ danh mục hiện có bằng mã và tên. Ứng dụng vẫn gọi Supabase Edge Function; Edge Function giữ Gemini API key và gọi Gemini.

## Luồng hiện tại

1. `GeneratedPlanService` tải bundle qua `AiCatalogLocalDatasource.loadScheduleCatalogBundle()`.
2. `AiCatalogDao` đọc mọi hàng trong `meal_catalog`. Legacy món đã selectable được đưa vào policy chung; candidate `nabi_vn_*` chỉ vào prompt khi nằm trong `eligibleCodesByType` của policy `wellnessSchedule`. Các bài tập tiếp tục được đọc từ `exercise_catalog` và chia theo trạng thái selection.
3. Trong mỗi lượt tạo bữa, prompt giữ đủ code/name của mọi legacy món được chọn và candidate wellness được cho phép. Candidate chỉ gửi `[{code, name}]`; không gửi description, ingredients, steps hay nutrition. Tóm tắt legacy có thể rút ngắn theo ngân sách byte. Trong mỗi lượt vận động, prompt chứa tất cả bài tập dạng `[{code, name}]`, nhóm thành `selectable` và `context_only` theo trạng thái `is_active` trong SQLite.
4. Catalog chứa 3.163 món và 40 bài tập: giữ 163 món hiện có, thêm 3.000 candidate; 16 bài M02 đang hoạt động để chọn, 24 bài M32 đang chờ rà soát chỉ làm ngữ cảnh. Không được chọn mã `context_only`; `ExerciseTasksAiNormalizer` từ chối mã inactive nếu AI trả về.
5. AI chỉ trả ngày, loại bữa và mã món hoặc ngày và mã bài. Ứng dụng kiểm tra mã/ngày/số lượng, dựng chi tiết chuẩn từ SQLite, giữ staging cho các lượt đã hợp lệ, rồi ghi kế hoạch nguyên tử khi đủ 35 bữa và 14 hoạt động.

## Giới hạn request

- Ngưỡng ký tự 32.000 ở prompt và Edge Function đã được gỡ. Danh sách không bị lọc theo điều kiện hay bỏ món để vừa request.
- JSON catalog món có ngân sách 1.000.000 byte. Nếu dữ liệu tóm tắt vượt ngân sách, ứng dụng rút ngắn `nutrition_summary` và bỏ trường tóm tắt nếu cần; mọi mã và tên vẫn còn trong danh sách. Nếu riêng mã/tên vượt ngưỡng, prompt báo lỗi rõ ràng thay vì bỏ món.
- Edge Function dùng `models.get` để lấy `inputTokenLimit`/`outputTokenLimit` và `models.countTokens` để đếm toàn bộ request, kể cả system instruction và generation config, trước `generateContent`.
- Request body bị chặn ở 1.500.000 byte. Vượt giới hạn model trả lỗi HTTP 413 với mã `MODEL_CONTEXT_LIMIT_EXCEEDED`; vượt dung lượng request trả mã `REQUEST_TOO_LARGE`. Flutter ánh xạ cả hai lỗi thành thông báo rõ ràng. Không có giới hạn token giả lập ở ứng dụng.
- Token preflight chỉ gửi nội dung đến Gemini qua backend có credential; thiết bị không gọi API Gemini trực tiếp.

## Quyền chọn và giới hạn dữ liệu

- Danh sách món giữ đủ mã và tên của các món qua cổng eligibility; tóm tắt dinh dưỡng là ngữ cảnh wellness, không phải phân tích khẩu phần. Chi tiết đầy đủ được ứng dụng nạp từ SQLite sau khi chuẩn hóa mã AI trả về. Normalizer kiểm tra trạng thái duyệt, active, plan eligibility, loại bữa và danh sách mã được profile selector cho phép.
- Theo quyết định trực tiếp ngày 2026-10-16, 3.000 món candidate được bundle và seed cùng 163 món cũ. `is_active=true` không cấp quyền chọn: policy wellness chỉ cho phép candidate có trạng thái cụ thể chưa rà soát và mã được selector đưa vào `eligibleCodesByType`; policy strict vẫn chặn. Normalizer và fallback áp dụng cùng danh sách mã. Dị ứng/thực phẩm cần tránh chưa xác minh tiếp tục fail-closed.
- Candidate vẫn có `is_plan_eligible=false`, `metadata_status=ai_generated_needs_review`, `nutrition_status=estimated_unverified`, `meal_type=unclassified`, allergen status unknown. AI chỉ nhận code/name. Sau khi AI chọn, SQLite hydrate recipe; nutrition estimate bị loại khỏi snapshot và không hiển thị như số liệu đã biết. Quyết định sử dụng chưa xác nhận quyền phân phối hoặc độ chính xác chuyên môn.
- Danh sách bài tập được gửi trọn vẹn. Chỉ trạng thái active cho phép lưu; trạng thái inactive được AI nhìn thấy để tham khảo nhưng không có quyền chọn.
- Mã và tên không đủ dữ kiện để xác minh dinh dưỡng, dị ứng, chống chỉ định hoặc mức phù hợp y khoa. Luồng này chỉ hỗ trợ wellness; không khẳng định lịch đã được xác minh y tế.
- Prompt version hiện tại là `personal_schedule_v12_unreviewed_wellness_candidates` để staging không trộn với catalog mới.

## Kiểm chứng

- Bundle/DAO test xác nhận 3.163 mã duy nhất gồm 163 legacy và 3.000 candidate; prompt giữ đủ code/name candidate và không thêm trường recipe/nutrition candidate.
- Migration v36 test xác nhận nâng 163 lên 3.163, hash nguồn, trạng thái `is_plan_eligible=false`, bảo toàn hàng cũ và dữ liệu người dùng; seeder cài mới có 3.163 món.
- Prompt bài tập xác nhận 16/24 được chia đúng hai nhóm; normalizer từ chối mã inactive.
- Luồng kế hoạch xác nhận 14 lượt theo thứ tự, 35 bữa/14 hoạt động và một lần commit nguyên tử.
- Deno test xác nhận nội dung trên 32.000 ký tự được chuyển tiếp, request trên 1.500.000 byte bị chặn, token preflight kiểm tra cả input và output, và không cần gọi Gemini thật trong test.

## Trạng thái xác nhận

Tích hợp source hiện tại đã đưa catalog 3.163 món vào SQLite/seeder; policy wellness gửi đủ code/name candidate và hydrate chi tiết từ SQLite. Nhóm kiểm chứng tập trung PASS: 6 test storage/migration/catalog bundle, 46 test selector/normalizer/lịch/hydrate/detail, và 2 test AIService cho candidate prompt/fallback. `flutter build bundle --no-pub` PASS; asset JSON trong `build/flutter_assets` khớp file nguồn và có kích thước 8.084.717 byte. Đây là kích thước asset chưa nén, không phải APK.

Thiết bị Xiaomi 220333QPG Android 11 đã hot-restart từ phiên `flutter run`, nâng SQLite v35 lên v36 và xác nhận tại database trên thiết bị có 3.163 món, 40 bài tập; hồ sơ và staging cũ được giữ lại. Onboarding hiện vẫn `in_progress`; request guest cũ có 0 bữa/0 hoạt động và trạng thái failed. Chưa tạo request AI mới, chưa nhận response Gemini hoặc xác nhận quota Supabase. Theo quyết định người dùng, việc gửi code/name trong policy wellness không đồng nghĩa quyền sử dụng đã được chứng minh hoặc dữ liệu chuyên môn đã được rà soát. `is_plan_eligible=false`, nutrition và allergen/constraint status chưa xác minh được giữ nguyên; policy strict vẫn chặn candidate.

## Kích thước dữ liệu candidate hiện tại

Đo `assets/data/nabi_3000_mon_viet_moi.json` ngày 2026-10-16:

- JSON gốc: 8.084.717 byte, 3.000 mã duy nhất.
- Chỉ mục JSON `[{code,name}]` của 3.000 candidate: 321.212 byte UTF-8.
- Flutter bundle chứa nguyên asset JSON, byte-for-byte cùng hash với file nguồn. Prompt chỉ nhận cặp code/name candidate; không gửi full JSON hoặc công thức.

Đây là phép đo serialization UTF-8 local, không phải số token Gemini hoặc chi phí/lời gọi model. Prompt vẫn áp dụng ngân sách catalog 1.000.000 byte và giữ đủ mã/tên; sau khi AI trả mã, ứng dụng hydrate recipe từ SQLite.

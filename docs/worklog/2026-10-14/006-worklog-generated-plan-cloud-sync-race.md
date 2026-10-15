Commit de xuat: docs(worklog): ghi nhan fix tao lich va cloud sync

# Worklog - Tái hiện và sửa lỗi tạo lịch trình mới

## Thời gian

- Ngày: 2026-10-14
- Bắt đầu: Phiên tiếp nối; thời điểm bắt đầu chính xác không được ghi lại.
- Kết thúc: 23:28
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: Tái hiện lỗi trên điện thoại, chẩn đoán và sửa lỗi, regression tests.
- Module chính: M02 tạo lịch AI; đồng bộ dữ liệu cục bộ/cloud.
- Yêu cầu gốc: Kiểm tra trạng thái app trên điện thoại đang chạy, tái hiện lỗi
  tạo lịch mới, ghi lỗi trong hội thoại và sửa lỗi. Người dùng cho phép thử với
  backend production.

## Đã làm

- Tái hiện lần đầu: request trên app có trạng thái `failed`, 7 ngày, 0 bữa,
  0 bài tập, 0 mục lịch, `error_code=staging_fingerprint_changed`; không có
  Flutter runtime exception.
- Thêm test tái hiện race khi hai lần tạo lịch guest đồng thời cùng user dùng
  chung request ID; thêm single-flight theo user.
- Lỗi staging vẫn tái hiện sau single-flight. Truy nguyên cloud pull dùng
  `INSERT OR REPLACE` cho bảng `users`, kích hoạt khóa ngoại cascade xóa request
  và staging; đồng thời snapshot cloud cũ có thể thay trạng thái request đang
  chạy. Sửa bằng update user tại chỗ và giữ request có staging trong lúc áp
  snapshot.
- Trên điện thoại, sau khi staging được giữ lại, backend production tạo đủ nội
  dung 7 ngày nhưng bước kết thúc ghi `failed / invalid_generation`. Truy nguyên
  cloud sync đã remap ID local không phải UUID thành UUID, trong khi transaction
  cuối kiểm tra theo ID local cũ.
- Đổi ID bữa ăn và lịch trình được sinh thành UUID v5 ổn định trước khi lưu
  từng ngày; cùng ID được dùng cho commit toàn lịch. Thử tiếp tục từ staging đã
  có và request hoàn tất, không cần tạo lại nội dung AI.

## File code/docs đã sửa

- `lib/app_versions/v1/services/ai/generated_plan_service.dart` - khóa
  single-flight tạo lịch guest và ID UUID ổn định cho hàng bữa ăn/lịch.
- `lib/app_versions/v2/features/cloud_sync/data/datasources/sqlite_user_data_sync_local_datasource.dart`
  - giữ request đang staging khi áp snapshot cloud; tránh thay parent user bằng
  thao tác gây cascade.
- `test/app_versions/v1/services/ai/generated_plan_service_auth_test.dart` -
  regression cho concurrent guest request và tính ổn định ID.
- `test/app_versions/v2/features/cloud_sync/sqlite_user_data_sync_proof_test.dart`
  - regression cho cloud replacement với request/staging đang chạy.
- `docs/fixbug/generated-plan-staging-cloud-sync/001-fixbug-generated-plan-staging-cloud-sync.md`
  - mô tả triệu chứng, nguyên nhân, sửa chữa và phạm vi kiểm chứng.

## Tài liệu liên quan

- `.codex/workflows/bugfix.md`
- `.codex/task-skills/bugfix.md`
- `.codex/domains/ai-service.md`
- `.codex/DOCS_WORKFLOW.md`

## Commands

- Regression test service `generated_plan_service_auth_test.dart`: PASS - 21
  test.
- Regression test `sqlite_user_data_sync_proof_test.dart`: PASS - 4 test.
- Dart analyzer trên 4 file Dart/test liên quan: PASS - không có lỗi.
- `dart format` trên 4 file liên quan: PASS - không cần thay đổi.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL - repository-wide check
  báo thiếu `docs/audit/source_truth_manifest.json` và stale paths trong
  `.codex/history/WORKLOG_2026-08-16_meal_nutrition_estimation.md` cùng
  `.codex/task-skills/nabi-character/SKILL.md`; các mục này nằm ngoài phạm vi
  file task đã sửa.
- Flutter hot reload: PASS; runtime error query sau lần chạy thành công: không
  có lỗi.
- `git diff --check`: PASS sau khi thêm tài liệu và refresh history/task-skill.
- Production-config phone generation: PASS - request `succeeded`, 7 ngày,
  35 bữa ăn, 14 bài tập, 77 mục lịch; staging 0 hàng, outbox 0 hàng.

## Lỗi/Rủi ro

- Đã fix: race ghi staging, cloud pull xóa staging do cascade, và mismatch ID
  làm transaction cuối đánh dấu lịch hợp lệ thành `invalid_generation`.
- Chưa fix: request tiếp tục từ staging hiển thị `generation_source=unknown`;
  chưa xác định nguồn của giá trị provenance này.
- Validation toàn repo: source-truth manifest thiếu và một số stale paths
  không liên quan làm script integrity thất bại; không sửa các file ngoài phạm
  vi bugfix.
- Cần kiểm tra tiếp: nếu cần khẳng định provenance AI trong ledger, truy nguyên
  riêng cách dữ liệu source được khôi phục sau staging. Không thay đổi dữ liệu
  user hoặc gửi thêm yêu cầu AI trong task này.

## Tỷ lệ hoàn thành

- Hoàn thành: tái hiện, sửa nguyên nhân, regression tests, analyzer, hot reload,
  và xác nhận kết quả trên điện thoại.
- Đang dở: không còn mục nào cần để đáp ứng lỗi tạo lịch; provenance
  `generation_source` là vấn đề riêng chưa giải quyết.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - theo dõi cả vòng staging, cloud pull và transaction
  cuối; không dừng ở lỗi đầu tiên.
- Mức độ hoàn thành task: hoàn thành; lịch đã được tạo thành công trên điện
  thoại production-config.
- Bằng chứng kiểm chứng: 25 test tập trung qua 2 suite, analyzer không lỗi,
  hot reload, runtime error query sạch, và request SQLite đạt 7/35/14/77 với
  staging/outbox rỗng.
- Điểm tốn token/chưa tối ưu: phải chạy lại một yêu cầu production đã được cho
  phép để có dữ liệu tái hiện; sau khi đủ chunk đã staging, các bước sửa sau
  được xác minh bằng tiếp tục request hiện có.
- Cách tối ưu cho phiên sau: thêm test mô phỏng cloud pull giữa các ngày tạo
  lịch và kiểm tra resume/commit với ID UUID ngay từ đầu.
- Task-skill cần đọc lần sau: `.codex/task-skills/bugfix.md`

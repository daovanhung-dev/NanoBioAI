Commit de xuat: docs(worklog): ghi nhan kiem tra live api backend

# Worklog - Kiểm tra live toàn bộ API backend

## Thời gian

- Ngày: 2026-10-31
- Bắt đầu: 15:52
- Kết thúc: 16:08
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: test
- Module chính: backend API
- Yêu cầu gốc: gọi đủ 95 API trong `docs/backend/listapi.md` trên server live và ghi input/output/trạng thái vào `docs/backend/result.md`.

## Đã làm

- Đối chiếu OpenAPI live: 85 path, 95 operation, khớp danh sách endpoint local.
- Gọi tuần tự toàn bộ 95 operation qua SSH tunnel, dùng actor và dữ liệu tổng hợp; kết quả ghi trong báo cáo bốn cột.
- Phân loại 84 API `Sống`, gồm phản hồi thành công và guard đúng contract; 11 API `Chết` theo HTTP/business code hoặc thiếu bảng PostgreSQL.
- Dùng nhánh an toàn cho Sleep Safety; không gửi SMS, không gọi điện và không cập nhật event thật.
- Xóa actor/bản ghi seed riêng. Gỡ đúng dòng allocation-use do test tạo sau khi kiểm tra xóa tài khoản phát hiện ràng buộc `RESTRICT`; API xóa tài khoản sau đó trả thành công.
- Không sửa source backend, cấu hình, migration, feature flag hoặc dữ liệu người dùng hiện có.

## File code/docs đã sửa

- `docs/backend/result.md` - tạo - kết quả 95 API, gồm input/output đã làm sạch và trạng thái.
- `docs/test/backend-api-live/001-test-backend-api-live-2026-10-31.md` - tạo - phạm vi, tóm tắt kết quả, lỗi server và giới hạn bằng chứng.
- `docs/worklog/2026-10-31/006-worklog-backend-live-api-test.md` - tạo - ghi nhận phiên kiểm thử.
- `.codex/history/*`, `.codex/task-skills/*` - dự kiến cập nhật bằng script history refresh sau khi worklog hoàn tất.

## Tài liệu liên quan

- `docs/backend/listapi.md`
- `backend/src/nanobio_backend/api/v1/router.py`
- `backend/src/nanobio_backend/modules/*/router.py`
- `backend/.agents/project/05-api-contract.md`
- `docs/test/backend-api-live/001-test-backend-api-live-2026-10-31.md`

## Commands

- Gọi HTTP tuần tự qua SSH tunnel tới server loopback: PASS - 95/95 operation có phản hồi và kết luận.
- So khớp OpenAPI live với `listapi.md`: PASS - 95 method/path trùng khớp.
- Kiểm tra schema PostgreSQL live: PASS - xác nhận thiếu `schedule_reward_registrations` và `schedule_health_checkins`.
- Xác nhận dọn dữ liệu: PASS - các bản ghi test được theo dõi còn 0; actor test bị xóa.
- Kiểm tra cấu trúc báo cáo 95 dòng, endpoint duy nhất, đủ input/output/status: PASS - 95 dòng, bốn cột, đúng thứ tự `listapi.md`, 84 sống/11 chết.
- So khớp OpenAPI live: PASS - 95 operation trên 85 path.
- `git diff --check`: PASS.
- `.codex/tools/validate_codex_integrity.ps1`: FAIL do lỗi toàn repo có trước: thiếu `docs/audit/source_truth_manifest.json` và đường dẫn cũ trong `.codex/history/WORKLOG_2026-08-16_meal_nutrition_estimation.md` cùng `.codex/task-skills/nabi-character/SKILL.md`.
- `.codex/tools/update_worklog_learning.ps1`: PASS - cập nhật 19 file history/task-skill sinh tự động.
- Unit/runtime test suite: SKIPPED - phạm vi là kiểm tra endpoint live đã yêu cầu; không sửa source backend.

## Lỗi/Rủi ro

- Đã fix trong phạm vi dữ liệu test: xóa dòng wellness allocation-use do test tạo để tài khoản test xóa được; không đổi schema hoặc source.
- Chưa fix: 11 endpoint bị cấu hình/provider/schema live chặn; các nguyên nhân và mã lỗi được ghi trong `docs/backend/result.md`.
- Cần kiểm tra tiếp: đối chiếu server source/revision trước khi quy lỗi nào cho snapshot local; server không có Git metadata và fingerprint source khác local.

## Tỷ lệ hoàn thành

- Hoàn thành: gọi đủ API, ghi báo cáo, dọn test seed, chạy kiểm tra cấu trúc, diff check và refresh history.
- Đang dở: integrity validator vẫn báo lỗi repo-wide ngoài phạm vi hiện tại.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - ghi rõ phản hồi live, guard, cấu hình thiếu và giới hạn snapshot server; không lưu token, mật khẩu, PII hay nội dung AI.
- Mức độ hoàn thành task: đủ 95/95 endpoint, báo cáo và cleanup hoàn tất.
- Bằng chứng kiểm chứng: OpenAPI 95 operation khớp; request HTTP có phản hồi; schema live xác nhận bảng còn thiếu; cleanup counts bằng 0; structural validator và `git diff --check` pass.
- Điểm tốn token/chưa tối ưu: một số payload đầu tiên bị enum/password-change guard; đã sửa payload và chạy lại đúng actor test.
- Cách tối ưu cho phiên sau: tự động lấy schema từ OpenAPI trước khi tạo payload và lưu metadata phản hồi đã redact theo từng request.
- Task-skill cần đọc lần sau: `.codex/task-skills/test.md`

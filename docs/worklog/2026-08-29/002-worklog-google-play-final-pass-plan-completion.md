Commit de xuat: docs(worklog): hoan thien Google Play final pass execution plan

# Worklog - Hoàn thiện Google Play Final Pass execution plan

## Thời gian

- Ngày: 2026-08-29
- Bắt đầu: 17:00
- Kết thúc: 17:08
- Timezone: Asia/Ho_Chi_Minh

## Phạm vi

- Loại task: `docs-context`
- Module chính: `docs/tasks`, release evidence Google Play
- Yêu cầu gốc: đọc và hoàn thiện `NanoBioAI_Google_Play_Final_PASS_Execution_Plan_GPT-5.6-Luna_2026-08-29.md`

## Đã làm

- Đọc toàn bộ kế hoạch 2.593 dòng và các tài liệu release Google Play liên quan.
- Chuẩn hóa metadata: workflow thực thi canonical là `fix-issues`; release-hardening
  là profile, không phải workflow thứ hai.
- Thêm `Definition of Ready`, quy tắc `RUN_ID/evidence`, protocol ghi nhận sau
  từng phase và bảng owner/output/checkpoint.
- Thêm current gate snapshot với trạng thái evidence hiện có; giữ rõ các gate
  `BLOCKED_EXTERNAL`/`FAIL`, không chuyển source evidence thành runtime PASS.
- Thêm kiểm tra input contract cho form Play và quy tắc redaction.
- Bổ sung Phase 14 về allowlist, ZIP handoff, kiểm tra giải nén và điều kiện
  đóng session.
- Cập nhật link/chú thích policy chính thức cho account deletion, Data Safety,
  target API, Billing, Health Apps, FGS và 16 KB; yêu cầu recheck trước execution.
- Ghi rõ phiên này chỉ hoàn thiện plan, chưa thực thi release gate và chưa tạo ZIP.

## File code/docs đã sửa

- `docs/tasks/NanoBioAI_Google_Play_Final_PASS_Execution_Plan_GPT-5.6-Luna_2026-08-29.md` - hoàn thiện cấu trúc, status snapshot, phase protocol và policy references.
- `docs/worklog/2026-08-29/002-worklog-google-play-final-pass-plan-completion.md` - ghi nhận phiên và self-review.

## Tài liệu liên quan

- `docs/release/google_play/README.md`
- `docs/release/google_play/RELEASE_EVIDENCE_MATRIX.md`
- `docs/release/google_play/ACCOUNT_DELETION.md`
- `docs/release/google_play/PRIVACY_POLICY_PUBLIC_PAGE.md`
- `docs/release/google_play/DATA_SAFETY_MAPPING.md`
- `docs/release/google_play/HEALTH_APPS_DECLARATION.md`
- `docs/release/google_play/FOREGROUND_SERVICE_DECLARATION.md`
- `docs/release/google_play/STORE_LISTING_CLAIMS_REVIEW.md`
- `.codex/history/OPEN_RISKS.md`

## Commands

- `sed -n ... docs/tasks/NanoBioAI_Google_Play_Final_PASS_Execution_Plan_GPT-5.6-Luna_2026-08-29.md`: PASS - đọc đủ file theo các đoạn liên tiếp.
- `grep -nE ... plan`: PASS - xác nhận các marker hoàn thiện; `rg` không có trong môi trường nên dùng fallback `grep`.
- `git diff --no-index --check /dev/null <plan>`: PASS - không còn trailing whitespace.
- `git diff --check`: PASS.
- `find`/`test -f` cho các path release/context: PASS - path tham chiếu tồn tại; form Play vẫn là external input theo plan.
- `powershell -ExecutionPolicy Bypass -File .codex/tools/validate_codex_integrity.ps1`: UNVERIFIED - môi trường không có `powershell` hoặc `pwsh`.
- Flutter analyze/test/build: SKIPPED - chỉ thay đổi tài liệu kế hoạch/worklog.

## Lỗi/Rủi ro

- Đã fix: status matrix trống, workflow metadata dễ hiểu là trộn nhiều workflow,
  thiếu Phase 14 và thiếu protocol evidence/owner/input.
- Chưa fix: release vẫn `NO-GO`; chưa có public legal URLs, Play Console,
  Supabase sandbox, Android device, Internal Track hoặc runtime purchase evidence.
- Cần kiểm tra tiếp: khi user xác nhận execution, bắt đầu Phase 0; chạy validator
  PowerShell trên môi trường có sẵn và cập nhật `RELEASE_EVIDENCE_MATRIX.md` chỉ
  sau khi có evidence thật.

## Tỷ lệ hoàn thành

- Hoàn thành: kế hoạch `100%` ở mức tài liệu/execution-ready.
- Đang dở: release verification và production submission `0%` trong phiên này;
  các gate mở được ghi rõ là `BLOCKED_EXTERNAL`, `FAIL` hoặc `PLANNED`.

## Tự đánh giá và tối ưu phiên sau

- Chất lượng đầu ra: tốt - plan có entry/exit criteria, owner, evidence và
  status snapshot; không tuyên bố runtime PASS từ source-only evidence.
- Mức độ hoàn thành task: hoàn tất yêu cầu đọc và hoàn thiện plan; chưa thực thi
  đúng theo chủ ý của tài liệu.
- Bằng chứng kiểm chứng: đọc đủ plan/release docs; targeted marker checks và
  `git diff --check` PASS; Codex integrity validator UNVERIFIED vì thiếu PowerShell.
- Điểm tốn token/chưa tối ưu: plan dài nên cần đọc theo heading/chunk; không đọc
  raw source/test vì task chỉ cập nhật docs.
- Cách tối ưu cho phiên sau: bắt đầu từ input contract và external access matrix,
  sau đó chỉ mở source/test đúng phase; giữ một `RUN_ID` xuyên suốt.
- Task-skill cần đọc lần sau: `.codex/task-skills/fix-issues.md`

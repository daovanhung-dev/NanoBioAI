Commit de xuat: docs(worklog): ghi nhan doi production api origin

# Worklog - Chuyển Production Backend sang domain nanobio.s2w.click

## Thoi gian

- Ngay: 2026-11-02
- Bat dau: truoc 11:32
- Ket thuc: 11:34
- Timezone: Asia/Saigon

## Pham vi

- Loai task: coding
- Module chinh: Flutter backend client, Admin Web, FastAPI CORS/public origin, build scripts
- Yeu cau goc: dùng `https://nanobio.s2w.click` làm Production API origin; giữ nguyên `/api/v1` trong endpoint, local overrides, auth và business logic.

## Da lam

- Đổi Flutter default và bundled public config sang `https://nanobio.s2w.click`; giữ base URL ở root.
- Giữ thứ tự `dart-define` → dotenv → bundled config. Run/build helpers dùng bundled config khi local `.env` thiếu `API_BASE_URL`; giá trị override không bí mật tiếp tục được chuyển thành Dart define. Không đọc/in/sửa `.env` local.
- Cố định Admin Web Production build vào domain mới; giữ `.env.example` trống để Vite local proxy tiếp tục dùng loopback.
- Thêm origin GitHub Pages chính xác vào ví dụ CORS và cập nhật `PUBLIC_API_BASE_URL`; không thêm wildcard hoặc sửa middleware/TLS.
- Cập nhật audit script, regression host mặc định và hướng dẫn AI hiện hành; giữ nguyên history, issue snapshot đang có và endpoint ESP `/api/chat` độc lập.
- Thêm tests cho bundled origin, dotenv/dart-define precedence, API path resolution, Admin Web API origin và CORS allowlist.
- Không sửa auth/JWT, AI, upload, cloud sync, business logic, schema hoặc dữ liệu.

## File code/docs da sua

- Flutter: `lib/core/network/backend_api_client.dart`, `assets/config/auth.env`, các tests trong `test/core/config/` và `test/core/network/`.
- Run/build: `tools/prepare_dart_defines.ps1`, `tools/run_v2.ps1`, `tools/build_authenticated.ps1`.
- Admin Web: `.github/workflows/deploy-admin-web.yml`, `admin-web/.env.example`, tests trong `admin-web/src/lib/`.
- Backend: `backend/.env.example`, `backend/tests/test_cors_config.py`.
- Audit/context: `tools/audit_self_hosted_runtime.py`, `tools/regression/Invoke-RegressionIntegration.ps1`, `.codex/domains/ai-service.md`, `lib/app_versions/v1/services/ai/README_FIX.md`.

## Tai lieu lien quan

- `.codex/AGENTS.md`
- `.codex/PROJECT_MAP.md`
- `.codex/workflows/coding.md`
- `.codex/task-skills/coding.md`
- `backend/.agents/context-map.md`

## Commands

- `flutter analyze` trên các file Dart liên quan: PASS - 0 issues.
- Flutter config/API path tests: PASS - 10 tests.
- Flutter `--dart-define` precedence test: PASS - 1 test.
- `uv run pytest tests/test_cors_config.py`: PASS - 3 tests; có cảnh báo deprecation từ Starlette/httpx.
- `uv run ruff check tests/test_cors_config.py ../tools/audit_self_hosted_runtime.py`: PASS.
- Admin Web Vitest qua Deno do không có Node/npm: PASS - 6 tests.
- Admin Web TypeScript build và Vite Production build qua Deno: PASS; output bundle chứa domain mới và không chứa IP cũ.
- `tools/run_v2.ps1 -ValidateOnly`: PASS - bundled fallback được dùng khi `.env` thiếu `API_BASE_URL`.
- `tools/prepare_dart_defines.ps1` với fixture tạm: PASS - override local được truyền đi; key thiếu vẫn unset để dùng bundled config.
- PowerShell parser cho run/build/prepare/regression scripts: PASS.
- `python3 tools/audit_self_hosted_runtime.py`: PASS - kiểm tra 948 file runtime/build.
- `pwsh -File .codex/tools/validate_codex_integrity.ps1`: FAIL - baseline thiếu `docs/audit/source_truth_manifest.json` và có các stale paths trong worklog/task-skill cũ, không liên quan tới thay đổi này.
- `git diff --check`: PASS.
- `curl https://nanobio.s2w.click/health/ready` và CORS preflight bằng TLS verification mặc định: BLOCKED - certificate không có SAN khớp hostname; HTTP status 000, TLS verify result 1. Không dùng HTTP hoặc bỏ xác minh TLS.
- Thiết bị thật, deployment và CORS production: NOT VERIFIED - deployment không thuộc phạm vi task; HTTPS chưa hợp lệ.

## Loi/Rui ro

- Da fix: các cấu hình Production trong source, Flutter asset, workflow và docs hiện hành dùng origin domain mới, không có `/api/v1` trong base URL.
- Chua fix: chứng chỉ Production không khớp `nanobio.s2w.click`; readiness và CORS qua mạng thật đang BLOCKED.
- Can kiem tra tiep: sau khi cấp chứng chỉ TLS có SAN đúng, chạy lại readiness/CORS preflight và nghiệm thu login, refresh, cloud sync, AI/streaming, upload, Admin và nghiệp vụ trên thiết bị thật.
- `.env` local không có `API_BASE_URL`; file bị ignore được giữ nguyên. Các tham chiếu IP còn lại là history/issue evidence và tài liệu ESP `/api/chat` riêng.

## Ty le hoan thanh

- Hoan thanh: cập nhật source/config, tests cục bộ và build Admin Web với origin Production mới.
- Dang do: kiểm tra Production readiness/CORS và nghiệm thu thiết bị thật bị BLOCKED bởi certificate.

## Tu danh gia va toi uu phien sau

- Chat luong dau ra: tot - giữ config precedence, local proxy, allowlist CORS và API path; không đổi business logic.
- Muc do hoan thanh task: source và local validation hoàn tất; Production acceptance còn BLOCKED do certificate.
- Bang chung kiem chung: targeted Flutter/Python/Admin tests, PowerShell validation, audit script và Admin bundle build đã chạy; live HTTPS không qua certificate verification.
- Diem ton token/chua toi uu: `rg` không có; dùng `git grep`. Node/npm không có nên dùng Deno cho Vitest/TypeScript/Vite.
- Cach toi uu cho phien sau: sau khi sửa certificate, chỉ cần lặp lại health/CORS probe và checklist thiết bị; không cần đọc lại toàn bộ source config.
- Task-skill can doc lan sau: `.codex/task-skills/coding.md`

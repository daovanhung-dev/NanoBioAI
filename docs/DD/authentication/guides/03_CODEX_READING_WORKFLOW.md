# Workflow đọc DD cho Codex

## Prompt khởi động gợi ý

```text
Nhiệm vụ: <mô tả task>.
1. Đọc .codex theo workflow dự án.
2. Đọc docs/DD/authentication/00_READ_FIRST.md.
3. Dựa vào Document Map, chỉ đọc DD feature của task và dependency trực tiếp.
4. Nêu các business rule/invariant không được phá vỡ.
5. Lập plan ngắn gồm file dự kiến sửa và test case DD cần đạt.
6. Chỉ coding sau khi plan đã xác định scope. Không tự sửa database/client ownership trái DD.
```

## Prompt review gợi ý

```text
Review thay đổi Authentication theo docs/DD/authentication.
Đọc 00_READ_FIRST.md, DD feature liên quan, 03_DATA_MODEL_RLS_AND_MIGRATIONS.md và 15_TEST_ACCEPTANCE_AND_TRACEABILITY.md.
Chỉ tìm issue; không coding. Báo cáo theo: DD ID / rule bị vi phạm / bằng chứng file-line / mức độ / hướng sửa.
```

## Prompt test gợi ý

```text
Test module Authentication theo DD-AUTH-TEST-001. Không sửa code.
Chạy các test khả dụng, đối chiếu test matrix theo feature thay đổi, và ghi nhận pass/fail/blocked kèm bằng chứng.
```

## Scope guard

- Task UI text: không mở/sửa SQL/auth flow trừ khi có bug liên quan.
- Task onboarding: không tự thêm OAuth/2FA.
- Task trigger/RLS: không refactor UI không liên quan.
- Task test: không chỉnh production code nếu chưa được yêu cầu fix.
